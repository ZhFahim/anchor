import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateNoteDto } from '../dto/create-note.dto';
import { UpdateNoteDto } from '../dto/update-note.dto';
import { SyncNotesDto } from '../dto/sync-notes.dto';
import { NoteState, NoteSharePermission } from 'src/generated/prisma/enums';
import { NoteAccessService } from './note-access.service';
import { transformNote } from '../utils/note-transformer.util';
import {
  ERROR_MESSAGES,
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
} from '../constants/notes.constants';

@Injectable()
export class NotesService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
  ) { }

  async create(userId: string, createNoteDto: CreateNoteDto) {
    const { tagIds, ...noteData } = createNoteDto;

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

    return transformNote(note, userId);
  }

  async findAll(userId: string, search?: string, tagId?: string) {
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
      },
      orderBy: [{ isPinned: 'desc' }, { updatedAt: 'desc' }],
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

    const { tagIds, ...noteData } = updateNoteDto;

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
      include: NOTE_INCLUDE_TAGS,
    });

    return transformNote(note, userId);
  }

  // Soft delete - moves note to trash (owner only)
  async remove(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.trashed },
      include: NOTE_INCLUDE_TAGS,
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
      include: NOTE_INCLUDE_TAGS,
    });

    return transformNote(restoredNote, userId);
  }

  // Permanent delete - sets state to deleted (tombstone) (owner only)
  async permanentDelete(userId: string, id: string) {
    await this.noteAccessService.verifyNoteOwnership(userId, id);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.deleted },
      include: NOTE_INCLUDE_TAGS,
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
      include: NOTE_INCLUDE_TAGS,
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
      include: NOTE_INCLUDE_TAGS,
    });

    return notes.map((note) => transformNote(note, userId));
  }

  // Purge tombstones older than retention period (30 days)
  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    // 1. Purge deleted notes
    const deletedNotes = await this.prisma.note.deleteMany({
      where: {
        state: NoteState.deleted,
        updatedAt: { lt: cutoffDate },
      },
    });

    // 2. Purge deleted shares
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

  // Sync endpoint - handles bi-directional sync with conflict resolution
  async sync(userId: string, syncDto: SyncNotesDto) {
    const { lastSyncedAt, changes } = syncDto;
    const processedIds: string[] = [];
    const conflicts: { noteId: string; resolution: 'server' | 'client' }[] = [];

    // Process incoming changes from client
    for (const change of changes || []) {
      const existingNote = await this.prisma.note.findUnique({
        where: { id: change.id },
      });

      if (!existingNote) {
        // Note doesn't exist on server - create it (only if user is owner)
        // For shared notes, they should already exist on server
        await this.prisma.note.create({
          data: {
            id: change.id,
            title: change.title,
            content: change.content,
            isPinned: change.isPinned ?? false,
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
        processedIds.push(change.id);
      } else {
        // Check access - owner or editor
        const access = await this.noteAccessService.hasNoteAccess(
          userId,
          change.id,
          NoteSharePermission.editor,
        );

        if (!access.hasAccess) {
          // No access or viewer trying to edit - skip
          continue;
        }

        // Note exists and user has edit access - compare timestamps for conflict resolution
        const clientUpdatedAt = new Date(change.updatedAt);
        const serverUpdatedAt = existingNote.updatedAt;

        if (clientUpdatedAt > serverUpdatedAt) {
          // Client wins - update server
          // Only allow certain fields to be updated for shared notes (not state, isArchived)
          const updateData: any = {
            title: change.title,
            content: change.content,
            isPinned: change.isPinned,
            background: change.background,
          };

          // Only owner can update state and isArchived
          if (access.isOwner) {
            updateData.isArchived = change.isArchived;
            updateData.state =
              (change.state as NoteState) ?? existingNote.state;
          }

          // Update tags if provided (editors can update tags)
          if (change.tagIds !== undefined) {
            updateData.tags = {
              set: change.tagIds.map((id) => ({ id })),
            };
          }

          await this.prisma.note.update({
            where: { id: change.id },
            data: updateData,
          });
          conflicts.push({ noteId: change.id, resolution: 'client' });
        } else {
          conflicts.push({ noteId: change.id, resolution: 'server' });
        }
        processedIds.push(change.id);
      }
    }

    // Get all notes modified after lastSyncedAt (including trashed and deleted/tombstones)
    const ownNotes = await this.prisma.note.findMany({
      where: {
        userId,
        updatedAt: lastSyncedAt ? { gt: new Date(lastSyncedAt) } : undefined,
      },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
      },
    });

    // Get shared notes modified after lastSyncedAt
    const sharedShares = await this.prisma.noteShare.findMany({
      where: {
        sharedWithUserId: userId,
        ...(lastSyncedAt
          ? {
            OR: [
              // Case 1: Share itself was updated (permission change or deleted)
              { updatedAt: { gt: new Date(lastSyncedAt) } },
              // Case 2: Note was updated AND share is not deleted
              {
                isDeleted: false,
                note: {
                  updatedAt: { gt: new Date(lastSyncedAt) },
                },
              },
            ],
          }
          : { isDeleted: false }), // Initial sync: only get active shares
      },
      include: {
        note: {
          include: {
            ...NOTE_INCLUDE_TAGS,
            ...NOTE_INCLUDE_SHARES,
          },
        },
      },
    });

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
      processedIds,
      conflicts,
      syncedAt: new Date().toISOString(),
    };
  }

  /**
   * Import multiple notes at once (e.g., from Google Keep export)
   * Automatically creates tags from labels if they don't exist
   */
  async importNotes(
    userId: string,
    notes: Array<CreateNoteDto & { labels?: string[] }>,
  ) {
    // Collect all unique labels from notes
    const allLabels = new Set<string>();
    for (const note of notes) {
      if (note.labels) {
        for (const label of note.labels) {
          allLabels.add(label);
        }
      }
    }

    // Get existing tags for this user
    const existingTags = await this.prisma.tag.findMany({
      where: {
        userId,
        name: { in: Array.from(allLabels) },
        isDeleted: false,
      },
    });

    const existingTagNames = new Set(existingTags.map((t) => t.name));
    const tagNameToId = new Map(existingTags.map((t) => [t.name, t.id]));

    // Create missing tags
    const labelsToCreate = Array.from(allLabels).filter(
      (label) => !existingTagNames.has(label),
    );

    if (labelsToCreate.length > 0) {
      const createdTags = await this.prisma.$transaction(
        labelsToCreate.map((name) =>
          this.prisma.tag.create({
            data: { name, userId },
          }),
        ),
      );

      // Add newly created tags to the map
      for (const tag of createdTags) {
        tagNameToId.set(tag.name, tag.id);
      }
    }

    // Create notes with their tags
    const createdNotes = await this.prisma.$transaction(
      notes.map((note) => {
        const { tagIds, labels, ...noteData } = note;

        // Combine explicit tagIds with labels converted to tag IDs
        const labelTagIds = (labels || [])
          .map((label) => tagNameToId.get(label))
          .filter((id): id is string => id !== undefined);

        const allTagIds = [...new Set([...(tagIds || []), ...labelTagIds])];

        return this.prisma.note.create({
          data: {
            ...noteData,
            state: NoteState.active,
            userId,
            tags: allTagIds.length
              ? {
                connect: allTagIds.map((id) => ({ id })),
              }
              : undefined,
          },
          include: NOTE_INCLUDE_TAGS,
        });
      }),
    );

    return {
      imported: createdNotes.length,
      tagsCreated: labelsToCreate.length,
      notes: createdNotes.map((note) => transformNote(note, userId)),
    };
  }
}
