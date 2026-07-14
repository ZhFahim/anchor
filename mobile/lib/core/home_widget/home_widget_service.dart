import 'dart:async';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notes/data/repository/notes_repository.dart';
import '../logging/app_logger.dart';
import '../providers/active_user_id_provider.dart';
import '../router/app_router.dart';
import 'home_widget_payload.dart';

part 'home_widget_service.g.dart';

const _widgetProviderQualifiedName =
    'com.zhfahim.anchor.widget.NotesWidgetProvider';

const _widgetUriScheme = 'anchorwidget';

/// Mirrors the active notes list into the Android home-screen widget.
///
/// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
/// every local notes change (edits, sync results) via the drift stream and to
/// login/logout via the active user id.
@Riverpod(keepAlive: true)
class HomeWidgetSync extends _$HomeWidgetSync {
  Timer? _debounce;

  @override
  void build() {
    if (!Platform.isAndroid) return;

    // Wait for auth to resolve; a transient null user at startup would push a
    // logged-out payload that sticks if the app is killed mid-load.
    if (ref.watch(authControllerProvider).isLoading) return;

    final userId = ref.watch(activeUserIdProvider);
    if (userId == null) {
      _push(buildHomeWidgetPayload(const [], loggedIn: false));
      return;
    }

    final subscription = ref
        .watch(notesRepositoryProvider)
        .watchNotes()
        .listen((notes) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            _push(buildHomeWidgetPayload(notes, loggedIn: true));
          });
        });

    ref.onDispose(() {
      _debounce?.cancel();
      subscription.cancel();
    });
  }

  Future<void> _push(String payload) async {
    try {
      await HomeWidget.saveWidgetData<String>(homeWidgetNotesKey, payload);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _widgetProviderQualifiedName,
      );
    } catch (e, stack) {
      AppLogger.instance.error(
        'HomeWidget',
        'Failed to push widget data',
        error: e,
        stackTrace: stack,
      );
    }
  }
}

/// Routes home-screen widget taps into the app:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
@Riverpod(keepAlive: true)
class HomeWidgetLaunchHandler extends _$HomeWidgetLaunchHandler {
  String? _pendingRoute;

  @override
  void build() {
    if (!Platform.isAndroid) return;

    HomeWidget.initiallyLaunchedFromHomeWidget().then(_queue);
    final subscription = HomeWidget.widgetClicked.listen(_queue);
    ref.onDispose(subscription.cancel);

    // Cold-start launch URIs arrive before auth settles; hold and flush then.
    ref.listen(authControllerProvider, (_, _) => _flush());
  }

  void _queue(Uri? uri) {
    final route = homeWidgetRouteForUri(uri);
    if (route == null) return;
    _pendingRoute = route;
    _flush();
  }

  void _flush() {
    final route = _pendingRoute;
    if (route == null) return;
    if (ref.read(authControllerProvider).isLoading) return;

    _pendingRoute = null;
    // No active user: let the normal config/login flow take over.
    if (ref.read(activeUserIdProvider) == null) return;

    ref.read(goRouterProvider).go(route);
  }
}

/// Maps a widget launch URI to a router location, or null to ignore it.
String? homeWidgetRouteForUri(Uri? uri) {
  if (uri == null || uri.scheme != _widgetUriScheme) return null;
  if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
    final target = uri.pathSegments.first;
    return target == 'new' ? '/note/new' : '/note/$target';
  }
  return '/';
}
