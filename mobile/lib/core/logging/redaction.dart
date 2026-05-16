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
};

const _redacted = '***';
const _maxStringLen = 2000;

bool _isSensitive(String key) => _sensitiveKeys.contains(key.toLowerCase());

String _truncate(String value) {
  if (value.length <= _maxStringLen) return value;
  final trimmed = value.length - _maxStringLen;
  return '${value.substring(0, _maxStringLen)}…[truncated $trimmed chars]';
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

/// Redacts a body that may be a JSON string, Map, FormData, or other.
String redactBody(Object? body) {
  if (body == null) return '';
  if (body is Map) {
    return jsonEncode(redactMap(Map<String, dynamic>.from(body)));
  }
  if (body is List) {
    return jsonEncode(body.map(redactValue).toList());
  }
  if (body is String) {
    // Try JSON, fall back to raw with truncation
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

/// Redacts sensitive query parameters; returns query WITHOUT leading '?',
/// or '' when there is none.
String redactQuery(Uri uri) {
  if (uri.query.isEmpty) return '';
  final parts = <String>[];
  uri.queryParametersAll.forEach((key, values) {
    if (_isSensitive(key)) {
      parts.add('$key=$_redacted');
    } else {
      for (final v in values) {
        parts.add('$key=${_truncate(v)}');
      }
    }
  });
  return parts.join('&');
}

Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
  final out = <String, dynamic>{};
  headers.forEach((key, value) {
    final lower = key.toLowerCase();
    if (lower == 'authorization') {
      out[key] = 'Bearer ***';
    } else if (_isSensitive(lower)) {
      out[key] = _redacted;
    } else if (value is String) {
      out[key] = _truncate(value);
    } else {
      out[key] = value;
    }
  });
  return out;
}
