import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/native_strings.dart';

const _rerun = 'Run dart run tool/native_strings.dart';

void main() {
  final arbs = readArbs(Directory('lib/l10n'));

  test('the text outside Flutter matches the ARB files', () {
    for (final MapEntry(key: path, value: text) in nativeStringFiles(
      arbs,
    ).entries) {
      expect(File(path).readAsStringSync(), text, reason: '$path. $_rerun');
    }
    expect(staleAndroidFiles(arbs), isEmpty, reason: _rerun);
  });

  test('iOS lists the same languages and English prompts as the ARBs', () {
    final locales = localesOf(arbs);
    final plist = File(infoPlistPath).readAsStringSync();
    expect(
      withPlistStrings(plist, locales, arbs['en']!),
      plist,
      reason: _rerun,
    );
    final project = File(xcodeProjectPath).readAsStringSync();
    expect(withKnownRegions(project, locales), project, reason: _rerun);
    expect(project, contains('InfoPlist.xcstrings in Resources'));
  });

  test('Android names each language folder the way it reads it', () {
    expect(androidFolderOf('en'), 'values');
    expect(androidFolderOf('de'), 'values-de');
    expect(androidFolderOf('pt_BR'), 'values-pt-rBR');
    expect(androidFolderOf('zh_Hans'), 'values-b+zh+Hans');
    expect(languageTagOf('pt_BR'), 'pt-BR');
  });

  test('Android text is escaped the way its resources read it', () {
    final xml = androidStrings({
      'nativeWidgetEmpty': "It's <new>\n& \"ready\"",
      'nativeWidgetLabel': '@home',
    }, isSource: false);
    expect(
      xml,
      contains(
        r'''<string name="widget_empty">It\'s &lt;new&gt;\n&amp; \"ready\"</string>''',
      ),
    );
    expect(xml, contains(r'<string name="widget_label">\@home</string>'));
    expect(xml, isNot(contains('app_name')));
  });

  Map<String, Object?> catalogOf(Map<String, Map<String, Object?>> arbs) =>
      (jsonDecode(shareExtensionStrings(arbs))
              as Map<String, Object?>)['strings']!
          as Map<String, Object?>;

  Map<String, Object?> english(Map<String, Object?> overrides) => {
    for (final key in shareExtensionKeys) key: key,
    ...overrides,
  };

  test('plurals become String Catalog variations', () {
    final strings = catalogOf({
      'en': english({
        'shareTooBig':
            '{count, plural, =1{1 file is too big.} other{{count} files are '
            'too big.}}',
      }),
    });
    expect((strings['shareTooBig']! as Map)['localizations'], {
      'en': {
        'variations': {
          'plural': {
            'one': {
              'stringUnit': {
                'state': 'translated',
                'value': '1 file is too big.',
              },
            },
            'other': {
              'stringUnit': {
                'state': 'translated',
                'value': r'%1$lld files are too big.',
              },
            },
          },
        },
      },
    });
  });

  test('a translation may move a placeholder and keeps its number', () {
    final strings = catalogOf({
      'en': english({'shareTag': 'Tag {name}'}),
      'pt_BR': {'shareTag': '{name}: etiqueta'},
    });
    final localizations = (strings['shareTag']! as Map)['localizations'] as Map;
    expect(localizations['en'], {
      'stringUnit': {'state': 'translated', 'value': r'Tag %1$@'},
    });
    expect(localizations['pt-BR'], {
      'stringUnit': {'state': 'translated', 'value': r'%1$@: etiqueta'},
    });
  });

  test('a language without a translation gets the English text', () {
    final strings = catalogOf({
      'en': english({'shareTag': 'Tag {name}', 'commonSave': 'Save'}),
      'de': {'commonSave': 'Speichern'},
    });
    Object? german(String key) =>
        ((strings[key]! as Map)['localizations'] as Map)['de'];
    expect(german('commonSave'), {
      'stringUnit': {'state': 'translated', 'value': 'Speichern'},
    });
    expect(german('shareTag'), {
      'stringUnit': {'state': 'translated', 'value': r'Tag %1$@'},
    });
  });
}
