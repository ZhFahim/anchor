import 'package:drift/drift.dart';

// Append-only log of pending local mutations. Written in the same transaction
// as the entity row so the user-visible change and the "owe the server" record
// commit atomically. Coalescing on enqueue replaces non-inflight rows for the
// same entity but never inflight ones — that's how the lost-edit race closes.
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get clientOpId => text().unique()();

  // 'note' | 'tag' | 'note_attachment'
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  // 'upsert' | 'delete'
  TextColumn get op => text()();

  TextColumn get payloadJson => text()();

  TextColumn get baseSyncVersion => text().nullable()();

  IntColumn get clientUpdatedAt => integer()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();

  BoolColumn get inflight => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();
}
