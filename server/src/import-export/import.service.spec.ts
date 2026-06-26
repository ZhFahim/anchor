import { Logger } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ImportService } from './import.service';
import { PrismaService } from '../prisma/prisma.service';
import { NoteAccessService } from '../notes/services/note-access.service';
import { ImportNoteItemDto } from './dto/import-notes.dto';
import { createMockPrisma, MockPrismaService } from '../../test/prisma-mock';

const USER_ID = 'user-1';
const OTHER_USER_ID = 'user-2';

interface NoteCreateArgs {
  data: {
    id?: string;
    userId: string;
    content: string | null;
    background: string | null;
    state: string;
    isArchived: boolean;
    createdAt?: Date;
    updatedAt?: Date;
    tags?: { connect: { id: string }[] };
  };
}

const noteCreateData = (prisma: MockPrismaService, call = 0) =>
  (prisma.note.create.mock.calls[call] as [NoteCreateArgs])[0].data;

const makeItem = (
  overrides: Partial<ImportNoteItemDto> = {},
): ImportNoteItemDto => ({
  ref: 'ref-1',
  title: 'Imported note',
  ...overrides,
});

describe('ImportService.importNotes', () => {
  let prisma: MockPrismaService;
  let service: ImportService;
  let loggerError: jest.SpyInstance;

  beforeEach(async () => {
    loggerError = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => undefined);
    prisma = createMockPrisma();
    prisma.note.findMany.mockResolvedValue([]);
    prisma.note.create.mockImplementation(
      ({ data }: { data: { id?: string } }) =>
        Promise.resolve({ id: data.id ?? 'generated-id' }),
    );
    prisma.notePin.create.mockResolvedValue({});
    prisma.tag.findMany.mockResolvedValue([]);
    prisma.tag.createMany.mockResolvedValue({ count: 0 });

    const moduleRef = await Test.createTestingModule({
      providers: [
        ImportService,
        { provide: PrismaService, useValue: prisma },
        {
          provide: NoteAccessService,
          useValue: { verifyNoteOwnership: jest.fn() },
        },
      ],
    }).compile();
    service = moduleRef.get(ImportService);
  });

  it('creates a note preserving id and second-truncated timestamps', async () => {
    const response = await service.importNotes(USER_ID, {
      notes: [
        makeItem({
          id: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f',
          content: '{"ops":[{"insert":"hi\\n"}]}',
          createdAt: '2025-01-01T10:00:00.789Z',
          updatedAt: '2025-03-01T10:00:00.456Z',
          isArchived: true,
          background: 'color_teal',
        }),
      ],
    });

    expect(response.results).toEqual([
      {
        ref: 'ref-1',
        status: 'created',
        noteId: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f',
      },
    ]);
    const data = noteCreateData(prisma);
    expect(data.id).toBe('0b54f5e9-8f51-4be9-a72f-3bd693466b2f');
    expect(data.userId).toBe(USER_ID);
    expect(data.isArchived).toBe(true);
    expect(data.background).toBe('color_teal');
    expect(data.state).toBe('active');
    expect(data.createdAt).toEqual(new Date('2025-01-01T10:00:00.000Z'));
    expect(data.updatedAt).toEqual(new Date('2025-03-01T10:00:00.000Z'));
  });

  it('skips notes whose id already belongs to the importer', async () => {
    prisma.note.findMany.mockResolvedValue([
      { id: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f', userId: USER_ID },
    ]);

    const response = await service.importNotes(USER_ID, {
      notes: [makeItem({ id: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f' })],
    });

    expect(response.results[0]).toEqual({
      ref: 'ref-1',
      status: 'skipped',
      noteId: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f',
    });
    expect(prisma.note.create).not.toHaveBeenCalled();
  });

  it('remaps notes whose id belongs to another user', async () => {
    prisma.note.findMany.mockResolvedValue([
      { id: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f', userId: OTHER_USER_ID },
    ]);

    const response = await service.importNotes(USER_ID, {
      notes: [makeItem({ id: '0b54f5e9-8f51-4be9-a72f-3bd693466b2f' })],
    });

    expect(response.results[0]).toEqual({
      ref: 'ref-1',
      status: 'remapped',
      noteId: 'generated-id',
    });
    expect(noteCreateData(prisma).id).toBeUndefined();
  });

  it('restores trashed notes preserving their real modified time', async () => {
    await service.importNotes(USER_ID, {
      notes: [
        makeItem({
          isTrashed: true,
          updatedAt: '2020-01-01T00:00:00.456Z',
        }),
      ],
    });

    const data = noteCreateData(prisma);
    expect(data.state).toBe('trashed');
    expect(data.updatedAt).toEqual(new Date('2020-01-01T00:00:00.000Z'));
  });

  it('creates a pin for pinned notes', async () => {
    await service.importNotes(USER_ID, {
      notes: [makeItem({ isPinned: true })],
    });

    expect(prisma.notePin.create).toHaveBeenCalledWith({
      data: { userId: USER_ID, noteId: 'generated-id' },
    });
  });

  it('drops invalid content and unknown backgrounds with a warning', async () => {
    const response = await service.importNotes(USER_ID, {
      notes: [
        makeItem({ content: 'not json at all', background: 'hot_pink_zebra' }),
      ],
    });

    const data = noteCreateData(prisma);
    expect(data.content).toBeNull();
    expect(data.background).toBeNull();
    expect(response.results[0].warning).toContain('Content');
    expect(response.results[0].warning).toContain('hot_pink_zebra');
  });

  it('reuses existing tags case-sensitively and creates missing ones', async () => {
    prisma.tag.findMany
      .mockResolvedValueOnce([{ id: 'tag-1', name: 'Work' }])
      .mockResolvedValueOnce([
        { id: 'tag-1', name: 'Work' },
        { id: 'tag-2', name: 'work' },
      ]);

    const response = await service.importNotes(USER_ID, {
      notes: [makeItem({ tagNames: ['Work', 'work'] })],
      tags: [
        { name: 'Work', color: '#ff0000' },
        { name: 'work', color: '#00ff00' },
      ],
    });

    // Only the missing tag is created, and it carries its palette color.
    expect(prisma.tag.createMany).toHaveBeenCalledWith({
      data: [{ name: 'work', userId: USER_ID, color: '#00ff00' }],
      skipDuplicates: true,
    });
    expect(response.tags).toEqual({ created: 1, reused: 1 });
    expect(noteCreateData(prisma).tags).toEqual({
      connect: [{ id: 'tag-1' }, { id: 'tag-2' }],
    });
  });

  it('isolates per-note failures so the batch continues', async () => {
    prisma.note.create
      .mockRejectedValueOnce(new Error('db down'))
      .mockResolvedValueOnce({ id: 'second-id' });

    const response = await service.importNotes(USER_ID, {
      notes: [
        makeItem({ ref: 'ref-1' }),
        makeItem({ ref: 'ref-2', title: 'Second' }),
      ],
    });

    expect(response.results).toEqual([
      { ref: 'ref-1', status: 'failed', error: 'Failed to create note' },
      { ref: 'ref-2', status: 'created', noteId: 'second-id' },
    ]);
    expect(loggerError).toHaveBeenCalledTimes(1);
  });
});
