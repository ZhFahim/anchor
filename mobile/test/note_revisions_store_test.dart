import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/notes/data/repository/note_revisions_store.dart';
import 'package:anchor/features/notes/domain/note_revision.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late NoteRevisionsStore store;

  const author = User(id: 'user-1', email: 'me@example.com', name: 'Me');
  final recentDay = DateTime.now().toUtc().subtract(const Duration(days: 7));

  DateTime at(int hour, {int minute = 0, int daysBefore = 0}) => DateTime.utc(
    recentDay.year,
    recentDay.month,
    recentDay.day - daysBefore,
    hour,
    minute,
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = NoteRevisionsStore(db, () async => author);
  });

  tearDown(() => db.close());

  NoteRevision revisionOf(
    String id, {
    DateTime? createdAt,
    String title = 'Groceries',
    String? content,
  }) => NoteRevision(
    id: id,
    noteId: 'n1',
    version: 1,
    title: title,
    cause: RevisionCause.edit,
    createdAt: createdAt ?? at(10),
    content: content,
  );

  Future<void> insertLocal(
    String id, {
    DateTime? createdAt,
    bool isSynced = false,
    String cause = 'edit',
    String noteId = 'n1',
  }) {
    return db
        .into(db.noteRevisions)
        .insert(
          NoteRevisionsCompanion.insert(
            id: id,
            noteId: noteId,
            title: 'Groceries',
            createdAt: (createdAt ?? at(10)).millisecondsSinceEpoch,
            cause: Value(cause),
            isSynced: Value(isSynced),
          ),
        );
  }

  test('a page from the server is kept, newest first', () async {
    await store.savePage(
      'n1',
      [
        revisionOf('r2', createdAt: at(11)),
        revisionOf('r1', createdAt: at(10)),
      ],
      cursor: null,
      nextCursor: null,
    );

    final kept = await store.watch('n1').first;

    expect(kept.map((revision) => revision.id), ['r2', 'r1']);
  });

  test('a complete page drops versions the server no longer has', () async {
    await insertLocal('gone', isSynced: true);
    await insertLocal('mine');

    await store.savePage(
      'n1',
      [revisionOf('r1', createdAt: at(11))],
      cursor: null,
      nextCursor: null,
    );

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), ['r1', 'mine']);
  });

  test('a partial page only drops within the stretch it covers', () async {
    await insertLocal(
      'older',
      createdAt: at(0, daysBefore: 17),
      isSynced: true,
    );
    await insertLocal('inside', createdAt: at(11, minute: 30), isSynced: true);

    await store.savePage(
      'n1',
      [
        revisionOf('r2', createdAt: at(12)),
        revisionOf('r1', createdAt: at(11)),
      ],
      cursor: null,
      nextCursor: 'older',
    );

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), ['r2', 'r1', 'older']);
  });

  test('a page hands over where the next read starts', () async {
    await store.savePage(
      'n1',
      [revisionOf('r2')],
      cursor: null,
      nextCursor: 'older',
    );

    var position = await store.position('n1');
    expect(position.cursor, 'older');
    expect(position.isComplete, isFalse);

    await store.savePage(
      'n1',
      [revisionOf('r1', createdAt: at(0, daysBefore: 1))],
      cursor: 'older',
      nextCursor: null,
    );

    position = await store.position('n1');
    expect(position.cursor, isNull);
    expect(position.isComplete, isTrue);
  });

  test('a note that changed elsewhere is read again from the top', () async {
    await store.savePage(
      'n1',
      [revisionOf('r1')],
      cursor: null,
      nextCursor: null,
    );

    await store.markStale('n1');

    final position = await store.position('n1');
    expect(position.cursor, isNull);
    expect(position.isComplete, isFalse);
    expect(await store.watch('n1').first, hasLength(1));
  });

  test('only the versions still to be sent are handed to a push', () async {
    await insertLocal('sent', isSynced: true);
    await insertLocal('waiting');

    final pending = await store.pending('n1', limit: 20);

    expect(pending.map((revision) => revision.id), ['waiting']);

    await store.markSynced(['waiting']);
    expect(await store.pending('n1', limit: 20), isEmpty);
  });

  test('versions older than the retention window are dropped', () async {
    final old = DateTime.now().toUtc().subtract(const Duration(days: 120));
    await insertLocal('old', createdAt: old, isSynced: true);
    await insertLocal(
      'old-restore',
      createdAt: old,
      isSynced: true,
      cause: 'restore',
    );
    await insertLocal('recent', isSynced: true);

    await store.prune('n1');

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), ['recent', 'old-restore']);
  });

  test('a note keeps at most two hundred versions', () async {
    await db.batch((batch) {
      batch.insertAll(db.noteRevisions, [
        for (var i = 0; i < 205; i++)
          NoteRevisionsCompanion.insert(
            id: 'r$i',
            noteId: 'n1',
            title: 'Groceries',
            createdAt: at(0).add(Duration(minutes: i)).millisecondsSinceEpoch,
            isSynced: const Value(true),
          ),
      ]);
    });

    await store.prune('n1');

    final kept = await store.watch('n1').first;
    expect(kept, hasLength(200));
    expect(kept.last.id, 'r5');
  });

  test('the cap never drops versions still to be sent', () async {
    await insertLocal('waiting-1', createdAt: at(1, daysBefore: 1));
    await insertLocal('waiting-2', createdAt: at(2, daysBefore: 1));
    await db.batch((batch) {
      batch.insertAll(db.noteRevisions, [
        for (var i = 0; i < 204; i++)
          NoteRevisionsCompanion.insert(
            id: 'r$i',
            noteId: 'n1',
            title: 'Groceries',
            createdAt: at(0).add(Duration(minutes: i)).millisecondsSinceEpoch,
            isSynced: const Value(true),
          ),
      ]);
    });

    await store.prune('n1');

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), contains('waiting-1'));
    expect(kept.map((revision) => revision.id), contains('waiting-2'));
    expect(kept, hasLength(202));
  });

  test('the cap spares a fresh conflict copy but not an aged one', () async {
    final fresh = DateTime.now().subtract(const Duration(days: 5));
    final aged = DateTime.now().subtract(const Duration(days: 120));
    await insertLocal(
      'conflict-fresh',
      createdAt: fresh.subtract(const Duration(hours: 2)),
      isSynced: true,
      cause: 'conflict',
    );
    await insertLocal(
      'conflict-aged',
      createdAt: aged,
      isSynced: true,
      cause: 'conflict',
    );
    await db.batch((batch) {
      batch.insertAll(db.noteRevisions, [
        for (var i = 0; i < 201; i++)
          NoteRevisionsCompanion.insert(
            id: 'r$i',
            noteId: 'n1',
            title: 'Groceries',
            createdAt: fresh.add(Duration(minutes: i)).millisecondsSinceEpoch,
            isSynced: const Value(true),
          ),
      ]);
    });

    await store.prune('n1');

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), contains('conflict-fresh'));
    expect(
      kept.map((revision) => revision.id),
      isNot(contains('conflict-aged')),
    );
  });

  test('versions saved within the same second keep their order', () async {
    final base = at(10);
    await store.savePage(
      'n1',
      [
        revisionOf('a', createdAt: base.add(const Duration(milliseconds: 600))),
        revisionOf('b', createdAt: base.add(const Duration(milliseconds: 200))),
      ],
      cursor: null,
      nextCursor: null,
    );

    final kept = await store.watch('n1').first;
    expect(kept.map((revision) => revision.id), ['a', 'b']);
  });

  test('lists the notes with versions still to be sent', () async {
    await insertLocal('sent', isSynced: true);
    await insertLocal('waiting-1');
    await insertLocal('waiting-2', noteId: 'n2');

    expect((await store.noteIdsWithPending()).toSet(), {'n1', 'n2'});

    await store.markSynced(['waiting-1', 'waiting-2']);
    expect(await store.noteIdsWithPending(), isEmpty);
  });

  test('a page read from where the history left off carries on', () async {
    await store.savePage(
      'n1',
      [revisionOf('r2')],
      cursor: null,
      nextCursor: 'page-2',
    );
    await store.savePage(
      'n1',
      [revisionOf('r1')],
      cursor: 'page-2',
      nextCursor: 'page-3',
    );

    expect((await store.position('n1')).cursor, 'page-3');
  });

  test('a page that lands after the history went stale is kept, but the '
      'next read still starts at the newest version', () async {
    await store.savePage(
      'n1',
      [revisionOf('r2')],
      cursor: null,
      nextCursor: 'page-2',
    );

    // A note change arrives from the feed while page 2 is still loading.
    await store.markStale('n1');
    await store.savePage(
      'n1',
      [revisionOf('r1')],
      cursor: 'page-2',
      nextCursor: 'page-3',
    );

    final position = await store.position('n1');
    expect(position.cursor, isNull);
    expect(position.isComplete, isFalse);
    expect(await store.watch('n1').first, hasLength(2));
  });
}
