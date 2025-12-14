import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNoteDto } from './dto/create-note.dto';
import { UpdateNoteDto } from './dto/update-note.dto';
import { SyncNotesDto } from './dto/sync-notes.dto';
import { NoteState } from 'src/generated/prisma/enums';

// Helper to transform note with tags to include tagIds array
function transformNote(note: any) {
  if (!note) return note;
  const { tags, ...rest } = note;
  return {
    ...rest,
    tagIds: tags?.map((t: any) => t.id) || [],
  };
}

@Injectable()
export class NotesService {
  constructor(private prisma: PrismaService) { }

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
      include: {
        tags: true,
      },
    });

    return transformNote(note);
  }

  async findAll(userId: string, search?: string, tagId?: string) {
    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: NoteState.active,
        ...(tagId && {
          tags: {
            some: { id: tagId },
          },
        }),
        OR: search
          ? [
            { title: { contains: search, mode: 'insensitive' } },
            { content: { contains: search, mode: 'insensitive' } },
          ]
          : undefined,
      },
      orderBy: [{ isPinned: 'desc' }, { updatedAt: 'desc' }],
      include: {
        tags: true,
      },
    });

    return notes.map(transformNote);
  }

  async findOne(userId: string, id: string, includeAllStates = false) {
    const note = await this.prisma.note.findUnique({
      where: { id },
      include: {
        tags: true,
      },
    });

    if (!note || note.userId !== userId) {
      throw new NotFoundException('Note not found');
    }

    if (!includeAllStates && note.state !== NoteState.active) {
      throw new NotFoundException('Note not found');
    }

    return transformNote(note);
  }

  async update(userId: string, id: string, updateNoteDto: UpdateNoteDto) {
    // Ensure note exists and belongs to user (include all states for sync scenarios)
    await this.findOne(userId, id, true);

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
      include: {
        tags: true,
      },
    });

    return transformNote(note);
  }

  // Soft delete - moves note to trash
  async remove(userId: string, id: string) {
    await this.findOne(userId, id, true);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.trashed },
      include: {
        tags: true,
      },
    });

    return transformNote(note);
  }

  // Restore from trash
  async restore(userId: string, id: string) {
    const existingNote = await this.findOne(userId, id, true);

    if (existingNote.state !== NoteState.trashed) {
      throw new NotFoundException('Note is not in trash');
    }

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.active },
      include: {
        tags: true,
      },
    });

    return transformNote(note);
  }

  // Permanent delete - sets state to deleted (tombstone)
  async permanentDelete(userId: string, id: string) {
    await this.findOne(userId, id, true);

    const note = await this.prisma.note.update({
      where: { id },
      data: { state: NoteState.deleted },
      include: {
        tags: true,
      },
    });

    return transformNote(note);
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
        tags: true,
      },
    });

    return notes.map(transformNote);
  }

  // Purge tombstones older than retention period (30 days)
  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    const result = await this.prisma.note.deleteMany({
      where: {
        state: NoteState.deleted,
        updatedAt: { lt: cutoffDate },
      },
    });

    return { purgedCount: result.count };
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
        // Note doesn't exist on server - create it
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
      } else if (existingNote.userId === userId) {
        // Note exists - compare timestamps for conflict resolution
        const clientUpdatedAt = new Date(change.updatedAt);
        const serverUpdatedAt = existingNote.updatedAt;

        if (clientUpdatedAt > serverUpdatedAt) {
          // Client wins - update server
          await this.prisma.note.update({
            where: { id: change.id },
            data: {
              title: change.title,
              content: change.content,
              isPinned: change.isPinned,
              isArchived: change.isArchived,
              background: change.background,
              state: (change.state as NoteState) ?? existingNote.state,
              // Update tags if provided
              ...(change.tagIds !== undefined && {
                tags: {
                  set: change.tagIds.map((id) => ({ id })),
                },
              }),
            },
          });
          conflicts.push({ noteId: change.id, resolution: 'client' });
        } else {
          conflicts.push({ noteId: change.id, resolution: 'server' });
        }
        processedIds.push(change.id);
      }
    }

    // Get all notes modified after lastSyncedAt (including trashed and deleted/tombstones)
    const serverNotes = await this.prisma.note.findMany({
      where: {
        userId,
        updatedAt: lastSyncedAt ? { gt: new Date(lastSyncedAt) } : undefined,
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        tags: true,
      },
    });

    const serverChanges = serverNotes.map(transformNote);

    return {
      serverChanges,
      processedIds,
      conflicts,
      syncedAt: new Date().toISOString(),
    };
  }
}
