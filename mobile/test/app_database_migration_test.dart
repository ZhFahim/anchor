import 'dart:io';

import 'package:anchor/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Upgrades on a real file database: an existing install must come out with
/// the tables the current code expects.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('anchor-db');
    file = File(path.join(dir.path, 'db.sqlite'));
  });

  tearDown(() => dir.delete(recursive: true));

  Future<void> withDatabase(Future<void> Function(AppDatabase db) body) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      await body(db);
    } finally {
      await db.close();
    }
  }

  test(
    'a database from before note history gains the versions tables',
    () async {
      await withDatabase((db) async {
        await db.customStatement('DROP TABLE note_revisions');
        await db.customStatement('DROP TABLE note_history_state');
        for (final column in _reminderColumns) {
          await db.customStatement('ALTER TABLE notes DROP COLUMN $column');
        }
        await db.customStatement('PRAGMA user_version = 8');
      });

      await withDatabase((db) async {
        await db
            .into(db.noteRevisions)
            .insert(
              NoteRevisionsCompanion.insert(
                id: 'r1',
                noteId: 'n1',
                title: 'Groceries',
                createdAt: DateTime.utc(2026, 8, 18).millisecondsSinceEpoch,
              ),
            );

        await db
            .into(db.noteHistoryState)
            .insert(NoteHistoryStateCompanion.insert(noteId: 'n1'));

        expect(await db.select(db.noteRevisions).get(), hasLength(1));
        expect(await db.select(db.noteHistoryState).get(), hasLength(1));

        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'index' AND tbl_name = 'note_revisions'",
            )
            .get();
        expect(
          indexes.map((row) => row.read<String>('name')),
          contains('note_revisions_note_created'),
        );
      });
    },
  );

  test('a database from before reminders gains the reminder columns', () async {
    await withDatabase((db) async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: 'n1',
              title: 'Groceries',
              isSynced: const Value(false),
              localRev: const Value(4),
            ),
          );
      for (final column in _reminderColumns) {
        await db.customStatement('ALTER TABLE notes DROP COLUMN $column');
      }
      await db.customStatement('PRAGMA user_version = 9');
    });

    await withDatabase((db) async {
      final columns = await db.customSelect('PRAGMA table_info(notes)').get();
      final names = columns.map((row) => row.read<String>('name')).toSet();
      expect(names, containsAll(_reminderColumns));

      final note = await db.select(db.notes).getSingle();
      expect(note.reminderAt, isNull);
      expect(note.reminderRecurrence, isNull);
      expect(note.reminderSlot, isNull);
      expect(note.isReminderSynced, isTrue);
      expect(note.isSynced, isFalse);
      expect(note.localRev, 4);
    });
  });

  test(
    'a database from the first reminders release re-downloads the feed',
    () async {
      await withDatabase((db) async {
        await db
            .into(db.syncState)
            .insert(const SyncStateCompanion(cursor: Value('cursor-42')));
        await db.customStatement('PRAGMA user_version = 10');
      });

      await withDatabase((db) async {
        final state = await db.select(db.syncState).getSingle();
        expect(state.cursor, isNull);
      });
    },
  );

  test('a database from before reminders re-downloads the feed too', () async {
    await withDatabase((db) async {
      await db
          .into(db.syncState)
          .insert(const SyncStateCompanion(cursor: Value('cursor-42')));
      for (final column in _reminderColumns) {
        await db.customStatement('ALTER TABLE notes DROP COLUMN $column');
      }
      await db.customStatement('PRAGMA user_version = 9');
    });

    await withDatabase((db) async {
      final state = await db.select(db.syncState).getSingle();
      expect(state.cursor, isNull);
    });
  });
}

const _reminderColumns = [
  'reminder_at',
  'reminder_recurrence',
  'reminder_version',
  'is_reminder_synced',
  'reminder_slot',
];
