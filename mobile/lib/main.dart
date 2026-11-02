import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_bootstrap.dart';
import 'app/bootstrap.dart';
import 'app/router/app_router.dart';
import 'core/motion/springs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/style_typography.dart';
import 'core/update/app_updater.dart';
import 'features/auth/presentation/magic_link_handler.dart';
import 'features/debug_recorder/data/debug_state_observer.dart';
import 'features/debug_recorder/presentation/debug_recorder_host.dart';
import 'features/home_widget/data/home_widget_service.dart';
import 'features/note_locks/data/note_lock_secrets.dart';
import 'features/note_locks/presentation/note_lock_session.dart';
import 'features/reminders/data/reminder_background_check.dart';
import 'features/reminders/data/reminder_scheduler.dart';
import 'features/reminders/presentation/reminder_tap_handler.dart';
import 'features/settings/presentation/editor_preferences_controller.dart';
import 'features/settings/presentation/theme_preferences_controller.dart';
import 'features/share_target/data/share_target_service.dart';
import 'features/share_target/presentation/share_sheet_app.dart';
import 'features/sync/data/sync_manager.dart';
import 'l10n/l10n.dart';

void main() async {
  final bootstrap = await initializeApp();
  runApp(
    ProviderScope(
      overrides: [appBootstrapProvider.overrideWithValue(bootstrap)],
      observers: const [DebugStateObserver()],
      child: const AnchorApp(),
    ),
  );
}

/// The sheet Android shows when another app shares to Anchor.
@pragma('vm:entry-point')
Future<void> shareMain() => runShareSheet();

class AnchorApp extends ConsumerStatefulWidget {
  const AnchorApp({super.key});

  @override
  ConsumerState<AnchorApp> createState() => _AnchorAppState();
}

class _AnchorAppState extends ConsumerState<AnchorApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final density = ref.watch(displayDensityControllerProvider);
    final scheme = ref.watch(colorSchemeControllerProvider);
    final style = ref.watch(appStyleControllerProvider);
    final customTheme = ref.watch(customThemeControllerProvider);
    final (font, textSize) = ref.watch(
      editorPreferencesControllerProvider.select(
        (editor) => (editor.noteFont, editor.noteTextSize),
      ),
    );

    ref.watch(syncManagerProvider);
    ref.watch(homeWidgetSyncProvider);
    ref.watch(homeWidgetLaunchHandlerProvider);
    ref.watch(magicLinkHandlerProvider);
    // Look for a newer release of the fork when the app starts.
    ref.watch(updateControllerProvider);
    ref.watch(reminderSchedulerProvider);
    // Picks up reminders set elsewhere while the app is closed.
    ref.watch(reminderBackgroundCheckProvider);
    ref.watch(reminderTapHandlerProvider);
    ref.watch(shareImportProvider);
    ref.watch(shareContextSyncProvider);
    // Unlocked notes lock again when the screen turns off. Listened to, not
    // watched: unlocking a note mustn't rebuild the app.
    ref.listen(noteLockSessionProvider, (_, _) {});
    // Keep this device's copy of the PIN and pattern current.
    ref.listen(noteLockSecretsControllerProvider, (_, _) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light(
        density,
        font,
        textSize,
        scheme,
        style,
        customTheme,
      ),
      darkTheme: AppTheme.dark(
        density,
        font,
        textSize,
        scheme,
        style,
        customTheme,
      ),
      themeMode: themeMode,
      themeAnimationStyle: isSystemMotionReduced
          ? AnimationStyle.noAnimation
          : null,
      routerConfig: router,
      builder: (context, child) => StyleTypography(
        style: style,
        // Debug mode: hold two fingers still for 3 s to film the app.
        child: DebugRecorderHost(child: BackdropGroup(child: child!)),
      ),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: appLocaleFor,
    );
  }
}
