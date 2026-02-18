import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../constants/auth_constants.dart';
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

  /// Save user data to secure storage
  Future<void> _saveUser(User user) async {
    final userJson = user.toJson();
    await _storage.write(key: 'user_data', value: jsonEncode(userJson));
  }

  /// Load user data from secure storage
  Future<User?> _loadUser() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        return User.fromJson(userJson);
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }

  Future<User> login(String email, String password) async {
    final data = await _authService.login(email, password);
    final token = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userJson);

    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_id', value: userJson['id']);
    await _storage.write(key: 'user_email', value: userJson['email']);
    await _saveUser(user);
    return user;
  }

  Future<void> register(String email, String password, String name) async {
    final data = await _authService.register(email, password, name);

    if (data.containsKey('access_token') && data['access_token'] != null) {
      final token = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userJson);

      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'user_id', value: userJson['id']);
      await _storage.write(key: 'user_email', value: userJson['email']);
      await _saveUser(user);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_data');
  }

  Future<String?> getToken() {
    return _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: 'refresh_token');
  }

  Future<User?> getCurrentUser() async {
    // Try to load full user data from storage
    final user = await _loadUser();
    if (user != null) {
      return user;
    }

    // Fallback to legacy storage (for backward compatibility)
    final id = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    if (id != null && email != null) {
      final fallbackUser = User(id: id, email: email, name: 'User');
      // Save as full user data for next time
      await _saveUser(fallbackUser);
      return fallbackUser;
    }
    return null;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _authService.changePassword(currentPassword, newPassword);
  }

  Future<User> updateProfile({String? name}) async {
    final data = await _authService.updateProfile(name: name);
    final user = User.fromJson(data);
    await _saveUser(user);
    return user;
  }

  Future<User> uploadProfileImage(File imageFile) async {
    final data = await _authService.uploadProfileImage(imageFile);
    final user = User.fromJson(data);
    await _saveUser(user);
    return user;
  }

  Future<User> removeProfileImage() async {
    final data = await _authService.removeProfileImage();
    final user = User.fromJson(data);
    await _saveUser(user);
    return user;
  }

  Future<User> getProfile() async {
    final data = await _authService.getProfile();
    final user = User.fromJson(data);
    await _saveUser(user);
    return user;
  }

  /// Sign in with OIDC. Returns null if user cancelled.
  Future<User?> loginWithOidc() async {
    final config = await _authService.getOidcConfig();
    if (!config.enabled ||
        config.issuerUrl == null ||
        config.clientId == null ||
        config.issuerUrl!.isEmpty ||
        config.clientId!.isEmpty) {
      throw Exception('OIDC is not enabled or not configured');
    }

    final appAuth = FlutterAppAuth();
    final request = AuthorizationTokenRequest(
      config.clientId!,
      oidcRedirectUri,
      issuer: config.issuerUrl,
      scopes: ['openid', 'email', 'profile'],
    );

    AuthorizationTokenResponse? result;
    try {
      result = await appAuth.authorizeAndExchangeCode(request);
    } on FlutterAppAuthUserCancelledException {
      return null;
    } on FlutterAppAuthPlatformException catch (e) {
      final d = e.platformErrorDetails;
      final msg = (d.errorDescription ?? e.message ?? d.error ?? e.code)
          .toString()
          .trim();
      throw Exception(msg.isEmpty ? 'Sign-in failed' : msg);
    } catch (e) {
      final s = e
          .toString()
          .replaceFirst(RegExp(r'^Exception:?\s*'), '')
          .trim();
      final line = s.split('\n').first.trim();
      throw Exception(line.isNotEmpty ? line : 'Sign-in failed');
    }
    final idpAccessToken = result.accessToken;
    if (idpAccessToken == null || idpAccessToken.isEmpty) {
      return null;
    }

    final data = await _authService.exchangeOidcMobileToken(idpAccessToken);
    final token = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userJson);

    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _saveUser(user);
    return user;
  }
}
