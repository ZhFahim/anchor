export const getSyncUpdatedAtWindow = (
  lastSyncedAt: string | undefined,
  cutoff: Date,
) =>
  lastSyncedAt ? { gt: new Date(lastSyncedAt), lte: cutoff } : { lte: cutoff };

// Watermark column to filter on: 'syncedAt' for notes, 'updatedAt' for tags.
export const withForcedSyncIds = (
  field: 'syncedAt' | 'updatedAt',
  window: ReturnType<typeof getSyncUpdatedAtWindow>,
  forceSyncIds: string[],
) =>
  forceSyncIds.length
    ? {
        OR: [{ [field]: window }, { id: { in: forceSyncIds } }],
      }
    : { [field]: window };
