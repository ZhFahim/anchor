import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from '../prisma/prisma.service';
import { SyncFeedService } from './sync-feed.service';
import { SyncHydratorService, SyncFeedRow } from './sync-hydrator.service';
import { decodeCursor, encodeCursor } from './sync-cursor.util';
import { SyncEntityType, SyncOp } from 'src/generated/prisma/enums';

/**
 * Cursor lifecycle (snapshot phases -> delta), pagination arithmetic, and the
 * resetRequired edges. Hydration is pass-through here.
 */
describe('SyncFeedService', () => {
  const USER = 'user-1';

  let service: SyncFeedService;
  let syncState: { lastSeq: bigint; prunedThroughSeq: bigint } | null;
  let changeLogRows: Array<SyncFeedRow & { recipientUserId: string }>;
  let tagIds: string[];
  let noteIds: string[];
  let attachmentNoteIds: string[];
  let pinNoteIds: string[];

  const keyset = (
    ids: string[],
    where: { id?: { gt: string } },
    take: number,
  ) =>
    ids
      .filter((id) => !where.id || id > where.id.gt)
      .slice(0, take)
      .map((id) => ({ id }));

  const changeLogFindMany = vi.fn(
    ({
      where,
      take,
    }: {
      where: { recipientUserId: string; seq: { gt: bigint } };
      take: number;
    }) =>
      Promise.resolve(
        changeLogRows
          .filter(
            (row) =>
              row.recipientUserId === where.recipientUserId &&
              row.seq > where.seq.gt,
          )
          .slice(0, take),
      ),
  );

  const prisma = {
    syncState: {
      findUnique: vi.fn(() => Promise.resolve(syncState)),
    },
    changeLog: { findMany: changeLogFindMany },
    tag: {
      findMany: vi.fn(
        ({ where, take }: { where: { id?: { gt: string } }; take: number }) =>
          Promise.resolve(keyset(tagIds, where, take)),
      ),
    },
    note: {
      findMany: vi.fn(
        ({ where, take }: { where: { id?: { gt: string } }; take: number }) => {
          const ids = 'AND' in where ? attachmentNoteIds : noteIds;
          return Promise.resolve(keyset(ids, where, take));
        },
      ),
    },
    notePin: {
      findMany: vi.fn(
        ({
          where,
          take,
        }: {
          where: { noteId?: { gt: string } };
          take: number;
        }) =>
          Promise.resolve(
            pinNoteIds
              .filter((id) => !where.noteId || id > where.noteId.gt)
              .slice(0, take)
              .map((noteId) => ({ noteId })),
          ),
      ),
    },
  } as unknown as PrismaService;

  // Pass-through: entries mirror the rows the feed produced.
  const hydrator = {
    hydrate: vi.fn((_userId: string, rows: SyncFeedRow[]) =>
      Promise.resolve(
        rows.map((row) => ({
          seq: row.seq.toString(),
          entityType: row.entityType,
          entityId: row.entityId,
          op: row.op,
        })),
      ),
    ),
  } as unknown as SyncHydratorService;

  const deltaCursor = (seq: bigint) => encodeCursor({ mode: 'delta', seq });

  beforeEach(() => {
    service = new SyncFeedService(prisma, hydrator);
    syncState = { lastSeq: 0n, prunedThroughSeq: 0n };
    changeLogRows = [];
    tagIds = [];
    noteIds = [];
    attachmentNoteIds = [];
    pinNoteIds = [];
    vi.clearAllMocks();
  });

  it('starts a fresh pull as a snapshot pinned at the current lastSeq', async () => {
    syncState = { lastSeq: 42n, prunedThroughSeq: 0n };

    const page = await service.pull(USER, undefined, 10);

    // Nothing to snapshot, so the cursor lands directly on the delta feed —
    // but hasMore stays true until that delta pull drains.
    expect(page.entries).toEqual([]);
    expect(page.hasMore).toBe(true);
    expect(decodeCursor(page.nextCursor!)).toEqual({ mode: 'delta', seq: 42n });
  });

  it('snapshots from seq 0 when the user has no SyncState row yet', async () => {
    syncState = null;

    const page = await service.pull(USER, undefined, 10);

    expect(decodeCursor(page.nextCursor!)).toEqual({ mode: 'delta', seq: 0n });
  });

  it('fills a snapshot page across phase boundaries in one request', async () => {
    tagIds = ['t1', 't2'];
    noteIds = ['n1', 'n2'];
    attachmentNoteIds = ['n2'];
    pinNoteIds = ['n1'];
    syncState = { lastSeq: 9n, prunedThroughSeq: 0n };

    const page = await service.pull(USER, undefined, 10);

    expect(page.entries).toEqual([
      { seq: '0', entityType: 'tag', entityId: 't1', op: SyncOp.upsert },
      { seq: '0', entityType: 'tag', entityId: 't2', op: SyncOp.upsert },
      { seq: '0', entityType: 'note', entityId: 'n1', op: SyncOp.upsert },
      { seq: '0', entityType: 'note', entityId: 'n2', op: SyncOp.upsert },
      {
        seq: '0',
        entityType: 'attachments',
        entityId: 'n2',
        op: SyncOp.upsert,
      },
      { seq: '0', entityType: 'pin', entityId: 'n1', op: SyncOp.upsert },
    ]);
    expect(page.hasMore).toBe(true);
    expect(decodeCursor(page.nextCursor!)).toEqual({ mode: 'delta', seq: 9n });
  });

  it('paginates inside a phase with a keyset cursor', async () => {
    tagIds = ['t1', 't2', 't3'];

    const first = await service.pull(USER, undefined, 2);
    expect(first.entries.map((e) => e.entityId)).toEqual(['t1', 't2']);
    expect(decodeCursor(first.nextCursor!)).toEqual({
      mode: 'snapshot',
      phase: 'tags',
      afterId: 't2',
      capturedSeq: 0n,
    });

    const second = await service.pull(USER, first.nextCursor!, 2);
    expect(second.entries.map((e) => e.entityId)).toEqual(['t3']);
    expect(decodeCursor(second.nextCursor!)).toEqual({
      mode: 'delta',
      seq: 0n,
    });
  });

  it('pages the delta feed with limit+1 lookahead', async () => {
    syncState = { lastSeq: 3n, prunedThroughSeq: 0n };
    changeLogRows = [1n, 2n, 3n].map((seq) => ({
      recipientUserId: USER,
      seq,
      entityType: SyncEntityType.note,
      entityId: `n${seq}`,
      op: SyncOp.upsert,
    }));

    const first = await service.pull(USER, deltaCursor(0n), 2);
    expect(first.entries.map((e) => e.seq)).toEqual(['1', '2']);
    expect(first.hasMore).toBe(true);
    expect(decodeCursor(first.nextCursor!)).toEqual({ mode: 'delta', seq: 2n });

    const second = await service.pull(USER, first.nextCursor!, 2);
    expect(second.entries.map((e) => e.seq)).toEqual(['3']);
    expect(second.hasMore).toBe(false);
    expect(decodeCursor(second.nextCursor!)).toEqual({
      mode: 'delta',
      seq: 3n,
    });
  });

  it('an empty delta keeps the cursor where it was', async () => {
    syncState = { lastSeq: 5n, prunedThroughSeq: 0n };

    const page = await service.pull(USER, deltaCursor(5n), 10);

    expect(page.entries).toEqual([]);
    expect(page.hasMore).toBe(false);
    expect(decodeCursor(page.nextCursor!)).toEqual({ mode: 'delta', seq: 5n });
  });

  it('demands a reset for a cursor below the prune horizon', async () => {
    syncState = { lastSeq: 100n, prunedThroughSeq: 50n };

    const page = await service.pull(USER, deltaCursor(40n), 10);

    expect(page).toEqual({
      entries: [],
      nextCursor: null,
      hasMore: false,
      resetRequired: true,
    });
  });

  it('demands a reset for a cursor beyond lastSeq (restored backup)', async () => {
    syncState = { lastSeq: 100n, prunedThroughSeq: 0n };

    const page = await service.pull(USER, deltaCursor(200n), 10);

    expect(page.resetRequired).toBe(true);
  });

  it('demands a reset for a snapshot cursor whose capturedSeq was pruned', async () => {
    syncState = { lastSeq: 100n, prunedThroughSeq: 50n };
    const cursor = encodeCursor({
      mode: 'snapshot',
      phase: 'notes',
      afterId: null,
      capturedSeq: 10n,
    });

    const page = await service.pull(USER, cursor, 10);

    expect(page.resetRequired).toBe(true);
  });
});
