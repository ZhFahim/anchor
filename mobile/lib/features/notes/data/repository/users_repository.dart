import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/user_search_result.dart';

part 'users_repository.g.dart';

@riverpod
UsersRepository usersRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return UsersRepository(dio);
}

class UsersRepository {
  final Dio _dio;

  UsersRepository(this._dio);

  /// Search for users by email for sharing purposes.
  /// Returns empty list if query is less than 2 characters.
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().length < 2) {
      return [];
    }

    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'q': query.trim()},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      // Return empty list on error - error handling done by Dio interceptor
      return [];
    }
  }
}
