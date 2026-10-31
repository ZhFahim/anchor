import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/notes/data/local/attachments_table.dart';
import '../../features/notes/data/local/note_history_state_table.dart';
import '../../features/notes/data/local/note_revisions_table.dart';
import '../../features/notes/data/local/notes_table.dart';
import '../../features/sync/data/local/sync_tables.dart';
import '../../features/tags/data/local/tags_table.dart';
import '../session/active_user_id_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Notes,
    Tags,
    NoteTags,
    NoteAttachments,
    NoteRevisions,
    NoteHistoryState,
    SyncState,
    SyncSweep,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(String userId) : super(_openConnection(userId));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 4) {
        await migrator.createTable(tags);
        await migrator.createTable(noteTags);
      }
      if (from < 5) {
        await migrator.renameColumn(notes, 'color', notes.background);
      }
      if (from < 6) {
        await migrator.addColumn(notes, notes.permission);
        await migrator.addColumn(notes, notes.shareIds);
        await migrator.addColumn(notes, notes.sharedById);
        await migrator.addColumn(notes, notes.sharedByName);
        await migrator.addColumn(notes, notes.sharedByEmail);
        await migrator.addColumn(notes, notes.sharedByProfileImage);
      }
      if (from < 7) {
        await migrator.createTable(noteAttachments);
      }
      if (from < 8) {
        await migrator.addColumn(notes, notes.version);
        await migrator.addColumn(notes, notes.localRev);
        await migrator.addColumn(notes, notes.isPinSynced);
        await migrator.addColumn(tags, tags.version);
        await migrator.addColumn(tags, tags.localRev);
        await migrator.createTable(syncState);
        await migrator.createTable(syncSweep);

        await (update(notes)..where(
              (tbl) => tbl.isSynced.equals(false) & tbl.isPinned.equals(true),
            ))
            .write(const NotesCompanion(isPinSynced: Value(false)));
      }
      if (from < 9) {
        await migrator.createTable(noteRevisions);
        await migrator.createTable(noteHistoryState);
        await migrator.createIndex(noteRevisionsNoteCreated);
      }
      if (from < 10) {
        await migrator.addColumn(notes, notes.reminderAt);
        await migrator.addColumn(notes, notes.reminderRecurrence);
        await migrator.addColumn(notes, notes.reminderVersion);
        await migrator.addColumn(notes, notes.isReminderSynced);
        await migrator.addColumn(notes, notes.reminderSlot);
      }
      if (from < 11) {
        await migrator.addColumn(notes, notes.syncedTitle);
        await migrator.addColumn(notes, notes.syncedContent);
        await migrator.addColumn(notes, notes.syncedBackground);
        await migrator.addColumn(notes, notes.syncedState);
        await (update(notes)..where(
              (tbl) => tbl.isSynced.equals(true) & tbl.version.isNotNull(),
            ))
            .write(
              NotesCompanion.custom(
                syncedTitle: notes.title,
                syncedContent: notes.content,
                syncedBackground: notes.background,
                syncedState: notes.state,
              ),
            );

        // The server sends each feed entry once; only a sync with no cursor
        // repeats them.
        await (update(syncState)..where((tbl) => tbl.cursor.isNotNull())).write(
          const SyncStateCompanion(cursor: Value(null)),
        );
      }
      if (from < 12) {
        await migrator.addColumn(notes, notes.noteType);
        // Re-read existing notes: earlier clients discarded their type.
        await (update(syncState)..where((tbl) => tbl.cursor.isNotNull())).write(
          const SyncStateCompanion(cursor: Value(null)),
        );
      }
    },
  );
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

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) {
    throw StateError('No active user - database unavailable');
  }
  final db = AppDatabase(userId);
  ref.onDispose(() => db.close());
  return db;
}
