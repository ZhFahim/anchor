// Writes the text that lives outside Flutter from the app's ARB files:
//   dart run tool/native_strings.dart
// - the iPhone share extension's strings (ios/ShareExtension/Localizable.xcstrings)
// - the iPhone permission prompts (ios/Runner/InfoPlist.xcstrings)
// - the Android home screen widget's strings (res/values*/strings.xml)
// - the languages the phone offers for the app: Android's locales_config.xml,
//   iOS's CFBundleLocalizations and the Xcode project's known regions.

import 'dart:convert';
import 'dart:io';

const shareExtensionStringsPath = 'ios/ShareExtension/Localizable.xcstrings';
const infoPlistStringsPath = 'ios/Runner/InfoPlist.xcstrings';
const infoPlistPath = 'ios/Runner/Info.plist';
const xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
const androidResPath = 'android/app/src/main/res';
const androidLocalesPath = '$androidResPath/xml/locales_config.xml';

const shareExtensionKeys = [
  'shareSheetTitle',
  'noteTitleHint',
  'editorPlaceholder',
  'commonCancel',
  'commonSave',
  'commonClose',
  'shareSignIn',
  'shareNothing',
  'shareNotAdded',
  'shareUnsupported',
  'shareTooBig',
  'shareOverLimit',
  'shareRemoveItem',
  'shareTag',
];

const infoPlistKeys = {
  'NSAppleMusicUsageDescription': 'nativeMusicUse',
  'NSCameraUsageDescription': 'nativeCameraUse',
  'NSLocalNetworkUsageDescription': 'nativeLocalNetworkUse',
  'NSMicrophoneUsageDescription': 'nativeMicrophoneUse',
  'NSPhotoLibraryAddUsageDescription': 'nativePhotoLibraryAddUse',
  'NSPhotoLibraryUsageDescription': 'nativePhotoLibraryUse',
};

const androidKeys = {
  'widget_label': 'nativeWidgetLabel',
  'widget_description': 'nativeWidgetDescription',
  'widget_new_note': 'nativeWidgetNewNote',
  'widget_empty': 'nativeWidgetEmpty',
  'widget_logged_out': 'nativeWidgetSignedOut',
};

const androidBrandStrings = {
  'app_name': 'Anchor Notes',
  'widget_app_name': 'Anchor',
};

const _generatedMark = '<!-- Written by tool/native_strings.dart. -->';

typedef Arbs = Map<String, Map<String, Object?>>;

String languageTagOf(String locale) => locale.replaceAll('_', '-');

List<String> localesOf(Arbs arbs) => [
  'en',
  ...arbs.keys.where((locale) => locale != 'en').toList()..sort(),
];

Map<String, String> nativeStringFiles(Arbs arbs) => {
  shareExtensionStringsPath: shareExtensionStrings(arbs),
  infoPlistStringsPath: _catalog(arbs, infoPlistKeys),
  for (final locale in localesOf(arbs))
    if (locale == 'en' || androidKeys.values.any(arbs[locale]!.containsKey))
      '$androidResPath/${androidFolderOf(locale)}/strings.xml': androidStrings(
        arbs[locale]!,
        isSource: locale == 'en',
      ),
  androidLocalesPath: androidLocalesConfig(localesOf(arbs)),
};

String shareExtensionStrings(Arbs arbs) =>
    _catalog(arbs, {for (final key in shareExtensionKeys) key: key});

String _catalog(Arbs arbs, Map<String, String> keys) {
  final source = arbs['en']!;
  final strings = <String, Object?>{};
  for (final MapEntry(key: catalogKey, value: arbKey) in keys.entries) {
    final value = source[arbKey];
    if (value is! String) throw StateError('No $arbKey in app_en.arb');
    final meta = source['@$arbKey'];
    final description = meta is Map ? meta['description'] : null;
    final order = _placeholderOrder(value);
    strings[catalogKey] = {
      'comment': ?description,
      'extractionState': 'manual',
      'localizations': {
        for (final locale in localesOf(arbs))
          languageTagOf(locale): _localization(switch (arbs[locale]![arbKey]) {
            final String translated => translated,
            _ => value,
          }, order),
      },
    };
  }
  final catalog = {
    'sourceLanguage': 'en',
    'strings': strings,
    'version': '1.0',
  };
  return '${const JsonEncoder.withIndent('  ').convert(catalog)}\n';
}

final _plural = RegExp(r'^\{(\w+), plural, (.*)\}$', dotAll: true);
final _placeholder = RegExp(r'\{(\w+)\}');

List<String> _placeholderOrder(String message) {
  final plural = _plural.firstMatch(message);
  if (plural != null) return [plural[1]!];
  return {
    for (final match in _placeholder.allMatches(message)) match[1]!,
  }.toList();
}

String _numbered(String text, List<String> order, String type) =>
    text.replaceAllMapped(_placeholder, (match) {
      final index = order.indexOf(match[1]!);
      return index < 0 ? match[0]! : '%${index + 1}\$$type';
    });

Map<String, Object?> _localization(String message, List<String> order) {
  final plural = _plural.firstMatch(message);
  if (plural == null) return _unit(_numbered(message, order, '@'));
  final forms = <String, Object?>{};
  for (final (:form, :text) in _branches(plural[2]!)) {
    final category = switch (form) {
      '=0' => 'zero',
      '=1' || 'one' => 'one',
      '=2' || 'two' => 'two',
      _ => form,
    };
    forms[category] = _unit(_numbered(text, order, 'lld'));
  }
  return {
    'variations': {'plural': forms},
  };
}

Map<String, Object?> _unit(String value) => {
  'stringUnit': {'state': 'translated', 'value': value},
};

/// `=1{one file} other{{count} files}` as its forms and texts.
List<({String form, String text})> _branches(String body) {
  final branches = <({String form, String text})>[];
  var at = 0;
  while (at < body.length) {
    final open = body.indexOf('{', at);
    if (open < 0) break;
    final form = body.substring(at, open).trim();
    var depth = 0;
    var close = open;
    for (; close < body.length; close++) {
      if (body[close] == '{') depth++;
      if (body[close] == '}' && --depth == 0) break;
    }
    branches.add((form: form, text: body.substring(open + 1, close)));
    at = close + 1;
  }
  return branches;
}

/// `values`, `values-de`, `values-pt-rBR`, or `values-b+zh+Hans` for a
/// language written in a named script.
String androidFolderOf(String locale) {
  if (locale == 'en') return 'values';
  final parts = locale.split('_');
  if (parts.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(parts[1])) {
    return 'values-${parts[0]}-r${parts[1]}';
  }
  return parts.length == 1 ? 'values-$locale' : 'values-b+${parts.join('+')}';
}

String androidStrings(Map<String, Object?> arb, {required bool isSource}) {
  final lines = <String>[
    '<?xml version="1.0" encoding="utf-8"?>',
    _generatedMark,
    '<resources>',
    if (isSource)
      for (final MapEntry(:key, :value) in androidBrandStrings.entries)
        '    <string name="$key" translatable="false">${_androidText(value)}</string>',
    for (final MapEntry(key: name, value: arbKey) in androidKeys.entries)
      if (arb[arbKey] case final String text)
        '    <string name="$name">${_androidText(text)}</string>',
    '</resources>',
  ];
  return '${lines.join('\n')}\n';
}

String _androidText(String text) {
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll("'", r"\'")
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return escaped.startsWith('@') || escaped.startsWith('?')
      ? '\\$escaped'
      : escaped;
}

String androidLocalesConfig(List<String> locales) => [
  '<?xml version="1.0" encoding="utf-8"?>',
  _generatedMark,
  '<locale-config xmlns:android="http://schemas.android.com/apk/res/android">',
  for (final locale in locales)
    '    <locale android:name="${languageTagOf(locale)}" />',
  '</locale-config>',
  '',
].join('\n');

String withPlistStrings(
  String plist,
  List<String> locales,
  Map<String, Object?> source,
) {
  for (final MapEntry(key: plistKey, value: arbKey) in infoPlistKeys.entries) {
    final prompt = RegExp('(<key>$plistKey</key>\\s*<string>)[^<]*(</string>)');
    if (!prompt.hasMatch(plist)) throw StateError('No $plistKey');
    final text = (source[arbKey]! as String)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    plist = plist.replaceFirstMapped(
      prompt,
      (match) => '${match[1]}$text${match[2]}',
    );
  }
  final localizations = RegExp(
    r'(<key>CFBundleLocalizations</key>\s*<array>)[\s\S]*?(\s*</array>)',
  );
  if (!localizations.hasMatch(plist)) {
    throw StateError('No CFBundleLocalizations');
  }
  return plist.replaceFirstMapped(
    localizations,
    (match) =>
        '${match[1]}'
        '${[for (final locale in locales) '\n\t\t\t<string>${languageTagOf(locale)}</string>'].join()}'
        '${match[2]}',
  );
}

String withKnownRegions(String project, List<String> locales) {
  final regions = RegExp(r'(knownRegions = \()[\s\S]*?(\n\t\t\t\);)');
  if (!regions.hasMatch(project)) throw StateError('No knownRegions');
  String quoted(String tag) =>
      RegExp(r'^[A-Za-z]+$').hasMatch(tag) ? tag : '"$tag"';
  return project.replaceFirstMapped(
    regions,
    (match) =>
        '${match[1]}'
        '${[
          for (final region in [...locales.map(languageTagOf), 'Base']) '\n\t\t\t\t${quoted(region)},',
        ].join()}'
        '${match[2]}',
  );
}

Arbs readArbs(Directory folder) => {
  for (final file in folder.listSync().whereType<File>())
    if (RegExp(r'app_(\w+)\.arb$').firstMatch(file.path) case final match?)
      match[1]!: jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
};

/// Generated Android string files whose language has no ARB file any more.
List<File> staleAndroidFiles(Arbs arbs) {
  final wanted = nativeStringFiles(arbs).keys.toSet();
  return [
    for (final folder in Directory(androidResPath).listSync())
      if (folder is Directory)
        for (final file in folder.listSync().whereType<File>())
          if (file.path.endsWith('/strings.xml') &&
              !wanted.contains(file.path) &&
              file.readAsStringSync().contains(_generatedMark))
            file,
  ];
}

void main() {
  final arbs = readArbs(Directory('lib/l10n'));
  for (final MapEntry(key: path, value: text) in nativeStringFiles(
    arbs,
  ).entries) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
    stdout.writeln('Wrote $path');
  }
  for (final file in staleAndroidFiles(arbs)) {
    file.deleteSync();
    stdout.writeln('Removed ${file.path}');
  }
  final locales = localesOf(arbs);
  final plist = File(infoPlistPath);
  plist.writeAsStringSync(
    withPlistStrings(plist.readAsStringSync(), locales, arbs['en']!),
  );
  final project = File(xcodeProjectPath);
  project.writeAsStringSync(
    withKnownRegions(project.readAsStringSync(), locales),
  );
  stdout.writeln('Updated $infoPlistPath and $xcodeProjectPath');
}
