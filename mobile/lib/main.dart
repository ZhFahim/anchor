import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'core/app_initializer.dart';
import 'core/network/connectivity_provider.dart';
import 'core/providers/active_user_id_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_worker.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/theme_preferences_controller.dart';

void main() async {
  await initializeApp();
  runApp(const ProviderScope(child: AnchorApp()));
}

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final userId = ref.read(activeUserIdProvider);
      if (userId != null) {
        ref.read(syncWorkerProvider).requestSync(immediate: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    ref.watch(syncManagerProvider);
    final userId = ref.watch(activeUserIdProvider);
    if (userId != null) {
      ref.watch(syncWorkerProvider);
    }

    return MaterialApp.router(
      title: 'Anchor Notes',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
    );
  }
}
