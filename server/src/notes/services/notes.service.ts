import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateNoteDto } from '../dto/create-note.dto';
import { UpdateNoteDto } from '../dto/update-note.dto';
import {
  NoteState,
  NoteSharePermission,
  ReminderRecurrence,
} from 'src/generated/prisma/enums';
import type { Prisma } from 'src/generated/prisma/client';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { transformNote } from '../utils/note-transformer.util';
import { ownedTagIds, reconcileUserTags } from '../utils/note-tags.util';
import {
  guardedNoteFieldsChanged,
  noteContentChanged,
} from '../utils/note-versioning.util';
import {
  SyncEmitterService,
  noteEmissions,
  pinEmission,
  reminderEmission,
} from '../../sync/sync-emitter.service';
import { NoteRevisionsService } from '../../sync/note-revisions.service';
import {
  ERROR_MESSAGES,
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
  NOTE_INCLUDE_ATTACHMENT_COUNT,
  NOTE_LIST_ORDER,
  notePinInclude,
  noteReminderInclude,
} from '../constants/notes.constants';
import { NoteReminderDto } from '../dto/note-reminder.dto';
import { RETENTION_CHUNK_SIZE } from '../../common/retention.constants';

@Injectable()
export class NotesService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private noteAttachmentsService: NoteAttachmentsService,
    private syncEmitter: SyncEmitterService,
    private noteRevisions: NoteRevisionsService,
  ) {}

  async create(userId: string, createNoteDto: CreateNoteDto) {
    const { tagIds, isPinned, reminder, ...noteData } = createNoteDto;
    const validTagIds = await this.filterOwnedTagIds(userId, tagIds);

    const note = await this.prisma.$transaction(async (tx) => {
      const created = await tx.note.create({
        data: {
          ...noteData,
          state: NoteState.active,
          userId,
          tags: validTagIds.length
            ? {
                connect: validTagIds.map((id) => ({ id })),
              }
            : undefined,
        },
        include: NOTE_INCLUDE_TAGS,
      });

      await this.setNotePin(tx, userId, created.id, isPinned);
      const saved = await this.setNoteReminder(
        tx,
        userId,
        created.id,
        reminder,
      );
      await this.syncEmitter.emit(tx, [
        ...noteEmissions([userId], created.id),
        ...(isPinned !== undefined
          ? [pinEmission(userId, created.id, isPinned)]
          : []),
        ...(saved?.changed
          ? [reminderEmission(userId, created.id, !!saved.row)]
          : []),
      ]);

      return { created, saved };
    });

    return transformNote(
      {
        ...note.created,
        pins: isPinned ? [{ userId }] : [],
        reminders: note.saved?.row ? [note.saved.row] : [],
      },
      userId,
    );
  }

  async findAll(
    userId: string,
    search?: string,
    tagId?: string,
    limit?: number,
  ) {
    const normalizedLimit = clampLimit(limit);

    const notes = await this.prisma.note.findMany({
      where: {
        AND: [
          {
            OR: [
              { userId }, // Own notes
              {
                sharedWith: {
                  some: { sharedWithUserId: userId, isDeleted: false },
                },
              }, // Shared notes
            ],
          },
          {
            state: NoteState.active,
            isArchived: false,
          },
          ...(tagId
            ? [
                {
                  tags: {
                    some: { id: tagId },
                  },
                },
              ]
            : []),
          ...(search
            ? [
                {
                  OR: [
                    {
                      title: { contains: search, mode: 'insensitive' as const },
                    },
                    {
                      content: {
                        contains: search,
                        mode: 'insensitive' as const,
                      },
                    },
                  ],
                },
              ]
            : []),
        ],
      },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
      orderBy: NOTE_LIST_ORDER,
      take: normalizedLimit,
    });

    return notes.map((note) => transformNote(note, userId));
  }

  async findOne(userId: string, id: string, includeAllStates = false) {
    const access = await this.noteAccessService.hasNoteAccess(userId, id);

    if (!access.hasAccess) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }

    const note = await this.prisma.note.findUnique({
      where: { id },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
    });

    if (!note) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }

    if (!includeAllStates && note.state === NoteState.deleted) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }

    return transformNote(note, userId);
  }

  async update(userId: string, id: string, updateNoteDto: UpdateNoteDto) {
    // Check access - owner or editor permission required
    await this.noteAccessService.ensureNoteAccess(
      userId,
      id,
      NoteSharePermission.editor,
    );

    const { tagIds, isPinned, reminder, baseVersion, ...noteData } =
      updateNoteDto;

    const outcome = await this.prisma.$transaction(async (tx) => {
      const prior = await tx.note.findUniqueOrThrow({ where: { id } });
      if (prior.state === NoteState.deleted) {
        return { gone: true as const };
      }

      if (baseVersion !== undefined && baseVersion !== prior.version) {
        return { conflict: true as const };
      }

      await this.setNotePin(tx, userId, id, isPinned);
      const savedReminder = await this.setNoteReminder(
        tx,
        userId,
        id,
        reminder,
      );

      if (noteContentChanged(prior, noteData)) {
        await this.noteRevisions.recordEdit(tx, prior, userId);
      }
      await tx.note.update({
        where: { id },
        data: {
          ...noteData,
          ...(guardedNoteFieldsChanged(prior, noteData)
            ? { version: { increment: 1 } }
            : {}),
        },
      });

      // Only update the caller's own tags so other users' tags aren't removed.
      if (tagIds !== undefined) {
        await reconcileUserTags(tx, id, userId, tagIds);
      }

      const recipients = await this.syncEmitter.noteRecipients(tx, id);
      await this.syncEmitter.emit(tx, [
        ...noteEmissions(recipients, id),
        ...(isPinned !== undefined ? [pinEmission(userId, id, isPinned)] : []),
        ...(savedReminder?.changed
          ? [reminderEmission(userId, id, !!savedReminder.row)]
          : []),
      ]);

      const note = await tx.note.findUniqueOrThrow({
        where: { id },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...notePinInclude(userId),
          ...noteReminderInclude(userId),
        },
      });
      return { conflict: false as const, note };
    });

    if ('gone' in outcome) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }
    if (outcome.conflict) {
      throw await this.noteVersionConflict(userId, id, updateNoteDto);
    }

    return transformNote(outcome.note, userId);
  }

  // The losing payload is kept as a conflict revision; the 409 carries the
  // full server copy back.
  private async noteVersionConflict(
    userId: string,
    id: string,
    dto: UpdateNoteDto,
  ) {
    const server = await this.prisma.note.findUniqueOrThrow({
      where: { id },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
    });

    if (dto.title !== undefined || dto.content !== undefined) {
      await this.noteRevisions.recordConflict(
        this.prisma,
        {
          noteId: id,
          title: dto.title ?? server.title,
          content: dto.content !== undefined ? dto.content : server.content,
          baseVersion: dto.baseVersion,
        },
        userId,
      );
    }

    return new ConflictException({
      message: 'Note was changed by someone else',
      serverNote: transformNote(server, userId),
    });
  }

  // Soft delete - moves note to trash (owner only)
  async remove(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.$transaction(async (tx) => {
      const prior = await tx.note.findUniqueOrThrow({ where: { id } });
      if (prior.state === NoteState.deleted) {
        throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
      }
      const updated = await tx.note.update({
        where: { id },
        data: {
          state: NoteState.trashed,
          ...(prior.state !== NoteState.trashed
            ? { version: { increment: 1 }, stateChangedAt: new Date() }
            : {}),
        },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...notePinInclude(userId),
          ...noteReminderInclude(userId),
        },
      });
      const recipients = await this.syncEmitter.noteRecipients(tx, id);
      await this.syncEmitter.emit(tx, noteEmissions(recipients, id));
      return updated;
    });

    return transformNote(note, userId);
  }

  // Restore from trash (owner only)
  async restore(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.note.findUnique({
      where: { id },
    });

    if (!note || note.state !== NoteState.trashed) {
      throw new NotFoundException('Note is not in trash');
    }

    const restoredNote = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.note.update({
        where: { id },
        data: {
          state: NoteState.active,
          version: { increment: 1 },
          stateChangedAt: new Date(),
        },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...notePinInclude(userId),
          ...noteReminderInclude(userId),
        },
      });
      const recipients = await this.syncEmitter.noteRecipients(tx, id);
      await this.syncEmitter.emit(tx, noteEmissions(recipients, id));
      return updated;
    });

    return transformNote(restoredNote, userId);
  }

  // Permanent delete - sets state to deleted (tombstone) (owner only)
  async permanentDelete(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.$transaction(async (tx) => {
      const prior = await tx.note.findUniqueOrThrow({ where: { id } });
      // Resolve recipients before anything changes; they all get the remove.
      const recipients = await this.syncEmitter.noteRecipients(tx, id);
      const updated = await tx.note.update({
        where: { id },
        data: {
          state: NoteState.deleted,
          ...(prior.state !== NoteState.deleted
            ? { version: { increment: 1 }, stateChangedAt: new Date() }
            : {}),
        },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...notePinInclude(userId),
          ...noteReminderInclude(userId),
        },
      });
      await this.syncEmitter.removeNote(tx, recipients, id);
      return updated;
    });

    return transformNote(note, userId);
  }

  // Get trashed notes
  async findTrashed(userId: string) {
    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: NoteState.trashed,
      },
      orderBy: NOTE_LIST_ORDER,
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
    });

    return notes.map((note) => transformNote(note, userId));
  }

  // Get archived notes
  async findArchived(userId: string) {
    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: NoteState.active,
        isArchived: true,
      },
      orderBy: NOTE_LIST_ORDER,
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
    });

    return notes.map((note) => transformNote(note, userId));
  }

  // Auto-delete notes that have been in trash for longer than retention period
  // Transitions trashed → deleted (tombstone) so sync clients can learn about the deletion
  async autoDeleteExpiredTrash(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    let convertedCount = 0;

    for (;;) {
      const expired = await this.prisma.note.findMany({
        where: {
          state: NoteState.trashed,
          stateChangedAt: { lt: cutoffDate },
        },
        select: { id: true },
        take: RETENTION_CHUNK_SIZE,
      });
      if (expired.length === 0) {
        break;
      }

      const ids = expired.map((note) => note.id);
      const converted = await this.prisma.$transaction(async (tx) => {
        const result = await tx.note.updateMany({
          where: { id: { in: ids } },
          data: {
            state: NoteState.deleted,
            version: { increment: 1 },
            stateChangedAt: new Date(),
          },
        });

        const recipientsByNote = await this.syncEmitter.notesRecipients(
          tx,
          ids,
        );
        await this.syncEmitter.removeNotes(tx, recipientsByNote);

        return result.count;
      });

      convertedCount += converted;
      if (converted === 0 || expired.length < RETENTION_CHUNK_SIZE) {
        break;
      }
    }

    return { convertedCount };
  }

  // Purge tombstones older than retention period (30 days)
  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    let purgedNotesCount = 0;

    for (;;) {
      // Attachment files go first: the DB cascade drops their rows.
      const doomed = await this.prisma.note.findMany({
        where: {
          state: NoteState.deleted,
          stateChangedAt: { lt: cutoffDate },
        },
        select: { id: true },
        take: RETENTION_CHUNK_SIZE,
      });
      if (doomed.length === 0) {
        break;
      }

      for (const note of doomed) {
        await this.noteAttachmentsService.deleteAllForNote(note.id);
      }

      const purged = await this.prisma.note.deleteMany({
        where: { id: { in: doomed.map((note) => note.id) } },
      });

      purgedNotesCount += purged.count;
      if (purged.count === 0 || doomed.length < RETENTION_CHUNK_SIZE) {
        break;
      }
    }

    const deletedShares = await this.prisma.noteShare.deleteMany({
      where: {
        isDeleted: true,
        updatedAt: { lt: cutoffDate },
      },
    });

    return {
      purgedNotesCount,
      purgedSharesCount: deletedShares.count,
    };
  }

  // Bulk delete - moves multiple notes to trash (owner only)
  async bulkRemove(userId: string, noteIds: string[]) {
    // Verify all notes belong to user (owner only)
    const notes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
        userId,
        state: { not: NoteState.deleted },
      },
    });

    if (notes.length !== noteIds.length) {
      throw new NotFoundException(
        'One or more notes not found or you do not have permission',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.note.updateMany({
        where: {
          id: { in: noteIds },
          userId,
        },
        data: {
          state: NoteState.trashed,
          version: { increment: 1 },
          stateChangedAt: new Date(),
        },
      });
      const recipientsByNote = await this.syncEmitter.notesRecipients(
        tx,
        noteIds,
      );
      await this.syncEmitter.emit(
        tx,
        noteIds.flatMap((id) =>
          noteEmissions(recipientsByNote.get(id) ?? [], id),
        ),
      );
    });

    return { count: noteIds.length };
  }

  // Bulk archive (owner only)
  async bulkArchive(userId: string, noteIds: string[]) {
    // Verify all notes belong to user (owner only)
    const notes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
        userId,
        state: { not: NoteState.deleted },
      },
    });

    if (notes.length !== noteIds.length) {
      throw new NotFoundException(
        'One or more notes not found or you do not have permission',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.note.updateMany({
        where: {
          id: { in: noteIds },
          userId,
        },
        data: { isArchived: true, version: { increment: 1 } },
      });
      const recipientsByNote = await this.syncEmitter.notesRecipients(
        tx,
        noteIds,
      );
      await this.syncEmitter.emit(
        tx,
        noteIds.flatMap((id) =>
          noteEmissions(recipientsByNote.get(id) ?? [], id),
        ),
      );
    });

    return { count: noteIds.length };
  }

  // Bulk pin/unpin - per-user, works for owned and shared notes
  async bulkSetPin(userId: string, noteIds: string[], isPinned: boolean) {
    // Only act on notes the user can actually see (own or shared with them).
    const accessibleNotes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
        state: { not: NoteState.deleted },
        OR: [
          { userId },
          {
            sharedWith: {
              some: { sharedWithUserId: userId, isDeleted: false },
            },
          },
        ],
      },
      select: { id: true },
    });

    const accessibleIds = accessibleNotes.map((note) => note.id);
    if (accessibleIds.length === 0) {
      return { count: 0 };
    }

    await this.prisma.$transaction(async (tx) => {
      if (isPinned) {
        await tx.notePin.createMany({
          data: accessibleIds.map((noteId) => ({ userId, noteId })),
          skipDuplicates: true,
        });
      } else {
        await tx.notePin.deleteMany({
          where: { userId, noteId: { in: accessibleIds } },
        });
      }
      await this.syncEmitter.emit(
        tx,
        accessibleIds.map((noteId) => pinEmission(userId, noteId, isPinned)),
      );
    });

    return { count: accessibleIds.length };
  }

  // Bulk add tags - merges the given tags into each note (owner only)
  async bulkAddTags(userId: string, noteIds: string[], tagIds: string[]) {
    // Verify all notes belong to user (owner only)
    const notes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
        userId,
        state: { not: NoteState.deleted },
      },
      select: { id: true },
    });

    if (notes.length !== noteIds.length) {
      throw new NotFoundException(
        'One or more notes not found or you do not have permission',
      );
    }

    // Only attach tags the user owns and that aren't deleted.
    const tags = await this.prisma.tag.findMany({
      where: { id: { in: tagIds }, userId, isDeleted: false },
      select: { id: true },
    });
    const validTagIds = tags.map((tag) => tag.id);

    if (validTagIds.length === 0) {
      return { count: 0 };
    }

    // `connect` is idempotent, so each note keeps its existing tags (merge).
    await this.prisma.$transaction(async (tx) => {
      for (const id of noteIds) {
        await tx.note.update({
          where: { id },
          data: {
            tags: { connect: validTagIds.map((tagId) => ({ id: tagId })) },
          },
        });
      }
      const recipientsByNote = await this.syncEmitter.notesRecipients(
        tx,
        noteIds,
      );
      await this.syncEmitter.emit(
        tx,
        noteIds.flatMap((id) =>
          noteEmissions(recipientsByNote.get(id) ?? [], id),
        ),
      );
    });

    return { count: noteIds.length };
  }

  private async filterOwnedTagIds(userId: string, tagIds?: string[]) {
    return ownedTagIds(this.prisma, userId, tagIds);
  }

  // undefined leaves the pin untouched; true pins, false unpins (per user).
  private async setNotePin(
    tx: Prisma.TransactionClient,
    userId: string,
    noteId: string,
    isPinned: boolean | undefined,
  ) {
    if (isPinned === undefined) {
      return;
    }
    if (isPinned) {
      await tx.notePin.upsert({
        where: { userId_noteId: { userId, noteId } },
        create: { userId, noteId },
        update: {},
      });
    } else {
      await tx.notePin.deleteMany({ where: { userId, noteId } });
    }
  }

  // undefined leaves the reminder untouched; null clears it. `changed` is
  // false when the stored value already matched, so repeating it neither bumps
  // the version nor emits.
  private async setNoteReminder(
    tx: Prisma.TransactionClient,
    userId: string,
    noteId: string,
    reminder: NoteReminderDto | null | undefined,
  ): Promise<ReminderWrite | undefined> {
    if (reminder === undefined) {
      return undefined;
    }

    const key = { userId_noteId: { userId, noteId } };
    const prior = await tx.noteReminder.findUnique({ where: key });

    if (!reminder) {
      if (!prior) return { changed: false, row: null };
      await tx.noteReminder.delete({ where: key });
      return { changed: true, row: null };
    }

    const recurrence = reminder.recurrence ?? ReminderRecurrence.none;
    if (
      prior &&
      prior.remindAt === reminder.remindAt &&
      prior.recurrence === recurrence
    ) {
      return { changed: false, row: prior };
    }

    const row = await tx.noteReminder.upsert({
      where: key,
      create: { userId, noteId, remindAt: reminder.remindAt, recurrence },
      update: {
        remindAt: reminder.remindAt,
        recurrence,
        version: { increment: 1 },
      },
    });
    return { changed: true, row };
  }
}

interface ReminderWrite {
  changed: boolean;
  row: {
    remindAt: string;
    recurrence: ReminderRecurrence;
    version: number;
  } | null;
}

const clampLimit = (limit?: number) => {
  if (typeof limit !== 'number' || Number.isNaN(limit)) {
    return undefined;
  }

  const normalized = Math.trunc(limit);
  return Math.min(Math.max(normalized, 1), 200);
};
