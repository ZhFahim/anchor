import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/tags/data/repository/tags_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAttachmentsRepo extends Mock implements NoteAttachmentsRepository {}

/// NotesRepository.sync against a real in-memory Drift database, with only
/// the network (Dio), secure storage, and attachments repo mocked.
void main() {
  const userId = 'user-1';

  late AppDatabase db;
  late MockDio dio;
  late MockSecureStorage storage;
  late MockAttachmentsRepo attachments;
  late NotesRepository repo;

  // Second precision, matching what Drift stores for dateTime columns.
  final localAt = DateTime.utc(2026, 7, 3, 10, 0, 0);
  final serverAt = DateTime.utc(2026, 7, 3, 12, 0, 0);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = MockDio();
    storage = MockSecureStorage();
    attachments = MockAttachmentsRepo();

    when(() => storage.read(key: any(named: 'key'))).thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      // Skip the protocol backfill migration; it has its own collaborators.
      if (key.startsWith('sync_protocol_version')) return '2';
      return null;
    });
    when(
      () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});

    when(() => attachments.sync()).thenAnswer((_) async {});
    when(
      () => attachments.fetchAttachmentsForNotes(any()),
    ).thenAnswer((_) async {});
    when(
      () => attachments.hasPendingAttachmentsForNote(any()),
    ).thenAnswer((_) async => false);
    when(
      () => attachments.deleteLocalFilesForNote(any()),
    ).thenAnswer((_) async {});
    when(
      () => attachments.deleteAllLocalForNote(any()),
    ).thenAnswer((_) async {});

    final tagsRepo = TagsRepository(db, dio, storage, userId);
    repo = NotesRepository(db, dio, storage, tagsRepo, attachments, userId);
  });

  tearDown(() => db.close());

  Future<void> insertLocalNote({
    required String id,
    String title = 'Local title',
    DateTime? updatedAt,
    bool isSynced = false,
    String state = 'active',
  }) {
    return db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            title: title,
            updatedAt: Value(updatedAt ?? localAt),
            isSynced: Value(isSynced),
            state: Value(state),
          ),
        );
  }

  Future<Note?> localNote(String id) =>
      (db.select(db.notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Map<String, dynamic> serverNoteJson(
    String id, {
    String title = 'Server title',
    DateTime? updatedAt,
    String state = 'active',
  }) {
    return {
      'id': id,
      'title': title,
      'content': null,
      'isPinned': false,
      'isArchived': false,
      'background': null,
      'state': state,
      'updatedAt': (updatedAt ?? serverAt).toIso8601String(),
      'tagIds': <String>[],
      'permission': 'owner',
    };
  }

  Map<String, dynamic> syncResponse({
    List<Map<String, dynamic>> serverChanges = const [],
    List<String> processedIds = const [],
    List<Map<String, dynamic>> conflicts = const [],
    List<String> revokedSharedNoteIds = const [],
  }) {
    return {
      'serverChanges': serverChanges,
      'revokedSharedNoteIds': revokedSharedNoteIds,
      'processedIds': processedIds,
      'conflicts': conflicts,
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  void stubSync(
    Map<String, dynamic> response, {
    Future<void> Function()? whileInFlight,
  }) {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer((
      _,
    ) async {
      await whileInFlight?.call();
      return Response(
        requestOptions: RequestOptions(path: '/api/notes/sync'),
        statusCode: 200,
        data: response,
      );
    });
  }

  Map<String, dynamic> capturedUpload() {
    final captured = verify(
      () => dio.post(any(), data: captureAny(named: 'data')),
    ).captured;
    return captured.single as Map<String, dynamic>;
  }

  test('uploads local unsynced changes and marks them synced', () async {
    await insertLocalNote(id: 'n1', title: 'Hello');
    stubSync(syncResponse(processedIds: ['n1']));

    await repo.sync();

    final upload = capturedUpload();
    final changes = upload['changes'] as List;
    expect(changes, hasLength(1));
    expect((changes.single as Map)['id'], 'n1');
    expect((changes.single as Map)['title'], 'Hello');

    final row = await localNote('n1');
    expect(row!.isSynced, isTrue);
    verify(
      () => storage.write(
        key: 'last_synced_at_$userId',
        value: any(named: 'value'),
      ),
    ).called(1);
  });

  test('applies a newer server change to a clean local note', () async {
    await insertLocalNote(id: 'n1', isSynced: true, updatedAt: localAt);
    stubSync(
      syncResponse(
        serverChanges: [serverNoteJson('n1', title: 'Server edit')],
      ),
    );

    await repo.sync();

    final row = await localNote('n1');
    expect(row!.title, 'Server edit');
    // Drift reads dateTime columns back in local time; compare instants.
    expect(row.updatedAt!.toUtc(), serverAt);
  });

  test('keeps the local note when it is newer than the server copy', () async {
    final newerLocal = serverAt.add(const Duration(hours: 1));
    await insertLocalNote(id: 'n1', isSynced: true, updatedAt: newerLocal);
    stubSync(
      syncResponse(serverChanges: [serverNoteJson('n1', title: 'Stale')]),
    );

    await repo.sync();

    final row = await localNote('n1');
    expect(row!.title, 'Local title');
    expect(row.updatedAt!.toUtc(), newerLocal);
  });

  test('removes the local row once the server acks a delete', () async {
    await insertLocalNote(id: 'n1', state: 'deleted');
    stubSync(syncResponse(processedIds: ['n1']));

    await repo.sync();

    expect(await localNote('n1'), isNull);
  });

  test('removes the local note when the server revokes a share', () async {
    await insertLocalNote(id: 'n1', isSynced: true);
    stubSync(syncResponse(revokedSharedNoteIds: ['n1']));

    await repo.sync();

    expect(await localNote('n1'), isNull);
    verify(() => attachments.deleteLocalFilesForNote('n1')).called(1);
  });

  test('a local edit made while the request is in flight survives '
      'and stays unsynced', () async {
    await insertLocalNote(id: 'n1', title: 'Uploaded');
    final midSyncEditAt = serverAt.add(const Duration(minutes: 5));

    stubSync(
      syncResponse(
        processedIds: ['n1'],
        conflicts: [
          {'noteId': 'n1', 'resolution': 'client'},
        ],
        serverChanges: [serverNoteJson('n1', title: 'Uploaded')],
      ),
      whileInFlight: () async {
        // User keeps typing while the sync request is on the wire.
        await (db.update(db.notes)..where((tbl) => tbl.id.equals('n1'))).write(
          NotesCompanion(
            title: const Value('Kept typing'),
            updatedAt: Value(midSyncEditAt),
            isSynced: const Value(false),
          ),
        );
      },
    );

    await repo.sync();

    final row = await localNote('n1');
    expect(row!.title, 'Kept typing');
    expect(row.isSynced, isFalse, reason: 'must re-upload the newer edit');
  });

  test('inserts a brand-new server note as synced, with its tags', () async {
    await db.into(db.tags).insert(TagsCompanion.insert(id: 't1', name: 'Work'));
    stubSync(
      syncResponse(
        serverChanges: [
          {...serverNoteJson('fresh', title: 'From server'), 'tagIds': ['t1']},
        ],
      ),
    );

    await repo.sync();

    final row = await localNote('fresh');
    expect(row!.title, 'From server');
    expect(row.isSynced, isTrue);
    final tagRows = await (db.select(
      db.noteTags,
    )..where((tbl) => tbl.noteId.equals('fresh'))).get();
    expect(tagRows.map((r) => r.tagId), ['t1']);
  });

  test('removes the local note when the server reports it deleted', () async {
    await insertLocalNote(id: 'n1', isSynced: true);
    stubSync(
      syncResponse(
        serverChanges: [serverNoteJson('n1', state: 'deleted')],
      ),
    );

    await repo.sync();

    expect(await localNote('n1'), isNull);
    verify(() => attachments.deleteLocalFilesForNote('n1')).called(1);
  });

  test('first-ever sync stamps the protocol version without running '
      'upgrade backfills', () async {
    await insertLocalNote(id: 'n1');
    final writes = <String, String?>{};
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((inv) async {
      // Fresh install: no version key, no lastSyncedAt.
      return null;
    });
    when(
      () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((inv) async {
      writes[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String?;
    });
    stubSync(syncResponse(processedIds: ['n1']));

    await repo.sync();

    expect(writes['sync_protocol_version_$userId'], '2');
    // The v2 attachment backfill must not run on a fresh install; only the
    // regular per-cycle metadata fetch may call this.
    verifyNever(() => attachments.fetchAttachmentsForNotes(['n1']));
  });

  test('server-won conflict with millisecond timestamps still marks the '
      'note synced', () async {
    // Drift stores dateTime at second precision; the server stamps ms. The
    // post-apply snapshot must use the stored (truncated) value or the note
    // gets stuck unsynced forever.
    final msServerAt = DateTime.utc(2026, 7, 3, 12, 0, 0, 123);
    await insertLocalNote(id: 'n1', title: 'Local edit');
    stubSync(
      syncResponse(
        processedIds: ['n1'],
        conflicts: [
          {'noteId': 'n1', 'resolution': 'server'},
        ],
        serverChanges: [
          serverNoteJson('n1', title: 'Server won', updatedAt: msServerAt),
        ],
      ),
    );

    await repo.sync();

    final row = await localNote('n1');
    expect(row!.title, 'Server won');
    expect(row.isSynced, isTrue);
  });
}
