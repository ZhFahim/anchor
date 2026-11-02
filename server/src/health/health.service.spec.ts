import { afterEach, describe, expect, it, vi } from 'vitest';
import { HealthService } from './health.service';
import type { PrismaService } from '../prisma/prisma.service';

function service(queryRaw: () => Promise<unknown>) {
  return new HealthService({
    $queryRaw: vi.fn(queryRaw),
  } as unknown as PrismaService);
}

describe('HealthService', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('finds the database up when a query answers', async () => {
    await expect(
      service(() => Promise.resolve([{ '?column?': 1 }])).isDatabaseUp(),
    ).resolves.toBe(true);
  });

  it('finds it down when the query fails', async () => {
    await expect(
      service(() => Promise.reject(new Error('ECONNREFUSED'))).isDatabaseUp(),
    ).resolves.toBe(false);
  });

  it('finds it down when the query never answers', async () => {
    vi.useFakeTimers();
    const up = service(() => new Promise(() => {})).isDatabaseUp();
    await vi.advanceTimersByTimeAsync(5000);
    await expect(up).resolves.toBe(false);
  });
});
