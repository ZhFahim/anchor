import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/active_user_id_provider.dart';
import '../domain/user.dart';
import '../data/repository/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<User?> build() async {
    final authRepo = ref.watch(authRepositoryProvider);

    // Check if we have a token
    final token = await authRepo.getToken();
    if (token == null) {
      // No token means user is not logged in
      return null;
    }

    // Try to fetch fresh data from server first
    try {
      final freshUser = await authRepo.getProfile();
      // Ensure activeUserId is set (covers app restart scenario)
      ref.read(activeUserIdProvider.notifier).set(freshUser.id);
      return freshUser;
    } catch (e) {
      // If fetch fails (network error, etc.), fall back to cached data
      final cachedUser = await authRepo.getCurrentUser();
      if (cachedUser != null) {
        ref.read(activeUserIdProvider.notifier).set(cachedUser.id);
      }
      return cachedUser;
    }
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
