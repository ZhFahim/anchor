import 'package:anchor/core/text/date_formats.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dates use the phone region when intl has it', () {
    expect(dateLocaleOf(const Locale('en', 'GB')), 'en_GB');
    expect(dateLocaleOf(const Locale('pt', 'BR')), 'pt_BR');
  });

  test('dates fall back to the language, not English', () {
    expect(dateLocaleOf(const Locale('de', 'DE')), 'de');
    expect(dateLocaleOf(const Locale('fr', 'FR')), 'fr');
    expect(
      dateLocaleOf(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      ),
      'zh',
    );
  });

  test('a language intl has no dates for uses English', () {
    expect(dateLocaleOf(const Locale('tlh')), 'en');
  });
}
