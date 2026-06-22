import { getSyncUpdatedAtWindow, withForcedSyncIds } from './sync-window.util';

describe('getSyncUpdatedAtWindow', () => {
  const cutoff = new Date('2026-06-28T12:00:00.000Z');

  it('builds a (gt, lte] window from the client cursor', () => {
    expect(getSyncUpdatedAtWindow('2026-06-01T00:00:00.000Z', cutoff)).toEqual({
      gt: new Date('2026-06-01T00:00:00.000Z'),
      lte: cutoff,
    });
  });

  it('falls back to an open (initial-sync) window when no cursor is given', () => {
    expect(getSyncUpdatedAtWindow(undefined, cutoff)).toEqual({ lte: cutoff });
  });
});

describe('withForcedSyncIds', () => {
  const window = { gt: new Date('2026-06-01T00:00:00.000Z'), lte: new Date() };

  it('filters on the given field when there are no forced ids', () => {
    expect(withForcedSyncIds('syncedAt', window, [])).toEqual({
      syncedAt: window,
    });
  });

  it('ORs the field window with the forced ids', () => {
    expect(withForcedSyncIds('syncedAt', window, ['a', 'b'])).toEqual({
      OR: [{ syncedAt: window }, { id: { in: ['a', 'b'] } }],
    });
  });

  it('keys off updatedAt when asked (tags path is unaffected)', () => {
    expect(withForcedSyncIds('updatedAt', window, [])).toEqual({
      updatedAt: window,
    });
  });
});
