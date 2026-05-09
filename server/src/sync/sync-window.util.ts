export const getSyncUpdatedAtWindow = (
  lastSyncedAt: string | undefined,
  cutoff: Date,
) =>
  lastSyncedAt ? { gt: new Date(lastSyncedAt), lte: cutoff } : { lte: cutoff };

export const withForcedSyncIds = (
  updatedAtWindow: ReturnType<typeof getSyncUpdatedAtWindow>,
  forceSyncIds: string[],
) =>
  forceSyncIds.length
    ? {
      OR: [{ updatedAt: updatedAtWindow }, { id: { in: forceSyncIds } }],
    }
    : { updatedAt: updatedAtWindow };
