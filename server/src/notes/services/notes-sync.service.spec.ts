import { NotesService, buildSharedSyncWhere } from './notes.service';
import { getSyncUpdatedAtWindow } from '../../sync/sync-window.util';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { PrismaService } from '../../prisma/prisma.service';
import { SyncNoteDto } from '../dto/sync-notes.dto';

/**
 * Tests for NotesService.sync conflict resolution, exercised against a small
 * in-memory note store:
 *  - unknown note ids are created
 *  - stale client changes lose to the server (and the server copy is echoed back)
 *  - newer client changes win via the optimistic updatedAt guard
 *  - a concurrent server write between read and write flips the win to 'server'
 *  - read-only users can't write note content, only their own pin
 *  - non-owners can't change isArchived/state
 *  - the syncedAt watermark bounds which notes come back as serverChanges
 */
describe('NotesService.sync conflict resolution', () => {
  const USER = 'user-1';
  const OTHER = 'user-2';

  interface NoteRecord {
    id: string;
    title: string;
    content: string | null;
    isArchived: boolean;
    background: string | null;
    state: string;
    userId: string;
    createdAt: Date;
    updatedAt: Date;
    syncedAt: Date;
  }

  interface DateWindow {
    gt?: Date;
    lte?: Date;
  }

  let notes: Map<string, NoteRecord>;
  // (userId, noteId) -> access; keyed without permission: editor+ access flag
  let editorAccess: Map<string, { hasAccess: boolean; isOwner: boolean }>;
  let readAccess: Map<string, boolean>;

  const key = (userId: string, noteId: string) => `${userId}:${noteId}`;

  const makeNote = (overrides: Partial<NoteRecord> & { id: string }) => {
    const at = new Date('2026-07-01T12:00:00.000Z');
    const note: NoteRecord = {
      title: 'Server title',
      content: null,
      isArchived: false,
      background: null,
      state: 'active',
      userId: USER,
      createdAt: at,
      updatedAt: at,
      syncedAt: at,
      ...overrides,
    };
    notes.set(note.id, note);
    return note;
  };

  const withIncludes = (note: NoteRecord) => ({
    ...note,
    tags: [],
    sharedWith: [],
    pins: [],
    _count: { attachments: 0 },
    attachments: [],
  });

  const inWindow = (date: Date, window: DateWindow) =>
    (window.gt === undefined || date > window.gt) &&
    (window.lte === undefined || date <= window.lte);

  // Mirrors withForcedSyncIds output: {syncedAt} or {OR:[{syncedAt},{id:{in}}]}
  const matchesSyncWhere = (
    note: NoteRecord,
    where: {
      syncedAt?: DateWindow;
      OR?: Array<{ syncedAt?: DateWindow; id?: { in: string[] } }>;
    },
  ): boolean => {
    if (where.syncedAt) {
      return inWindow(note.syncedAt, where.syncedAt);
    }
    return (where.OR ?? []).some((clause) =>
      clause.syncedAt
        ? inWindow(note.syncedAt, clause.syncedAt)
        : (clause.id?.in ?? []).includes(note.id),
    );
  };

  const noteFindUnique = jest.fn(({ where }: { where: { id: string } }) =>
    Promise.resolve(notes.get(where.id) ?? null),
  );

  const noteCreate = jest.fn(({ data }: { data: Record<string, unknown> }) => {
    const now = new Date();
    const note = makeNote({
      id: data.id as string,
      title: data.title as string,
      content: (data.content as string) ?? null,
      isArchived: (data.isArchived as boolean) ?? false,
      background: (data.background as string) ?? null,
      state: data.state as string,
      userId: data.userId as string,
      createdAt: now,
      updatedAt: now,
      syncedAt: now,
    });
    return Promise.resolve(note);
  });

  // Optimistic guard: only writes when updatedAt still matches, like the DB.
  const noteUpdateMany = jest.fn(
    ({
      where,
      data,
    }: {
      where: { id: string; updatedAt: Date };
      data: Record<string, unknown>;
    }) => {
      const note = notes.get(where.id);
      if (!note || note.updatedAt.getTime() !== where.updatedAt.getTime()) {
        return Promise.resolve({ count: 0 });
      }
      const now = new Date();
      Object.assign(note, data, { updatedAt: now, syncedAt: now });
      return Promise.resolve({ count: 1 });
    },
  );

  const noteFindMany = jest.fn(
    ({
      where,
    }: {
      where: Parameters<typeof matchesSyncWhere>[1] & { userId: string };
    }) =>
      Promise.resolve(
        [...notes.values()]
          .filter((n) => n.userId === where.userId)
          .filter((n) => matchesSyncWhere(n, where))
          .map(withIncludes),
      ),
  );

  const noteShareFindMany = jest.fn().mockResolvedValue([]);
  const notePinUpsert = jest.fn().mockResolvedValue({});

  const prisma = {
    $transaction: (cb: (tx: PrismaService) => unknown) => cb(prisma),
    note: {
      findUnique: noteFindUnique,
      create: noteCreate,
      updateMany: noteUpdateMany,
      findMany: noteFindMany,
    },
    noteShare: { findMany: noteShareFindMany },
    notePin: {
      upsert: notePinUpsert,
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
    tag: { findMany: jest.fn().mockResolvedValue([]) },
  } as unknown as PrismaService;

  const noteAccess = {
    hasNoteAccess: jest.fn(
      (userId: string, noteId: string, permission?: string) => {
        if (permission === 'editor') {
          return Promise.resolve(
            editorAccess.get(key(userId, noteId)) ?? {
              hasAccess: false,
              isOwner: false,
            },
          );
        }
        return Promise.resolve({
          hasAccess: readAccess.get(key(userId, noteId)) ?? false,
          isOwner: false,
        });
      },
    ),
  } as unknown as NoteAccessService;

  let service: NotesService;

  const grantOwner = (userId: string, noteId: string) => {
    editorAccess.set(key(userId, noteId), { hasAccess: true, isOwner: true });
    readAccess.set(key(userId, noteId), true);
  };

  const grantEditor = (userId: string, noteId: string) => {
    editorAccess.set(key(userId, noteId), { hasAccess: true, isOwner: false });
    readAccess.set(key(userId, noteId), true);
  };

  const grantViewer = (userId: string, noteId: string) => {
    editorAccess.set(key(userId, noteId), { hasAccess: false, isOwner: false });
    readAccess.set(key(userId, noteId), true);
  };

  const change = (overrides: Partial<SyncNoteDto> & { id: string }) =>
    ({
      title: 'Client title',
      updatedAt: new Date().toISOString(),
      ...overrides,
    }) as SyncNoteDto;

  beforeEach(() => {
    notes = new Map();
    editorAccess = new Map();
    readAccess = new Map();
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
    );
    jest.clearAllMocks();
  });

  it('creates a note the server has never seen', async () => {
    const result = await service.sync(USER, {
      changes: [change({ id: 'new-note', title: 'From client' })],
    });

    expect(noteCreate).toHaveBeenCalledTimes(1);
    expect(notes.get('new-note')?.title).toBe('From client');
    expect(notes.get('new-note')?.userId).toBe(USER);
    expect(result.processedIds).toEqual(['new-note']);
    expect(result.conflicts).toEqual([]);
  });

  it('rejects a stale client change and echoes the server copy back', async () => {
    const lastSyncedAt = '2026-07-02T00:00:00.000Z';
    // Synced before the watermark: only reachable via the forced-id echo.
    makeNote({ id: 'note-1' });
    grantOwner(USER, 'note-1');

    const result = await service.sync(USER, {
      lastSyncedAt,
      changes: [
        change({
          id: 'note-1',
          title: 'Stale client edit',
          updatedAt: '2026-07-01T11:00:00.000Z',
        }),
      ],
    });

    expect(noteUpdateMany).not.toHaveBeenCalled();
    expect(notes.get('note-1')?.title).toBe('Server title');
    expect(result.conflicts).toEqual([
      { noteId: 'note-1', resolution: 'server' },
    ]);
    // Server version comes back even though its syncedAt predates the window.
    expect(result.serverChanges.map((n) => n.id)).toContain('note-1');
  });

  it('applies a newer client change and resolves the conflict as client', async () => {
    makeNote({ id: 'note-1' });
    grantOwner(USER, 'note-1');

    const result = await service.sync(USER, {
      lastSyncedAt: '2026-07-02T00:00:00.000Z',
      changes: [
        change({
          id: 'note-1',
          title: 'Newer client edit',
          updatedAt: '2026-07-03T00:00:00.000Z',
        }),
      ],
    });

    expect(notes.get('note-1')?.title).toBe('Newer client edit');
    expect(result.conflicts).toEqual([
      { noteId: 'note-1', resolution: 'client' },
    ]);
    expect(result.processedIds).toEqual(['note-1']);
    // The write gave the note a new server updatedAt; the client only learns
    // it via the echo, else its next edit would false-conflict.
    expect(result.serverChanges.map((n) => n.id)).toContain('note-1');
  });

  it('treats an equal-timestamp change as a server win without rewriting', async () => {
    const at = new Date('2026-07-01T12:00:00.000Z');
    makeNote({ id: 'note-1', updatedAt: at });
    grantOwner(USER, 'note-1');

    const result = await service.sync(USER, {
      changes: [
        change({
          id: 'note-1',
          title: 'Same-instant edit',
          updatedAt: at.toISOString(),
        }),
      ],
    });

    expect(noteUpdateMany).not.toHaveBeenCalled();
    expect(notes.get('note-1')?.title).toBe('Server title');
    expect(result.conflicts).toEqual([
      { noteId: 'note-1', resolution: 'server' },
    ]);
  });

  it('drops foreign or unknown tag ids when creating a synced note', async () => {
    // tag.findMany returns [] — no tag in the store is ownable by USER.
    const result = await service.sync(USER, {
      changes: [
        change({ id: 'new-note', title: 'Tagged', tagIds: ['foreign-tag'] }),
      ],
    });

    expect(result.processedIds).toEqual(['new-note']);
    const [createArgs] = noteCreate.mock.calls[0];
    expect(createArgs.data.tags).toBeUndefined();
  });

  it('falls back to server when the note changes between read and write', async () => {
    const note = makeNote({ id: 'note-1' });
    grantOwner(USER, 'note-1');

    // Simulate a concurrent writer landing right after the read.
    noteFindUnique.mockImplementationOnce(({ where }) => {
      const snapshot = { ...notes.get(where.id)! };
      note.updatedAt = new Date('2026-07-03T12:00:00.000Z');
      return Promise.resolve(snapshot);
    });

    const result = await service.sync(USER, {
      changes: [
        change({
          id: 'note-1',
          title: 'Client edit',
          updatedAt: '2026-07-03T00:00:00.000Z',
        }),
      ],
    });

    expect(notes.get('note-1')?.title).toBe('Server title');
    expect(result.conflicts).toEqual([
      { noteId: 'note-1', resolution: 'server' },
    ]);
  });

  it('lets a viewer sync their pin but never their content edits', async () => {
    makeNote({ id: 'note-1', userId: OTHER });
    grantViewer(USER, 'note-1');

    const result = await service.sync(USER, {
      changes: [
        change({
          id: 'note-1',
          title: 'Viewer edit',
          isPinned: true,
          updatedAt: '2026-07-03T00:00:00.000Z',
        }),
      ],
    });

    expect(noteUpdateMany).not.toHaveBeenCalled();
    expect(notes.get('note-1')?.title).toBe('Server title');
    expect(notePinUpsert).toHaveBeenCalledTimes(1);
    expect(result.conflicts).toEqual([
      { noteId: 'note-1', resolution: 'server' },
    ]);
    expect(result.processedIds).toEqual(['note-1']);
  });

  it('ignores a change for a note the user cannot access at all', async () => {
    makeNote({ id: 'note-1', userId: OTHER });

    const result = await service.sync(USER, {
      changes: [
        change({
          id: 'note-1',
          title: 'Intruder edit',
          updatedAt: '2026-07-03T00:00:00.000Z',
        }),
      ],
    });

    expect(noteUpdateMany).not.toHaveBeenCalled();
    expect(notes.get('note-1')?.title).toBe('Server title');
    expect(result.processedIds).toEqual([]);
    expect(result.conflicts).toEqual([]);
  });

  it("does not let an editor change the owner's isArchived or state", async () => {
    makeNote({ id: 'note-1', userId: OTHER });
    grantEditor(USER, 'note-1');

    await service.sync(USER, {
      changes: [
        change({
          id: 'note-1',
          title: 'Editor edit',
          isArchived: true,
          updatedAt: '2026-07-03T00:00:00.000Z',
        }),
      ],
    });

    const note = notes.get('note-1')!;
    expect(note.title).toBe('Editor edit');
    expect(note.isArchived).toBe(false);
    expect(note.state).toBe('active');
    const [writeArgs] = noteUpdateMany.mock.calls[0];
    expect(writeArgs.data).not.toHaveProperty('isArchived');
    expect(writeArgs.data).not.toHaveProperty('state');
  });

  it('only returns notes synced after the lastSyncedAt watermark', async () => {
    makeNote({ id: 'old-note', syncedAt: new Date('2026-07-01T00:00:00Z') });
    makeNote({ id: 'fresh-note', syncedAt: new Date('2026-07-03T00:00:00Z') });

    const result = await service.sync(USER, {
      lastSyncedAt: '2026-07-02T00:00:00.000Z',
      changes: [],
    });

    expect(result.serverChanges.map((n) => n.id)).toEqual(['fresh-note']);
    expect(new Date(result.syncedAt).getTime()).not.toBeNaN();
  });

  it('reports revoked shares so clients can drop the note locally', async () => {
    noteShareFindMany.mockResolvedValueOnce([
      {
        noteId: 'shared-note',
        isDeleted: true,
        note: withIncludes(makeNote({ id: 'shared-note', userId: OTHER })),
      },
    ]);

    const result = await service.sync(USER, {
      lastSyncedAt: '2026-07-02T00:00:00.000Z',
      changes: [],
    });

    expect(result.revokedSharedNoteIds).toEqual(['shared-note']);
    expect(result.serverChanges).toEqual([]);
  });
});

describe('buildSharedSyncWhere', () => {
  const cutoff = new Date('2026-07-04T00:00:00.000Z');
  const lastSyncedAt = '2026-07-02T00:00:00.000Z';
  const window = (last?: string) => getSyncUpdatedAtWindow(last, cutoff);

  it('initial sync: active shares up to the cutoff only', () => {
    expect(buildSharedSyncWhere(undefined, cutoff, window(), [])).toEqual({
      isDeleted: false,
      updatedAt: { lte: cutoff },
      note: { syncedAt: { lte: cutoff } },
    });
  });

  it('initial sync with forced ids: ORs in the forced active shares', () => {
    expect(buildSharedSyncWhere(undefined, cutoff, window(), ['n1'])).toEqual({
      OR: [
        {
          isDeleted: false,
          updatedAt: { lte: cutoff },
          note: { syncedAt: { lte: cutoff } },
        },
        { isDeleted: false, noteId: { in: ['n1'] } },
      ],
    });
  });

  it('incremental sync: share row by updatedAt (revocations included), note by syncedAt watermark', () => {
    const w = window(lastSyncedAt);
    expect(buildSharedSyncWhere(lastSyncedAt, cutoff, w, ['n1'])).toEqual({
      OR: [
        // No isDeleted filter here — revoked shares must come through.
        { updatedAt: w },
        { isDeleted: false, note: { syncedAt: w } },
        { isDeleted: false, noteId: { in: ['n1'] } },
      ],
    });
  });
});
