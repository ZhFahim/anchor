import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/custom_headers.dart';
import '../../../core/network/dio_provider.dart';
import 'server_info_provider.dart';

sealed class ServerCheck {
  const ServerCheck();
}

final class ServerFound extends ServerCheck {
  const ServerFound(this.info);

  final ServerInfo info;
}

final class NotAnchorServer extends ServerCheck {
  const NotAnchorServer();
}

final class UntrustedCertificate extends ServerCheck {
  const UntrustedCertificate();
}

final class ServerUnreachable extends ServerCheck {
  const ServerUnreachable();
}

class ServerConnector {
  ServerConnector({
    required bool allowSelfSigned,
    List<CustomHeader> customHeaders = const [],
    Dio? dio,
  }) : _allowSelfSigned = allowSelfSigned,
       _customHeaders = customHeaders,
       _dio = dio;

  final bool _allowSelfSigned;
  final List<CustomHeader> _customHeaders;
  final Dio? _dio;

  /// [url] must be a normalized address.
  Future<ServerCheck> check(String url) async {
    final dio =
        _dio ??
        createServerDio(
          url,
          allowSelfSigned: _allowSelfSigned,
          customHeaders: _customHeaders,
        );
    try {
      final response = await dio.get<Object?>('$url/api/health');
      final data = response.data;
      if (response.statusCode != 200 ||
          data is! Map<String, dynamic> ||
          data['app'] != 'anchor') {
        return const NotAnchorServer();
      }
      return ServerFound(ServerInfo.fromJson(data));
    } on DioException catch (error) {
      if (error.apiError is CertificateApiError) {
        return const UntrustedCertificate();
      }
      return error.type == DioExceptionType.badResponse
          ? const NotAnchorServer()
          : const ServerUnreachable();
    } catch (_) {
      return const ServerUnreachable();
    }
  }
}
