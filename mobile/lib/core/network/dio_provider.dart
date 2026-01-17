import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'server_config_provider.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final serverUrl = ref.watch(serverUrlProvider);
  final dio = Dio();

  // Set base URL from server config
  if (serverUrl != null && serverUrl.isNotEmpty) {
    dio.options.baseUrl = serverUrl;
  }

  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  dio.options.headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Add Authorization Interceptor
  const storage = FlutterSecureStorage();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Transform DioException into user-friendly error
        final transformedError = _transformError(e);
        return handler.next(transformedError);
      },
    ),
  );

  // Add logging interceptor in debug mode
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
}

/// Transform DioException into a more user-friendly error with better messages
DioException _transformError(DioException e) {
  // If there's already a response with a message, preserve it
  if (e.response?.data != null && e.response!.data is Map) {
    final data = e.response!.data as Map<String, dynamic>;
    if (data.containsKey('message')) {
      // Server already provided a message, use it
      return e;
    }
  }

  // Transform based on error type
  String message;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      message =
          'Connection timeout. Please check your internet connection and try again.';
      break;
    case DioExceptionType.sendTimeout:
      message = 'Request timeout. Please try again.';
      break;
    case DioExceptionType.receiveTimeout:
      message = 'Response timeout. Please try again.';
      break;
    case DioExceptionType.connectionError:
      message = 'No internet connection. Please check your network settings.';
      break;
    case DioExceptionType.badCertificate:
      message = 'Certificate error.';
      break;
    case DioExceptionType.badResponse:
      // Handle specific status codes
      final statusCode = e.response?.statusCode;
      switch (statusCode) {
        case 400:
          message = 'Invalid request. Please check your input.';
          break;
        case 401:
          message = 'Authentication required. Please log in again.';
          break;
        case 403:
          message = 'Permission denied.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        case 502:
        case 503:
        case 504:
          message = 'Server unavailable. Please try again later.';
          break;
        default:
          message = 'Request failed. Please try again.';
      }
      break;
    case DioExceptionType.cancel:
      message = 'Request cancelled.';
      break;
    case DioExceptionType.unknown:
      // Check if it's a network-related error
      if (e.error?.toString().contains('SocketException') == true ||
          e.error?.toString().contains('Network is unreachable') == true) {
        message = 'No internet connection. Please check your network settings.';
      } else {
        message = 'An unexpected error occurred. Please try again.';
      }
      break;
  }

  // Create a new DioException with the transformed message
  // Preserve the original error but add the message to response data
  if (e.response != null) {
    final response = e.response!;
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    data['message'] = message;
    return DioException(
      requestOptions: e.requestOptions,
      response: Response(
        data: data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        requestOptions: response.requestOptions,
      ),
      type: e.type,
      error: e.error,
      stackTrace: e.stackTrace,
    );
  }

  // For errors without response, create a synthetic response with the message
  return DioException(
    requestOptions: e.requestOptions,
    response: Response(
      data: {'message': message},
      statusCode: e.response?.statusCode ?? 0,
      requestOptions: e.requestOptions,
    ),
    type: e.type,
    error: e.error,
    stackTrace: e.stackTrace,
  );
}
