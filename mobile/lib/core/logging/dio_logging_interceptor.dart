import 'dart:math';

import 'package:dio/dio.dart';

import 'app_logger.dart';
import 'redaction.dart';

const _startTsKey = 'app_logger_start_ts';
const _reqIdKey = 'app_logger_req_id';
const _tag = 'Dio';

/// Headers that carry no debug signal
const _boilerplateHeaders = <String>{'content-type', 'accept', 'authorization'};

/// Paths excluded from logging, routine polls.
/// Matched against [Uri.path] (no query string).
const _skipPaths = <String>{'/api/health'};

final _random = Random();

String _genReqId() {
  return _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
}

Map<String, dynamic> _nonDefaultHeaders(Map<String, dynamic> headers) {
  final out = <String, dynamic>{};
  for (final entry in headers.entries) {
    if (_boilerplateHeaders.contains(entry.key.toLowerCase())) continue;
    out[entry.key] = entry.value;
  }
  return out;
}

/// Dio interceptor that pipes request/response/error events into [AppLogger].
class AppLoggingInterceptor extends Interceptor {
  AppLoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_skipPaths.contains(options.uri.path)) {
      handler.next(options);
      return;
    }

    final reqId = _genReqId();
    options.extra[_reqIdKey] = reqId;
    options.extra[_startTsKey] = DateTime.now().millisecondsSinceEpoch;

    final body = options.data != null ? redactBody(options.data) : null;
    final headers = redactHeaders(_nonDefaultHeaders(options.headers));
    final q = redactQuery(options.uri);
    final query = q.isNotEmpty ? '?$q' : '';
    final sizeSuffix = body != null ? ' (${body.length}B)' : '';

    final buf = StringBuffer()
      ..write(
        '→[$reqId] ${options.method} ${options.uri.path}$query$sizeSuffix',
      );
    if (headers.isNotEmpty) {
      buf.write('\nheaders: $headers');
    }
    if (body != null) {
      buf.write('\nbody: $body');
    }
    AppLogger.instance.info(_tag, buf.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_skipPaths.contains(response.requestOptions.uri.path)) {
      handler.next(response);
      return;
    }
    final reqId = _reqId(response.requestOptions);
    final duration = _duration(response.requestOptions);
    final body = response.data != null ? redactBody(response.data) : null;
    final sizeSuffix = body != null ? ', ${body.length}B' : '';

    final buf = StringBuffer()
      ..write(
        '←[$reqId] ${response.requestOptions.method} '
        '${response.requestOptions.uri.path} '
        '${response.statusCode} (${duration}ms$sizeSuffix)',
      );
    if (body != null) {
      buf.write('\nbody: $body');
    }
    AppLogger.instance.info(_tag, buf.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_skipPaths.contains(err.requestOptions.uri.path)) {
      handler.next(err);
      return;
    }
    final reqId = _reqId(err.requestOptions);
    final duration = _duration(err.requestOptions);
    final status = err.response?.statusCode;
    final body = err.response?.data != null
        ? redactBody(err.response!.data)
        : null;

    final buf = StringBuffer()
      ..write(
        '✗[$reqId] ${err.requestOptions.method} '
        '${err.requestOptions.uri.path} '
        '${status ?? err.type.name} (${duration}ms): ${err.message ?? ''}',
      );
    if (body != null) {
      buf.write('\nresponse: $body');
    }
    AppLogger.instance.error(_tag, buf.toString(), error: err.error);
    handler.next(err);
  }

  String _reqId(RequestOptions options) {
    final v = options.extra[_reqIdKey];
    return v is String ? v : '------';
  }

  int _duration(RequestOptions options) {
    final start = options.extra[_startTsKey];
    if (start is int) {
      return DateTime.now().millisecondsSinceEpoch - start;
    }
    return 0;
  }
}
