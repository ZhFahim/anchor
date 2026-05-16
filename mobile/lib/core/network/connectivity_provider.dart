import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../logging/app_logger.dart';
import '../providers/active_user_id_provider.dart';
import '../../features/notes/data/repository/note_attachments_repository.dart';
import '../../features/notes/data/repository/notes_repository.dart';
import '../../features/tags/data/repository/tags_repository.dart';
import 'sync_requester.dart';

part 'connectivity_provider.g.dart';

/// Helper to check if connectivity results indicate online status.
bool isOnlineFromResults(List<ConnectivityResult> results) =>
    results.isNotEmpty && !results.contains(ConnectivityResult.none);

@riverpod
Stream<List<ConnectivityResult>> connectivityStream(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

@riverpod
class SyncManager extends _$SyncManager {
  bool _wasOffline = false;
  bool _rerunRequested = false;
  Future<void>? _activeSync;

  @override
  bool build() {
    registerAppSyncRequester(requestSync);
    ref.onDispose(() => registerAppSyncRequester(null));

    // Listen to connectivity changes
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((results) {
          if (isOnlineFromResults(results) && _wasOffline) {
            // Connection restored - trigger sync
            requestSync();
          }

          _wasOffline = !isOnlineFromResults(results);
        });
      },
    );

    ref.listen<String?>(activeUserIdProvider, (previous, next) {
      if (next != null && next != previous) {
        requestSync();
      }
    });

    // Check initial connectivity state
    _checkInitialState();

    return false; // isSyncing
  }

  Future<void> _checkInitialState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _wasOffline =
          results.isEmpty || results.contains(ConnectivityResult.none);
      if (!_wasOffline) {
        requestSync();
      }
    } catch (e) {
      _wasOffline = true;
    }
  }

  Future<void> requestSync() {
    // Don't sync if no user is logged in
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return Future.value();

    final activeSync = _activeSync;
    if (activeSync != null) {
      _rerunRequested = true;
      return activeSync;
    }

    final syncFuture = _runSyncLoop();
    _activeSync = syncFuture;
    return syncFuture;
  }

  Future<void> _runSyncLoop() async {
    state = true;
    try {
      do {
        _rerunRequested = false;
        try {
          await _runSyncCycle();
        } catch (e, stack) {
          AppLogger.instance.error(
            'Sync',
            'Sync failed',
            error: e,
            stackTrace: stack,
          );
          break;
        }
      } while (_rerunRequested && ref.read(activeUserIdProvider) != null);
    } finally {
      state = false;
      _activeSync = null;
    }
  }

  Future<void> _runSyncCycle() async {
    final start = DateTime.now();
    AppLogger.instance.info('Sync', 'App sync cycle start');
    try {
      // Sync tags FIRST to ensure tag IDs are resolved before notes sync
      await ref.read(tagsRepositoryProvider).sync();
      // Sync notes (includes attachment sync, atomic mark-synced when content + attachments synced)
      await ref.read(notesRepositoryProvider).sync();
      // Evict old cached attachments if cache exceeds threshold
      await ref.read(noteAttachmentsRepositoryProvider).evictCache();
      AppLogger.instance.info(
        'Sync',
        'App sync cycle done in ${DateTime.now().difference(start).inMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.instance.warn(
        'Sync',
        'App sync cycle aborted after ${DateTime.now().difference(start).inMilliseconds}ms: $e',
      );
      rethrow;
    }
  }

  Future<void> manualSync() async {
    await requestSync();
  }
}

/// Reactive online status — rebuilds when connectivity changes.
@riverpod
bool isOnline(Ref ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(data: isOnlineFromResults, orElse: () => true);
}
