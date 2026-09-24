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

describe('NotesService.listReminders', () => {
  let prisma: { noteReminder: { findMany: jest.Mock } };
  let service: NotesService;

  beforeEach(() => {
    prisma = {
      noteReminder: {
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

  it("queries the user's reminders and returns title + state-joined rows", async () => {
    prisma.noteReminder.findMany.mockResolvedValue([
      {
        noteId: 'n1',
        remindAt: '2026-10-01T09:00',
        recurrence: 'daily',
        note: { title: 'Groceries', state: 'active' },
      },
      {
        noteId: 'n2',
        remindAt: '2026-10-02T09:00',
        recurrence: 'none',
        note: { title: '', state: 'trashed' },
      },
    ]);

    const rows = await service.listReminders('u1');

    expect(prisma.noteReminder.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1' } }),
    );
    expect(rows).toEqual([
      {
        noteId: 'n1',
        title: 'Groceries',
        remindAt: '2026-10-01T09:00',
        recurrence: 'daily',
        noteState: 'active',
      },
      {
        noteId: 'n2',
        title: '(untitled)',
        remindAt: '2026-10-02T09:00',
        recurrence: 'none',
        noteState: 'trashed',
      },
    ]);
  });

  it('returns an empty array when the user has no reminders', async () => {
    await expect(service.listReminders('u1')).resolves.toEqual([]);
  });
});
