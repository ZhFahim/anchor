import { BadRequestException } from '@nestjs/common';
import { coded } from '../common/errors/coded';
import { ErrorCode } from '../common/errors/error-code';

export const SNAPSHOT_PHASES = [
  'tags',
  'notes',
  'attachments',
  'pins',
] as const;
export type SnapshotPhase = (typeof SNAPSHOT_PHASES)[number];

export type SyncCursor =
  | { mode: 'delta'; seq: bigint }
  | {
      mode: 'snapshot';
      phase: SnapshotPhase;
      afterId: string | null;
      capturedSeq: bigint;
    };

interface DeltaCursorWire {
  v: 3;
  m: 'd';
  s: string;
}

interface SnapshotCursorWire {
  v: 3;
  m: 's';
  p: SnapshotPhase;
  a: string | null;
  c: string;
}

export function encodeCursor(cursor: SyncCursor): string {
  const wire: DeltaCursorWire | SnapshotCursorWire =
    cursor.mode === 'delta'
      ? { v: 3, m: 'd', s: cursor.seq.toString() }
      : {
          v: 3,
          m: 's',
          p: cursor.phase,
          a: cursor.afterId,
          c: cursor.capturedSeq.toString(),
        };
  return Buffer.from(JSON.stringify(wire)).toString('base64url');
}

export function decodeCursor(raw: string): SyncCursor {
  let wire: unknown;
  try {
    wire = JSON.parse(Buffer.from(raw, 'base64url').toString('utf8'));
  } catch {
    throw coded(
      new BadRequestException('Malformed sync cursor'),
      ErrorCode.SYNC_CURSOR_INVALID,
    );
  }

  if (typeof wire !== 'object' || wire === null) {
    throw coded(
      new BadRequestException('Malformed sync cursor'),
      ErrorCode.SYNC_CURSOR_INVALID,
    );
  }
  const record = wire as Record<string, unknown>;
  if (record.v !== 3) {
    throw coded(
      new BadRequestException('Malformed sync cursor'),
      ErrorCode.SYNC_CURSOR_INVALID,
    );
  }

  if (record.m === 'd') {
    return { mode: 'delta', seq: parseSeq(record.s) };
  }

  if (record.m === 's') {
    const phase = record.p;
    if (!SNAPSHOT_PHASES.includes(phase as SnapshotPhase)) {
      throw coded(
        new BadRequestException('Malformed sync cursor'),
        ErrorCode.SYNC_CURSOR_INVALID,
      );
    }
    const afterId = record.a;
    if (afterId !== null && typeof afterId !== 'string') {
      throw coded(
        new BadRequestException('Malformed sync cursor'),
        ErrorCode.SYNC_CURSOR_INVALID,
      );
    }
    return {
      mode: 'snapshot',
      phase: phase as SnapshotPhase,
      afterId,
      capturedSeq: parseSeq(record.c),
    };
  }

  throw coded(
    new BadRequestException('Malformed sync cursor'),
    ErrorCode.SYNC_CURSOR_INVALID,
  );
}

function parseSeq(value: unknown): bigint {
  if (typeof value !== 'string' || !/^\d+$/.test(value)) {
    throw coded(
      new BadRequestException('Malformed sync cursor'),
      ErrorCode.SYNC_CURSOR_INVALID,
    );
  }
  return BigInt(value);
}
