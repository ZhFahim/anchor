import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { HeartbeatService } from './heartbeat.service';
import type { HealthService } from './health.service';

const URL = 'http://kuma.local:3001/api/push/abc?status=up&msg=OK&ping=';

function heartbeat(
  heartbeatUrl: string | undefined,
  databaseUp = true,
): HeartbeatService {
  const health = {
    isDatabaseUp: vi.fn().mockResolvedValue(databaseUp),
  } as unknown as HealthService;
  return new HeartbeatService({ heartbeatUrl, heartbeatInterval: 60 }, health);
}

describe('HeartbeatService', () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    fetchMock.mockReset().mockResolvedValue(new Response('ok'));
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it('calls the URL right away and then every interval', async () => {
    vi.useFakeTimers();
    const service = heartbeat(URL);
    service.onApplicationBootstrap();
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe(URL);

    await vi.advanceTimersByTimeAsync(60_000);
    expect(fetchMock).toHaveBeenCalledTimes(2);

    service.onApplicationShutdown();
    await vi.advanceTimersByTimeAsync(120_000);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('does nothing without a URL', async () => {
    vi.useFakeTimers();
    heartbeat(undefined).onApplicationBootstrap();
    await vi.advanceTimersByTimeAsync(120_000);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('skips the beat while the database is down', async () => {
    await heartbeat(URL, false).beat();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('survives a monitor that is unreachable', async () => {
    fetchMock.mockRejectedValue(new Error('ECONNREFUSED'));
    await expect(heartbeat(URL).beat()).resolves.toBeUndefined();
  });
});
