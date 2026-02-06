import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/notes/domain/note.dart';
import '../../features/notes/presentation/notes_list_screen.dart';
import '../../features/notes/presentation/note_edit_screen.dart';
import '../../features/notes/presentation/trash_screen.dart';
import '../../features/notes/presentation/archive_screen.dart';
import '../presentation/splash_screen.dart';
import '../presentation/server_config_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../network/server_config_provider.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  // Create listenables for auth and config state
  final authStateNotifier = ValueNotifier<AsyncValue<void>>(
    const AsyncLoading(),
  );
  final configStateNotifier = ValueNotifier<AsyncValue<void>>(
    const AsyncLoading(),
  );

  // Update notifiers when providers change
  ref.listen(
    authControllerProvider,
    (_, next) => authStateNotifier.value = next,
  );
  ref.listen(
    serverConfigProvider,
    (_, next) => configStateNotifier.value = next,
  );

  // Merge listenables to trigger router refresh
  final listenable = Listenable.merge([authStateNotifier, configStateNotifier]);

  // Clean up notifiers when the provider is disposed
  ref.onDispose(() {
    authStateNotifier.dispose();
    configStateNotifier.dispose();
  });

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.serverConfig,
        builder: (context, state) {
          final initialUrl = state.extra as String?;
          return ServerConfigScreen(initialUrl: initialUrl);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.noteNew,
            builder: (context, state) => const NoteEditScreen(),
          ),
          GoRoute(
            path: AppRoutes.noteEdit,
            builder: (context, state) {
              final id = state.pathParameters['id'];
              final note = state.extra as Note?;
              return NoteEditScreen(noteId: id, note: note);
            },
          ),
          GoRoute(
            path: AppRoutes.trash,
            builder: (context, state) => const TrashScreen(),
          ),
          GoRoute(
            path: AppRoutes.archive,
            builder: (context, state) => const ArchiveScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.changePassword,
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: AppRoutes.editProfile,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final configState = ref.read(serverConfigProvider);

      final isAuthLoading = authState.isLoading;
      final isConfigLoading = configState.isLoading;

      // If still loading initial state, stay on splash.
      // This also prevents redirecting while a specialized loading state
      // (like signing in) is active, preserving user input on the screen.
      if (isAuthLoading || isConfigLoading) {
        return null;
      }

      final hasServerUrl = configState.value?.isNotEmpty == true;
      final isLoggedIn = authState.value != null;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isServerConfig = state.matchedLocation == AppRoutes.serverConfig;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;

      // 1. Server Config Check
      if (!hasServerUrl) {
        return isServerConfig ? null : AppRoutes.serverConfig;
      }

      // 2. Auth Check
      if (!isLoggedIn) {
        // Allow login, register, and server config screens
        if (isLogin || isRegister || isServerConfig) {
          return null;
        }
        return AppRoutes.login;
      }

      // 3. Logged In
      // Redirect splash, login, register to home
      if (isSplash || isLogin || isRegister) {
        return AppRoutes.home;
      }

      return null;
    },
  );
}
