import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/notes/data/repository/note_history_repository.dart';
import 'package:anchor/features/notes/data/repository/note_revisions_store.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late NoteRevisionsStore store;
  late NoteHistoryRepository repository;

  const author = User(id: 'user-1', email: 'me@example.com', name: 'Me');

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = MockDio();
    store = NoteRevisionsStore(db, () async => author);
    repository = NoteHistoryRepository(dio, store);
  });

  tearDown(() => db.close());

  Map<String, dynamic> revisionJson(String id) => {
    'id': id,
    'noteId': 'n1',
    'version': 1,
    'title': 'Groceries',
    'cause': 'edit',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'content': null,
    'author': null,
  };

  List<Map<String, dynamic>> stub(List<Map<String, dynamic>> pages) {
    final queries = <Map<String, dynamic>>[];
    var index = 0;
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer((invocation) async {
      queries.add(
        invocation.namedArguments[#queryParameters] as Map<String, dynamic>,
      );
      final body = pages[index++];
      return Response(
        requestOptions: RequestOptions(path: '/api/notes/n1/revisions'),
        statusCode: 200,
        data: body,
      );
    });
    return queries;
  }

  Map<String, dynamic> page(List<String> ids, {String? nextCursor}) => {
    'revisions': [for (final id in ids) revisionJson(id)],
    'nextCursor': nextCursor,
  };

  test('reads down from the newest version, a page at a time', () async {
    final queries = stub([
      page(['r3', 'r2'], nextCursor: 'r2'),
      page(['r1']),
    ]);

    await repository.fetch('n1');
    await repository.fetch('n1');

    expect(queries[0]['cursor'], isNull);
    expect(queries[1]['cursor'], 'r2');
    expect(await store.watch('n1').first, hasLength(3));
    expect((await store.position('n1')).isComplete, isTrue);
  });

  test('asks for nothing more once the whole history is here', () async {
    stub([
      page(['r1']),
    ]);

    await repository.fetch('n1');
    await repository.fetch('n1');

    verify(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).called(1);
  });

  test('a page the server can no longer serve sends the next read back to '
      'the newest version', () async {
    stub([
      page(['r3', 'r2'], nextCursor: 'r2'),
      page([]),
    ]);

    await repository.fetch('n1');
    await repository.fetch('n1');

    final position = await store.position('n1');
    expect(position.isComplete, isFalse);
    expect(position.cursor, isNull);
  });
}
