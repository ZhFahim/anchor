import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/tags/data/repository/tags_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
      return freshUser;
    } catch (e) {
      // If fetch fails (network error, etc.), fall back to cached data
      final cachedUser = await authRepo.getCurrentUser();
      return cachedUser;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).login(email, password);
    });
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(email, password, name);
      return null;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      // Clear local data
      await ref.read(notesRepositoryProvider).clearAll();
      await ref.read(tagsRepositoryProvider).clearAll();
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
