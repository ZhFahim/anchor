import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/motion/motion_speed.dart';
import '../core/theme/display_density.dart';
import '../features/settings/domain/editor_preferences.dart';
import 'router/app_routes.dart';

part 'app_bootstrap.g.dart';

class AppBootstrap {
  const AppBootstrap({
    this.themeMode = ThemeMode.system,
    this.displayDensity = DisplayDensity.standard,
    this.appLockEnabled = false,
    this.lockGraceMinutes = 5,
    this.lastUnlockedAt,
    this.motionSpeed = MotionSpeed.slow,
    this.editorPreferences = const EditorPreferences(),
    this.foldedChecklistNotes = const [],
    this.openArchivedTags = const [],
    this.userId,
    this.initialRoute = AppRoutes.home,
  });

  final ThemeMode themeMode;
  final DisplayDensity displayDensity;
  final bool appLockEnabled;
  final int lockGraceMinutes;
  final DateTime? lastUnlockedAt;
  final MotionSpeed motionSpeed;
  final EditorPreferences editorPreferences;

  final List<String> foldedChecklistNotes;
  final List<String> openArchivedTags;
  final String? userId;
  final String initialRoute;
}

/// Overridden in `main` with what `initializeApp` read.
@Riverpod(keepAlive: true)
AppBootstrap appBootstrap(Ref ref) => const AppBootstrap();
