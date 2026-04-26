import 'package:dio/dio.dart';
import 'sync_models.dart';

class SyncApiClient {
  final Dio _dio;

  SyncApiClient(this._dio);

  Future<SyncResponse> sync(SyncRequest request) async {
    final response = await _dio.post(
      '/api/sync',
      data: request.toJson(),
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return SyncResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
