// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  SyncOutboxDaoManager get managers => SyncOutboxDaoManager(this);
}

class SyncOutboxDaoManager {
  final _$SyncOutboxDaoMixin _db;
  SyncOutboxDaoManager(this._db);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}
