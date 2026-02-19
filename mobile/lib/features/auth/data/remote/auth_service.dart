import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/oidc_config.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
}

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        '/api/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to change password';
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? name}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;

      final response = await _dio.patch('/api/auth/profile', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update profile';
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/auth/profile/image',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to upload profile image';
    }
  }

  Future<Map<String, dynamic>> removeProfileImage() async {
    try {
      final response = await _dio.delete('/api/auth/profile/image');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to remove profile image';
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get profile';
    }
  }

  Future<OidcConfig> getOidcConfig() async {
    try {
      final response = await _dio.get('/api/auth/oidc/config');
      return OidcConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (_) {
      // Server may not have OIDC (old version)
      return const OidcConfig();
    }
  }

  Future<Map<String, dynamic>> exchangeOidcMobileToken(
    String accessToken,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/oidc/exchange/mobile',
        data: {'access_token': accessToken},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to complete sign-in';
    }
  }
}
