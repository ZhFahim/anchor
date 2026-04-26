import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/active_user_id_provider.dart';
import '../sync/sync_worker.dart';

part 'connectivity_provider.g.dart';

bool isOnlineFromResults(List<ConnectivityResult> results) =>
    results.isNotEmpty && !results.contains(ConnectivityResult.none);

@riverpod
Stream<List<ConnectivityResult>> connectivityStream(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

// Thin facade over SyncWorker, kept so existing pull-to-refresh and main.dart
// callers don't break.
@riverpod
class SyncManager extends _$SyncManager {
  bool _wasOffline = false;

  @override
  bool build() {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((results) {
          if (isOnlineFromResults(results) && _wasOffline) {
            _kick(immediate: true);
          }
          _wasOffline = !isOnlineFromResults(results);
        });
      },
    );

    _checkInitialState();
    return false;
  }

  Future<void> _checkInitialState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _wasOffline =
          results.isEmpty || results.contains(ConnectivityResult.none);
    } catch (_) {
      _wasOffline = true;
    }
  }

  void _kick({bool immediate = false}) {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;
    ref.read(syncWorkerProvider).requestSync(immediate: immediate);
  }

  Future<void> manualSync() async {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;
    await ref.read(syncWorkerProvider).requestSync(immediate: true);
  }
}

@riverpod
bool isOnline(Ref ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(data: isOnlineFromResults, orElse: () => true);
}
