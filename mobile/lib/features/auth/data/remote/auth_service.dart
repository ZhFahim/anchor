import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/auth_failure.dart';
import '../../domain/oidc_config.dart';

part 'auth_service.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
}

/// A request that fails throws an [AuthFailure].
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) => _send(
    () => _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    ),
  );

  /// The answer has tokens, or only the user while an admin still has to
  /// approve the account.
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) => _send(
    () => _dio.post(
      '/api/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    ),
  );

  Future<void> changePassword(
    String currentPassword,
    String newPassword, {
    String? refreshToken,
  }) async {
    await _send<Object?>(
      () => _dio.post(
        '/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'refreshToken': ?refreshToken,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> updateProfile({String? name}) =>
      _send(() => _dio.patch('/api/auth/profile', data: {'name': ?name}));

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) =>
      _send(() async {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });
        return _dio.post('/api/auth/profile/image', data: formData);
      });

  Future<Map<String, dynamic>> removeProfileImage() =>
      _send(() => _dio.delete('/api/auth/profile/image'));

  Future<Map<String, dynamic>> getProfile() =>
      _send(() => _dio.get('/api/auth/me'));

  Future<OidcConfig> getOidcConfig() async {
    try {
      final response = await _dio.get('/api/auth/oidc/config');
      return OidcConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      // Older servers have no OIDC endpoint.
      if (error.response?.statusCode == 404) return const OidcConfig();
      throw authFailureOf(error);
    }
  }

  Future<String?> getRegistrationMode() async {
    try {
      final response = await _dio.get('/api/auth/registration-mode');
      final data = response.data as Map<String, dynamic>;
      return data['mode'] as String?;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw authFailureOf(error);
    }
  }

  Future<void> revokeRefreshToken(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
    } on Exception {
      // Local sign-out goes ahead anyway.
    }
  }

  Future<Map<String, dynamic>> exchangeOidcMobileToken(String accessToken) =>
      _send(
        () => _dio.post(
          '/api/auth/oidc/exchange/mobile',
          data: {'access_token': accessToken},
        ),
      );

  /// Settings' magic login on the web: a one-time code for this phone.
  Future<Map<String, dynamic>> redeemMagicLogin(String code) => _send(
    () => _dio.post('/api/auth/magic-login/redeem', data: {'code': code}),
  );

  Future<T> _send<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (error) {
      throw authFailureOf(error);
    }
  }
}

AuthFailure authFailureOf(DioException exception) {
  final apiError = exception.apiError;
  if (apiError is OfflineApiError ||
      apiError is TimeoutApiError ||
      apiError is CertificateApiError ||
      apiError is CancelledApiError) {
    return const UnreachableFailure();
  }
  final data = exception.response?.data;
  return AuthFailure.fromResponse(
    exception.response?.statusCode,
    data is Map ? data['message'] : null,
    error: apiError,
  );
}
