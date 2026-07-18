import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/server_config_provider.dart';
import '../../../core/providers/active_user_id_provider.dart';
import '../data/repository/auth_repository.dart';
import '../domain/user.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<User?> build() async {
    final serverUrl = await ref.watch(serverConfigProvider.future);
    await ref.watch(allowSelfSignedCertProvider.future);

    final authRepo = ref.watch(authRepositoryProvider);

    final token = await authRepo.getToken();
    if (token == null) {
      return null;
    }

    if (serverUrl == null || serverUrl.isEmpty) {
      return null;
    }

    // Offline-first: trust the cached profile so startup never waits on the
    // network, then refresh it in the background.
    final cachedUser = await authRepo.getCurrentUser();
    if (cachedUser != null) {
      ref.read(activeUserIdProvider.notifier).set(cachedUser.id);
      _refreshProfileInBackground(authRepo);
      return cachedUser;
    }

    // No cached profile (e.g. corrupt cache); fall back to the server.
    try {
      final freshUser = await authRepo.getProfile();
      ref.read(activeUserIdProvider.notifier).set(freshUser.id);
      return freshUser;
    } catch (e) {
      return null;
    }
  }

  void _refreshProfileInBackground(AuthRepository authRepo) {
    Future(() async {
      try {
        final freshUser = await authRepo.getProfile();
        if (!ref.mounted) return;
        if (state.value?.id == freshUser.id) {
          state = AsyncData(freshUser);
        }
      } catch (_) {
        // Server unreachable; keep the cached profile.
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      // Set activeUserId so the per-user database is opened
      ref.read(activeUserIdProvider.notifier).set(user.id);
      return user;
    });
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(email, password, name);
      return null;
    });
  }

  Future<void> loginWithOidc() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).loginWithOidc();
      if (user == null) {
        // User cancelled the OIDC flow; stay on login (state = AsyncData(null))
        return null;
      }
      ref.read(activeUserIdProvider.notifier).set(user.id);
      return user;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      // Clear activeUserId - this closes the DB via provider invalidation
      // Data stays safe in the per-user database file
      ref.read(activeUserIdProvider.notifier).set(null);
      return null;
    });
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .changePassword(currentPassword, newPassword);
      return state.value; // Keep the current user state
    });
  }
}
