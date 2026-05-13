import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_config_provider.g.dart';

const _serverUrlKey = 'server_url';
const _allowSelfSignedCertKey = 'allow_self_signed_cert';
const _customHeadersKey = 'custom_headers';
const int maxCustomHeaders = 10;
@riverpod
class ServerConfig extends _$ServerConfig {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> build() async {
    return await _storage.read(key: _serverUrlKey);
  }

  Future<void> setServerUrl(String url) async {
    // Normalize URL: remove trailing slash
    String normalizedUrl = url.trim();
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    await _storage.write(key: _serverUrlKey, value: normalizedUrl);
    state = AsyncData(normalizedUrl);
  }

  Future<void> clearServerUrl() async {
    await _storage.delete(key: _serverUrlKey);
    state = const AsyncData(null);
  }
}

/// Synchronous provider that returns the current server URL or null.
/// Use this when you need immediate access without async.
@riverpod
String? serverUrl(Ref ref) {
  final config = ref.watch(serverConfigProvider);
  return config.value;
}

/// Manages the "allow self-signed certificates" setting.
/// When enabled, Dio will accept invalid/self-signed TLS certificates.
class AllowSelfSignedCertNotifier extends AsyncNotifier<bool> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<bool> build() async {
    try {
      final value = await _storage.read(key: _allowSelfSignedCertKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> toggle(bool value) async {
    state = AsyncData(value);
    try {
      await _storage.write(
        key: _allowSelfSignedCertKey,
        value: value.toString(),
      );
    } catch (_) {
      // Ignore storage errors
    }
  }
}

final allowSelfSignedCertProvider =
    AsyncNotifierProvider<AllowSelfSignedCertNotifier, bool>(
      AllowSelfSignedCertNotifier.new,
    );
class CustomHeader {
  final String key;
  final String value;
  const CustomHeader({required this.key, required this.value});
  Map<String, String> toJson() => {'key': key, 'value': value};
  factory CustomHeader.fromJson(Map<String, dynamic> json) =>
      CustomHeader(key: json['key'] as String, value: json['value'] as String);
  CustomHeader copyWith({String? key, String? value}) =>
      CustomHeader(key: key ?? this.key, value: value ?? this.value);
}
class CustomHeadersNotifier extends AsyncNotifier<List<CustomHeader>> {
  final _storage = const FlutterSecureStorage();
  @override
  Future<List<CustomHeader>> build() async {
    try {
      final raw = await _storage.read(key: _customHeadersKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CustomHeader.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
  Future<void> _persist(List<CustomHeader> headers) async {
    try {
      final encoded = jsonEncode(headers.map((h) => h.toJson()).toList());
      await _storage.write(key: _customHeadersKey, value: encoded);
    } catch (_) {
      // Ignore storage errors
    }
  }
  Future<void> addHeader(CustomHeader header) async {
    final current = state.value ?? [];
    if (current.length >= maxCustomHeaders) return;
    final updated = [...current, header];
    state = AsyncData(updated);
    await _persist(updated);
  }
  Future<void> updateHeader(int index, CustomHeader header) async {
    final current = List<CustomHeader>.from(state.value ?? []);
    if (index < 0 || index >= current.length) return;
    current[index] = header;
    state = AsyncData(current);
    await _persist(current);
  }
  Future<void> removeHeader(int index) async {
    final current = List<CustomHeader>.from(state.value ?? []);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    state = AsyncData(current);
    await _persist(current);
  }
  Future<void> setHeaders(List<CustomHeader> headers) async {
    final limited = headers.take(maxCustomHeaders).toList();
    state = AsyncData(limited);
    await _persist(limited);
  }
}
final customHeadersProvider =
    AsyncNotifierProvider<CustomHeadersNotifier, List<CustomHeader>>(
      CustomHeadersNotifier.new,
    );