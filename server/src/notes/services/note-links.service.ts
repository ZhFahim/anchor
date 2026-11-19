import { randomBytes } from 'crypto';
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteState } from 'src/generated/prisma/enums';
import { Prisma } from '../../generated/prisma/client';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { ERROR_MESSAGES } from '../constants/notes.constants';

export interface NoteLinkResponse {
  token: string;
  createdAt: string;
}

export interface PublicNoteResponse {
  title: string;
  content: string | null;
  background: string | null;
  updatedAt: string;
  attachments: {
    id: string;
    type: string;
    mimeType: string;
    originalFilename: string;
  }[];
}

// 24 random bytes: 32 URL-safe characters, far past guessing.
const newToken = () => randomBytes(24).toString('base64url');

const toResponse = (link: {
  token: string;
  createdAt: Date;
}): NoteLinkResponse => ({
  token: link.token,
  createdAt: link.createdAt.toISOString(),
});

@Injectable()
export class NoteLinksService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private noteAttachmentsService: NoteAttachmentsService,
  ) {}

  async getLink(ownerId: string, noteId: string) {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);
    const link = await this.prisma.noteLink.findUnique({ where: { noteId } });
    return { link: link ? toResponse(link) : null };
  }

  /** Returns the note's link, creating it on the first call. */
  async createLink(ownerId: string, noteId: string): Promise<NoteLinkResponse> {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);
    await this.noteAccessService.ensureNoteIsActive(noteId);

    const existing = await this.prisma.noteLink.findUnique({
      where: { noteId },
    });
    if (existing) return toResponse(existing);

    try {
      const link = await this.prisma.noteLink.create({
        data: { noteId, token: newToken(), createdByUserId: ownerId },
      });
      return toResponse(link);
    } catch (error) {
      // Two tabs turned the link on at once: both get the one that won.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const raced = await this.prisma.noteLink.findUnique({
          where: { noteId },
        });
        if (raced) return toResponse(raced);
      }
      throw error;
    }
  }

  async deleteLink(ownerId: string, noteId: string) {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);
    await this.prisma.noteLink.deleteMany({ where: { noteId } });
    return { success: true };
  }

  async getPublicNote(token: string): Promise<PublicNoteResponse> {
    const note = await this.findLinkedNote(token);
    const attachments = await this.prisma.noteAttachment.findMany({
      where: { noteId: note.id },
      orderBy: { position: 'asc' },
    });

    return {
      title: note.title,
      content: note.content,
      background: note.background,
      updatedAt: note.updatedAt.toISOString(),
      attachments: attachments.map((a) => ({
        id: a.id,
        type: a.type,
        mimeType: a.mimeType,
        originalFilename: a.originalFilename,
      })),
    };
  }

  async openPublicAttachment(token: string, attachmentId: string) {
    const note = await this.findLinkedNote(token);
    return this.noteAttachmentsService.openFile(note.id, attachmentId);
  }

  // A trashed note stops showing through its link; restoring it brings the
  // link back. Every miss looks the same, so the answer gives nothing away.
  private async findLinkedNote(token: string) {
    const link = await this.prisma.noteLink.findUnique({
      where: { token },
      include: { note: true },
    });
    if (!link || link.note.state !== NoteState.active) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }
    return link.note;
  }
}
