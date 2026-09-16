import { BadRequestException } from '@nestjs/common';
import { NotesService } from './notes.service';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  createMockSyncEmitter,
  createMockNoteRevisions,
  asSyncEmitter,
  asNoteRevisions,
} from '../../../test/sync-mocks';

describe('NotesService.findAll search hardening', () => {
  let prisma: { note: { findMany: jest.Mock } };
  let service: NotesService;

  beforeEach(() => {
    prisma = {
      note: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    service = new NotesService(
      prisma as unknown as PrismaService,
      {} as unknown as NoteAccessService,
      {} as unknown as NoteAttachmentsService,
      asSyncEmitter(createMockSyncEmitter()),
      asNoteRevisions(createMockNoteRevisions()),
    );
  });

  it('rejects an overlong search query with a 400', async () => {
    await expect(service.findAll('u1', 'x'.repeat(301))).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(prisma.note.findMany).not.toHaveBeenCalled();
  });

  it('accepts a search within the cap', async () => {
    await service.findAll('u1', 'x'.repeat(300));
    expect(prisma.note.findMany).toHaveBeenCalled();
  });

  it('handles an undefined search', async () => {
    await service.findAll('u1');
    expect(prisma.note.findMany).toHaveBeenCalled();
  });
});
