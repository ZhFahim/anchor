import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/user.dart';

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

  Future<User> register(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password},
      );
      // Register returns { id, email }
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.post(
        '/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to change password';
    }
  }
}
