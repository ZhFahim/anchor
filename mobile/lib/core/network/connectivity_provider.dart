import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/active_user_id_provider.dart';
import '../../features/notes/data/repository/note_attachments_repository.dart';
import '../../features/notes/data/repository/notes_repository.dart';
import '../../features/tags/data/repository/tags_repository.dart';

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

  @override
  bool build() {
    // Listen to connectivity changes
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((results) {
          if (isOnlineFromResults(results) && _wasOffline) {
            // Connection restored - trigger sync
            _triggerSync();
          }

          _wasOffline = !isOnlineFromResults(results);
        });
      },
    );

    // Check initial connectivity state
    _checkInitialState();

    return false; // isSyncing
  }

  Future<void> _checkInitialState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _wasOffline =
          results.isEmpty || results.contains(ConnectivityResult.none);
    } catch (e) {
      _wasOffline = true;
    }
  }

  Future<void> _triggerSync() async {
    // Don't sync if no user is logged in
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;

    if (state) return; // Already syncing
    state = true;
    try {
      // Sync tags FIRST to ensure tag IDs are resolved before notes sync
      await ref.read(tagsRepositoryProvider).sync();
      // Sync notes (includes attachment sync, atomic mark-synced when content + attachments synced)
      await ref.read(notesRepositoryProvider).sync();
      // Evict old cached attachments if cache exceeds threshold
      await ref.read(noteAttachmentsRepositoryProvider).evictCache();
    } catch (e) {
      // Sync failed, will retry on next connectivity change
    } finally {
      state = false;
    }
  }

  Future<void> manualSync() async {
    await _triggerSync();
  }
}

/// Reactive online status — rebuilds when connectivity changes.
@riverpod
bool isOnline(Ref ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(data: isOnlineFromResults, orElse: () => true);
}
