import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'home_widget/home_widget_payload.dart';
import 'logging/app_logger.dart';
import 'router/app_routes.dart';

const _themeModeKey = 'theme_mode';
const _serverUrlKey = 'server_url';
const _accessTokenKey = 'access_token';
const _storage = FlutterSecureStorage();

/// Holds the initial theme mode loaded before the app starts
/// This is set by [initializeApp] and read by the theme provider
ThemeMode initialThemeMode = ThemeMode.system;

/// Holds the initial user ID loaded before the app starts
/// This is set by [initializeApp] and read by [ActiveUserId] provider
String? initialUserId;

/// The route the app starts on, decided from local storage alone so the
/// native splash hands off straight to the right screen.
String initialRoute = AppRoutes.home;

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

  // User id for per-user database selection, read from the persisted user json.
  final userData = await _storage.read(key: 'user_data');
  if (userData != null) {
    try {
      initialUserId =
          (jsonDecode(userData) as Map<String, dynamic>)['id'] as String?;
    } catch (_) {
      // Corrupt cache; treat as logged out until auth resolves.
    }
  }

  final serverUrl = await _storage.read(key: _serverUrlKey);
  final accessToken = await _storage.read(key: _accessTokenKey);
  if (serverUrl == null || serverUrl.isEmpty) {
    initialRoute = AppRoutes.serverConfig;
  } else if (accessToken == null) {
    initialRoute = AppRoutes.login;
  } else {
    initialRoute = await _widgetLaunchRoute() ?? AppRoutes.home;
  }
}

/// The route for a cold start from a home-widget tap, or null when the app
/// was launched normally.
Future<String?> _widgetLaunchRoute() async {
  if (!Platform.isAndroid) return null;
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    return homeWidgetRouteForUri(uri);
  } catch (_) {
    return null;
  }
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
