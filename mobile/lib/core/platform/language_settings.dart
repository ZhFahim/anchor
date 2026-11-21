import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../logging/app_logger.dart';
import '../logging/log_tags.dart';

abstract final class LanguageSettings {
  static const _channel = MethodChannel('anchor/language');

  /// False while the app has one language, or where the phone has no page.
  static final Future<bool> isAvailable = _isAvailable();

  static Future<bool> _isAvailable() async {
    if (AppLocalizations.supportedLocales.length < 2) return false;
    try {
      return await _channel.invokeMethod<bool>('canOpen') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('open');
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      AppLogger.instance.warn(
        LogTags.settings,
        'Opening the language page failed: ${e.code} ${e.message}',
      );
    }
  }
}
