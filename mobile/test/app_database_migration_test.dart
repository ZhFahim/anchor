import 'dart:io';

import 'package:anchor/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('anchor-db');
    file = File(path.join(dir.path, 'db.sqlite'));
  });

  tearDown(() => dir.delete(recursive: true));

  Future<void> dropColumns(AppDatabase db, List<String> columns) async {
    for (final column in {...columns, 'note_type'}) {
      await db.customStatement('ALTER TABLE notes DROP COLUMN $column');
    }
  }

  Future<void> withDatabase(Future<void> Function(AppDatabase db) body) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      await body(db);
    } finally {
      await db.close();
    }
  }

  test(
    'version 11 keeps notes and refreshes their newly stored type',
    () async {
      await withDatabase((db) async {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                id: 'draft',
                title: 'Offline draft',
                localRev: const Value(7),
              ),
            );
        await db
            .into(db.syncState)
            .insert(const SyncStateCompanion(cursor: Value('cursor-42')));
        await dropColumns(db, []);
        await db.customStatement('PRAGMA user_version = 11');
      });
      await withDatabase((db) async {
        final note = await db.select(db.notes).getSingle();
        expect(note.noteType, 'note');
        expect(note.title, 'Offline draft');
        expect(note.localRev, 7);
        expect(note.isSynced, isFalse);
        expect((await db.select(db.syncState).getSingle()).cursor, isNull);
      });
    },
  );

  test(
    'a database from before note history gains the versions tables',
    () async {
      await withDatabase((db) async {
        await db.customStatement('DROP TABLE note_revisions');
        await db.customStatement('DROP TABLE note_history_state');
        await dropColumns(db, [..._reminderColumns, ..._syncedCopyColumns]);
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
      await dropColumns(db, [..._reminderColumns, ..._syncedCopyColumns]);
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
        await dropColumns(db, _syncedCopyColumns);
        await db.customStatement('PRAGMA user_version = 10');
      });

      await withDatabase((db) async {
        final state = await db.select(db.syncState).getSingle();
        expect(state.cursor, isNull);
      });
    },
  );

  test(
    'a database from the first reminders release gives synced notes a synced '
    'copy',
    () async {
      await withDatabase((db) async {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                id: 'synced',
                title: 'Groceries',
                content: const Value('milk'),
                background: const Value('color_teal'),
                isSynced: const Value(true),
                version: const Value(4),
              ),
            );
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                id: 'waiting',
                title: 'Trip',
                isSynced: const Value(false),
                version: const Value(2),
              ),
            );
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                id: 'new',
                title: 'Draft',
                isSynced: const Value(true),
              ),
            );
        await dropColumns(db, _syncedCopyColumns);
        await db.customStatement('PRAGMA user_version = 10');
      });

      await withDatabase((db) async {
        Future<NoteRow> row(String id) => (db.select(
          db.notes,
        )..where((tbl) => tbl.id.equals(id))).getSingle();

        final synced = await row('synced');
        expect(synced.syncedTitle, 'Groceries');
        expect(synced.syncedContent, 'milk');
        expect(synced.syncedBackground, 'color_teal');
        expect(synced.syncedState, 'active');

        expect((await row('waiting')).syncedTitle, isNull);
        expect((await row('new')).syncedTitle, isNull);
      });
    },
  );

  test('a database from before reminders re-downloads the feed too', () async {
    await withDatabase((db) async {
      await db
          .into(db.syncState)
          .insert(const SyncStateCompanion(cursor: Value('cursor-42')));
      await dropColumns(db, [..._reminderColumns, ..._syncedCopyColumns]);
      await db.customStatement('PRAGMA user_version = 9');
    });

    await withDatabase((db) async {
      final state = await db.select(db.syncState).getSingle();
      expect(state.cursor, isNull);
    });
  });
}

const _syncedCopyColumns = [
  'synced_title',
  'synced_content',
  'synced_background',
  'synced_state',
];

const _reminderColumns = [
  'reminder_at',
  'reminder_recurrence',
  'reminder_version',
  'is_reminder_synced',
  'reminder_slot',
];
