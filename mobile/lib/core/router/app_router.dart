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
import '../app_initializer.dart';
import '../presentation/server_config_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/log_viewer_screen.dart';
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
    initialLocation: initialRoute,
    refreshListenable: listenable,
    debugLogDiagnostics: true,
    routes: [
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
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'];
              final note = state.extra as Note?;
              return MaterialPage(
                key: ValueKey('note/$id'),
                child: NoteEditScreen(noteId: id, note: note),
              );
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
              GoRoute(
                path: AppRoutes.viewLogs,
                builder: (context, state) => const LogViewerScreen(),
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
      GoRoute(
        path: AppRoutes.widgetNoteNew,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: ValueKey('widget-note-new/${state.uri.query}'),
            child: const NoteEditScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.widgetNote,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return MaterialPage(
            key: ValueKey('widget-note/$id'),
            child: NoteEditScreen(noteId: id),
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final configState = ref.read(serverConfigProvider);

      final isAuthLoading = authState.isLoading;
      final isConfigLoading = configState.isLoading;

      // While the initial state loads (local storage reads, no network) stay
      // on the pre-computed initial route. This also prevents redirecting
      // while a specialized loading state (like signing in) is active,
      // preserving user input on the screen.
      if (isAuthLoading || isConfigLoading) {
        return null;
      }

      final hasServerUrl = configState.value?.isNotEmpty == true;
      final isLoggedIn = authState.value != null;

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
      // Redirect login and register to home
      if (isLogin || isRegister) {
        return AppRoutes.home;
      }

      return null;
    },
  );
}
