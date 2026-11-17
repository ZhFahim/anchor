import { describe, expect, it } from 'vitest';
import { deviceTime } from './device-time.util';

describe('deviceTime', () => {
  const now = Date.parse('2026-08-01T12:00:00.000Z');

  it('keeps a time in the past', () => {
    expect(deviceTime('2026-07-30T08:15:00.000Z', now)).toEqual(
      new Date('2026-07-30T08:15:00.000Z'),
    );
  });

  it('brings a time ahead of the server back to now', () => {
    expect(deviceTime('2026-08-02T00:00:00.000Z', now)).toEqual(new Date(now));
  });

  it('uses now when the device sent none', () => {
    expect(deviceTime(undefined, now)).toEqual(new Date(now));
  });
});
