import { describe, expect, it } from 'vitest';
import { trashDate } from './trash-date.util';

describe('trashDate', () => {
  const now = new Date('2026-09-29T12:00:00.000Z');

  it('is now when no date is sent, or the date is not one', () => {
    expect(trashDate(undefined, now)).toEqual(now);
    expect(trashDate('yesterday-ish', now)).toEqual(now);
  });

  it('keeps an earlier date inside the trash window', () => {
    expect(trashDate('2026-09-10T08:00:00.000Z', now)).toEqual(
      new Date('2026-09-10T08:00:00.000Z'),
    );
  });

  it('never goes past now or before the window starts', () => {
    expect(trashDate('2026-10-05T00:00:00.000Z', now)).toEqual(now);
    expect(trashDate('2026-01-01T00:00:00.000Z', now)).toEqual(
      new Date('2026-08-30T12:00:00.000Z'),
    );
  });
});
