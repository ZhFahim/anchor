import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/logging/app_logger.dart';
import '../core/logging/log_tags.dart';
import '../core/motion/motion_speed.dart';
import '../core/storage/clear_storage_on_new_install.dart';
import '../core/storage/preferences_repository.dart';
import '../core/storage/storage_keys.dart';
import '../core/theme/display_density.dart';
import '../core/theme/note_typography.dart';
import '../features/home_widget/data/home_widget_payload.dart';
import '../features/reminders/presentation/notification_launch.dart';
import '../features/settings/domain/editor_preferences.dart';
import '../features/settings/presentation/motion_speed_controller.dart';
import 'app_bootstrap.dart';
import 'router/app_routes.dart';

/// Reads what the first frame needs from local storage, never the network.
Future<AppBootstrap> initializeApp({
  FlutterSecureStorage storage = const FlutterSecureStorage(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  // DateFormat with a locale throws until this has run.
  await initializeDateFormatting();

  await AppLogger.instance.init();
  await _logSessionHeader();
  FlutterError.onError = (details) {
    AppLogger.instance.error(
      LogTags.flutterError,
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      LogTags.platformError,
      error.toString(),
      error: error,
      stackTrace: stack,
    );
    return false;
  };

  if (Platform.isIOS) {
    try {
      final support = await getApplicationSupportDirectory();
      await clearStorageOnNewInstall(
        storage,
        File(p.join(support.path, 'installed')),
      );
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.app,
        'Install marker failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  final preferences = PreferencesRepository(storage);
  final savedTheme = await preferences.getThemeMode();
  final themeMode = ThemeMode.values.firstWhere(
    (mode) => mode.name == savedTheme,
    orElse: () => ThemeMode.system,
  );

  final savedDensity = await preferences.getDisplayDensity();
  final displayDensity = DisplayDensity.values.firstWhere(
    (density) => density.name == savedDensity,
    orElse: () => DisplayDensity.standard,
  );

  final savedFont = await preferences.getNoteFont();
  final savedTextSize = await preferences.getNoteTextSize();
  final editorPreferences = EditorPreferences(
    sortChecklistItems: await preferences.getSortChecklistItems(),
    noteFont: NoteFont.values.firstWhere(
      (font) => font.name == savedFont,
      orElse: () => NoteFont.sans,
    ),
    noteTextSize: savedTextSize,
  );

  String? userId;
  final userData = await storage.read(key: StorageKeys.userData);
  if (userData != null) {
    try {
      userId = (jsonDecode(userData) as Map<String, dynamic>)['id'] as String?;
    } catch (_) {
      AppLogger.instance.warn(LogTags.app, 'Saved user could not be read');
    }
  }

  // Registers notifications on every launch, whatever route the app opens on.
  final notificationRoute = await _notificationLaunchRoute();

  final serverUrl = await storage.read(key: StorageKeys.serverUrl);
  final accessToken = await storage.read(key: StorageKeys.accessToken);
  final String initialRoute;
  if (serverUrl == null || serverUrl.isEmpty) {
    initialRoute = AppRoutes.serverConfig;
  } else if (accessToken == null) {
    initialRoute = AppRoutes.login;
  } else {
    initialRoute =
        notificationRoute ?? await _widgetLaunchRoute() ?? AppRoutes.home;
  }

  final motionSpeed = motionSpeedFromName(
    await preferences.getMotionSpeedName(),
  );
  MotionSpeed.current = motionSpeed;

  return AppBootstrap(
    themeMode: themeMode,
    displayDensity: displayDensity,
    appLockEnabled: await preferences.getAppLockEnabled(),
    lockGraceMinutes: await preferences.getLockGraceMinutes(),
    lastUnlockedAt: await preferences.getLastUnlockedAt(),
    motionSpeed: motionSpeed,
    editorPreferences: editorPreferences,
    foldedChecklistNotes: await preferences.getFoldedChecklistNotes(),
    openArchivedTags: await preferences.getOpenArchivedTags(),
    userId: userId,
    initialRoute: initialRoute,
  );
}

Future<String?> _notificationLaunchRoute() async {
  try {
    return await initializeNotifications();
  } catch (error, stack) {
    AppLogger.instance.error(
      LogTags.app,
      'Notification init failed',
      error: error,
      stackTrace: stack,
    );
    return null;
  }
}

Future<String?> _widgetLaunchRoute() async {
  if (!Platform.isAndroid) return null;
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    return homeWidgetRouteForUri(uri);
  } catch (_) {
    return null;
  }
}

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
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

  AppLogger.instance.info(
    LogTags.app,
    '=== Session start: v$version, $platform, '
    'tz=${now.timeZoneName} (UTC$sign$hours:$minutes), locale=${Platform.localeName} ===',
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
