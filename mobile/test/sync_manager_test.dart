import 'dart:async';

import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/session/active_user_id_provider.dart';
import 'package:anchor/core/session/session_expired_provider.dart';
import 'package:anchor/features/sync/data/sync_compatibility.dart';
import 'package:anchor/features/sync/data/sync_cursor.dart';
import 'package:anchor/features/sync/data/sync_events.dart';
import 'package:anchor/features/sync/data/sync_manager.dart';
import 'package:anchor/features/sync/data/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class HeldSyncService implements SyncService {
  final runs = <Completer<void>>[];

  @override
  Future<void> run() {
    final run = Completer<void>();
    runs.add(run);
    return run.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class QuietSyncEvents extends SyncEvents {
  QuietSyncEvents() : super(Dio());

  @override
  void connect() {}

  @override
  void disconnect() {}
}

class FixedServerConfig extends ServerConfig {
  @override
  Future<String?> build() async => 'https://anchor.example.com';
}

class NoSelfSignedCert extends AllowSelfSignedCert {
  @override
  Future<bool> build() async => false;
}

class NoCustomHeaders extends CustomHeaders {
  @override
  Future<List<CustomHeader>> build() async => const [];
}

class SignedIn extends ActiveUserId {
  @override
  String? build() => 'user-1';
}

class SignedOut extends ActiveUserId {
  @override
  String? build() => null;
}

class FixedSyncManager extends SyncManager {
  FixedSyncManager({required this.isSyncing});

  final bool isSyncing;

  @override
  bool build() => isSyncing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HeldSyncService service;
  late ProviderContainer container;

  ProviderContainer start([
    SyncCompatibility compatibility = SyncCompatibility.ok,
  ]) {
    final started = ProviderContainer(
      overrides: [
        syncServiceProvider.overrideWithValue(service),
        syncEventsProvider.overrideWithValue(QuietSyncEvents()),
        serverConfigProvider.overrideWith(FixedServerConfig.new),
        allowSelfSignedCertProvider.overrideWith(NoSelfSignedCert.new),
        customHeadersProvider.overrideWith(NoCustomHeaders.new),
        syncCompatibilityProvider.overrideWith((ref) async => compatibility),
        connectivityStreamProvider.overrideWith(
          (ref) => const Stream<List<ConnectivityResult>>.empty(),
        ),
        activeUserIdProvider.overrideWith(SignedIn.new),
      ],
    );
    addTearDown(started.dispose);
    started.listen(syncManagerProvider, (_, _) {});
    return started;
  }

  setUp(() {
    service = HeldSyncService();
    container = start();
  });

  SyncManager manager() => container.read(syncManagerProvider.notifier);

  test('stopping waits for the sync running now and starts no more', () async {
    unawaited(manager().requestSync());
    await pumpEventQueue();
    expect(service.runs, hasLength(1));

    var isStopped = false;
    unawaited(manager().stop().then((_) => isStopped = true));
    unawaited(manager().requestSync());
    await pumpEventQueue();
    expect(isStopped, isFalse, reason: 'the running sync has not finished');

    service.runs.single.complete();
    await pumpEventQueue();
    expect(isStopped, isTrue);

    await manager().requestSync();
    expect(service.runs, hasLength(1));
  });

  test('a failed sync is reported until one works', () async {
    final failing = manager().requestSync();
    await pumpEventQueue();
    service.runs.single.completeError(StateError('server error'));
    expect(await failing, isFalse);
    expect(container.read(syncFailedProvider), isTrue);

    final working = manager().requestSync();
    await pumpEventQueue();
    service.runs.last.complete();
    expect(await working, isTrue);
    expect(container.read(syncFailedProvider), isFalse);
  });

  test('a sync paused for an old app is not counted as synced', () async {
    final paused = start(SyncCompatibility.appOutdated);
    await pumpEventQueue();

    expect(
      await paused.read(syncManagerProvider.notifier).requestSync(),
      isFalse,
    );
    expect(service.runs, isEmpty);
    expect(paused.read(syncFailedProvider), isTrue);
  });

  test('the next sign-in syncs again', () async {
    await manager().stop();

    container.read(activeUserIdProvider.notifier).set(null);
    container.read(activeUserIdProvider.notifier).set('user-2');
    await pumpEventQueue();

    expect(service.runs, hasLength(1));
  });

  test('the first download ends once the cursor is saved and the full '
      'download is done', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cursor = SyncCursor(db);
    final seen = <bool>[];
    final watch = SyncCursor.watchHasDownloaded(db).listen(seen.add);
    addTearDown(watch.cancel);
    await pumpEventQueue();
    expect(seen.last, isFalse);

    await cursor.prepare();
    await cursor.save('first page');
    await pumpEventQueue();
    expect(seen.last, isFalse);

    await cursor.endSweep();
    await pumpEventQueue();
    expect(seen.last, isTrue);
  });

  group('the first download', () {
    Future<FirstDownload> firstDownload({
      Stream<bool>? hasDownloaded,
      bool isSignedIn = true,
      bool isOnline = true,
      bool isSyncing = false,
      bool hasFailed = false,
      bool isExpired = false,
      SyncCompatibility compatibility = SyncCompatibility.ok,
    }) async {
      final container = ProviderContainer(
        overrides: [
          activeUserIdProvider.overrideWith(
            isSignedIn ? SignedIn.new : SignedOut.new,
          ),
          hasDownloadedProvider.overrideWith(
            (ref) => hasDownloaded ?? Stream.value(false),
          ),
          isOnlineProvider.overrideWith((ref) => isOnline),
          syncManagerProvider.overrideWith(
            () => FixedSyncManager(isSyncing: isSyncing),
          ),
          syncCompatibilityProvider.overrideWith((ref) async => compatibility),
        ],
      );
      addTearDown(container.dispose);
      if (hasFailed) container.read(syncFailedProvider.notifier).set(true);
      if (isExpired) container.read(sessionExpiredProvider.notifier).expire();
      container.listen(firstDownloadProvider, (_, _) {});
      await pumpEventQueue();
      return container.read(firstDownloadProvider);
    }

    test('is running while it can still come', () async {
      expect(await firstDownload(), FirstDownload.running);
      expect(
        await firstDownload(hasDownloaded: const Stream.empty()),
        FirstDownload.running,
        reason: 'not known yet',
      );
      expect(
        await firstDownload(isOnline: false, hasFailed: true, isSyncing: true),
        FirstDownload.running,
        reason: 'trying again',
      );
    });

    test('has failed offline or after a failed sync', () async {
      expect(await firstDownload(isOnline: false), FirstDownload.failed);
      expect(await firstDownload(hasFailed: true), FirstDownload.failed);
    });

    test('is paused when signed out or the versions do not match', () async {
      expect(await firstDownload(isExpired: true), FirstDownload.paused);
      expect(
        await firstDownload(
          hasFailed: true,
          compatibility: SyncCompatibility.appOutdated,
        ),
        FirstDownload.paused,
      );
    });

    test('is done once it has come, or with no account', () async {
      expect(
        await firstDownload(hasDownloaded: Stream.value(true), isOnline: false),
        FirstDownload.done,
      );
      expect(
        await firstDownload(hasDownloaded: Stream.error(StateError('closed'))),
        FirstDownload.done,
      );
      expect(await firstDownload(isSignedIn: false), FirstDownload.done);
    });
  });
}
