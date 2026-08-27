import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { Note } from 'src/generated/prisma/client';
import {
  NoteSharePermission,
  NoteState,
  SyncOp,
} from 'src/generated/prisma/enums';
import { NoteAccessService } from '../notes/services/note-access.service';
import {
  GuardedNoteFields,
  guardedNoteFieldsChanged,
  noteContentChanged,
} from '../notes/utils/note-versioning.util';
import { transformNote } from '../notes/utils/note-transformer.util';
import { ownedTagIds, reconcileUserTags } from '../notes/utils/note-tags.util';
import {
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
  NOTE_INCLUDE_ATTACHMENT_COUNT,
  notePinInclude,
} from '../notes/constants/notes.constants';
import {
  SyncEmitterService,
  noteEmissions,
  pinEmission,
  tagEmission,
} from './sync-emitter.service';
import { NoteRevisionsService, revisionsCover } from './note-revisions.service';
import type {
  SyncChange,
  SyncNoteChangeDto,
  SyncPinChangeDto,
  SyncTagChangeDto,
} from './dto/sync-request.dto';
import { SyncApplyResult, toSyncTagPayload } from './dto/sync-response.dto';

@Injectable()
export class SyncApplyService {
  private readonly logger = new Logger(SyncApplyService.name);

  constructor(
    private prisma: PrismaService,
    private noteAccess: NoteAccessService,
    private syncEmitter: SyncEmitterService,
    private noteRevisions: NoteRevisionsService,
  ) {}

  async apply(
    userId: string,
    changes: SyncChange[],
  ): Promise<SyncApplyResult[]> {
    // Repeats of the same entity coalesce to the last one.
    const deduped = new Map<string, SyncChange>();
    for (const change of changes) {
      deduped.set(`${change.type}:${change.id}`, change);
    }

    const results: SyncApplyResult[] = [];
    for (const change of deduped.values()) {
      results.push(await this.applyChange(userId, change));
    }
    return results;
  }

  // One change failing must not cost the client the results of the rest of the
  // batch: it comes back retryable and the others still commit.
  private async applyChange(
    userId: string,
    change: SyncChange,
  ): Promise<SyncApplyResult> {
    try {
      switch (change.type) {
        case 'note':
          return await this.applyNote(userId, change);
        case 'tag':
          return await this.applyTag(userId, change);
        case 'pin':
          return await this.applyPin(userId, change);
      }
    } catch (error) {
      this.logger.error(
        `Failed to apply ${change.type} ${change.id}`,
        error instanceof Error ? error.stack : String(error),
      );
      return { type: change.type, id: change.id, status: 'failed' };
    }
  }

  private async applyNote(
    userId: string,
    change: SyncNoteChangeDto,
  ): Promise<SyncApplyResult> {
    const base = { type: 'note' as const, id: change.id };
    const existing = await this.prisma.note.findUnique({
      where: { id: change.id },
      select: { id: true },
    });

    if (!existing) {
      // A baseVersion means the client once had this from the server, so the
      // note was purged rather than never created. Recreating it would undo a
      // delete the client hasn't caught up with yet.
      if (change.baseVersion !== undefined) {
        return { ...base, status: 'denied' };
      }
      const version = await this.createNote(userId, change);
      return { ...base, status: 'applied', version };
    }

    const access = await this.noteAccess.hasNoteAccess(
      userId,
      change.id,
      NoteSharePermission.editor,
    );
    if (!access.hasAccess) {
      if (access.permission !== NoteSharePermission.viewer) {
        return { ...base, status: 'denied' };
      }
      // Viewers can't write history; ack so the client stops resending.
      if (change.revisionsOnly) {
        return this.ackRevisionsOnly(userId, change, { record: false });
      }
      // Viewers can't win content writes; preserve what they typed anyway.
      return this.noteConflict(userId, change, { canWriteHistory: false });
    }

    if (change.revisionsOnly) {
      return this.ackRevisionsOnly(userId, change, { record: true });
    }

    const outcome = await this.prisma.$transaction(async (tx) => {
      const prior = await tx.note.findUnique({ where: { id: change.id } });
      if (!prior) {
        return { kind: 'missing' as const };
      }
      if (
        change.baseVersion === undefined ||
        change.baseVersion !== prior.version
      ) {
        return { kind: 'conflict' as const };
      }

      const noteData: GuardedNoteFields = {
        title: change.title,
        content: change.content,
        background: change.background,
      };
      if (access.isOwner) {
        noteData.isArchived = change.isArchived;
        noteData.state = change.state;
      }
      const finalState = noteData.state ?? prior.state;
      const guardedChanged = guardedNoteFieldsChanged(prior, {
        ...noteData,
        state: finalState,
      });

      // A writer that slipped in since the read above makes count 0.
      const updated = await tx.note.updateMany({
        where: { id: change.id, version: prior.version },
        data: {
          ...noteData,
          ...(guardedChanged ? { version: { increment: 1 } } : {}),
          ...(finalState !== prior.state ? { stateChangedAt: new Date() } : {}),
        },
      });
      if (updated.count !== 1) {
        return { kind: 'conflict' as const };
      }

      if (
        noteContentChanged(prior, noteData) &&
        !revisionsCover(change.revisions, prior)
      ) {
        await this.noteRevisions.recordEdit(tx, prior, userId);
      }
      if (change.revisions?.length) {
        await this.noteRevisions.recordClient(
          tx,
          change.id,
          change.revisions,
          userId,
        );
      }
      if (change.tagIds !== undefined) {
        await reconcileUserTags(tx, change.id, userId, change.tagIds);
      }

      const recipients = await this.syncEmitter.noteRecipients(tx, change.id);
      if (finalState === NoteState.deleted) {
        await this.syncEmitter.removeNote(tx, recipients, change.id);
      } else {
        await this.syncEmitter.emit(tx, noteEmissions(recipients, change.id));
      }

      return {
        kind: 'applied' as const,
        version: prior.version + (guardedChanged ? 1 : 0),
      };
    });

    if (outcome.kind === 'missing') {
      return { ...base, status: 'denied' };
    }
    if (outcome.kind === 'conflict') {
      return this.noteConflict(userId, change, { canWriteHistory: true });
    }
    return { ...base, status: 'applied', version: outcome.version };
  }

  // A push that carries only recorded history: nothing on the note to apply,
  // no conflict possible, ack at whatever version the server holds.
  private async ackRevisionsOnly(
    userId: string,
    change: SyncNoteChangeDto,
    { record }: { record: boolean },
  ): Promise<SyncApplyResult> {
    const base = { type: 'note' as const, id: change.id };
    const note = await this.prisma.note.findUnique({
      where: { id: change.id },
    });
    if (!note) {
      return { ...base, status: 'denied' };
    }
    if (record) {
      await this.keepClientRevisions(userId, change);
    }
    return { ...base, status: 'applied', version: note.version };
  }

  // Stores the revisions a change carried and tells other devices their read
  // of this note's history is behind.
  private async keepClientRevisions(
    userId: string,
    change: SyncNoteChangeDto,
  ): Promise<void> {
    const revisions = change.revisions;
    if (!revisions?.length) return;

    await this.prisma.$transaction(async (tx) => {
      await this.noteRevisions.recordClient(tx, change.id, revisions, userId);
      const recipients = await this.syncEmitter.noteRecipients(tx, change.id);
      await this.syncEmitter.emit(tx, noteEmissions(recipients, change.id));
    });
  }

  private async createNote(
    userId: string,
    change: SyncNoteChangeDto,
  ): Promise<number> {
    const validTagIds = await ownedTagIds(this.prisma, userId, change.tagIds);

    return this.prisma.$transaction(async (tx) => {
      const created = await tx.note.create({
        data: {
          id: change.id,
          title: change.title,
          content: change.content,
          isArchived: change.isArchived ?? false,
          background: change.background,
          state: (change.state as NoteState | undefined) ?? NoteState.active,
          userId,
          tags: validTagIds.length
            ? { connect: validTagIds.map((id) => ({ id })) }
            : undefined,
        },
        select: { state: true, version: true },
      });

      if (change.revisions?.length) {
        await this.noteRevisions.recordClient(
          tx,
          change.id,
          change.revisions,
          userId,
        );
      }

      if (created.state === NoteState.deleted) {
        await this.syncEmitter.removeNote(tx, [userId], change.id);
      } else {
        await this.syncEmitter.emit(tx, noteEmissions([userId], change.id));
      }

      return created.version;
    });
  }

  // The rejected payload is kept as a conflict revision, then the full server
  // copy rides back so the client can converge.
  private async noteConflict(
    userId: string,
    change: SyncNoteChangeDto,
    { canWriteHistory }: { canWriteHistory: boolean },
  ): Promise<SyncApplyResult> {
    const note = await this.prisma.note.findUnique({
      where: { id: change.id },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
      },
    });
    if (!note) {
      return { type: 'note', id: change.id, status: 'denied' };
    }

    // A redelivered push whose payload already landed: ack it instead of
    // conflicting the client against its own content. The ack stops the
    // client resending, so carried revisions land here.
    if (noteAlreadyMatches(note, userId, change)) {
      if (canWriteHistory) {
        await this.keepClientRevisions(userId, change);
      }
      return {
        type: 'note',
        id: change.id,
        status: 'applied',
        version: note.version,
      };
    }

    await this.noteRevisions.recordConflict(
      this.prisma,
      {
        noteId: change.id,
        title: change.title,
        content: change.content ?? null,
        baseVersion: change.baseVersion,
      },
      userId,
    );

    return {
      type: 'note',
      id: change.id,
      status: 'conflict',
      serverCopy: transformNote(note, userId),
    };
  }

  private async applyTag(
    userId: string,
    change: SyncTagChangeDto,
  ): Promise<SyncApplyResult> {
    const base = { type: 'tag' as const, id: change.id };
    const existing = await this.prisma.tag.findUnique({
      where: { id: change.id },
    });

    if (existing && existing.userId !== userId) {
      return { ...base, status: 'denied' };
    }

    if (!existing) {
      if (change.isDeleted) {
        // Deleting something the server never had: ack so it's never resent.
        return { ...base, status: 'applied' };
      }
      if (change.baseVersion !== undefined) {
        // The client had this from the server, so it was purged; recreating it
        // would undo a delete the client hasn't caught up with yet.
        return { ...base, status: 'denied' };
      }
      const collision = await this.findActiveTagByName(
        userId,
        change.name,
        change.id,
      );
      if (collision) {
        // serverCopy carries a DIFFERENT id: merge the local tag into it.
        return {
          ...base,
          status: 'conflict',
          serverCopy: toSyncTagPayload(collision),
        };
      }
      const created = await this.prisma.$transaction(async (tx) => {
        const tag = await tx.tag.create({
          data: {
            id: change.id,
            name: change.name,
            color: change.color,
            userId,
          },
        });
        await this.syncEmitter.emit(tx, [tagEmission(userId, change.id)]);
        return tag;
      });
      return { ...base, status: 'applied', version: created.version };
    }

    if (
      change.baseVersion === undefined ||
      change.baseVersion !== existing.version
    ) {
      return {
        ...base,
        status: 'conflict',
        serverCopy: toSyncTagPayload(existing),
      };
    }

    if (change.isDeleted) {
      const applied = await this.prisma.$transaction(async (tx) => {
        const result = await tx.tag.updateMany({
          where: { id: change.id, version: existing.version },
          data: { isDeleted: true, version: { increment: 1 } },
        });
        if (result.count !== 1) {
          return false;
        }
        await this.syncEmitter.emit(tx, [
          tagEmission(userId, change.id, SyncOp.remove),
        ]);
        return true;
      });
      return applied
        ? { ...base, status: 'applied', version: existing.version + 1 }
        : this.tagConflict(base, change.id);
    }

    if (change.name !== existing.name) {
      const collision = await this.findActiveTagByName(
        userId,
        change.name,
        change.id,
      );
      if (collision) {
        return {
          ...base,
          status: 'conflict',
          serverCopy: toSyncTagPayload(collision),
        };
      }
    }

    const changed =
      change.name !== existing.name ||
      (change.color !== undefined && change.color !== existing.color);
    const applied = await this.prisma.$transaction(async (tx) => {
      const result = await tx.tag.updateMany({
        where: { id: change.id, version: existing.version },
        data: {
          name: change.name,
          color: change.color,
          ...(changed ? { version: { increment: 1 } } : {}),
        },
      });
      if (result.count !== 1) {
        return false;
      }
      await this.syncEmitter.emit(tx, [tagEmission(userId, change.id)]);
      return true;
    });
    return applied
      ? {
          ...base,
          status: 'applied',
          version: existing.version + (changed ? 1 : 0),
        }
      : this.tagConflict(base, change.id);
  }

  private async tagConflict(
    base: { type: 'tag'; id: string },
    tagId: string,
  ): Promise<SyncApplyResult> {
    const tag = await this.prisma.tag.findUnique({ where: { id: tagId } });
    if (!tag) {
      return { ...base, status: 'denied' };
    }
    return { ...base, status: 'conflict', serverCopy: toSyncTagPayload(tag) };
  }

  private findActiveTagByName(userId: string, name: string, exceptId: string) {
    return this.prisma.tag.findFirst({
      where: { userId, name, isDeleted: false, id: { not: exceptId } },
    });
  }

  // Pins are per-user and conflict-free: read access is all it takes.
  private async applyPin(
    userId: string,
    change: SyncPinChangeDto,
  ): Promise<SyncApplyResult> {
    const base = { type: 'pin' as const, id: change.id };
    const access = await this.noteAccess.hasNoteAccess(userId, change.id);
    if (!access.hasAccess || access.state === NoteState.deleted) {
      return { ...base, status: 'denied' };
    }

    const pinned = await this.prisma.notePin.findUnique({
      where: { userId_noteId: { userId, noteId: change.id } },
      select: { noteId: true },
    });
    if (!!pinned === change.isPinned) {
      return { ...base, status: 'applied' };
    }

    await this.prisma.$transaction(async (tx) => {
      if (change.isPinned) {
        await tx.notePin.upsert({
          where: { userId_noteId: { userId, noteId: change.id } },
          create: { userId, noteId: change.id },
          update: {},
        });
      } else {
        await tx.notePin.deleteMany({
          where: { userId, noteId: change.id },
        });
      }
      await this.syncEmitter.emit(tx, [
        pinEmission(userId, change.id, change.isPinned),
      ]);
    });

    return { ...base, status: 'applied' };
  }
}

type NoteWithOwnTags = Note & { tags: Array<{ id: string; userId: string }> };

// Whether the push would write nothing: every field it carries already holds
// the value it is asking for.
function noteAlreadyMatches(
  note: NoteWithOwnTags,
  userId: string,
  change: SyncNoteChangeDto,
): boolean {
  const isOwner = note.userId === userId;
  const guarded: GuardedNoteFields = {
    title: change.title,
    content: change.content,
    background: change.background,
    ...(isOwner
      ? {
          isArchived: change.isArchived,
          state: change.state,
        }
      : {}),
  };
  if (guardedNoteFieldsChanged(note, guarded)) {
    return false;
  }
  if (change.tagIds === undefined) {
    return true;
  }
  const current = note.tags.filter((tag) => tag.userId === userId);
  const wanted = new Set(change.tagIds);
  return (
    current.length === wanted.size && current.every((tag) => wanted.has(tag.id))
  );
}
