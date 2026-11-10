import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import '../logging/log_tags.dart';
import '../storage/preferences_repository.dart';
import '../storage/secure_storage_provider.dart';
import '../storage/storage_keys.dart';
import 'custom_headers.dart';
import 'server_address.dart';

part 'server_config_provider.g.dart';

@Riverpod(keepAlive: true)
class ServerConfig extends _$ServerConfig {
  @override
  Future<String?> build() async {
    return ref.watch(secureStorageProvider).read(key: StorageKeys.serverUrl);
  }

  Future<void> setServerUrl(String url) async {
    final normalizedUrl = normalizeServerUrl(url) ?? url.trim();
    await ref
        .read(secureStorageProvider)
        .write(key: StorageKeys.serverUrl, value: normalizedUrl);
    state = AsyncData(normalizedUrl);
  }
}

@Riverpod(keepAlive: true)
String? serverUrl(Ref ref) {
  final config = ref.watch(serverConfigProvider);
  return config.value;
}

@Riverpod(keepAlive: true)
class AllowSelfSignedCert extends _$AllowSelfSignedCert {
  @override
  Future<bool> build() async {
    try {
      return await ref
          .watch(preferencesRepositoryProvider)
          .getAllowSelfSignedCert();
    } catch (error) {
      AppLogger.instance.warn(
        LogTags.settings,
        'Reading the self-signed setting failed',
        error: error,
      );
      return false;
    }
  }

  Future<void> toggle(bool value) async {
    state = AsyncData(value);
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setAllowSelfSignedCert(value);
    } catch (error) {
      AppLogger.instance.warn(
        LogTags.settings,
        'Saving the self-signed setting failed',
        error: error,
      );
    }
  }
}

@Riverpod(keepAlive: true)
class CustomHeaders extends _$CustomHeaders {
  @override
  Future<List<CustomHeader>> build() async {
    try {
      return await ref.watch(preferencesRepositoryProvider).getCustomHeaders();
    } catch (error) {
      AppLogger.instance.warn(
        LogTags.settings,
        'Reading the custom headers failed',
        error: error,
      );
      return const [];
    }
  }

  Future<void> set(List<CustomHeader> headers) async {
    state = AsyncData(headers);
    try {
      await ref.read(preferencesRepositoryProvider).setCustomHeaders(headers);
    } catch (error) {
      AppLogger.instance.warn(
        LogTags.settings,
        'Saving the custom headers failed',
        error: error,
      );
    }
  }
}
