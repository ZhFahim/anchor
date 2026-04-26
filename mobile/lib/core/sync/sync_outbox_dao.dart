import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'sync_outbox_table.dart';

part 'sync_outbox_dao.g.dart';

const _uuid = Uuid();

// Exponential backoff with jitter, capped at 5 minutes.
int _computeNextAttemptAt(int attempts) {
  final seconds = 1 << (attempts.clamp(0, 8));
  final cappedSeconds = seconds.clamp(1, 300);
  final jitter = (DateTime.now().millisecondsSinceEpoch % 1000);
  return DateTime.now().millisecondsSinceEpoch + cappedSeconds * 1000 + jitter;
}

// Sentinel attempts value meaning "do not auto-retry".
const int kPoisonAttempts = -1;

@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  // Must run inside the same transaction as the entity-row write. Replaces
  // any non-inflight row for the same entity; never touches inflight rows.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String op,
    required String payloadJson,
    String? baseSyncVersion,
    DateTime? clientUpdatedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (delete(syncOutbox)..where(
          (tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId) &
              tbl.inflight.equals(false),
        ))
        .go();

    await into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        clientOpId: _uuid.v4(),
        entityType: entityType,
        entityId: entityId,
        op: op,
        payloadJson: payloadJson,
        baseSyncVersion: Value(baseSyncVersion),
        clientUpdatedAt:
            clientUpdatedAt?.millisecondsSinceEpoch ?? now,
        createdAt: now,
      ),
    );
  }

  Future<List<SyncOutboxData>> nextBatch({int limit = 100}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(syncOutbox)
          ..where((tbl) {
            return tbl.inflight.equals(false) &
                tbl.attempts.isBiggerOrEqualValue(0) &
                tbl.nextAttemptAt.isSmallerOrEqualValue(now);
          })
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])
          ..limit(limit))
        .get();
  }

  Future<bool> hasReady() async {
    final rows = await nextBatch(limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> markInflight(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(syncOutbox)..where((tbl) => tbl.id.isIn(ids))).write(
      const SyncOutboxCompanion(inflight: Value(true)),
    );
  }

  Future<void> clearInflight(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(syncOutbox)..where((tbl) => tbl.id.isIn(ids))).write(
      const SyncOutboxCompanion(inflight: Value(false)),
    );
  }

  Future<void> retire(String clientOpId) async {
    await (delete(
      syncOutbox,
    )..where((tbl) => tbl.clientOpId.equals(clientOpId))).go();
  }

  Future<void> recordFailure({
    required int id,
    required String error,
    bool poison = false,
  }) async {
    final row = await (select(
      syncOutbox,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) return;

    final newAttempts = poison ? kPoisonAttempts : row.attempts + 1;
    final nextAt = poison ? row.nextAttemptAt : _computeNextAttemptAt(newAttempts);

    await (update(syncOutbox)..where((tbl) => tbl.id.equals(id))).write(
      SyncOutboxCompanion(
        attempts: Value(newAttempts),
        lastError: Value(error),
        nextAttemptAt: Value(nextAt),
        inflight: const Value(false),
      ),
    );
  }

  // Lost-edit defense: caller skips overwriting a local row from the server
  // response when this returns true.
  Future<bool> hasOtherPending({
    required String entityType,
    required String entityId,
    required String exceptClientOpId,
  }) async {
    final rows = await (select(syncOutbox)
          ..where(
            (tbl) =>
                tbl.entityType.equals(entityType) &
                tbl.entityId.equals(entityId) &
                tbl.clientOpId.equals(exceptClientOpId).not(),
          )
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }
}
