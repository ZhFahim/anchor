import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { NoteState } from 'src/generated/prisma/enums';
import { PrismaService } from 'src/prisma/prisma.service';
import { NoteLockService } from 'src/notes/note-lock.service';
import { UpdateHomarrNoteDto } from './dto/update-homarr-note.dto';

interface ListNotesInput {
  userId: string;
  search?: string;
  tagId?: string;
  limit?: number;
}

@Injectable()
export class HomarrIntegrationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly noteLockService: NoteLockService,
  ) {}

  async listNotes({ userId, search, tagId, limit }: ListNotesInput) {
    const normalizedSearch = search?.trim();
    const clampedLimit = clampLimit(limit);

    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: NoteState.active,
        isArchived: false,
        ...(tagId && {
          tags: {
            some: { id: tagId },
          },
        }),
        OR: normalizedSearch
          ? [
            { title: { contains: normalizedSearch, mode: 'insensitive' } },
            { content: { contains: normalizedSearch, mode: 'insensitive' } },
          ]
          : undefined,
      },
      orderBy: [{ isPinned: 'desc' }, { updatedAt: 'desc' }],
      take: clampedLimit,
      include: {
        tags: {
          select: { id: true },
        },
      },
    });

    return notes.map((note) => ({
      id: note.id,
      title: note.title,
      updatedAt: note.updatedAt,
      isPinned: note.isPinned,
      tagIds: note.tags.map((tag) => tag.id),
    }));
  }

  async getNote(userId: string, id: string) {
    const note = await this.getActiveNote(userId, id);
    return this.formatNote(note);
  }

  async lockNote(userId: string, id: string) {
    await this.getActiveNote(userId, id);
    const result = this.noteLockService.acquire(id, 'homarr', userId);
    if (result.status === 'locked') {
      throw new ConflictException({
        message: 'Note is locked',
        lockedBy: result.lockedBy,
        expiresAt: result.expiresAt,
        status: result.status,
      });
    }
    return result;
  }

  async unlockNote(userId: string, id: string) {
    await this.getActiveNote(userId, id);
    this.noteLockService.release(id, 'homarr', userId);
    return { status: 'released' };
  }

  async updateNote(userId: string, id: string, updateNoteDto: UpdateHomarrNoteDto) {
    await this.getActiveNote(userId, id);
    const lockStatus = this.noteLockService.check(id, 'homarr', userId);
    if (lockStatus.status === 'locked') {
      throw new ConflictException({
        message: 'Note is locked',
        lockedBy: lockStatus.lock.lockedBy,
        expiresAt: lockStatus.lock.expiresAt,
      });
    }

    const note = await this.prisma.note.update({
      where: { id },
      data: {
        ...(updateNoteDto.title !== undefined && { title: updateNoteDto.title }),
        ...(updateNoteDto.content !== undefined && { content: updateNoteDto.content }),
      },
      include: {
        tags: {
          select: { id: true },
        },
      },
    });

    return this.formatNote(note);
  }

  private async getActiveNote(userId: string, id: string) {
    const note = await this.prisma.note.findUnique({
      where: { id },
      include: {
        tags: {
          select: { id: true },
        },
      },
    });

    if (!note || note.userId !== userId || note.state !== NoteState.active) {
      throw new NotFoundException('Note not found');
    }

    return note;
  }

  private formatNote(note: {
    id: string;
    title: string;
    content: string | null;
    createdAt: Date;
    updatedAt: Date;
    isPinned: boolean;
    isArchived: boolean;
    background: string | null;
    tags: { id: string }[];
  }) {
    return {
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      background: note.background,
      tagIds: note.tags.map((tag) => tag.id),
    };
  }
}

const clampLimit = (limit?: number) => {
  const value = typeof limit === 'number' && !Number.isNaN(limit) ? limit : 50;
  return Math.min(Math.max(value, 1), 200);
};
