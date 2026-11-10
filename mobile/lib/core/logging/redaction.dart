import 'dart:convert';

const _sensitiveKeys = <String>{
  'password',
  'password_hash',
  'passwordhash',
  'newpassword',
  'new_password',
  'oldpassword',
  'old_password',
  'currentpassword',
  'current_password',
  'access_token',
  'accesstoken',
  'refresh_token',
  'refreshtoken',
  'token',
  'authorization',
  'secret',
  'email',
  'title',
  'content',
  'name',
  'q',
};

const _redacted = '***';
const _maxStringLength = 2000;

bool _isSensitive(String key) => _sensitiveKeys.contains(key.toLowerCase());

String _truncate(String value) {
  if (value.length <= _maxStringLength) return value;
  final trimmed = value.length - _maxStringLength;
  return '${value.substring(0, _maxStringLength)}…[truncated $trimmed chars]';
}

Object? redactValue(Object? value) {
  if (value is Map) {
    return redactMap(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    return value.map(redactValue).toList();
  }
  if (value is String) {
    return _truncate(value);
  }
  return value;
}

Map<String, dynamic> redactMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  input.forEach((key, value) {
    if (_isSensitive(key)) {
      out[key] = _redacted;
    } else {
      out[key] = redactValue(value);
    }
  });
  return out;
}

String redactBody(Object? body) {
  if (body == null) return '';
  if (body is Map) {
    return jsonEncode(redactMap(Map<String, dynamic>.from(body)));
  }
  if (body is List) {
    return jsonEncode(body.map(redactValue).toList());
  }
  if (body is String) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return jsonEncode(redactMap(Map<String, dynamic>.from(decoded)));
      }
      if (decoded is List) {
        return jsonEncode(decoded.map(redactValue).toList());
      }
    } catch (_) {
      // not JSON
    }
    return _truncate(body);
  }
  return _truncate(body.toString());
}

/// Returns the query without a leading '?', or '' when there is none.
String redactQuery(Uri uri) {
  if (uri.query.isEmpty) return '';
  final parts = <String>[];
  uri.queryParametersAll.forEach((key, values) {
    if (_isSensitive(key)) {
      parts.add('$key=$_redacted');
    } else {
      for (final value in values) {
        parts.add('$key=${_truncate(value)}');
      }
    }
  });
  return parts.join('&');
}

const _headersSafeToLog = <String>{
  'accept',
  'content-length',
  'content-type',
  'x-anchor-protocol',
};

Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
  final out = <String, dynamic>{};
  headers.forEach((key, value) {
    final lower = key.toLowerCase();
    if (lower == 'authorization') {
      out[key] = 'Bearer ***';
    } else if (!_headersSafeToLog.contains(lower)) {
      out[key] = _redacted;
    } else if (value is String) {
      out[key] = _truncate(value);
    } else {
      out[key] = value;
    }
  });
  return out;
}
