import { beforeEach, describe, expect, it, type Mock, vi } from 'vitest';
import { Prisma } from '../../generated/prisma/client';
import { NotesService } from './notes.service';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { NoteSharesService } from './note-shares.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  createMockSyncEmitter,
  createMockNoteRevisions,
  asSyncEmitter,
  asNoteRevisions,
} from '../../../test/sync-mocks';

/**
 * Regression tests for the "tags disappearing from shared notes" bug.
 *
 * Tags are a note-global relation, but the API only ever exposes/accepts a
 * user's own tags. Writes used to `set` (replace) the whole relation, which
 * wiped tags another user had attached to a shared note. These tests exercise
 * the two-user shared-note flow against a small in-memory tag relation and
 * assert the other user's tag survives.
 */
describe('NotesService tag reconciliation (shared notes)', () => {
  const NOTE_ID = 'note-1';
  const OWNER = 'user-owner';
  const EDITOR = 'user-editor';

  interface Tag {
    id: string;
    userId: string;
    isDeleted: boolean;
  }

  interface TagWhere {
    id?: { in: string[] };
    userId: string;
    isDeleted?: boolean;
    notes?: { some: { id: string } };
  }

  interface TagRef {
    id: string;
  }

  interface NoteWrite {
    where: { id: string };
    data?: {
      tags?: { set?: TagRef[]; connect?: TagRef[]; disconnect?: TagRef[] };
      version?: unknown;
      reminder?: unknown;
    };
  }

  let tags: Tag[];
  let noteTags: Set<string>; // `${noteId}:${tagId}`
  let service: NotesService;

  const pair = (noteId: string, tagId: string) => `${noteId}:${tagId}`;

  const tagFindMany = ({ where }: { where: TagWhere }): Promise<TagRef[]> => {
    // Shape 1: ownable tags for the caller — { id: { in }, userId, isDeleted }
    if (where.id?.in) {
      return Promise.resolve(
        tags
          .filter(
            (t) =>
              where.id!.in.includes(t.id) &&
              t.userId === where.userId &&
              t.isDeleted === where.isDeleted,
          )
          .map((t) => ({ id: t.id })),
      );
    }
    // Shape 2: caller's tags attached to a note — { userId, notes: { some } }
    const noteId = where.notes!.some.id;
    return Promise.resolve(
      tags
        .filter(
          (t) => t.userId === where.userId && noteTags.has(pair(noteId, t.id)),
        )
        .map((t) => ({ id: t.id })),
    );
  };

  const noteUpdate = ({ where, data }: NoteWrite) => {
    if (data?.tags) {
      // Honor `set` (full replace) too, so a regression to the old behavior is
      // actually reproduced and caught by these tests.
      if (data.tags.set) {
        for (const t of tags) noteTags.delete(pair(where.id, t.id));
        for (const { id } of data.tags.set) noteTags.add(pair(where.id, id));
      }
      for (const { id } of data.tags.connect ?? []) {
        noteTags.add(pair(where.id, id));
      }
      for (const { id } of data.tags.disconnect ?? []) {
        noteTags.delete(pair(where.id, id));
      }
    }
    return Promise.resolve({ id: where.id });
  };

  const attachedTagsFor = (noteId: string) =>
    tags
      .filter((t) => noteTags.has(pair(noteId, t.id)))
      .map((t) => ({ id: t.id, userId: t.userId }));

  const noteUpdateMock = vi.fn(noteUpdate);
  const noteUpdateManyMock = vi.fn().mockResolvedValue({ count: 1 });
  const notePinUpsert = vi.fn();
  let storedReminder: {
    remindAt: string;
    recurrence: string;
    version: number;
  } | null = null;

  const reminderUpsert = vi.fn().mockResolvedValue({
    remindAt: '2026-09-04T09:00',
    recurrence: 'none',
    version: 1,
  });
  const reminderFindUnique = vi.fn(() => Promise.resolve(storedReminder));
  const reminderDelete = vi.fn().mockResolvedValue(undefined);

  const prisma = {
    $transaction: (cb: (tx: PrismaService) => unknown) => cb(prisma),
    note: {
      update: noteUpdateMock,
      updateMany: noteUpdateManyMock,
      findUniqueOrThrow: vi.fn(({ where }: { where: { id: string } }) =>
        Promise.resolve({
          id: where.id,
          title: 'Groceries',
          content: null,
          background: null,
          state: 'active',
          version: 3,
          createdAt: new Date(),
          updatedAt: new Date(),
          userId: OWNER,
          tags: attachedTagsFor(where.id),
          pins: [],
          archives: [],
        }),
      ),
    },
    tag: { findMany: vi.fn(tagFindMany) },
    notePin: { upsert: notePinUpsert, deleteMany: vi.fn() },
    noteArchive: {
      createMany: vi.fn().mockResolvedValue({ count: 1 }),
      deleteMany: vi.fn().mockResolvedValue({ count: 1 }),
    },
    noteReminder: {
      findUnique: reminderFindUnique,
      upsert: reminderUpsert,
      delete: reminderDelete,
      deleteMany: vi.fn().mockResolvedValue({ count: 1 }),
    },
  } as unknown as PrismaService;

  const ensureNoteAccess = vi.fn().mockResolvedValue(undefined);
  const noteAccess = { ensureNoteAccess } as unknown as NoteAccessService;
  const noteShares = {
    leaveShare: vi.fn(),
  } as unknown as NoteSharesService;

  beforeEach(() => {
    tags = [
      { id: 'tag-owner', userId: OWNER, isDeleted: false },
      { id: 'tag-family', userId: EDITOR, isDeleted: false },
    ];
    noteTags = new Set([
      pair(NOTE_ID, 'tag-owner'),
      pair(NOTE_ID, 'tag-family'),
    ]);
    storedReminder = null;
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(createMockSyncEmitter()),
      asNoteRevisions(createMockNoteRevisions()),
    );
    vi.clearAllMocks();
  });

  it("owner's update does not drop the editor's tag on a shared note", async () => {
    // Owner saves the note; their client only knows about their own tag.
    await service.update(OWNER, NOTE_ID, { tagIds: ['tag-owner'] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it("editor's update does not drop the owner's tag on a shared note", async () => {
    await service.update(EDITOR, NOTE_ID, { tagIds: ['tag-family'] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
  });

  it("removing the caller's own tag leaves the other user's tag intact", async () => {
    await service.update(EDITOR, NOTE_ID, { tagIds: [] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(false);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it('cannot attach a tag owned by another user', async () => {
    // A foreign tag that is not yet on the note must stay unattached.
    tags.push({ id: 'tag-owner-2', userId: OWNER, isDeleted: false });

    await service.update(EDITOR, NOTE_ID, {
      tagIds: ['tag-owner-2', 'tag-family'],
    });

    expect(noteTags.has(pair(NOTE_ID, 'tag-owner-2'))).toBe(false);
    // The editor's own tag and the owner's existing tag are untouched.
    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it("adds the caller's new tag without a full-relation replace", async () => {
    noteTags = new Set([pair(NOTE_ID, 'tag-owner')]);
    await service.update(EDITOR, NOTE_ID, { tagIds: ['tag-family'] });

    const tagWrite = noteUpdateMock.mock.calls
      .map(([arg]) => arg)
      .find((arg) => arg.data?.tags);
    // The write must be a targeted connect/disconnect, never a `set`.
    expect(tagWrite?.data?.tags?.set).toBeUndefined();
    expect(tagWrite?.data?.tags?.connect).toEqual([{ id: 'tag-family' }]);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it('keeps the reminder out of the note write and off the version', async () => {
    await service.update(OWNER, NOTE_ID, {
      reminder: { remindAt: '2026-09-04T09:00' },
    });

    for (const [arg] of noteUpdateMock.mock.calls) {
      expect(arg.data).not.toHaveProperty('reminder');
      expect(arg.data?.version).toBeUndefined();
    }
    expect(reminderUpsert).toHaveBeenCalled();
  });

  it('a save that repeats the stored reminder writes nothing', async () => {
    storedReminder = {
      remindAt: '2026-09-04T09:00',
      recurrence: 'none',
      version: 3,
    };
    const emitter = createMockSyncEmitter();
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(emitter),
      asNoteRevisions(createMockNoteRevisions()),
    );

    await service.update(OWNER, NOTE_ID, {
      reminder: { remindAt: '2026-09-04T09:00' },
    });

    expect(reminderUpsert).not.toHaveBeenCalled();
    expect(emittedTypes(emitter)).not.toContain('reminder');
  });

  it('a save carrying no reminder on a note without one emits nothing', async () => {
    const emitter = createMockSyncEmitter();
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(emitter),
      asNoteRevisions(createMockNoteRevisions()),
    );

    await service.update(OWNER, NOTE_ID, { title: 'Typing', reminder: null });

    expect(reminderDelete).not.toHaveBeenCalled();
    expect(emittedTypes(emitter)).not.toContain('reminder');
  });

  it('an archive-only save needs read access and leaves the note alone', async () => {
    const emitter = createMockSyncEmitter();
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(emitter),
      asNoteRevisions(createMockNoteRevisions()),
    );

    await service.update(EDITOR, NOTE_ID, { isArchived: true });

    expect(ensureNoteAccess).toHaveBeenCalledWith(EDITOR, NOTE_ID, undefined);
    expect(noteUpdateMock).not.toHaveBeenCalled();
    expect(emitter.emit).toHaveBeenCalledWith(prisma, [
      {
        recipientUserId: EDITOR,
        entityType: 'note',
        entityId: NOTE_ID,
        op: 'upsert',
      },
    ]);
  });

  it('a tags-only save needs read access and reaches only the tagger', async () => {
    const emitter = createMockSyncEmitter();
    emitter.noteRecipients.mockResolvedValue([OWNER, EDITOR]);
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(emitter),
      asNoteRevisions(createMockNoteRevisions()),
    );

    await service.update(EDITOR, NOTE_ID, { tagIds: [] });

    expect(ensureNoteAccess).toHaveBeenCalledWith(EDITOR, NOTE_ID, undefined);
    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(false);
    expect(emitter.emit).toHaveBeenCalledWith(prisma, [
      {
        recipientUserId: EDITOR,
        entityType: 'note',
        entityId: NOTE_ID,
        op: 'upsert',
      },
    ]);
  });

  it('a save that loses a race to another writer is a conflict, with nothing else applied', async () => {
    noteUpdateManyMock.mockResolvedValueOnce({ count: 0 });

    await expect(
      service.update(OWNER, NOTE_ID, {
        title: 'Mine',
        baseVersion: 3,
        isPinned: true,
      }),
    ).rejects.toMatchObject({ status: 409 });
    expect(noteUpdateManyMock).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: NOTE_ID, version: 3 } }),
    );
    expect(notePinUpsert).not.toHaveBeenCalled();
  });

  it('keeps a stale save in History only when its text differs', async () => {
    const revisions = createMockNoteRevisions();
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
      noteShares,
      asSyncEmitter(createMockSyncEmitter()),
      asNoteRevisions(revisions),
    );

    await expect(
      service.update(OWNER, NOTE_ID, { title: 'Groceries', baseVersion: 2 }),
    ).rejects.toMatchObject({ status: 409 });
    expect(revisions.recordConflict).not.toHaveBeenCalled();

    await expect(
      service.update(OWNER, NOTE_ID, { title: 'Mine', baseVersion: 2 }),
    ).rejects.toMatchObject({ status: 409 });
    expect(revisions.recordConflict).toHaveBeenCalledTimes(1);
  });

  it('a save that edits the note still needs editor permission', async () => {
    await service.update(EDITOR, NOTE_ID, {
      title: 'Groceries',
      isArchived: true,
    });

    expect(ensureNoteAccess).toHaveBeenCalledWith(EDITOR, NOTE_ID, 'editor');
    for (const [arg] of noteUpdateMock.mock.calls) {
      expect(arg.data).not.toHaveProperty('isArchived');
    }
  });
});

type Emit = (tx: unknown, emissions: Array<{ entityType: string }>) => unknown;

const emittedTypes = (emitter: { emit: Mock<Emit> }): string[] =>
  emitter.emit.mock.calls.flatMap(([, emissions]) =>
    emissions.map((emission) => emission.entityType),
  );

describe('NotesService.create with a client id', () => {
  const USER = 'user-1';
  const ID = '0b6f6c1e-3d52-4d3a-9d2b-2c7f7b8a9e10';
  const findUnique = vi.fn();
  const create = vi.fn();
  const prisma = {
    $transaction: (cb: (tx: PrismaService) => unknown) => cb(prisma),
    note: { findUnique, create },
  } as unknown as PrismaService;
  let service: NotesService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new NotesService(
      prisma,
      {} as unknown as NoteAccessService,
      {} as unknown as NoteAttachmentsService,
      {} as unknown as NoteSharesService,
      asSyncEmitter(createMockSyncEmitter()),
      asNoteRevisions(createMockNoteRevisions()),
    );
    vi.spyOn(service, 'findOne').mockResolvedValue({ id: ID } as never);
  });

  it('a create sent again gets the note the first one made', async () => {
    findUnique.mockResolvedValue({ userId: USER });

    await expect(
      service.create(USER, { id: ID, title: 'Groceries' }),
    ).resolves.toEqual({ id: ID });
    expect(create).not.toHaveBeenCalled();
  });

  it("refuses an id that belongs to someone else's note", async () => {
    findUnique.mockResolvedValue({ userId: 'someone-else' });

    await expect(
      service.create(USER, { id: ID, title: 'Groceries' }),
    ).rejects.toMatchObject({ status: 409 });
  });

  it('two sends at the same time make one note', async () => {
    findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ userId: USER });
    create.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: 'test',
      }),
    );

    await expect(
      service.create(USER, { id: ID, title: 'Groceries' }),
    ).resolves.toEqual({ id: ID });
  });
});
