import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/notes/data/local/notes_table.dart';
import '../../features/tags/data/local/tags_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, Tags, NoteTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

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
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}
