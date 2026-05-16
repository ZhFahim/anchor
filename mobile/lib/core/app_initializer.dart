import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'logging/app_logger.dart';

const _themeModeKey = 'theme_mode';
const _storage = FlutterSecureStorage();

/// Holds the initial theme mode loaded before the app starts
/// This is set by [initializeApp] and read by the theme provider
ThemeMode initialThemeMode = ThemeMode.system;

/// Holds the initial user ID loaded before the app starts
/// This is set by [initializeApp] and read by [ActiveUserId] provider
String? initialUserId;

/// Load app initialization data before the app starts
/// This prevents theme flash and other initialization issues
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.instance.init();
  await _logSessionHeader();
  FlutterError.onError = (details) {
    AppLogger.instance.error(
      'FlutterError',
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'PlatformError',
      error.toString(),
      error: error,
      stackTrace: stack,
    );
    return false;
  };

  // Load saved theme preference
  final savedTheme = await _storage.read(key: _themeModeKey);
  if (savedTheme != null) {
    initialThemeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
  }

  // Load saved user ID for per-user database selection
  initialUserId = await _storage.read(key: 'user_id');
}

/// Logs a one-line environment summary so copied logs always include
/// app version, platform, and timezone — vital context for bug reports.
Future<void> _logSessionHeader() async {
  String version = 'unknown';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } catch (_) {
    // PackageInfo may not be available on all platforms; fall through.
  }

  final platform = _describePlatform();
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hh = offset.inHours.abs().toString().padLeft(2, '0');
  final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

  AppLogger.instance.info(
    'App',
    '=== Session start: v$version, $platform, '
        'tz=${now.timeZoneName} (UTC$sign$hh:$mm), locale=${Platform.localeName} ===',
  );
}

String _describePlatform() {
  try {
    if (Platform.isAndroid) {
      return 'Android (${Platform.operatingSystemVersion})';
    }
    if (Platform.isIOS) return 'iOS (${Platform.operatingSystemVersion})';
    if (Platform.isMacOS) return 'macOS (${Platform.operatingSystemVersion})';
    if (Platform.isWindows) {
      return 'Windows (${Platform.operatingSystemVersion})';
    }
    if (Platform.isLinux) return 'Linux (${Platform.operatingSystemVersion})';
    return '${Platform.operatingSystem} (${Platform.operatingSystemVersion})';
  } catch (_) {
    return 'unknown platform';
  }
}
