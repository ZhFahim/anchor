import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NoteState, SyncEntityType, SyncOp } from 'src/generated/prisma/enums';
import { SyncHydratorService, SyncFeedRow } from './sync-hydrator.service';
import {
  SNAPSHOT_PHASES,
  SnapshotPhase,
  SyncCursor,
  decodeCursor,
  encodeCursor,
} from './sync-cursor.util';
import type { SyncFeedPage } from './dto/sync-response.dto';

@Injectable()
export class SyncFeedService {
  constructor(
    private prisma: PrismaService,
    private hydrator: SyncHydratorService,
  ) {}

  async pull(
    userId: string,
    rawCursor: string | undefined,
    limit: number,
  ): Promise<SyncFeedPage> {
    const state = await this.prisma.syncState.findUnique({
      where: { userId },
    });
    const lastSeq = state?.lastSeq ?? 0n;
    const prunedThroughSeq = state?.prunedThroughSeq ?? 0n;

    const cursor: SyncCursor = rawCursor
      ? decodeCursor(rawCursor)
      : {
          mode: 'snapshot',
          phase: 'tags',
          afterId: null,
          capturedSeq: lastSeq,
        };

    // Below the prune horizon the cursor missed deleted remove-rows; above
    // lastSeq it points at a feed that no longer exists. Neither can be
    // patched forward.
    const seqRef = cursor.mode === 'delta' ? cursor.seq : cursor.capturedSeq;
    if (seqRef < prunedThroughSeq || seqRef > lastSeq) {
      return {
        entries: [],
        nextCursor: null,
        hasMore: false,
        resetRequired: true,
      };
    }

    if (cursor.mode === 'delta') {
      return this.pullDelta(userId, cursor.seq, limit);
    }
    return this.pullSnapshot(userId, cursor, limit);
  }

  private async pullDelta(
    userId: string,
    afterSeq: bigint,
    limit: number,
  ): Promise<SyncFeedPage> {
    const rows = await this.prisma.changeLog.findMany({
      where: { recipientUserId: userId, seq: { gt: afterSeq } },
      orderBy: { seq: 'asc' },
      take: limit + 1,
    });
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);
    const entries = await this.hydrator.hydrate(userId, page);
    const nextSeq = page.length > 0 ? page[page.length - 1].seq : afterSeq;
    return {
      entries,
      nextCursor: encodeCursor({ mode: 'delta', seq: nextSeq }),
      hasMore,
    };
  }

  // Phases run in fixed order, filling up to `limit` entries per request. The
  // last one hands out a delta cursor at capturedSeq, so writes that landed
  // mid-snapshot re-arrive as deltas. hasMore stays true until that delta
  // pull drains.
  private async pullSnapshot(
    userId: string,
    cursor: Extract<SyncCursor, { mode: 'snapshot' }>,
    limit: number,
  ): Promise<SyncFeedPage> {
    const rows: SyncFeedRow[] = [];
    let next: SyncCursor = cursor;

    while (next.mode === 'snapshot' && rows.length < limit) {
      const phase = next.phase;
      const room = limit - rows.length;
      const ids = await this.fetchPhaseIds(
        userId,
        phase,
        next.afterId,
        room + 1,
      );
      const page = ids.slice(0, room);
      rows.push(
        ...page.map((entityId) => ({
          seq: 0n,
          entityType: phaseEntityType(phase),
          entityId,
          op: SyncOp.upsert,
        })),
      );

      if (ids.length > room) {
        next = { ...next, afterId: page[page.length - 1] };
      } else {
        next = advancePhase(next);
      }
    }

    const entries = await this.hydrator.hydrate(userId, rows);
    return { entries, nextCursor: encodeCursor(next), hasMore: true };
  }

  private async fetchPhaseIds(
    userId: string,
    phase: SnapshotPhase,
    afterId: string | null,
    take: number,
  ): Promise<string[]> {
    const keyset = afterId ? { gt: afterId } : undefined;

    switch (phase) {
      case 'tags': {
        const tags = await this.prisma.tag.findMany({
          where: {
            userId,
            isDeleted: false,
            ...(keyset ? { id: keyset } : {}),
          },
          orderBy: { id: 'asc' },
          take,
          select: { id: true },
        });
        return tags.map((tag) => tag.id);
      }
      case 'notes': {
        const notes = await this.prisma.note.findMany({
          where: {
            ...accessibleNotesWhere(userId),
            ...(keyset ? { id: keyset } : {}),
          },
          orderBy: { id: 'asc' },
          take,
          select: { id: true },
        });
        return notes.map((note) => note.id);
      }
      case 'attachments': {
        const notes = await this.prisma.note.findMany({
          where: {
            ...accessibleNotesWhere(userId),
            // OR is taken by accessibleNotesWhere.
            AND: [
              {
                OR: [{ attachments: { some: {} } }, { files: { some: {} } }],
              },
            ],
            ...(keyset ? { id: keyset } : {}),
          },
          orderBy: { id: 'asc' },
          take,
          select: { id: true },
        });
        return notes.map((note) => note.id);
      }
      case 'pins': {
        const pins = await this.prisma.notePin.findMany({
          where: {
            userId,
            note: { state: { not: NoteState.deleted } },
            ...(keyset ? { noteId: keyset } : {}),
          },
          orderBy: { noteId: 'asc' },
          take,
          select: { noteId: true },
        });
        return pins.map((pin) => pin.noteId);
      }
    }
  }
}

const accessibleNotesWhere = (userId: string) => ({
  state: { not: NoteState.deleted },
  OR: [
    { userId },
    { sharedWith: { some: { sharedWithUserId: userId, isDeleted: false } } },
  ],
});

const phaseEntityType = (phase: SnapshotPhase): SyncEntityType => {
  switch (phase) {
    case 'tags':
      return SyncEntityType.tag;
    case 'notes':
      return SyncEntityType.note;
    case 'attachments':
      return SyncEntityType.attachments;
    case 'pins':
      return SyncEntityType.pin;
  }
};

const advancePhase = (
  cursor: Extract<SyncCursor, { mode: 'snapshot' }>,
): SyncCursor => {
  const index = SNAPSHOT_PHASES.indexOf(cursor.phase);
  const nextPhase = SNAPSHOT_PHASES[index + 1];
  if (!nextPhase) {
    return { mode: 'delta', seq: cursor.capturedSeq };
  }
  return { ...cursor, phase: nextPhase, afterId: null };
};
