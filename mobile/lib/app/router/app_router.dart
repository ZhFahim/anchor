import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/server_config_provider.dart';
import '../../core/search/search_pattern.dart';
import '../../features/auth/domain/magic_link.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/debug_recorder/data/debug_route_observer.dart';
import '../../features/note_locks/presentation/note_lock_gate.dart';
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
    observers: [DebugRouteObserver()],
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: AppRoutes.serverConfig,
        builder: (context, state) {
          // The server in use (from sign in), or a magic link.
          final extra = state.extra;
          return ServerConfigScreen(
            initialUrl: extra is String ? extra : null,
            magicLink: extra is MagicLink ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(
            path: _newNotePath,
            pageBuilder: (context, state) => NoteMorphPage(
              key: const ValueKey('note/new'),
              child: NoteEditScreen(
                // "New list", from holding the New note button.
                startAsChecklist:
                    state.uri.queryParameters[AppRoutes.checklistParameter] ==
                    '1',
                // Double-tapping New note pastes the clipboard into it.
                pasteClipboard:
                    state.uri.queryParameters[AppRoutes.pasteParameter] == '1',
                // "Camera note", from holding the New note button.
                takePicture:
                    state.uri.queryParameters[AppRoutes.cameraParameter] == '1',
              ),
            ),
          ),
          GoRoute(
            path: _notePath,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'];
              // The list passes the note; Undo of its trash, the caret.
              final extra = state.extra;
              final note = extra is Note ? extra : null;
              return NoteMorphPage(
                key: ValueKey('note/$id'),
                noteId: id,
                backgroundId: note?.background,
                // A locked note opens only once unlocked.
                child: NoteLockGate(
                  noteId: id!,
                  note: note,
                  child: NoteEditScreen(
                    noteId: id,
                    note: note,
                    searchTerm:
                        state.uri.queryParameters[AppRoutes.searchParameter],
                    searchOptions: SearchOptions.fromQueryParameters(
                      state.uri.queryParameters,
                    ),
                    caret: extra is NoteCaret ? extra : null,
                  ),
                ),
              );
            },
            routes: [
              GoRoute(
                path: _historyPath,
                builder: (context, state) => NoteLockGate(
                  noteId: state.pathParameters['id']!,
                  child: NoteHistoryScreen(noteId: state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: _revisionPath,
                    builder: (context, state) => NoteLockGate(
                      noteId: state.pathParameters['id']!,
                      child: NoteRevisionScreen(
                        noteId: state.pathParameters['id']!,
                        revisionId: state.pathParameters['revisionId']!,
                      ),
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
            builder: (context, state) =>
                SettingsScreen(section: state.uri.queryParameters['section']),
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
            child: NoteEditScreen(
              startAsChecklist: state.uri.queryParameters['checklist'] == '1',
            ),
          );
        },
      ),
      GoRoute(
        path: _widgetNotePath,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return MaterialPage(
            key: ValueKey('widget-note/$id'),
            child: NoteLockGate(
              noteId: id!,
              child: NoteEditScreen(noteId: id),
            ),
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
