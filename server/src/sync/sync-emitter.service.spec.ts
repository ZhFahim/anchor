import type { Prisma } from 'src/generated/prisma/client';
import { SyncEntityType, SyncOp } from 'src/generated/prisma/enums';
import {
  SyncEmitterService,
  noteEmissions,
  pinEmission,
} from './sync-emitter.service';
import { CHANGELOG_UPSERT_CHUNK_SIZE } from './sync.constants';
import { asSyncEvents, createMockSyncEvents } from '../../test/sync-mocks';

interface UpsertedRow {
  recipientUserId: string;
  entityType: SyncEntityType;
  entityId: string;
  op: SyncOp;
  seq: bigint;
}

// changeLogRow binds five values per row; updatedAt comes from the database.
const VALUES_PER_ROW = 5;

/**
 * Seq block allocation and assignment, per-call dedup, sorted lock order, and
 * the removeNote cleanup. next_sync_seq itself is pinned by the e2e infra
 * suite.
 */
describe('SyncEmitterService', () => {
  let service: SyncEmitterService;
  let syncEvents: ReturnType<typeof createMockSyncEvents>;
  let seqByUser: Map<string, bigint>;
  let upserted: UpsertedRow[];

  const queryRaw = jest.fn(
    (_strings: TemplateStringsArray, uid: string, n: number) => {
      const last = (seqByUser.get(uid) ?? 0n) + BigInt(n);
      seqByUser.set(uid, last);
      return Promise.resolve([{ seq: last }]);
    },
  );

  const executeRaw = jest.fn((query: Prisma.Sql) => {
    for (let i = 0; i < query.values.length; i += VALUES_PER_ROW) {
      const [recipientUserId, entityType, entityId, op, seq] =
        query.values.slice(i, i + VALUES_PER_ROW);
      upserted.push({
        recipientUserId: recipientUserId as string,
        entityType: entityType as SyncEntityType,
        entityId: entityId as string,
        op: op as SyncOp,
        seq: BigInt(seq as string),
      });
    }
    return Promise.resolve(upserted.length);
  });

  const changeLogDeleteMany = jest.fn().mockResolvedValue({ count: 0 });

  const tx = {
    $queryRaw: queryRaw,
    $executeRaw: executeRaw,
    changeLog: { deleteMany: changeLogDeleteMany },
  } as unknown as Prisma.TransactionClient;

  beforeEach(() => {
    syncEvents = createMockSyncEvents();
    service = new SyncEmitterService(asSyncEvents(syncEvents));
    seqByUser = new Map();
    upserted = [];
    jest.clearAllMocks();
  });

  it('allocates one contiguous seq block per recipient', async () => {
    const recipients = await service.emit(tx, [
      ...noteEmissions(['user-a'], 'note-1'),
      ...noteEmissions(['user-a'], 'note-2'),
      pinEmission('user-a', 'note-1', true),
    ]);

    expect(recipients).toEqual(['user-a']);
    expect(queryRaw).toHaveBeenCalledTimes(1);
    expect(upserted.map((row) => row.seq)).toEqual([1n, 2n, 3n]);
  });

  it('writes the whole batch in one statement', async () => {
    await service.emit(tx, [
      ...noteEmissions(['user-a', 'user-b'], 'note-1'),
      ...noteEmissions(['user-a', 'user-b'], 'note-2'),
    ]);

    expect(executeRaw).toHaveBeenCalledTimes(1);
    expect(upserted).toHaveLength(4);
  });

  it('splits an oversized batch into chunked statements', async () => {
    const emissions = Array.from(
      { length: CHANGELOG_UPSERT_CHUNK_SIZE + 1 },
      (_, index) => noteEmissions(['user-a'], `note-${index}`)[0],
    );

    await service.emit(tx, emissions);

    expect(executeRaw).toHaveBeenCalledTimes(2);
    expect(upserted).toHaveLength(CHANGELOG_UPSERT_CHUNK_SIZE + 1);
  });

  it('dedupes same-entity emissions within a call, keeping the last op', async () => {
    await service.emit(tx, [
      ...noteEmissions(['user-a'], 'note-1', SyncOp.upsert),
      ...noteEmissions(['user-a'], 'note-1', SyncOp.remove),
    ]);

    expect(upserted).toHaveLength(1);
    expect(upserted[0].op).toBe(SyncOp.remove);
  });

  it('takes recipient seq blocks in sorted order for a stable lock order', async () => {
    await service.emit(tx, [
      ...noteEmissions(['user-c', 'user-a', 'user-b'], 'note-1'),
    ]);

    expect(queryRaw.mock.calls.map((call) => call[1])).toEqual([
      'user-a',
      'user-b',
      'user-c',
    ]);
  });

  it('re-stamps an existing entity row with a fresh seq on update', async () => {
    await service.emit(tx, noteEmissions(['user-a'], 'note-1'));
    await service.emit(tx, noteEmissions(['user-a'], 'note-1'));

    expect(upserted[1]).toEqual({
      recipientUserId: 'user-a',
      entityType: SyncEntityType.note,
      entityId: 'note-1',
      op: SyncOp.upsert,
      seq: 2n,
    });
  });

  it('removeNote drops the pin/reminder/attachments index rows and folds extras into one emit', async () => {
    await service.removeNote(
      tx,
      ['user-b'],
      'note-1',
      noteEmissions(['user-a'], 'note-1'),
    );

    expect(changeLogDeleteMany).toHaveBeenCalledWith({
      where: {
        recipientUserId: { in: ['user-b'] },
        entityId: 'note-1',
        entityType: {
          in: [
            SyncEntityType.pin,
            SyncEntityType.reminder,
            SyncEntityType.attachments,
          ],
        },
      },
    });
    const ops = new Map(upserted.map((row) => [row.recipientUserId, row.op]));
    expect(ops.get('user-b')).toBe(SyncOp.remove);
    expect(ops.get('user-a')).toBe(SyncOp.upsert);
    // One emit call: both recipients' blocks allocated in the same sorted pass.
    expect(queryRaw.mock.calls.map((call) => call[1])).toEqual([
      'user-a',
      'user-b',
    ]);
  });

  it('removeNote takes the seq lock before deleting index rows', async () => {
    await service.removeNote(tx, ['user-a'], 'note-1');

    expect(queryRaw.mock.invocationCallOrder[0]).toBeLessThan(
      changeLogDeleteMany.mock.invocationCallOrder[0],
    );
  });

  it('removeNotes takes the seq lock before deleting index rows', async () => {
    await service.removeNotes(tx, new Map([['note-1', ['user-a']]]));

    expect(queryRaw.mock.invocationCallOrder[0]).toBeLessThan(
      changeLogDeleteMany.mock.invocationCallOrder[0],
    );
  });

  it('emits nothing and touches no locks for an empty emission list', async () => {
    const recipients = await service.emit(tx, []);

    expect(recipients).toEqual([]);
    expect(queryRaw).not.toHaveBeenCalled();
    expect(executeRaw).not.toHaveBeenCalled();
  });

  it("schedules a poke with each recipient's last allocated seq", async () => {
    await service.emit(tx, [
      ...noteEmissions(['user-a'], 'note-1'),
      ...noteEmissions(['user-a'], 'note-2'),
      ...noteEmissions(['user-b'], 'note-1'),
    ]);

    expect(syncEvents.schedulePoke).toHaveBeenCalledWith(
      new Map([
        ['user-a', 2n],
        ['user-b', 1n],
      ]),
    );
  });

  it('schedules an empty poke map for an empty emission list', async () => {
    await service.emit(tx, []);

    expect(syncEvents.schedulePoke).toHaveBeenCalledWith(new Map());
  });
});
