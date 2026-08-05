import 'package:anchor/core/widgets/editor/checklist_lines.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

Document docFrom(List<(String, String?)> lines) {
  final ops = <Map<String, dynamic>>[];
  for (final (text, list) in lines) {
    if (text.isNotEmpty) ops.add({'insert': text});
    ops.add({
      'insert': '\n',
      if (list != null)
        'attributes': {'list': list},
    });
  }
  return Document.fromJson(ops);
}

List<(String, String?)> linesOf(Document doc) {
  final parsed = parseDocumentLines(doc);
  final text = doc.toPlainText();
  return [
    for (final line in parsed)
      (
        text.substring(line.startOffset, line.startOffset + line.length - 1),
        line.listType,
      ),
  ];
}

Document moved(Document doc, int from, int to) {
  final delta = buildLineMoveDelta(doc, parseDocumentLines(doc), from, to);
  doc.compose(delta, ChangeSource.local);
  return doc;
}

void main() {
  group('buildLineMoveDelta', () {
    test('moves a middle line down', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'unchecked'),
        ('d', 'unchecked'),
      ]);
      expect(linesOf(moved(doc, 1, 2)), [
        ('a', 'unchecked'),
        ('c', 'unchecked'),
        ('b', 'unchecked'),
        ('d', 'unchecked'),
      ]);
    });

    test('moves a middle line up', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'unchecked'),
        ('d', 'unchecked'),
      ]);
      expect(linesOf(moved(doc, 2, 0)), [
        ('c', 'unchecked'),
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('d', 'unchecked'),
      ]);
    });

    test('moves the first line to the end of the document', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'checked'),
        ('c', 'checked'),
      ]);
      expect(linesOf(moved(doc, 0, 2)), [
        ('b', 'checked'),
        ('c', 'checked'),
        ('a', 'unchecked'),
      ]);
    });

    test('moves the last line of the document to the top', () {
      final doc = docFrom([
        ('a', 'checked'),
        ('b', 'checked'),
        ('c', 'unchecked'),
      ]);
      expect(linesOf(moved(doc, 2, 0)), [
        ('c', 'unchecked'),
        ('a', 'checked'),
        ('b', 'checked'),
      ]);
    });

    test('lines keep their own attributes across a move past mixed states', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'checked'),
        ('c', 'unchecked'),
      ]);
      expect(linesOf(moved(doc, 0, 2)), [
        ('b', 'checked'),
        ('c', 'unchecked'),
        ('a', 'unchecked'),
      ]);
    });

    test('a trailing paragraph outside the group is untouched', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('note', null),
      ]);
      expect(linesOf(moved(doc, 0, 1)), [
        ('b', 'unchecked'),
        ('a', 'unchecked'),
        ('note', null),
      ]);
    });

    test('group heal: one toggle re-sorts a mixed group, stably', () {
      // "e" (index 4) was just checked in a group that was never sorted.
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'checked'),
        ('c', 'checked'),
        ('d', 'unchecked'),
        ('e', 'checked'),
        ('f', 'unchecked'),
      ]);
      final lines = parseDocumentLines(doc);
      final order = checklistSortOrder(lines, 0, 5, 4);
      expect(order, [0, 3, 5, 1, 2, 4]);

      doc.compose(
        buildGroupReorderDelta(doc, lines, 0, order!),
        ChangeSource.local,
      );
      expect(linesOf(doc), [
        ('a', 'unchecked'),
        ('d', 'unchecked'),
        ('f', 'unchecked'),
        ('b', 'checked'),
        ('c', 'checked'),
        ('e', 'checked'),
      ]);
    });

    test('group heal at end of document survives an undo round-trip', () {
      final doc = docFrom([
        ('a', 'checked'),
        ('b', 'unchecked'),
        ('c', 'checked'),
      ]);
      final lines = parseDocumentLines(doc);
      final order = checklistSortOrder(lines, 0, 2, 2);
      expect(order, [1, 0, 2]);

      final before = doc.toDelta();
      final heal = buildGroupReorderDelta(doc, lines, 0, order!);
      final inverted = heal.invert(before);
      doc.compose(heal, ChangeSource.local);
      expect(linesOf(doc), [
        ('b', 'unchecked'),
        ('a', 'checked'),
        ('c', 'checked'),
      ]);
      doc.compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });

    test('checklistSortOrder is null for an already sorted group', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'checked'),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistSortOrder(lines, 0, 1, 1), isNull);
      expect(checklistSortOrder(lines, 0, 1, 0), isNull);
    });

    test('the toggled line goes to the end of its own section', () {
      // Checking "a" must put it BELOW the already-checked "b".
      final doc = docFrom([
        ('a', 'checked'),
        ('b', 'checked'),
        ('c', 'unchecked'),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistSortOrder(lines, 0, 2, 0), [2, 1, 0]);
    });

    test('moves survive an undo round-trip', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'checked'),
      ]);
      final before = doc.toDelta();
      final delta = buildLineMoveDelta(doc, parseDocumentLines(doc), 2, 0);
      final inverted = delta.invert(before);
      doc
        ..compose(delta, ChangeSource.local)
        ..compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });
  });
}
