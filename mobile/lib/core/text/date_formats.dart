import 'dart:ui';

import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

String get dateLocale => dateLocaleOf(
  appLocaleFor(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  ),
);

/// The closest locale intl has dates for: `de` for `de_DE`, which it lacks.
String dateLocaleOf(Locale locale) => [
  locale.toString(),
  locale.languageCode,
].firstWhere(DateFormat.localeExists, orElse: () => 'en');

String clockLabel(DateTime time, {bool? is24Hour}) =>
    ((is24Hour ?? PlatformDispatcher.instance.alwaysUse24HourFormat)
            ? DateFormat.Hm(dateLocale)
            : DateFormat.jm(dateLocale))
        .format(time);
