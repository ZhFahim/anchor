import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/user.dart';
import '../remote/auth_service.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  const storage = FlutterSecureStorage();
  return AuthRepository(authService, storage);
}

class AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthRepository(this._authService, this._storage);

  Future<User> login(String email, String password) async {
    final data = await _authService.login(email, password);
    final token = data['access_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'user_id', value: userJson['id']);
    await _storage.write(key: 'user_email', value: userJson['email']);
    return User.fromJson(userJson);
  }

  Future<void> register(String email, String password) async {
    await _authService.register(email, password);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() {
    return _storage.read(key: 'access_token');
  }

  Future<User?> getCurrentUser() async {
    final id = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    if (id != null && email != null) {
      return User(id: id, email: email);
    }
    return null;
  }
}
