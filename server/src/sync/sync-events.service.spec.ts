import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MessageEvent } from '@nestjs/common';
import { SyncEventsService } from './sync-events.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  MAX_SYNC_EVENT_STREAMS_PER_USER,
  SYNC_EVENTS_MAX_STREAM_AGE_MS,
  SYNC_EVENTS_PING_INTERVAL_MS,
} from './sync.constants';

/**
 * Poke delivery gated on commit, ping/reconnect timing, the per-user
 * connection cap, and teardown.
 */
describe('SyncEventsService', () => {
  let service: SyncEventsService;
  let pendingCommits: Array<() => void>;

  const prisma = {
    afterCommit: (hook: () => void) => pendingCommits.push(hook),
  } as unknown as PrismaService;

  const flushCommits = () => {
    for (const hook of pendingCommits.splice(0)) hook();
  };

  interface Connection {
    events: MessageEvent[];
    completed: boolean;
    unsubscribe: () => void;
  }

  const connect = (userId: string): Connection => {
    const conn: Connection = {
      events: [],
      completed: false,
      unsubscribe: () => {},
    };
    const sub = service.stream(userId).subscribe({
      next: (event) => conn.events.push(event),
      complete: () => {
        conn.completed = true;
      },
    });
    conn.unsubscribe = () => sub.unsubscribe();
    return conn;
  };

  beforeEach(() => {
    vi.useFakeTimers();
    pendingCommits = [];
    service = new SyncEventsService(prisma);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('delivers a scheduled poke only once the transaction commits', () => {
    const conn = connect('user-1');

    service.schedulePoke(new Map([['user-1', 7n]]));
    expect(conn.events).toEqual([]);

    flushCommits();
    expect(conn.events).toEqual([{ type: 'sync', data: { seq: '7' } }]);
  });

  it('schedules nothing for an empty recipient map', () => {
    service.schedulePoke(new Map());
    expect(pendingCommits).toHaveLength(0);
  });

  it('pokes every open connection of the user and no one else', () => {
    const first = connect('user-1');
    const second = connect('user-1');
    const other = connect('user-2');

    service.poke('user-1', 3n);

    expect(first.events).toEqual([{ type: 'sync', data: { seq: '3' } }]);
    expect(second.events).toEqual([{ type: 'sync', data: { seq: '3' } }]);
    expect(other.events).toEqual([]);
  });

  it('sends a ping every interval', () => {
    const conn = connect('user-1');

    vi.advanceTimersByTime(SYNC_EVENTS_PING_INTERVAL_MS);
    vi.advanceTimersByTime(SYNC_EVENTS_PING_INTERVAL_MS);

    expect(conn.events).toEqual([
      { type: 'ping', data: '' },
      { type: 'ping', data: '' },
    ]);
    expect(conn.completed).toBe(false);
  });

  it('sends a reconnect event and completes at the max stream age', () => {
    const conn = connect('user-1');

    vi.advanceTimersByTime(SYNC_EVENTS_MAX_STREAM_AGE_MS);

    expect(conn.events[conn.events.length - 1]).toEqual({
      type: 'reconnect',
      data: '',
    });
    expect(conn.completed).toBe(true);
    expect(service.connectionCount('user-1')).toBe(0);
  });

  it('evicts the oldest connection once a user is at the cap', () => {
    const oldest = connect('user-1');
    const rest = Array.from(
      { length: MAX_SYNC_EVENT_STREAMS_PER_USER - 1 },
      () => connect('user-1'),
    );

    const newest = connect('user-1');

    expect(oldest.completed).toBe(true);
    expect(rest.every((conn) => !conn.completed)).toBe(true);
    expect(newest.completed).toBe(false);
    expect(service.connectionCount('user-1')).toBe(
      MAX_SYNC_EVENT_STREAMS_PER_USER,
    );

    service.poke('user-1', 5n);
    expect(oldest.events).toEqual([]);
    expect(newest.events).toEqual([{ type: 'sync', data: { seq: '5' } }]);
  });

  it('stops delivering to a connection the client closed', () => {
    const conn = connect('user-1');
    conn.unsubscribe();

    service.poke('user-1', 4n);

    expect(conn.events).toEqual([]);
    expect(service.connectionCount('user-1')).toBe(0);
  });

  it('ends every connection of a disconnected user and no one else', () => {
    const first = connect('user-1');
    const second = connect('user-1');
    const other = connect('user-2');

    service.disconnect('user-1');

    expect(first.completed).toBe(true);
    expect(second.completed).toBe(true);
    expect(other.completed).toBe(false);
    expect(service.connectionCount('user-1')).toBe(0);
  });

  it('completes every stream on module destroy', () => {
    const first = connect('user-1');
    const second = connect('user-2');

    service.onModuleDestroy();

    expect(first.completed).toBe(true);
    expect(second.completed).toBe(true);
    expect(service.connectionCount('user-1')).toBe(0);
    expect(service.connectionCount('user-2')).toBe(0);
  });
});
