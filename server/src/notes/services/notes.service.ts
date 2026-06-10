import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateNoteDto } from '../dto/create-note.dto';
import { UpdateNoteDto } from '../dto/update-note.dto';
import { SyncNoteDto, SyncNotesDto } from '../dto/sync-notes.dto';
import { NoteState, NoteSharePermission } from 'src/generated/prisma/enums';
import type { Note, Prisma } from 'src/generated/prisma/client';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { transformNote } from '../utils/note-transformer.util';
import {
  getSyncUpdatedAtWindow,
  withForcedSyncIds,
} from '../../sync/sync-window.util';
import {
  ERROR_MESSAGES,
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
  NOTE_INCLUDE_ATTACHMENT_COUNT,
  notePinInclude,
} from '../constants/notes.constants';

@Injectable()
export class NotesService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private noteAttachmentsService: NoteAttachmentsService,
  ) {}

  async create(userId: string, createNoteDto: CreateNoteDto) {
    const { tagIds, isPinned, ...noteData } = createNoteDto;

    const note = await this.prisma.note.create({
      data: {
        ...noteData,
        state: NoteState.active,
        userId,
        tags: tagIds?.length
          ? {
              connect: tagIds.map((id) => ({ id })),
            }
          : undefined,
      },
      include: NOTE_INCLUDE_TAGS,
    });

    await this.setNotePin(userId, note.id, isPinned);

    return transformNote(
      { ...note, pins: isPinned ? [{ userId }] : [] },
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
      },
      orderBy: [{ updatedAt: 'desc' }],
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

    const { tagIds, isPinned, ...noteData } = updateNoteDto;

    // Apply the pin first so the include below reflects the new state.
    await this.setNotePin(userId, id, isPinned);

    const note = await this.prisma.note.update({
      where: { id },
      data: {
        ...noteData,
        // Use 'set' to replace all tags at once (implicit many-to-many)
        ...(tagIds !== undefined && {
          tags: {
            set: tagIds.map((tagId) => ({ id: tagId })),
          },
        }),
      },
      include: { ...NOTE_INCLUDE_TAGS, ...notePinInclude(userId) },
    });

    return transformNote(note, userId);
  }

  // Soft delete - moves note to trash (owner only)
  async remove(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.trashed },
      include: { ...NOTE_INCLUDE_TAGS, ...notePinInclude(userId) },
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

    const restoredNote = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.active },
      include: { ...NOTE_INCLUDE_TAGS, ...notePinInclude(userId) },
    });

    return transformNote(restoredNote, userId);
  }

  // Permanent delete - sets state to deleted (tombstone) (owner only)
  async permanentDelete(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.deleted },
      include: { ...NOTE_INCLUDE_TAGS, ...notePinInclude(userId) },
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
      orderBy: { updatedAt: 'desc' },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
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
      orderBy: { updatedAt: 'desc' },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
      },
    });

    return notes.map((note) => transformNote(note, userId));
  }

  // Auto-delete notes that have been in trash for longer than retention period
  // Transitions trashed → deleted (tombstone) so sync clients can learn about the deletion
  async autoDeleteExpiredTrash(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    const result = await this.prisma.note.updateMany({
      where: {
        state: NoteState.trashed,
        updatedAt: { lt: cutoffDate },
      },
      data: { state: NoteState.deleted },
    });

    return { convertedCount: result.count };
  }

  // Purge tombstones older than retention period (30 days)
  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    // 1. Find notes to be purged before deleting
    const notesToPurge = await this.prisma.note.findMany({
      where: {
        state: NoteState.deleted,
        updatedAt: { lt: cutoffDate },
      },
      select: { id: true },
    });

    // 2. Delete attachment files from disk for each note
    for (const note of notesToPurge) {
      await this.noteAttachmentsService.deleteAllForNote(note.id);
    }

    // 3. Purge deleted notes (DB cascade removes NoteAttachment rows)
    const deletedNotes = await this.prisma.note.deleteMany({
      where: {
        state: NoteState.deleted,
        updatedAt: { lt: cutoffDate },
      },
    });

    // 4. Purge deleted shares
    const deletedShares = await this.prisma.noteShare.deleteMany({
      where: {
        isDeleted: true,
        updatedAt: { lt: cutoffDate },
      },
    });

    return {
      purgedNotesCount: deletedNotes.count,
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
      },
    });

    if (notes.length !== noteIds.length) {
      throw new NotFoundException(
        'One or more notes not found or you do not have permission',
      );
    }

    await this.prisma.note.updateMany({
      where: {
        id: { in: noteIds },
        userId,
      },
      data: { state: NoteState.trashed },
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
      },
    });

    if (notes.length !== noteIds.length) {
      throw new NotFoundException(
        'One or more notes not found or you do not have permission',
      );
    }

    await this.prisma.note.updateMany({
      where: {
        id: { in: noteIds },
        userId,
      },
      data: { isArchived: true },
    });

    return { count: noteIds.length };
  }

  // Bulk pin/unpin - per-user, works for owned and shared notes
  async bulkSetPin(userId: string, noteIds: string[], isPinned: boolean) {
    // Only act on notes the user can actually see (own or shared with them).
    const accessibleNotes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
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

    if (isPinned) {
      await this.prisma.notePin.createMany({
        data: accessibleIds.map((noteId) => ({ userId, noteId })),
        skipDuplicates: true,
      });
    } else {
      await this.prisma.notePin.deleteMany({
        where: { userId, noteId: { in: accessibleIds } },
      });
    }

    return { count: accessibleIds.length };
  }

  // Bulk add tags - merges the given tags into each note (owner only)
  async bulkAddTags(userId: string, noteIds: string[], tagIds: string[]) {
    // Verify all notes belong to user (owner only)
    const notes = await this.prisma.note.findMany({
      where: {
        id: { in: noteIds },
        userId,
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
    // Each update bumps updatedAt so sync clients learn about the change.
    await this.prisma.$transaction(
      noteIds.map((id) =>
        this.prisma.note.update({
          where: { id },
          data: {
            tags: { connect: validTagIds.map((tagId) => ({ id: tagId })) },
          },
        }),
      ),
    );

    return { count: noteIds.length };
  }

  // Sync endpoint - handles bi-directional sync with conflict resolution
  async sync(userId: string, syncDto: SyncNotesDto) {
    const { lastSyncedAt, changes } = syncDto;
    const incoming = await this.processIncomingSyncChanges(
      userId,
      changes || [],
    );

    const syncCutoff = new Date();
    const forceServerIds = Array.from(incoming.forceServerNoteIds);
    const updatedAtWindow = getSyncUpdatedAtWindow(lastSyncedAt, syncCutoff);

    const ownNotes = await this.findOwnSyncNotes(
      userId,
      updatedAtWindow,
      forceServerIds,
    );
    const sharedShares = await this.findSharedSyncShares(
      userId,
      lastSyncedAt,
      syncCutoff,
      updatedAtWindow,
      forceServerIds,
    );

    // Transform own notes
    const transformedOwnNotes = ownNotes.map((note) =>
      transformNote(note, userId),
    );

    const revokedSharedNoteIds = sharedShares
      .filter((share) => share.isDeleted)
      .map((share) => share.noteId);

    // Transform shared notes (active shares only)
    const transformedSharedNotes = sharedShares
      .filter((share) => !share.isDeleted)
      .map((share) => transformNote(share.note, userId));

    const serverChanges = [...transformedOwnNotes, ...transformedSharedNotes];

    return {
      serverChanges,
      revokedSharedNoteIds,
      processedIds: incoming.processedIds,
      conflicts: incoming.conflicts,
      syncedAt: syncCutoff.toISOString(),
    };
  }

  private async processIncomingSyncChanges(
    userId: string,
    changes: SyncNoteDto[],
  ): Promise<IncomingNoteSyncResult> {
    const result: IncomingNoteSyncResult = {
      processedIds: [],
      conflicts: [],
      forceServerNoteIds: new Set<string>(),
    };

    for (const change of changes) {
      const existingNote = await this.prisma.note.findUnique({
        where: { id: change.id },
      });

      if (!existingNote) {
        await this.createMissingSyncNote(userId, change);
        result.processedIds.push(change.id);
        continue;
      }

      await this.processExistingSyncNote(userId, change, existingNote, result);
    }

    return result;
  }

  private async createMissingSyncNote(userId: string, change: SyncNoteDto) {
    await this.prisma.note.create({
      data: {
        id: change.id,
        title: change.title,
        content: change.content,
        isArchived: change.isArchived ?? false,
        background: change.background,
        state: (change.state as NoteState) ?? NoteState.active,
        userId,
        tags: change.tagIds?.length
          ? {
              connect: change.tagIds.map((id) => ({ id })),
            }
          : undefined,
      },
    });

    await this.setNotePin(userId, change.id, change.isPinned);
  }

  private async processExistingSyncNote(
    userId: string,
    change: SyncNoteDto,
    existingNote: Note,
    result: IncomingNoteSyncResult,
  ) {
    const access = await this.noteAccessService.hasNoteAccess(
      userId,
      change.id,
      NoteSharePermission.editor,
    );

    if (!access.hasAccess) {
      const readAccess = await this.noteAccessService.hasNoteAccess(
        userId,
        change.id,
      );
      if (readAccess.hasAccess) {
        await this.setNotePin(userId, change.id, change.isPinned);
        result.forceServerNoteIds.add(change.id);
        result.conflicts.push({ noteId: change.id, resolution: 'server' });
        result.processedIds.push(change.id);
      }
      return;
    }

    // Pin state is per-user and conflict-free
    await this.setNotePin(userId, change.id, change.isPinned);

    const clientUpdatedAt = new Date(change.updatedAt);
    const serverUpdatedAt = existingNote.updatedAt;

    if (clientUpdatedAt <= serverUpdatedAt) {
      result.forceServerNoteIds.add(change.id);
      result.conflicts.push({ noteId: change.id, resolution: 'server' });
      result.processedIds.push(change.id);
      return;
    }

    const didUpdate = await this.updateSyncNoteIfUnchanged(
      change,
      existingNote,
      access.isOwner,
    );

    if (didUpdate) {
      result.conflicts.push({ noteId: change.id, resolution: 'client' });
    } else {
      result.forceServerNoteIds.add(change.id);
      result.conflicts.push({ noteId: change.id, resolution: 'server' });
    }
    result.processedIds.push(change.id);
  }

  private async updateSyncNoteIfUnchanged(
    change: SyncNoteDto,
    existingNote: Note,
    isOwner: boolean,
  ) {
    const updateData: Prisma.NoteUpdateInput = {
      title: change.title,
      content: change.content,
      background: change.background,
    };

    if (isOwner) {
      updateData.isArchived = change.isArchived;
      updateData.state = (change.state as NoteState) ?? existingNote.state;
    }

    return this.prisma.$transaction(async (tx) => {
      const result = await tx.note.updateMany({
        where: { id: change.id, updatedAt: existingNote.updatedAt },
        data: updateData,
      });

      if (result.count !== 1) {
        return false;
      }

      if (change.tagIds !== undefined) {
        await tx.note.update({
          where: { id: change.id },
          data: {
            tags: {
              set: change.tagIds.map((id) => ({ id })),
            },
          },
        });
      }

      return true;
    });
  }

  private findOwnSyncNotes(
    userId: string,
    updatedAtWindow: ReturnType<typeof getSyncUpdatedAtWindow>,
    forceServerIds: string[],
  ) {
    return this.prisma.note.findMany({
      where: {
        userId,
        ...withForcedSyncIds(updatedAtWindow, forceServerIds),
      },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
      },
    });
  }

  private findSharedSyncShares(
    userId: string,
    lastSyncedAt: string | undefined,
    syncCutoff: Date,
    updatedAtWindow: ReturnType<typeof getSyncUpdatedAtWindow>,
    forceServerIds: string[],
  ) {
    return this.prisma.noteShare.findMany({
      where: {
        sharedWithUserId: userId,
        ...buildSharedSyncWhere(
          lastSyncedAt,
          syncCutoff,
          updatedAtWindow,
          forceServerIds,
        ),
      },
      include: {
        note: {
          include: {
            ...NOTE_INCLUDE_TAGS,
            ...NOTE_INCLUDE_SHARES,
            ...NOTE_INCLUDE_ATTACHMENT_COUNT,
            ...notePinInclude(userId),
          },
        },
      },
    });
  }

  // undefined leaves the pin untouched; true pins, false unpins (per user).
  private async setNotePin(
    userId: string,
    noteId: string,
    isPinned: boolean | undefined,
  ) {
    if (isPinned === undefined) {
      return;
    }
    if (isPinned) {
      await this.prisma.notePin.upsert({
        where: { userId_noteId: { userId, noteId } },
        create: { userId, noteId },
        update: {},
      });
    } else {
      await this.prisma.notePin.deleteMany({ where: { userId, noteId } });
    }
  }
}

type SyncConflict = { noteId: string; resolution: 'server' | 'client' };

interface IncomingNoteSyncResult {
  processedIds: string[];
  conflicts: SyncConflict[];
  forceServerNoteIds: Set<string>;
}

const buildSharedSyncWhere = (
  lastSyncedAt: string | undefined,
  syncCutoff: Date,
  updatedAtWindow: ReturnType<typeof getSyncUpdatedAtWindow>,
  forceServerIds: string[],
) => {
  if (lastSyncedAt) {
    return {
      OR: [
        { updatedAt: updatedAtWindow },
        { isDeleted: false, note: { updatedAt: updatedAtWindow } },
        ...activeForcedNoteIds(forceServerIds),
      ],
    };
  }

  const initialActiveShares = {
    isDeleted: false,
    updatedAt: { lte: syncCutoff },
    note: { updatedAt: { lte: syncCutoff } },
  };

  return forceServerIds.length
    ? { OR: [initialActiveShares, ...activeForcedNoteIds(forceServerIds)] }
    : initialActiveShares;
};

const activeForcedNoteIds = (forceServerIds: string[]) =>
  forceServerIds.length
    ? [{ isDeleted: false, noteId: { in: forceServerIds } }]
    : [];

const clampLimit = (limit?: number) => {
  if (typeof limit !== 'number' || Number.isNaN(limit)) {
    return undefined;
  }

  const normalized = Math.trunc(limit);
  return Math.min(Math.max(normalized, 1), 200);
};
