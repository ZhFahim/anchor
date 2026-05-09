class SyncUploadSnapshot {
  final Map<String, DateTime?> _updatedAtById;

  SyncUploadSnapshot(Map<String, DateTime?> updatedAtById)
    : _updatedAtById = Map.unmodifiable(updatedAtById);

  bool contains(String id) => _updatedAtById.containsKey(id);

  bool isCurrent(String id, DateTime? updatedAt) {
    if (!contains(id)) return false;
    return sameSyncTimestamp(updatedAt, _updatedAtById[id]);
  }

  bool hasChanged(String id, DateTime? updatedAt) {
    if (!contains(id)) return false;
    return !isCurrent(id, updatedAt);
  }
}

bool sameSyncTimestamp(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.isAtSameMomentAs(b);
}
