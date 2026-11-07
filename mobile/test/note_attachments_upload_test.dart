import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/domain/note_attachment.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _SlowServer implements HttpClientAdapter {
  final answer = Completer<void>();
  final received = Completer<void>();
  final requests = <String>[];
  int? refusesWith;
  bool isOffline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    await requestStream?.drain<void>();
    if (options.method != 'POST') return ResponseBody.fromString('', 200);
    if (!received.isCompleted) received.complete();
    if (isOffline) throw const SocketException('offline');
    await answer.future;
    if (refusesWith case final status?) {
      return ResponseBody.fromString('{}', status);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'server1',
        'noteId': 'n1',
        'type': 'image',
        'originalFilename': 'a.png',
        'mimeType': 'image/png',
        'fileSize': 3,
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory files;
  late AppDatabase db;
  late _SlowServer server;
  late NoteAttachmentsRepository repo;

  setUp(() async {
    files = Directory.systemTemp.createTempSync('anchor-upload');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => files.path,
        );
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = _SlowServer();
    repo = NoteAttachmentsRepository(db, Dio()..httpClientAdapter = server);
    await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', title: ''));
    final picture = File('${files.path}/a.png')..writeAsBytesSync([1, 2, 3]);
    await db
        .into(db.noteAttachments)
        .insert(
          NoteAttachmentsCompanion.insert(
            id: 'local1',
            noteId: 'n1',
            type: 'image',
            originalFilename: 'a.png',
            mimeType: 'image/png',
            fileSize: 3,
            localPath: Value(picture.path),
            syncStatus: Value(AttachmentSyncStatus.pendingUpload.dbValue),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    files.deleteSync(recursive: true);
  });

  Future<List<AttachmentRow>> rows() => db.select(db.noteAttachments).get();

  test('a picture deleted while it uploads is deleted on the server', () async {
    final syncing = repo.sync();
    await server.received.future;
    await repo.deleteAttachment('n1', 'local1');
    server.answer.complete();
    await syncing;

    expect(await repo.watchAttachments('n1').first, isEmpty);
    expect((await rows()).single.syncStatus, 'pending_delete');

    await repo.sync();
    expect(
      server.requests,
      contains('DELETE /api/notes/n1/attachments/server1'),
    );
    expect(await rows(), isEmpty);
  });

  test('a file over 50 MB is turned away before it is kept', () async {
    final big = File('${files.path}/big.m4a').openSync(mode: FileMode.write)
      ..setPositionSync(maxAttachmentBytes)
      ..writeByteSync(0)
      ..closeSync();

    await expectLater(
      repo.addAttachment('n1', big.path, 'audio/mp4', 'big.m4a'),
      throwsA(isA<AttachmentTooBigException>()),
    );
    expect((await rows()).map((row) => row.id), ['local1']);
  });

  test('a picture the server refuses waits for Try again', () async {
    server
      ..refusesWith = 413
      ..answer.complete();
    await repo.sync();

    expect(
      (await repo.watchAttachments('n1').first).single.isUploadFailed,
      isTrue,
    );
    await repo.sync();
    expect(
      server.requests.where((request) => request.startsWith('POST')),
      hasLength(1),
    );

    server.refusesWith = null;
    await repo.retryUpload('local1');
    await repo.sync();
    expect((await rows()).single.id, 'server1');
  });

  test(
    'a picture sent while the server restarts goes up on a later sync',
    () async {
      server
        ..refusesWith = 502
        ..answer.complete();
      await expectLater(repo.sync(), throwsException);
      expect(
        (await repo.watchAttachments('n1').first).single.isUploadFailed,
        isFalse,
      );

      server.refusesWith = null;
      await repo.sync();
      expect((await rows()).single.id, 'server1');
    },
  );

  test('an upload waits for a server that answers late', () async {
    final slow = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => slow.close(force: true));
    slow.listen((request) async {
      await request.drain<void>();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      request.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'id': 'server1',
            'noteId': 'n1',
            'type': 'image',
            'originalFilename': 'a.png',
            'mimeType': 'image/png',
            'fileSize': 3,
          }),
        );
      await request.response.close();
    });
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:${slow.port}',
        receiveTimeout: const Duration(milliseconds: 100),
      ),
    );

    await HttpOverrides.runWithHttpOverrides(
      () => NoteAttachmentsRepository(db, dio).sync(),
      _RealHttp(),
    );

    expect((await rows()).single.id, 'server1');
  });

  test('a picture that gets no answer goes up on a later sync', () async {
    server.isOffline = true;
    await expectLater(repo.sync(), throwsException);

    final waiting = (await repo.watchAttachments('n1').first).single;
    expect(waiting.isPendingUpload, isTrue);
    expect(waiting.isUploadFailed, isFalse);
  });

  test('a delete waiting on Undo finds its picture once uploaded', () async {
    server.answer.complete();
    await repo.sync();
    expect((await rows()).single.id, 'server1');

    await repo.deleteAttachment('n1', 'local1');

    expect(repo.currentIdOf('local1'), 'server1');
    expect(await repo.watchAttachments('n1').first, isEmpty);
    expect((await rows()).single.syncStatus, 'pending_delete');
  });
}
