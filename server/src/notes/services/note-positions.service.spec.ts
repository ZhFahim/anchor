import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from '../../prisma/prisma.service';
import {
  asSyncEmitter,
  createMockSyncEmitter,
  MockSyncEmitter,
} from '../../../test/sync-mocks';
import { NotePositionsService } from './note-positions.service';

describe('NotePositionsService', () => {
  const prisma = {
    note: { findMany: vi.fn() },
    notePosition: { deleteMany: vi.fn() },
    $executeRaw: vi.fn(),
    $transaction: vi.fn(),
  };
  let emitter: MockSyncEmitter;
  let service: NotePositionsService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma.$transaction.mockImplementation((run: (tx: unknown) => unknown) =>
      run(prisma),
    );
    emitter = createMockSyncEmitter();
    service = new NotePositionsService(
      prisma as unknown as PrismaService,
      asSyncEmitter(emitter),
    );
  });

  const stored = (id: string, position: string | null) => ({
    id,
    positions: position ? [{ position }] : [],
  });

  it('writes only notes whose place changed, and tells only the mover', async () => {
    prisma.note.findMany.mockResolvedValue([
      stored('a', 'a0'),
      stored('b', null),
      stored('c', 'a2'),
    ]);

    const result = await service.setPositions('me', [
      { noteId: 'a', position: 'a0' },
      { noteId: 'b', position: 'a1' },
      { noteId: 'c', position: null },
    ]);

    expect(result.updated).toEqual(['b', 'c']);
    expect(prisma.$executeRaw).toHaveBeenCalledTimes(1);
    expect(prisma.notePosition.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'me', noteId: { in: ['c'] } },
    });
    const emissions = emitter.emit.mock.calls[0][1] as {
      recipientUserId: string;
      entityId: string;
    }[];
    expect(emissions.map((e) => e.entityId)).toEqual(['b', 'c']);
    expect(new Set(emissions.map((e) => e.recipientUserId))).toEqual(
      new Set(['me']),
    );
  });

  it('lets the last change for a note win', async () => {
    prisma.note.findMany.mockResolvedValue([stored('a', null)]);

    await service.setPositions('me', [
      { noteId: 'a', position: 'a0' },
      { noteId: 'a', position: 'a5' },
    ]);

    const [query] = prisma.$executeRaw.mock.calls[0] as [{ values: unknown[] }];
    const [, ids, positions] = query.values;
    expect(ids).toEqual(['a']);
    expect(positions).toEqual(['a5']);
  });

  it('does nothing when no place changed', async () => {
    prisma.note.findMany.mockResolvedValue([stored('a', 'a0')]);

    const result = await service.setPositions('me', [
      { noteId: 'a', position: 'a0' },
    ]);

    expect(result.updated).toEqual([]);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(emitter.emit).not.toHaveBeenCalled();
  });
});
