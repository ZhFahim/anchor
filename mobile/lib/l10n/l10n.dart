import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10n on BuildContext {
  /// English when the app's localizations aren't set up.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _english;
}

final _english = lookupAppLocalizations(const Locale('en'));

/// Joins words with this language's punctuation.
extension Joining on AppLocalizations {
  String joinSentences(Iterable<String> parts) => parts.join(sentenceSeparator);

  String joinList(Iterable<String> parts) => parts.join(listSeparator);

  String joinDetails(Iterable<String> parts) => parts.join(detailSeparator);
}

/// The phone's first locale in a language the app has, region kept.
Locale appLocaleFor(List<Locale>? phone, Iterable<Locale> supported) {
  final language = basicLocaleListResolution(phone, supported).languageCode;
  return phone
          ?.where((locale) => locale.languageCode == language)
          .firstOrNull ??
      Locale(language);
}

/// The phone's language, for text shown outside the app's screens.
AppLocalizations deviceL10n() => lookupAppLocalizations(
  basicLocaleListResolution(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  ),
);
