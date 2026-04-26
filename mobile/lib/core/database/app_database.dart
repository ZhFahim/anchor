import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../features/notes/data/local/notes_table.dart';
import '../../features/notes/data/local/attachments_table.dart';
import '../../features/tags/data/local/tags_table.dart';
import '../providers/active_user_id_provider.dart';
import '../sync/sync_outbox_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, Tags, NoteTags, NoteAttachments, SyncOutbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String userId) : super(_openConnection(userId));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 4) {
        await m.createTable(tags);
        await m.createTable(noteTags);
      }
      if (from < 5) {
        await m.renameColumn(notes, 'color', notes.background);
      }
      if (from < 6) {
        // Add sharing columns
        await m.addColumn(notes, notes.permission);
        await m.addColumn(notes, notes.shareIds);
        await m.addColumn(notes, notes.sharedById);
        await m.addColumn(notes, notes.sharedByName);
        await m.addColumn(notes, notes.sharedByEmail);
        await m.addColumn(notes, notes.sharedByProfileImage);
      }
      if (from < 7) {
        await m.createTable(noteAttachments);
      }
      if (from < 8) {
        await m.createTable(syncOutbox);
        await m.addColumn(notes, notes.syncVersion);
        await m.addColumn(tags, tags.syncVersion);
        await m.addColumn(noteAttachments, noteAttachments.syncVersion);
        await _backfillOutboxFromDirtyRows();
      }
    },
  );

  // Carry pre-upgrade dirty rows into the new outbox so unsynced offline
  // edits aren't stranded after the protocol switch.
  Future<void> _backfillOutboxFromDirtyRows() async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    final dirtyNotes = await (select(
      notes,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
    for (final note in dirtyNotes) {
      final tagRows = await (select(
        noteTags,
      )..where((tbl) => tbl.noteId.equals(note.id))).get();
      final tagIds = tagRows.map((r) => r.tagId).toList();

      final isDelete = note.state == 'deleted';
      final payload = isDelete
          ? <String, dynamic>{}
          : {
              'title': note.title,
              'content': note.content,
              'isPinned': note.isPinned,
              'isArchived': note.isArchived,
              'background': note.background,
              'state': note.state,
              'tagIds': tagIds,
            };

      await into(syncOutbox).insert(
        SyncOutboxCompanion.insert(
          clientOpId: uuid.v4(),
          entityType: 'note',
          entityId: note.id,
          op: isDelete ? 'delete' : 'upsert',
          payloadJson: jsonEncode(payload),
          clientUpdatedAt: note.updatedAt?.millisecondsSinceEpoch ?? now,
          createdAt: now,
        ),
      );
    }

    final dirtyTags = await (select(
      tags,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
    for (final tag in dirtyTags) {
      final isDelete = tag.isDeleted;
      final payload = isDelete
          ? <String, dynamic>{}
          : {'name': tag.name, 'color': tag.color};

      await into(syncOutbox).insert(
        SyncOutboxCompanion.insert(
          clientOpId: uuid.v4(),
          entityType: 'tag',
          entityId: tag.id,
          op: isDelete ? 'delete' : 'upsert',
          payloadJson: jsonEncode(payload),
          clientUpdatedAt: tag.updatedAt?.millisecondsSinceEpoch ?? now,
          createdAt: now,
        ),
      );
    }
  }
}

LazyDatabase _openConnection(String userId) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final userDbFile = File(path.join(dbFolder.path, 'db_$userId.sqlite'));

    if (!userDbFile.existsSync()) {
      final legacyFile = File(path.join(dbFolder.path, 'db.sqlite'));
      if (legacyFile.existsSync()) {
        await legacyFile.rename(userDbFile.path);
      }
    }

    return NativeDatabase.createInBackground(userDbFile);
  });
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) {
    throw StateError('No active user - database unavailable');
  }
  final db = AppDatabase(userId);
  ref.onDispose(() => db.close());
  return db;
}
