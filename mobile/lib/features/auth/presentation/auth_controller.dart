import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/user.dart';
import '../data/repository/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<User?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).login(email, password);
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(email, password);
      // Auto login after register or just return null (require login)
      // Let's require login for now to keep it simple, or implement auto-login
      // The prompt says "Keep features minimal".
      // If I return null, state becomes null, user is not logged in.
      // I'll just return null, so user stays on whatever screen or navigates.
      // Actually, if register is successful, we usually want to redirect to login.
      // State shouldn't change to 'loggedIn' unless we have a user.
      return null;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return null;
    });
  }
}
