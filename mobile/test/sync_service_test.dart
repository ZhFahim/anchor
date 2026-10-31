import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/data/repository/note_revisions_store.dart';
import 'package:anchor/features/sync/data/sync_api.dart';
import 'package:anchor/features/sync/data/sync_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockAttachmentsRepo extends Mock implements NoteAttachmentsRepository {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late MockAttachmentsRepo attachments;
  late SyncService service;
  late List<Map<String, dynamic>> requests;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = MockDio();
    attachments = MockAttachmentsRepo();
    requests = [];

    // Starts up to date.
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(cursor: const Value('cursor-0')));

    when(() => attachments.sync()).thenAnswer((_) async {});
    when(
      () => attachments.evictCache(maxCacheBytes: any(named: 'maxCacheBytes')),
    ).thenAnswer((_) async {});
    when(() => attachments.evictCache()).thenAnswer((_) async {});
    when(
      () => attachments.deleteLocalFilesForNote(any()),
    ).thenAnswer((_) async {});
    when(() => attachments.deleteFiles(any())).thenAnswer((_) async {});
    when(
      () => attachments.applyServerAttachments(any(), any()),
    ).thenAnswer((_) async => <String>[]);

    service = SyncService(
      db,
      SyncApi(dio),
      attachments,
      NoteRevisionsStore(
        db,
        () async =>
            const User(id: 'user-1', email: 'me@example.com', name: 'Me'),
      ),
    );
  });

  tearDown(() => db.close());

  Map<String, dynamic> response({
    List<Map<String, dynamic>> results = const [],
    List<Map<String, dynamic>> entries = const [],
    String? nextCursor,
    bool hasMore = false,
    bool resetRequired = false,
  }) {
    return {
      'protocol': 4,
      'results': results,
      'entries': entries,
      'nextCursor': nextCursor,
      'hasMore': hasMore,
      if (resetRequired) 'resetRequired': true,
    };
  }

  final drained = response();

  /// Replies with [replies] in order, then keeps returning a drained page.
  void stub(
    List<Map<String, dynamic>> replies, {
    Future<void> Function()? whileInFlight,
  }) {
    var index = 0;
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer((
      invocation,
    ) async {
      requests.add(invocation.namedArguments[#data] as Map<String, dynamic>);
      await whileInFlight?.call();
      final body = index < replies.length ? replies[index] : drained;
      index++;
      return Response(
        requestOptions: RequestOptions(path: syncPath),
        statusCode: 200,
        data: body,
      );
    });
  }

  List<Map<String, dynamic>> changesOf(int request) =>
      ((requests[request]['changes'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();

  Map<String, dynamic> serverNoteJson(
    String id, {
    String noteType = 'note',
    String title = 'Server title',
    String? content,
    String? background,
    int version = 2,
    String state = 'active',
    String permission = 'owner',
    bool isPinned = false,
    List<String> tagIds = const [],
    List<String> shareIds = const [],
    bool withReminder = false,
    Map<String, dynamic>? reminder,
  }) {
    return {
      'id': id,
      'title': title,
      'noteType': noteType,
      'content': content,
      'version': version,
      'isPinned': isPinned,
      'isArchived': false,
      'background': background,
      'state': state,
      'updatedAt': '2026-08-15T10:00:00.000Z',
      'createdAt': '2026-08-15T09:00:00.000Z',
      'userId': 'user-1',
      'tagIds': tagIds,
      'permission': permission,
      'shareIds': shareIds,
      if (withReminder) 'reminder': reminder,
    };
  }

  Map<String, dynamic> reminderJson({
    String remindAt = '2026-09-04T09:00',
    String recurrence = 'none',
    int version = 1,
  }) => {'remindAt': remindAt, 'recurrence': recurrence, 'version': version};

  Map<String, dynamic> serverTagJson(
    String id, {
    String name = 'Server tag',
    int version = 2,
  }) {
    return {
      'id': id,
      'name': name,
      'color': null,
      'version': version,
      'createdAt': '2026-08-15T09:00:00.000Z',
      'updatedAt': '2026-08-15T10:00:00.000Z',
    };
  }

  Map<String, dynamic> noteEntry(
    Map<String, dynamic> note, {
    String seq = '1',
  }) {
    return {
      'seq': seq,
      'entityType': 'note',
      'entityId': note['id'],
      'op': 'upsert',
      'note': note,
    };
  }

  Future<void> insertNote({
    required String id,
    String noteType = 'note',
    String title = 'Local title',
    String? content,
    bool isSynced = false,
    int? version,
    int localRev = 1,
    String state = 'active',
    bool isPinned = false,
    bool isPinSynced = true,
    String permission = 'owner',
    String? background,
    bool isArchived = false,
    bool hasSyncedCopy = false,
    String? syncedTitle,
    String? syncedContent,
    String? syncedBackground,
    String? syncedState,
  }) {
    return db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            title: title,
            noteType: Value(noteType),
            content: Value(content),
            background: Value(background),
            isArchived: Value(isArchived),
            syncedTitle: Value(
              hasSyncedCopy ? syncedTitle ?? title : syncedTitle,
            ),
            syncedContent: Value(
              hasSyncedCopy ? syncedContent ?? content : syncedContent,
            ),
            syncedBackground: Value(
              hasSyncedCopy ? syncedBackground ?? background : syncedBackground,
            ),
            syncedState: Value(
              hasSyncedCopy ? syncedState ?? state : syncedState,
            ),
            isSynced: Value(isSynced),
            version: Value(version),
            localRev: Value(localRev),
            state: Value(state),
            isPinned: Value(isPinned),
            isPinSynced: Value(isPinSynced),
            permission: Value(permission),
          ),
        );
  }

  Future<void> insertTag({
    required String id,
    String name = 'Local tag',
    bool isSynced = false,
    int? version,
    int localRev = 1,
    bool isDeleted = false,
  }) {
    return db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: id,
            name: name,
            isSynced: Value(isSynced),
            version: Value(version),
            localRev: Value(localRev),
            isDeleted: Value(isDeleted),
          ),
        );
  }

  Future<NoteRow?> note(String id) => (db.select(
    db.notes,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<TagRow?> tag(String id) =>
      (db.select(db.tags)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  test('new checklist notes send their type with the create', () async {
    await insertNote(id: 'tasks', noteType: 'checklist');
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'tasks', 'status': 'applied', 'version': 1},
        ],
      ),
    ]);
    await service.run();
    expect(changesOf(0).single['noteType'], 'checklist');
    expect((await note('tasks'))!.noteType, 'checklist');
  });

  test('downloaded checklist notes keep their type locally', () async {
    stub([
      response(
        entries: [noteEntry(serverNoteJson('web', noteType: 'checklist'))],
      ),
    ]);
    await service.run();
    expect((await note('web'))!.noteType, 'checklist');
  });

  test(
    'a refreshed type lands without overwriting unsent offline edits',
    () async {
      await insertNote(id: 'dirty', title: 'Offline edit', version: 2);
      stub([
        response(
          results: [
            {'type': 'note', 'id': 'dirty', 'status': 'failed'},
          ],
          entries: [
            noteEntry(
              serverNoteJson('dirty', title: 'Web copy', noteType: 'checklist'),
            ),
          ],
        ),
      ]);
      await service.run();
      final row = (await note('dirty'))!;
      expect(row.title, 'Offline edit');
      expect(row.noteType, 'checklist');
      expect(row.isSynced, isFalse);
    },
  );

  test(
    'pushes a locally edited note with the version it was based on',
    () async {
      await insertNote(id: 'n1', title: 'Edited', version: 4);
      stub([
        response(
          results: [
            {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
          ],
        ),
      ]);

      await service.run();

      final change = changesOf(0).single;
      expect(change['type'], 'note');
      expect(change['id'], 'n1');
      expect(change['baseVersion'], 4);
      expect(change['title'], 'Edited');

      final row = await note('n1');
      expect(row!.version, 5);
      expect(row.isSynced, isTrue);
    },
  );

  Future<void> insertRevision({
    required String id,
    String noteId = 'n1',
    String title = 'Earlier title',
    String? content = 'earlier content',
    String cause = 'edit',
    bool isSynced = false,
    DateTime? createdAt,
  }) {
    return db
        .into(db.noteRevisions)
        .insert(
          NoteRevisionsCompanion.insert(
            id: id,
            noteId: noteId,
            title: title,
            content: Value(content),
            cause: Value(cause),
            createdAt: (createdAt ?? DateTime.utc(2026, 8, 15, 8))
                .millisecondsSinceEpoch,
            isSynced: Value(isSynced),
          ),
        );
  }

  Future<NoteRevisionRow?> revision(String id) => (db.select(
    db.noteRevisions,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  test('a new note goes up before its pictures', () async {
    final calls = <String>[];
    when(() => attachments.sync()).thenAnswer((_) async => calls.add('files'));
    stub([], whileInFlight: () async => calls.add('notes'));
    await insertNote(id: 'n1', title: 'Made offline');

    await service.run();

    expect(calls, ['notes', 'files']);
  });

  test('carries the versions recorded on the device', () async {
    await insertNote(id: 'n1', title: 'Edited', version: 4);
    await insertRevision(id: 'r1');
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
        ],
      ),
    ]);

    await service.run();

    final sent = (changesOf(0).single['revisions'] as List).single;
    expect(sent, {
      'id': 'r1',
      'version': 0,
      'title': 'Earlier title',
      'content': 'earlier content',
      'cause': 'edit',
      'createdAt': '2026-08-15T08:00:00.000Z',
    });
    expect((await revision('r1'))!.isSynced, isTrue);
  });

  test(
    'a rejected push keeps its recorded versions for the next try',
    () async {
      await insertNote(id: 'n1', title: 'Edited', version: 4);
      await insertRevision(id: 'r1');
      stub([
        response(
          results: [
            {
              'type': 'note',
              'id': 'n1',
              'status': 'conflict',
              'serverCopy': serverNoteJson('n1', version: 6),
            },
          ],
        ),
      ]);

      await service.run();

      expect((changesOf(1).single['revisions'] as List).single['id'], 'r1');
      expect((await revision('r1'))!.isSynced, isFalse);
    },
  );

  test('more recorded versions than fit one push all go up', () async {
    await insertNote(id: 'n1', title: 'Edited', version: 4);
    for (var i = 0; i < 25; i++) {
      await insertRevision(
        id: 'r$i',
        createdAt: DateTime.utc(2026, 8, 15, 8).add(Duration(minutes: i)),
      );
    }
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-1',
      ),
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-2',
      ),
    ]);

    await service.run();

    expect(changesOf(0).single['revisions'], hasLength(20));
    final followUp = changesOf(1).single;
    expect(followUp['baseVersion'], 5);
    expect((followUp['revisions'] as List).map((json) => (json as Map)['id']), [
      'r20',
      'r21',
      'r22',
      'r23',
      'r24',
    ]);
    expect((await revision('r24'))!.isSynced, isTrue);
    expect((await note('n1'))!.isSynced, isTrue);
  });

  test('more text than fits one request is spread over several', () async {
    final big = 'x' * (3 * 1024 * 1024);
    for (var n = 0; n < 3; n++) {
      await insertNote(id: 'n$n', content: big, version: 4);
    }
    stub([
      response(
        results: [
          for (var n = 0; n < 2; n++)
            {'type': 'note', 'id': 'n$n', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-1',
      ),
      response(
        results: [
          {'type': 'note', 'id': 'n2', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-2',
      ),
    ]);

    await service.run();

    expect(changesOf(0).map((change) => change['id']), ['n0', 'n1']);
    expect(changesOf(1).map((change) => change['id']), ['n2']);
    for (var n = 0; n < 3; n++) {
      expect((await note('n$n'))!.isSynced, isTrue);
    }
  });

  test('a note too big on its own still goes, versions after it', () async {
    await insertNote(id: 'n1', content: 'x' * maxRequestBytes, version: 4);
    await insertRevision(id: 'r1');
    await insertRevision(id: 'r2', createdAt: DateTime.utc(2026, 8, 15, 9));
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-1',
      ),
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
        ],
        nextCursor: 'cursor-2',
      ),
    ]);

    await service.run();

    expect((changesOf(0).single['revisions'] as List).single['id'], 'r1');
    final followUp = changesOf(1).single;
    expect(followUp['id'], 'n1');
    expect((followUp['revisions'] as List).single['id'], 'r2');
    expect((await revision('r2'))!.isSynced, isTrue);
  });

  test('a clean note sends its versions marked as such, and the ack leaves '
      'the row alone', () async {
    await insertNote(id: 'n1', isSynced: true, version: 4);
    await insertRevision(id: 'r1');
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 6},
        ],
      ),
    ]);

    await service.run();

    final change = changesOf(0).single;
    expect(change['revisionsOnly'], isTrue);
    expect(change['baseVersion'], 4);
    expect((change['revisions'] as List).single['id'], 'r1');
    expect((await revision('r1'))!.isSynced, isTrue);

    final row = await note('n1');
    expect(row!.version, 4);
    expect(row.title, 'Local title');
    expect(row.isSynced, isTrue);
    expect(requests, hasLength(1));
  });

  test('a note changed elsewhere has its history read again', () async {
    await insertNote(id: 'n1', isSynced: true, version: 4);
    await db
        .into(db.noteHistoryState)
        .insert(NoteHistoryStateCompanion.insert(noteId: 'n1'));
    stub([
      response(entries: [noteEntry(serverNoteJson('n1', version: 5))]),
    ]);

    await service.run();

    final position = await NoteRevisionsStore(
      db,
      () async => null,
    ).position('n1');
    expect(position.isComplete, isFalse);
  });

  test('a note created offline goes up without a base version', () async {
    await insertNote(id: 'n1', title: 'Brand new');
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 1},
        ],
      ),
    ]);

    await service.run();

    expect(changesOf(0).single.containsKey('baseVersion'), isFalse);
    expect((await note('n1'))!.version, 1);
  });

  test('a rejected push keeps the local text and goes again on the server '
      'version', () async {
    await insertNote(id: 'n1', title: 'Mine', version: 3);
    stub([
      response(
        results: [
          {
            'type': 'note',
            'id': 'n1',
            'status': 'conflict',
            'serverCopy': serverNoteJson('n1', title: 'Theirs', version: 7),
          },
        ],
      ),
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 8},
        ],
      ),
    ]);

    await service.run();

    expect(changesOf(1).single['baseVersion'], 7);
    expect(changesOf(1).single['title'], 'Mine');

    final row = await note('n1');
    expect(row!.title, 'Mine', reason: 'the local edit must survive');
    expect(row.version, 8);
    expect(row.isSynced, isTrue);
  });

  test('a read-only conflict adopts the server copy and keeps the overwritten '
      'text as a version', () async {
    await insertNote(id: 'n1', title: 'Mine', version: 3);
    stub([
      response(
        results: [
          {
            'type': 'note',
            'id': 'n1',
            'status': 'conflict',
            'serverCopy': serverNoteJson(
              'n1',
              title: 'Theirs',
              version: 7,
              permission: 'viewer',
            ),
          },
        ],
      ),
    ]);

    await service.run();

    final row = await note('n1');
    expect(row!.title, 'Theirs');
    expect(row.version, 7);
    expect(row.isSynced, isTrue);
    expect(requests, hasLength(1));

    final kept = await (db.select(
      db.noteRevisions,
    )..where((tbl) => tbl.noteId.equals('n1'))).getSingle();
    expect(kept.title, 'Mine');
    expect(kept.cause, 'conflict');
    expect(kept.isSynced, isTrue);
  });

  group('a conflict keeps only what changed on this device', () {
    Map<String, dynamic> conflict(Map<String, dynamic> serverNote) => response(
      results: [
        {
          'type': 'note',
          'id': serverNote['id'],
          'status': 'conflict',
          'serverCopy': serverNote,
        },
      ],
    );

    Map<String, dynamic> applied(String id, int version) => response(
      results: [
        {'type': 'note', 'id': id, 'status': 'applied', 'version': version},
      ],
    );

    test('an archive made here takes the newer text from elsewhere', () async {
      await insertNote(
        id: 'n1',
        title: 'Shopping',
        content: 'milk',
        version: 3,
        isArchived: true,
        hasSyncedCopy: true,
      );
      stub([
        conflict(
          serverNoteJson(
            'n1',
            title: 'Shopping',
            content: 'milk, eggs',
            version: 7,
          ),
        ),
        applied('n1', 7),
      ]);

      await service.run();

      final resent = changesOf(1).single;
      expect(resent['baseVersion'], 7);
      expect(resent['content'], 'milk, eggs');
      expect(resent['isArchived'], isTrue);

      final row = await note('n1');
      expect(row!.content, 'milk, eggs');
      expect(row.isArchived, isTrue);
      expect(row.isSynced, isTrue);
      expect(row.updatedAt!.toUtc(), DateTime.utc(2026, 8, 15, 10));
    });

    test(
      'a title changed here stays while the text takes the server\'s',
      () async {
        await insertNote(
          id: 'n1',
          title: 'Weekly shop',
          content: 'milk',
          version: 3,
          hasSyncedCopy: true,
          syncedTitle: 'Shopping',
        );
        stub([
          conflict(
            serverNoteJson(
              'n1',
              title: 'Shopping',
              content: 'milk, eggs',
              version: 7,
            ),
          ),
          applied('n1', 8),
        ]);

        await service.run();

        final resent = changesOf(1).single;
        expect(resent['title'], 'Weekly shop');
        expect(resent['content'], 'milk, eggs');

        final row = await note('n1');
        expect(row!.title, 'Weekly shop');
        expect(row.content, 'milk, eggs');
        expect(row.syncedTitle, 'Weekly shop');
        expect(row.syncedContent, 'milk, eggs');
      },
    );

    test(
      'a color changed here stays while the text takes the server\'s',
      () async {
        await insertNote(
          id: 'n1',
          title: 'Shopping',
          content: 'milk',
          background: 'color_teal',
          version: 3,
          hasSyncedCopy: true,
          syncedBackground: 'color_red',
        );
        stub([
          conflict(
            serverNoteJson(
              'n1',
              title: 'Shopping',
              content: 'milk, eggs',
              background: 'color_red',
              version: 7,
            ),
          ),
          applied('n1', 8),
        ]);

        await service.run();

        final resent = changesOf(1).single;
        expect(resent['background'], 'color_teal');
        expect(resent['content'], 'milk, eggs');
      },
    );

    test('a note trashed elsewhere stays trashed when this device only tagged '
        'it', () async {
      await insertNote(
        id: 'n1',
        title: 'Shopping',
        content: 'milk',
        version: 3,
        hasSyncedCopy: true,
      );
      stub([
        conflict(
          serverNoteJson(
            'n1',
            title: 'Shopping',
            content: 'milk',
            state: 'trashed',
            version: 4,
          ),
        ),
        applied('n1', 4),
      ]);

      await service.run();

      expect(changesOf(1).single['state'], 'trashed');
      expect((await note('n1'))!.state, 'trashed');
    });

    test(
      'a note trashed here stays trashed and takes the server\'s text',
      () async {
        await insertNote(
          id: 'n1',
          title: 'Shopping',
          content: 'milk',
          state: 'trashed',
          version: 3,
          hasSyncedCopy: true,
          syncedState: 'active',
        );
        stub([
          conflict(
            serverNoteJson(
              'n1',
              title: 'Shopping',
              content: 'milk, eggs',
              version: 7,
            ),
          ),
          applied('n1', 8),
        ]);

        await service.run();

        final resent = changesOf(1).single;
        expect(resent['state'], 'trashed');
        expect(resent['content'], 'milk, eggs');
      },
    );

    test('an accepted push becomes the synced copy', () async {
      await insertNote(
        id: 'n1',
        title: 'Shopping',
        content: 'milk',
        version: 3,
      );
      stub([applied('n1', 4)]);

      await service.run();

      final row = await note('n1');
      expect(row!.syncedTitle, 'Shopping');
      expect(row.syncedContent, 'milk');
      expect(row.syncedState, 'active');
    });

    test('a note from the feed becomes the synced copy', () async {
      stub([
        response(
          entries: [
            noteEntry(
              serverNoteJson(
                'n1',
                title: 'Shopping',
                content: 'milk',
                background: 'color_teal',
              ),
            ),
          ],
          nextCursor: 'cursor-1',
        ),
      ]);

      await service.run();

      final row = await note('n1');
      expect(row!.syncedTitle, 'Shopping');
      expect(row.syncedContent, 'milk');
      expect(row.syncedBackground, 'color_teal');
      expect(row.syncedState, 'active');
    });

    test(
      'a viewer whose text never changed here keeps no conflict version',
      () async {
        await insertNote(
          id: 'n1',
          title: 'Trip plan',
          content: 'book hotel',
          version: 3,
          permission: 'viewer',
          hasSyncedCopy: true,
        );
        stub([
          conflict(
            serverNoteJson(
              'n1',
              title: 'Trip plan',
              content: 'book hotel, rent car',
              version: 7,
              permission: 'viewer',
            ),
          ),
        ]);

        await service.run();

        expect((await note('n1'))!.content, 'book hotel, rent car');
        expect(await db.select(db.noteRevisions).get(), isEmpty);
      },
    );
  });

  test('a denied push drops the note instead of recreating it', () async {
    await insertNote(id: 'n1', version: 3);
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'denied'},
        ],
      ),
    ]);

    await service.run();

    expect(await note('n1'), isNull);
    verify(() => attachments.deleteLocalFilesForNote('n1')).called(1);
  });

  test(
    "a shared note's push sends its state only when it is removed",
    () async {
      await insertNote(id: 'mine', version: 1, state: 'trashed');
      await insertNote(
        id: 'theirs',
        version: 1,
        state: 'trashed',
        permission: 'editor',
      );
      await insertNote(
        id: 'removed',
        version: 1,
        state: 'deleted',
        permission: 'viewer',
      );
      stub([response()]);

      await service.run();

      final states = {
        for (final change in changesOf(0)) change['id']: change['state'],
      };
      expect(states, {'mine': 'trashed', 'theirs': null, 'removed': 'deleted'});
      expect(
        changesOf(
          0,
        ).firstWhere((c) => c['id'] == 'theirs').containsKey('state'),
        isFalse,
      );
    },
  );

  test('a transient failure leaves the note queued', () async {
    await insertNote(id: 'n1', version: 3);
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'failed'},
        ],
      ),
    ]);

    await service.run();

    final row = await note('n1');
    expect(row!.isSynced, isFalse);
    expect(row.version, 3, reason: 'nothing was applied server-side');
  });

  test('an edit made while the push is in flight stays queued', () async {
    await insertNote(id: 'n1', title: 'Uploaded', version: 4);
    stub(
      [
        response(
          results: [
            {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 5},
          ],
        ),
      ],
      whileInFlight: () async {
        await (db.update(db.notes)..where((tbl) => tbl.id.equals('n1'))).write(
          NotesCompanion(
            title: const Value('Kept typing'),
            localRev: const Value(2),
            isSynced: const Value(false),
          ),
        );
      },
    );

    await service.run();

    final row = await note('n1');
    expect(row!.title, 'Kept typing');
    expect(row.version, 5, reason: 'the next push must build on the new base');
    expect(row.isSynced, isFalse);
  });

  test('a tombstone the server acked is removed locally', () async {
    await insertNote(id: 'n1', state: 'deleted', version: 3);
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'applied', 'version': 4},
        ],
      ),
    ]);

    await service.run();

    expect(await note('n1'), isNull);
  });

  test('feed entries create notes and skip locally edited ones', () async {
    await insertNote(id: 'dirty', title: 'Mine', version: 3);
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'dirty', 'status': 'failed'},
        ],
        entries: [
          noteEntry(serverNoteJson('fresh', title: 'From server')),
          noteEntry(serverNoteJson('dirty', title: 'Theirs', version: 9)),
        ],
        nextCursor: 'cursor-1',
      ),
    ]);

    await service.run();

    final fresh = await note('fresh');
    expect(fresh!.title, 'From server');
    expect(fresh.isSynced, isTrue);
    expect(fresh.version, 2);

    final dirty = await note('dirty');
    expect(dirty!.title, 'Mine');
    expect(dirty.version, 3);
  });

  test('a locally edited note still takes who it is shared with', () async {
    await insertNote(id: 'n1', title: 'Mine', version: 3);
    stub([
      response(
        results: [
          {'type': 'note', 'id': 'n1', 'status': 'failed'},
        ],
        entries: [
          noteEntry(
            serverNoteJson(
              'n1',
              title: 'Theirs',
              version: 9,
              shareIds: ['user-2'],
            ),
          ),
        ],
        nextCursor: 'cursor-1',
      ),
    ]);

    await service.run();

    final row = await note('n1');
    expect(row!.title, 'Mine');
    expect(row.version, 3);
    expect(row.isSynced, isFalse);
    expect(row.shareIds, '["user-2"]');
  });

  test(
    'a remove entry deletes the note and everything hanging off it',
    () async {
      await insertNote(id: 'n1', isSynced: true, version: 2);
      await db
          .into(db.noteTags)
          .insert(NoteTagsCompanion.insert(noteId: 'n1', tagId: 't1'));
      stub([
        response(
          entries: [
            {
              'seq': '4',
              'entityType': 'note',
              'entityId': 'n1',
              'op': 'remove',
            },
          ],
        ),
      ]);

      await service.run();

      expect(await note('n1'), isNull);
      final tagLinks = await (db.select(
        db.noteTags,
      )..where((tbl) => tbl.noteId.equals('n1'))).get();
      expect(tagLinks, isEmpty);
      verify(() => attachments.deleteLocalFilesForNote('n1')).called(1);
    },
  );

  test('the cursor is stored and sent on the next cycle', () async {
    stub([response(nextCursor: 'cursor-1')]);
    await service.run();
    expect(requests.single['cursor'], 'cursor-0');

    requests.clear();
    stub([response(nextCursor: 'cursor-2')]);
    await service.run();

    expect(requests.single['cursor'], 'cursor-1');
  });

  test('a snapshot drops rows the server no longer sends', () async {
    await db
        .update(db.syncState)
        .write(const SyncStateCompanion(cursor: Value(null)));
    await insertNote(id: 'kept', isSynced: true, version: 2);
    await insertNote(id: 'gone', isSynced: true, version: 2);
    await insertTag(id: 't-gone', isSynced: true, version: 2);
    stub([
      response(
        entries: [noteEntry(serverNoteJson('kept'))],
        nextCursor: 'cursor-1',
        hasMore: true,
      ),
      response(nextCursor: 'cursor-2'),
    ]);

    await service.run();

    expect(await note('kept'), isNotNull);
    expect(await note('gone'), isNull);
    expect(await tag('t-gone'), isNull);
  });

  test(
    'a snapshot drops attachment metadata the server no longer lists',
    () async {
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(cursor: Value(null)));
      await insertNote(id: 'n1', isSynced: true, version: 2);
      await db
          .into(db.noteAttachments)
          .insert(
            NoteAttachmentsCompanion.insert(
              id: 'gone',
              noteId: 'n1',
              type: 'image',
              originalFilename: 'gone.png',
              mimeType: 'image/png',
              fileSize: 10,
            ),
          );
      await db
          .into(db.noteAttachments)
          .insert(
            NoteAttachmentsCompanion.insert(
              id: 'queued',
              noteId: 'n1',
              type: 'image',
              originalFilename: 'queued.png',
              mimeType: 'image/png',
              fileSize: 10,
              syncStatus: const Value('pending_upload'),
            ),
          );
      stub([
        response(
          entries: [noteEntry(serverNoteJson('n1'))],
          nextCursor: 'cursor-1',
          hasMore: true,
        ),
        response(nextCursor: 'cursor-2'),
      ]);

      await service.run();

      final rows = await (db.select(
        db.noteAttachments,
      )..where((tbl) => tbl.noteId.equals('n1'))).get();
      expect(rows.map((row) => row.id), ['queued']);
    },
  );

  test('an expired cursor restarts from a snapshot', () async {
    stub([response(resetRequired: true), response(nextCursor: 'cursor-1')]);

    await service.run();

    expect(requests[0]['cursor'], 'cursor-0');
    expect(requests[1]['cursor'], isNull);
    final state = await db.select(db.syncState).getSingle();
    expect(state.cursor, 'cursor-1');
  });

  test('pins travel as their own change and leave the note alone', () async {
    await insertNote(
      id: 'n1',
      isSynced: true,
      version: 2,
      isPinned: true,
      isPinSynced: false,
    );
    stub([
      response(
        results: [
          {'type': 'pin', 'id': 'n1', 'status': 'applied'},
        ],
      ),
    ]);

    await service.run();

    final change = changesOf(0).single;
    expect(change['type'], 'pin');
    expect(change['isPinned'], isTrue);

    final row = await note('n1');
    expect(row!.isPinSynced, isTrue);
    expect(row.version, 2);
  });

  test('a tag that collides by name folds into the server copy', () async {
    await insertTag(id: 'local-tag', name: 'Work');
    await insertNote(id: 'n1', isSynced: true, version: 2);
    await db
        .into(db.noteTags)
        .insert(NoteTagsCompanion.insert(noteId: 'n1', tagId: 'local-tag'));
    stub([
      response(
        results: [
          {
            'type': 'tag',
            'id': 'local-tag',
            'status': 'conflict',
            'serverCopy': serverTagJson('server-tag', name: 'Work'),
          },
        ],
      ),
    ]);

    await service.run();

    expect(await tag('local-tag'), isNull);
    expect((await tag('server-tag'))!.name, 'Work');

    final links = await (db.select(
      db.noteTags,
    )..where((tbl) => tbl.noteId.equals('n1'))).get();
    expect(links.map((row) => row.tagId), ['server-tag']);
    expect(
      (await note('n1'))!.isSynced,
      isFalse,
      reason: 'the note now carries a different tag id',
    );
  });

  test('tags are pushed before the notes that reference them', () async {
    await insertTag(id: 't1');
    await insertNote(id: 'n1');
    stub([response()]);

    await service.run();

    expect(changesOf(0).map((change) => change['type']), ['tag', 'note']);
  });

  group('reminders', () {
    Future<void> insertNote(
      String id, {
      String? reminderAt,
      String? recurrence,
      int? reminderVersion,
      bool isReminderSynced = true,
      bool isSynced = true,
      int? version,
      int? slot,
    }) async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: id,
              title: 'Groceries',
              isSynced: Value(isSynced),
              version: Value(version),
              reminderAt: Value(reminderAt),
              reminderRecurrence: Value(recurrence),
              reminderVersion: Value(reminderVersion),
              isReminderSynced: Value(isReminderSynced),
              reminderSlot: Value(slot),
            ),
          );
    }

    Future<NoteRow> noteRow(String id) =>
        (db.select(db.notes)..where((t) => t.id.equals(id))).getSingle();

    test('pushes a dirty reminder after the note and pin changes', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        recurrence: 'daily',
        reminderVersion: 3,
        isReminderSynced: false,
        isSynced: false,
      );
      stub([drained]);

      await service.run();

      final changes = changesOf(0);
      expect(changes.map((c) => c['type']), ['note', 'reminder']);
      expect(changes.last, {
        'type': 'reminder',
        'id': 'n1',
        'remindAt': '2026-09-04T09:00',
        'recurrence': 'daily',
        'baseVersion': 3,
      });
    });

    test('sends a clear as a null remindAt', () async {
      await insertNote('n1', reminderVersion: 2, isReminderSynced: false);
      stub([drained]);

      await service.run();

      expect(changesOf(0).single['remindAt'], isNull);
    });

    test('settles the flag after a clear is applied', () async {
      await insertNote('n1', reminderVersion: 2, isReminderSynced: false);
      stub([
        response(
          results: [
            {'type': 'reminder', 'id': 'n1', 'status': 'applied'},
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.isReminderSynced, isTrue);
      expect(row.reminderVersion, isNull);
    });

    test('settles the flag and takes the version on applied', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        recurrence: 'none',
        isReminderSynced: false,
      );
      stub([
        response(
          results: [
            {'type': 'reminder', 'id': 'n1', 'status': 'applied', 'version': 5},
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.isReminderSynced, isTrue);
      expect(row.reminderVersion, 5);
    });

    test('leaves the flag dirty when the row moved on mid-flight', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        isReminderSynced: false,
      );
      stub(
        [
          response(
            results: [
              {
                'type': 'reminder',
                'id': 'n1',
                'status': 'applied',
                'version': 5,
              },
            ],
          ),
        ],
        whileInFlight: () async {
          await (db.update(db.notes)..where((t) => t.id.equals('n1'))).write(
            const NotesCompanion(reminderAt: Value('2026-09-09T07:00')),
          );
        },
      );

      await service.run();

      final row = await noteRow('n1');
      expect(row.isReminderSynced, isFalse);
      expect(row.reminderVersion, 5);
    });

    test('pushes the edit made mid-flight against the new version', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        reminderVersion: 4,
        isReminderSynced: false,
      );
      stub(
        [
          response(
            results: [
              {
                'type': 'reminder',
                'id': 'n1',
                'status': 'applied',
                'version': 5,
              },
            ],
          ),
        ],
        whileInFlight: () async {
          await (db.update(db.notes)..where((t) => t.id.equals('n1'))).write(
            const NotesCompanion(reminderAt: Value('2026-09-09T07:00')),
          );
        },
      );

      await service.run();
      await service.run();

      expect(changesOf(1).single, {
        'type': 'reminder',
        'id': 'n1',
        'remindAt': '2026-09-09T07:00',
        'recurrence': 'none',
        'baseVersion': 5,
      });
    });

    test('adopts the server copy on a conflict', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        reminderVersion: 1,
        isReminderSynced: false,
      );
      stub([
        response(
          results: [
            {
              'type': 'reminder',
              'id': 'n1',
              'status': 'conflict',
              'version': 7,
              'serverCopy': reminderJson(
                remindAt: '2026-09-05T18:30',
                recurrence: 'weekly',
                version: 7,
              ),
            },
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, '2026-09-05T18:30');
      expect(row.reminderRecurrence, 'weekly');
      expect(row.reminderVersion, 7);
      expect(row.isReminderSynced, isTrue);
      expect(row.reminderSlot, isNotNull);
    });

    test('takes a reminder set again after this device removed one', () async {
      await insertNote('n1', reminderVersion: 1, isReminderSynced: false);
      stub([
        response(
          results: [
            {'type': 'reminder', 'id': 'n1', 'status': 'applied'},
          ],
          entries: [
            {
              'seq': '7',
              'entityType': 'reminder',
              'entityId': 'n1',
              'op': 'upsert',
              'reminder': reminderJson(remindAt: '2026-09-06T08:00'),
            },
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, '2026-09-06T08:00');
      expect(row.isReminderSynced, isTrue);
      expect(row.reminderSlot, isNotNull);
    });

    test(
      'keeps the local reminder when a conflict carries no server copy',
      () async {
        await insertNote(
          'n1',
          reminderAt: '2026-09-04T09:00',
          reminderVersion: 3,
          isReminderSynced: false,
        );
        stub([
          response(
            results: [
              {'type': 'reminder', 'id': 'n1', 'status': 'conflict'},
            ],
          ),
        ]);

        await service.run();

        final row = await noteRow('n1');
        expect(row.reminderAt, '2026-09-04T09:00');
        expect(row.isReminderSynced, isFalse);
      },
    );

    test('clears the reminder when the push is denied', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        isReminderSynced: false,
        version: 2,
      );
      stub([
        response(
          results: [
            {'type': 'reminder', 'id': 'n1', 'status': 'denied'},
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, isNull);
      expect(row.isReminderSynced, isTrue);
    });

    test('keeps the reminder when the note itself never landed', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-04T09:00',
        isReminderSynced: false,
        isSynced: false,
      );
      stub([
        response(
          results: [
            {'type': 'note', 'id': 'n1', 'status': 'failed'},
            {'type': 'reminder', 'id': 'n1', 'status': 'denied'},
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, '2026-09-04T09:00');
      expect(row.isReminderSynced, isFalse);
    });

    test('applies a reminder feed entry to a clean row', () async {
      await insertNote('n1');
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'reminder',
              'entityId': 'n1',
              'op': 'upsert',
              'reminder': reminderJson(recurrence: 'monthly'),
            },
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, '2026-09-04T09:00');
      expect(row.reminderRecurrence, 'monthly');
      expect(row.reminderSlot, isNotNull);
    });

    test('a reminder entry keeps the slot the note already has', () async {
      await insertNote('n1', reminderAt: '2026-09-04T09:00', slot: 7);
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'reminder',
              'entityId': 'n1',
              'op': 'upsert',
              'reminder': reminderJson(recurrence: 'daily'),
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderSlot, 7);
    });

    test('slots stay distinct across notes in one batch', () async {
      await insertNote('n1');
      await insertNote('n2');
      stub([
        response(
          entries: [
            for (final id in ['n1', 'n2'])
              {
                'seq': id == 'n1' ? '5' : '6',
                'entityType': 'reminder',
                'entityId': id,
                'op': 'upsert',
                'reminder': reminderJson(),
              },
          ],
        ),
      ]);

      await service.run();

      final slots = [
        (await noteRow('n1')).reminderSlot,
        (await noteRow('n2')).reminderSlot,
      ];
      expect(slots, everyElement(isNotNull));
      expect(slots.toSet(), hasLength(2));
    });

    test('a remove entry clears the reminder', () async {
      await insertNote('n1', reminderAt: '2026-09-04T09:00');
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'reminder',
              'entityId': 'n1',
              'op': 'remove',
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderAt, isNull);
    });

    test('a reminder entry never overwrites an unsent local one', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-09T07:00',
        isReminderSynced: false,
      );
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'reminder',
              'entityId': 'n1',
              'op': 'upsert',
              'reminder': reminderJson(),
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderAt, '2026-09-09T07:00');
    });

    test('a note payload carries the reminder onto a clean row', () async {
      await insertNote('n1', reminderAt: '2026-09-04T09:00');
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'note',
              'entityId': 'n1',
              'op': 'upsert',
              'note': serverNoteJson('n1', withReminder: true, reminder: null),
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderAt, isNull);
    });

    test('a note payload brings a reminder down ready to schedule', () async {
      await insertNote('n1');
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'note',
              'entityId': 'n1',
              'op': 'upsert',
              'note': serverNoteJson(
                'n1',
                withReminder: true,
                reminder: reminderJson(),
              ),
            },
          ],
        ),
      ]);

      await service.run();

      final row = await noteRow('n1');
      expect(row.reminderAt, '2026-09-04T09:00');
      expect(row.reminderSlot, isNotNull);
    });

    test('a note payload never clobbers an unsent local reminder', () async {
      await insertNote(
        'n1',
        reminderAt: '2026-09-09T07:00',
        isReminderSynced: false,
      );
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'note',
              'entityId': 'n1',
              'op': 'upsert',
              'note': serverNoteJson('n1', withReminder: true, reminder: null),
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderAt, '2026-09-09T07:00');
    });

    test('a note payload without the key leaves the reminder alone', () async {
      await insertNote('n1', reminderAt: '2026-09-04T09:00');
      stub([
        response(
          entries: [
            {
              'seq': '5',
              'entityType': 'note',
              'entityId': 'n1',
              'op': 'upsert',
              'note': serverNoteJson('n1'),
            },
          ],
        ),
      ]);

      await service.run();

      expect((await noteRow('n1')).reminderAt, '2026-09-04T09:00');
    });

    test(
      'an unknown entity type is skipped and the cursor still moves',
      () async {
        await insertNote('n1');
        stub([
          response(
            entries: [
              {
                'seq': '5',
                'entityType': 'somethingNew',
                'entityId': 'n1',
                'op': 'upsert',
              },
            ],
            nextCursor: 'cursor-9',
          ),
        ]);

        await service.run();

        final state = await db.select(db.syncState).getSingle();
        expect(state.cursor, 'cursor-9');
      },
    );
  });
}
