import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

double _revisionOf(File file) {
  final data = file.readAsBytesSync();
  final view = ByteData.sublistView(data);
  for (var i = 0; i < view.getUint16(4); i++) {
    final record = 12 + 16 * i;
    if (String.fromCharCodes(data.sublist(record, record + 4)) == 'head') {
      return view.getInt32(view.getUint32(record + 8) + 4) / 65536;
    }
  }
  throw StateError('${file.path} has no head table');
}

void main() {
  test('every style of a font comes from the same release', () {
    final revisions = <String, Map<String, double>>{};
    for (final file in Directory('assets/fonts').listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('.ttf')) continue;
      (revisions[name.split('-').first] ??= {})[name] = _revisionOf(file);
    }

    expect(
      revisions.keys,
      containsAll(['DMSans', 'JetBrainsMono', 'Literata']),
    );
    for (final MapEntry(key: family, value: files) in revisions.entries) {
      expect(files.values.toSet(), hasLength(1), reason: '$family: $files');
    }
  });
}
