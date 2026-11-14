import 'dart:convert';
import 'dart:io';

import 'package:anchor/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));

  test('counts read naturally in English', () {
    expect(
      english.settingsSignOutMessage(0),
      startsWith('Your notes stay on this phone'),
    );
    expect(
      english.settingsSignOutMessage(1),
      startsWith('1 change hasn’t synced yet. It '),
    );
    expect(
      english.settingsSignOutMessage(3),
      startsWith('3 changes haven’t synced yet. They '),
    );
    expect(english.logsCopied(1), '1 log copied');
    expect(english.logsCopied(4), '4 logs copied');
    expect(english.passwordHelp(8), 'At least 8 characters.');
  });

  final arb =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final messages = [
    for (final key in arb.keys)
      if (!key.startsWith('@')) key,
  ];

  test('the app name is Notesx', () {
    expect(english.appName, 'Notesx');
  });

  test('messages use no em or en dashes', () {
    final dashed = [
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') &&
            value is String &&
            value.contains(RegExp('[–—]')))
          key,
    ];
    expect(dashed, isEmpty);
  });

  test('every message tells translators where it shows', () {
    final undescribed = messages.where((key) {
      final meta = arb['@$key'] as Map<String, dynamic>?;
      final note = meta?['description'] as String?;
      return note == null || note.isEmpty;
    });
    expect(undescribed, isEmpty);
  });

  test('the app keeps the phone\'s region for a language it has', () {
    const supported = [Locale('en')];

    expect(
      appLocaleFor(const [Locale('en', 'GB')], supported),
      const Locale('en', 'GB'),
    );
    expect(
      appLocaleFor(const [Locale('fr', 'FR'), Locale('en', 'AU')], supported),
      const Locale('en', 'AU'),
    );
    expect(
      appLocaleFor(const [Locale('fr', 'FR')], supported),
      const Locale('en'),
    );
    expect(appLocaleFor(null, supported), const Locale('en'));
  });
}
