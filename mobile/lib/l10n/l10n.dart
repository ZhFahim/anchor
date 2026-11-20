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

/// Chinese is written in two scripts, and a phone that names only its region
/// still expects the script that region writes with.
const _traditionalChineseRegions = {'TW', 'HK', 'MO'};

/// The phone's first locale in a language the app has, region kept.
Locale appLocaleFor(List<Locale>? phone, Iterable<Locale> supported) {
  final language = basicLocaleListResolution(phone, supported).languageCode;
  final locale =
      phone?.where((locale) => locale.languageCode == language).firstOrNull ??
      Locale(language);
  if (language != 'zh') {
    return locale;
  }
  // Name the script so the lookup can tell the two Chinese translations apart.
  return Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode:
        locale.scriptCode ??
        (_traditionalChineseRegions.contains(locale.countryCode)
            ? 'Hant'
            : 'Hans'),
    countryCode: locale.countryCode,
  );
}

/// The phone's language, for text shown outside the app's screens.
AppLocalizations deviceL10n() => lookupAppLocalizations(
  appLocaleFor(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  ),
);
