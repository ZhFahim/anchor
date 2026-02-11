import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/notes/data/local/notes_table.dart';
import '../../features/tags/data/local/tags_table.dart';
import '../providers/active_user_id_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, Tags, NoteTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String userId) : super(_openConnection(userId));

  @override
  int get schemaVersion => 7;

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
        await m.addColumn(notes, notes.position);
      }
    },
  );
}

LazyDatabase _openConnection(String userId) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final userDbFile = File(path.join(dbFolder.path, 'db_$userId.sqlite'));

    // One-time migration: rename legacy db.sqlite for current user
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
