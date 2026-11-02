import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/router/app_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/l10n.dart';
import '../domain/magic_link.dart';
import 'auth_controller.dart';

part 'magic_link_handler.g.dart';

/// Talks to MainActivity, which keeps the anchorplus://magic-login link the
/// app was opened with.
const _channel = MethodChannel('anchor/magic_link');

/// A magic link opened on this phone (from the web's Settings, through its
/// /magic-login page) signs in on the server screen, which shows how it
/// goes. Someone already signed in is told so instead.
@Riverpod(keepAlive: true)
class MagicLinkHandler extends _$MagicLinkHandler {
  @override
  void build() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'link') await _take();
    });
    ref.onDispose(() => _channel.setMethodCallHandler(null));
    _take();
  }

  Future<void> _take() async {
    final String? text;
    try {
      text = await _channel.invokeMethod<String>('takeLink');
    } on MissingPluginException {
      return; // Not on Android.
    } on PlatformException catch (e) {
      AppLogger.instance.warn(LogTags.auth, 'Magic link unknown: $e');
      return;
    }
    if (text == null) return;
    final link = MagicLink.parse(text);
    if (link == null) {
      AppLogger.instance.warn(LogTags.auth, 'Not a magic link');
      return;
    }
    AppLogger.instance.info(LogTags.auth, 'Opened with a magic link');

    // Startup reads who is signed in first.
    final user = await ref
        .read(authControllerProvider.future)
        .catchError((Object _) => null);
    if (!ref.mounted) return;
    final router = ref.read(goRouterProvider);
    if (user != null) {
      final context = router.routerDelegate.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppSnackbar.show(context, context.l10n.magicLoginAlreadySignedIn);
      }
      return;
    }
    router.go(AppRoutes.serverConfig, extra: link);
  }
}
