import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/server_config_provider.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/notes/domain/note.dart';
import '../../features/notes/presentation/note_edit_screen.dart';
import '../../features/notes/presentation/note_folder.dart';
import '../../features/notes/presentation/note_history_screen.dart';
import '../../features/notes/presentation/note_morph_route.dart';
import '../../features/notes/presentation/note_revision_screen.dart';
import '../../features/notes/presentation/notes_list_screen.dart';
import '../../features/server/presentation/server_config_screen.dart';
import '../../features/settings/presentation/log_viewer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../app_bootstrap.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

const _notePath = 'note/:id';
const _newNotePath = 'note/new';
const _historyPath = 'history';
const _revisionPath = ':revisionId';
const _trashPath = 'trash';
const _archivePath = 'archive';
const _settingsPath = 'settings';
const _changePasswordPath = 'change-password';
const _editProfilePath = 'edit-profile';
const _logsPath = 'logs';
const _widgetNotePath = '/widget/note/:id';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  final authStateNotifier = ValueNotifier<AsyncValue<void>>(
    const AsyncLoading(),
  );
  final configStateNotifier = ValueNotifier<AsyncValue<void>>(
    const AsyncLoading(),
  );

  ref.listen(
    authControllerProvider,
    (_, next) => authStateNotifier.value = next,
  );
  ref.listen(
    serverConfigProvider,
    (_, next) => configStateNotifier.value = next,
  );

  String showFolder(NoteFolder folder) {
    ref.read(noteFolderProvider.notifier).go(folder);
    return AppRoutes.home;
  }

  final listenable = Listenable.merge([authStateNotifier, configStateNotifier]);

  ref.onDispose(() {
    authStateNotifier.dispose();
    configStateNotifier.dispose();
  });

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: ref.read(appBootstrapProvider).initialRoute,
    refreshListenable: listenable,
    debugLogDiagnostics: kDebugMode,
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
            path: _newNotePath,
            pageBuilder: (context, state) => NoteMorphPage(
              key: ValueKey(
                'note/new/${state.uri.queryParameters['type'] ?? 'note'}',
              ),
              child: NoteEditScreen(
                newNoteType: NoteType.fromString(
                  state.uri.queryParameters['type'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: _notePath,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'];
              final note = state.extra as Note?;
              return NoteMorphPage(
                key: ValueKey('note/$id'),
                noteId: id,
                backgroundId: note?.background,
                child: NoteEditScreen(noteId: id, note: note),
              );
            },
            routes: [
              GoRoute(
                path: _historyPath,
                builder: (context, state) =>
                    NoteHistoryScreen(noteId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: _revisionPath,
                    builder: (context, state) => NoteRevisionScreen(
                      noteId: state.pathParameters['id']!,
                      revisionId: state.pathParameters['revisionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: _trashPath,
            redirect: (_, _) => showFolder(NoteFolder.trash),
          ),
          GoRoute(
            path: _archivePath,
            redirect: (_, _) => showFolder(NoteFolder.archive),
          ),
          GoRoute(
            path: _settingsPath,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: _changePasswordPath,
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: _editProfilePath,
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: _logsPath,
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
        path: AppRoutes.widgetNewNote,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: ValueKey('widget-note-new/${state.uri.query}'),
            child: const NoteEditScreen(),
          );
        },
      ),
      GoRoute(
        path: _widgetNotePath,
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

      if (isAuthLoading || isConfigLoading) {
        return null;
      }

      final hasServerUrl = configState.value?.isNotEmpty == true;
      final isLoggedIn = authState.value != null;

      final isServerConfig = state.matchedLocation == AppRoutes.serverConfig;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;

      if (!hasServerUrl) {
        return isServerConfig ? null : AppRoutes.serverConfig;
      }

      if (!isLoggedIn) {
        if (isLogin || isRegister || isServerConfig) {
          return null;
        }
        return AppRoutes.login;
      }

      if (isLogin || isRegister) {
        return AppRoutes.home;
      }

      return null;
    },
  );
}
