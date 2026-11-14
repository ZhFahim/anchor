import { Injectable, MessageEvent, OnModuleDestroy } from '@nestjs/common';
import {
  Observable,
  Subject,
  concat,
  defer,
  interval,
  merge,
  of,
  timer,
} from 'rxjs';
import { finalize, map, takeUntil } from 'rxjs/operators';
import { PrismaService } from '../prisma/prisma.service';
import {
  MAX_SYNC_EVENT_STREAMS_PER_USER,
  SYNC_EVENTS_MAX_STREAM_AGE_MS,
  SYNC_EVENTS_PING_INTERVAL_MS,
} from './sync.constants';

interface EventStream {
  pokes: Subject<{ seq: string }>;
  closed: Subject<void>;
}

// Notify-then-pull: a poke carries only the recipient's latest seq, and the
// client reacts by pulling /api/sync. Fan-out is in-process, so it assumes the
// single-instance deployment.
@Injectable()
export class SyncEventsService implements OnModuleDestroy {
  private readonly streams = new Map<string, Set<EventStream>>();

  constructor(private prisma: PrismaService) {}

  // Pokes and pings until the max age, then a reconnect event and a clean
  // complete. Eviction and shutdown close the session through `closed`.
  stream(userId: string): Observable<MessageEvent> {
    return defer(() => {
      const stream = this.register(userId);
      const session = merge(
        stream.pokes.pipe(map((poke) => ({ type: 'sync', data: poke }))),
        interval(SYNC_EVENTS_PING_INTERVAL_MS).pipe(
          map(() => ({ type: 'ping', data: '' })),
        ),
      ).pipe(takeUntil(timer(SYNC_EVENTS_MAX_STREAM_AGE_MS)));

      return concat(session, of({ type: 'reconnect', data: '' })).pipe(
        takeUntil(stream.closed),
        finalize(() => this.unregister(userId, stream)),
      );
    });
  }

  // Delivery waits for the commit; a poke that beats it makes clients pull
  // before the change exists.
  schedulePoke(lastSeqByRecipient: Map<string, bigint>): void {
    if (lastSeqByRecipient.size === 0) {
      return;
    }
    this.prisma.afterCommit(() => {
      for (const [userId, seq] of lastSeqByRecipient) {
        this.poke(userId, seq);
      }
    });
  }

  poke(userId: string, seq: bigint): void {
    const set = this.streams.get(userId);
    if (!set) {
      return;
    }
    const data = { seq: seq.toString() };
    for (const stream of set) {
      stream.pokes.next(data);
    }
  }

  connectionCount(userId: string): number {
    return this.streams.get(userId)?.size ?? 0;
  }

  disconnect(userId: string): void {
    for (const stream of [...(this.streams.get(userId) ?? [])]) {
      stream.closed.next();
    }
  }

  onModuleDestroy(): void {
    for (const set of this.streams.values()) {
      for (const stream of [...set]) {
        stream.closed.next();
      }
    }
    this.streams.clear();
  }

  private register(userId: string): EventStream {
    let set = this.streams.get(userId);
    if (!set) {
      set = new Set();
      this.streams.set(userId, set);
    }
    // Evict the oldest connection at the cap; Set keeps insertion order.
    if (set.size >= MAX_SYNC_EVENT_STREAMS_PER_USER) {
      const [oldest] = set;
      oldest.closed.next();
    }
    const stream: EventStream = {
      pokes: new Subject(),
      closed: new Subject(),
    };
    set.add(stream);
    return stream;
  }

  private unregister(userId: string, stream: EventStream): void {
    const set = this.streams.get(userId);
    if (!set) {
      return;
    }
    set.delete(stream);
    if (set.size === 0) {
      this.streams.delete(userId);
    }
  }
}
