import 'dart:convert';
import 'dart:io';

import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/core/logging/app_logger.dart';
import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/session/active_user_id_provider.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';
import 'package:anchor/features/auth/domain/auth_failure.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/share_target/data/share_inbox.dart';
import 'package:anchor/features/share_target/domain/share_entry.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const _ada = {
  'id': 'user-1',
  'email': 'ada@example.com',
  'name': 'Ada',
  'profileImage': '/profiles/ada.jpg',
};

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.isReviewing = false}) : super(Dio());

  final bool isReviewing;
  int profileReads = 0;
  AuthFailure? deleteFailure;
  final deletePasswords = <String?>[];

  @override
  Future<void> deleteAccount(String? password) async {
    deletePasswords.add(password);
    final failure = deleteFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async => isReviewing
      ? {'user': _ada, 'message': 'Your account is pending approval.'}
      : {'access_token': 'access', 'refresh_token': 'refresh', 'user': _ada};

  @override
  Future<Map<String, dynamic>> login(String email, String password) async =>
      throw const InvalidCredentialsFailure();

  @override
  Future<Map<String, dynamic>> getProfile() async {
    profileReads++;
    return {..._ada, 'hasPassword': true};
  }

  @override
  Future<Map<String, dynamic>> removeProfileImage() async => {
    ..._ada,
    'profileImage': null,
  };
}

class _FakePhotoCache extends Fake implements BaseCacheManager {
  int emptied = 0;
  Object? failure;

  @override
  Future<void> emptyCache() async {
    emptied++;
    final failure = this.failure;
    if (failure != null) throw failure;
  }
}

class _FixedServerConfig extends ServerConfig {
  @override
  Future<String?> build() async => 'https://anchor.example.com';
}

class _NoSelfSignedCert extends AllowSelfSignedCert {
  @override
  Future<bool> build() async => false;
}

class _NoCustomHeaders extends CustomHeaders {
  @override
  Future<List<CustomHeader>> build() async => const [];
}

ProviderContainer _container(
  _FakeAuthService service, {
  AppDatabase? database,
}) {
  final container = ProviderContainer(
    overrides: [
      if (database != null) appDatabaseProvider.overrideWithValue(database),
      authServiceProvider.overrideWithValue(service),
      serverConfigProvider.overrideWith(_FixedServerConfig.new),
      allowSelfSignedCertProvider.overrideWith(_NoSelfSignedCert.new),
      customHeadersProvider.overrideWith(_NoCustomHeaders.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('signed out', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('signing up on an open server signs in', () async {
      final container = _container(_FakeAuthService());
      expect(await container.read(authControllerProvider.future), isNull);

      final isSignedIn = await container
          .read(authControllerProvider.notifier)
          .register('ada@example.com', 'long enough', 'Ada');

      expect(isSignedIn, isTrue);
      expect(container.read(authControllerProvider).value?.id, 'user-1');
      expect(container.read(activeUserIdProvider), 'user-1');
    });

    test('signing up for review stays signed out', () async {
      final container = _container(_FakeAuthService(isReviewing: true));
      await container.read(authControllerProvider.future);

      final isSignedIn = await container
          .read(authControllerProvider.notifier)
          .register('ada@example.com', 'long enough', 'Ada');

      expect(isSignedIn, isFalse);
      expect(container.read(authControllerProvider).value, isNull);
      expect(container.read(activeUserIdProvider), isNull);
    });

    test('a wrong password leaves the app’s sign-in state alone', () async {
      final container = _container(_FakeAuthService());
      await container.read(authControllerProvider.future);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .login('ada@example.com', 'wrong'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.value, isNull);
    });
  });

  group('deleting the account', () {
    late Directory documents;
    late Directory cache;
    late AppDatabase database;
    late _FakeAuthService service;
    late ProviderContainer container;
    late _FakePhotoCache photoCache;

    File fileIn(Directory folder, String name) =>
        File(path.join(folder.path, name))..createSync(recursive: true);

    Future<void> eventually(bool Function() isDone) async {
      for (var i = 0; i < 300 && !isDone(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    const logLine = 'id=note-1';
    bool logsCleared() =>
        AppLogger.instance.snapshot.every((entry) => entry.message != logLine);

    setUp(() async {
      AppLogger.instance.info('Test', logLine);
      photoCache = _FakePhotoCache();
      CachedNetworkImageProvider.defaultCacheManager = photoCache;
      documents = Directory.systemTemp.createTempSync('anchor-documents');
      cache = Directory.systemTemp.createTempSync('anchor-cache');
      addTearDown(() {
        documents.deleteSync(recursive: true);
        cache.deleteSync(recursive: true);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => call.method == 'getApplicationCacheDirectory'
                ? cache.path
                : documents.path,
          );
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'user_data': jsonEncode(_ada),
      });
      database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database
          .into(database.notes)
          .insert(
            NotesCompanion.insert(
              id: 'note-1',
              title: 'Note',
              updatedAt: Value(DateTime(2026)),
              isSynced: const Value(true),
            ),
          );
      service = _FakeAuthService();
      container = _container(service, database: database);
      await container.read(authControllerProvider.future);
    });

    test('a refused password changes nothing', () async {
      service.deleteFailure = const WrongCurrentPasswordFailure();
      final databaseFile = fileIn(documents, 'db_user-1.sqlite');

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .deleteAccount(password: 'wrong'),
        throwsA(isA<WrongCurrentPasswordFailure>()),
      );

      expect(container.read(authControllerProvider).value?.id, 'user-1');
      expect(container.read(activeUserIdProvider), 'user-1');
      expect(databaseFile.existsSync(), isTrue);
      expect(
        await const FlutterSecureStorage().read(key: 'access_token'),
        'access',
      );
    });

    test('signs out and leaves nothing of the account behind', () async {
      final kept = fileIn(documents, 'db_someone-else.sqlite');
      final files = [
        fileIn(documents, 'db_user-1.sqlite'),
        fileIn(documents, 'db_user-1.sqlite-journal'),
        fileIn(documents, 'db_user-1.sqlite-wal'),
        fileIn(documents, 'db_user-1.sqlite-shm'),
        fileIn(documents, 'attachments/note-1/photo.jpg'),
        fileIn(cache, 'attachments/note-1/photo.jpg'),
      ];
      final otherAttachment = fileIn(documents, 'attachments/note-2/photo.jpg');

      await container
          .read(authControllerProvider.notifier)
          .deleteAccount(password: 'my password');

      expect(service.deletePasswords, ['my password']);
      expect(container.read(authControllerProvider).value, isNull);
      expect(container.read(activeUserIdProvider), isNull);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(await storage.read(key: 'user_data'), isNull);

      await eventually(() => files.every((file) => !file.existsSync()));
      expect(files.where((file) => file.existsSync()), isEmpty);
      expect(kept.existsSync(), isTrue);
      expect(otherAttachment.existsSync(), isTrue);
    });

    test('removes the real database files once it has closed', () async {
      final real = _container(service);
      await real.read(authControllerProvider.future);
      final db = real.read(appDatabaseProvider);
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: 'note-1',
              title: 'Note',
              updatedAt: Value(DateTime(2026)),
              isSynced: const Value(true),
            ),
          );
      List<String> databaseFiles() => [
        for (final file in documents.listSync())
          if (path.basename(file.path).startsWith('db_user-1.sqlite'))
            file.path,
      ];
      expect(databaseFiles(), isNotEmpty);
      final attachment = fileIn(documents, 'attachments/note-1/photo.jpg');

      await real.read(authControllerProvider.notifier).deleteAccount();

      await eventually(() => databaseFiles().isEmpty && logsCleared());
      expect(databaseFiles(), isEmpty);
      expect(attachment.existsSync(), isFalse);
      expect(photoCache.emptied, 1);
    });

    test('removes this account’s pending shares and no one else’s', () async {
      final shares = Directory.systemTemp.createTempSync('anchor-shares');
      addTearDown(() => shares.deleteSync(recursive: true));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('anchor/share'),
            (call) async => call.method == 'folder' ? shares.path : null,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('anchor/share'),
              null,
            ),
      );
      final inbox = ShareInbox(shares);
      Future<Directory> pendingShare(String id, String userId) async {
        final staging = Directory(path.join(shares.path, 'staging', id));
        await inbox.save(
          ShareEntry(id: id, userId: userId, savedAt: DateTime(2026)),
          staging,
        );
        return Directory(path.join(shares.path, 'inbox', id));
      }

      final mine = await pendingShare('share-1', 'user-1');
      final theirs = await pendingShare('share-2', 'someone-else');

      await container.read(authControllerProvider.notifier).deleteAccount();

      await eventually(() => !mine.existsSync());
      expect(mine.existsSync(), isFalse);
      expect(theirs.existsSync(), isTrue);
    });

    test('empties the photo cache and clears the logs', () async {
      await container.read(authControllerProvider.notifier).deleteAccount();

      await eventually(logsCleared);
      expect(photoCache.emptied, 1);
      expect(logsCleared(), isTrue);
    });

    test('a failed step doesn’t stop the others, and keeps the logs', () async {
      photoCache.failure = StateError('no cache');
      final databaseFile = fileIn(documents, 'db_user-1.sqlite');

      await container.read(authControllerProvider.notifier).deleteAccount();

      await eventually(() => photoCache.emptied == 1);
      await pumpEventQueue();
      expect(databaseFile.existsSync(), isFalse);
      expect(logsCleared(), isFalse);
    });

    test('the account still ends when its notes can’t be read', () async {
      final databaseFile = fileIn(documents, 'db_user-1.sqlite');
      await database.close();

      await container.read(authControllerProvider.notifier).deleteAccount();

      expect(container.read(authControllerProvider).value, isNull);
      expect(container.read(activeUserIdProvider), isNull);
      await eventually(() => photoCache.emptied == 1);
      await pumpEventQueue();
      expect(databaseFile.existsSync(), isFalse);
      expect(logsCleared(), isFalse);
    });
  });

  test('removing the photo shows at once, without loading again', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user_data': jsonEncode(_ada),
    });
    final service = _FakeAuthService();
    final container = _container(service);
    final user = await container.read(authControllerProvider.future);
    expect(user?.profileImage, '/profiles/ada.jpg');
    // The background refresh after starting from the stored profile.
    await pumpEventQueue();
    final reads = service.profileReads;

    final auth = container.read(authControllerProvider.notifier);
    await auth.removePhoto();

    final state = container.read(authControllerProvider);
    expect(state.value?.profileImage, isNull);
    expect(state.value?.hasPassword, isTrue);
    expect(service.profileReads, reads);
  });
}
