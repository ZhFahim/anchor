import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/log_tags.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/auth_failure.dart';
import '../../domain/user.dart';
import '../remote/auth_service.dart';

part 'auth_repository.g.dart';

/// The scheme must match `appAuthRedirectScheme` in
/// android/app/build.gradle.kts and the URL scheme in ios/Runner/Info.plist.
const _oidcRedirectUri = 'anchor://oidc/callback';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService, ref.watch(secureStorageProvider));
}

/// Failures are [AuthFailure]s.
class AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthRepository(this._authService, this._storage);

  Future<void> _saveUser(User user) async {
    final userJson = user.toJson();
    await _storage.write(
      key: StorageKeys.userData,
      value: jsonEncode(userJson),
    );
  }

  Future<User?> _loadUser() async {
    final userData = await _storage.read(key: StorageKeys.userData);
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        return User.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<User> _saveSession(Map<String, dynamic> data) async {
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.write(
      key: StorageKeys.accessToken,
      value: data['access_token'] as String,
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: data['refresh_token'] as String,
    );
    await _saveUser(user);
    return user;
  }

  Future<User> login(String email, String password) async =>
      _saveSession(await _authService.login(email, password));

  /// Returns null when an admin has to approve the account first.
  Future<User?> register(String email, String password, String name) async {
    final data = await _authService.register(email, password, name);
    if (data['access_token'] == null) return null;
    return _saveSession(data);
  }

  Future<User> loginWithMagicCode(String code) async =>
      _saveSession(await _authService.redeemMagicLogin(code));

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (refreshToken != null) {
      await _authService.revokeRefreshToken(refreshToken);
    }
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userData);
  }

  Future<String?> getToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<User?> getCurrentUser() => _loadUser();

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Keeps this session; the server signs out every other one.
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    await _authService.changePassword(
      currentPassword,
      newPassword,
      refreshToken: refreshToken,
    );
  }

  /// Profile answers may leave out hasPassword; the stored value is kept then.
  Future<User> _profileFrom(Map<String, dynamic> data) async {
    final user = User.fromJson(data);
    if (data.containsKey('hasPassword')) return user;
    final stored = await _loadUser();
    return stored == null
        ? user
        : user.copyWith(hasPassword: stored.hasPassword);
  }

  Future<User> updateProfile({String? name}) async {
    final data = await _authService.updateProfile(name: name);
    final user = await _profileFrom(data);
    await _saveUser(user);
    return user;
  }

  Future<User> uploadProfileImage(File imageFile) async {
    final data = await _authService.uploadProfileImage(imageFile);
    final user = await _profileFrom(data);
    await _saveUser(user);
    return user;
  }

  Future<User> removeProfileImage() async {
    final data = await _authService.removeProfileImage();
    final user = await _profileFrom(data);
    await _saveUser(user);
    return user;
  }

  Future<User> getProfile() async {
    final data = await _authService.getProfile();
    final user = User.fromJson(data);
    await _saveUser(user);
    return user;
  }

  /// Returns null if the user cancelled.
  Future<User?> loginWithOidc() async {
    final config = await _authService.getOidcConfig();
    final issuerUrl = config.issuerUrl;
    final clientId = config.clientId;
    if (!config.enabled ||
        issuerUrl == null ||
        issuerUrl.isEmpty ||
        clientId == null ||
        clientId.isEmpty) {
      throw const ProviderNotSetUpFailure();
    }

    final request = AuthorizationTokenRequest(
      clientId,
      _oidcRedirectUri,
      issuer: issuerUrl,
      scopes: ['openid', 'email', 'profile'],
    );

    final AuthorizationTokenResponse result;
    try {
      result = await FlutterAppAuth().authorizeAndExchangeCode(request);
    } on FlutterAppAuthUserCancelledException {
      return null;
    } on FlutterAppAuthPlatformException catch (error) {
      AppLogger.instance.warn(
        LogTags.auth,
        'Provider sign-in failed',
        error: error,
      );
      final details = error.platformErrorDetails;
      final detail = details.errorDescription ?? error.message;
      throw ProviderSignInFailure(
        detail == null || detail.trim().isEmpty ? null : detail.trim(),
      );
    } catch (error) {
      AppLogger.instance.warn(
        LogTags.auth,
        'Provider sign-in failed',
        error: error,
      );
      throw const ProviderSignInFailure();
    }
    final idpAccessToken = result.accessToken;
    if (idpAccessToken == null || idpAccessToken.isEmpty) {
      return null;
    }

    return _saveSession(
      await _authService.exchangeOidcMobileToken(idpAccessToken),
    );
  }
}
