import 'package:anchor/core/widgets/editor/checklist_lines.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

Document docFrom(List<(String, String?)> lines) {
  final ops = <Map<String, dynamic>>[];
  for (final (text, list) in lines) {
    if (text.isNotEmpty) ops.add({'insert': text});
    ops.add({
      'insert': '\n',
      if (list != null) 'attributes': {'list': list},
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

Document nestedDoc(List<(String, String?, int)> lines) {
  final ops = <Map<String, dynamic>>[];
  for (final (text, list, indent) in lines) {
    if (text.isNotEmpty) ops.add({'insert': text});
    ops.add({
      'insert': '\n',
      if (list != null || indent > 0)
        'attributes': {'list': ?list, if (indent > 0) 'indent': indent},
    });
  }
  return Document.fromJson(ops);
}

List<(String, String?, int)> nestedLinesOf(Document doc) {
  final parsed = parseDocumentLines(doc);
  final text = doc.toPlainText();
  return [
    for (final line in parsed)
      (
        text.substring(line.startOffset, line.startOffset + line.length - 1),
        line.listType,
        line.indent,
      ),
  ];
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
      final doc = docFrom([('a', 'unchecked'), ('b', 'checked')]);
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

  group('nested checklists', () {
    test('a block spans a line and its indented children within the range', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('g1', 'unchecked', 2),
        ('b', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistBlockEnd(lines, 0, 3), 2);
      expect(checklistBlockEnd(lines, 1, 3), 2);
      expect(checklistBlockEnd(lines, 3, 3), 3);
      // A tighter range end bounds the block.
      expect(checklistBlockEnd(lines, 0, 1), 1);
    });

    test(
      'a parent block moves to the end of the document with its subtree',
      () {
        final doc = nestedDoc([
          ('a', 'unchecked', 0),
          ('a1', 'unchecked', 1),
          ('a2', 'unchecked', 1),
          ('b', 'unchecked', 0),
        ]);
        final before = doc.toDelta();
        final lines = parseDocumentLines(doc);
        final move = buildBlockMoveDelta(doc, lines, 0, 2, 4);
        final inverted = move.invert(before);

        doc.compose(move, ChangeSource.local);
        expect(nestedLinesOf(doc), [
          ('b', 'unchecked', 0),
          ('a', 'unchecked', 0),
          ('a1', 'unchecked', 1),
          ('a2', 'unchecked', 1),
        ]);
        doc.compose(inverted, ChangeSource.local);
        expect(doc.toDelta(), before);
      },
    );

    test('a block ending the document moves up with its subtree', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 0),
        ('b1', 'unchecked', 1),
      ]);
      final before = doc.toDelta();
      final lines = parseDocumentLines(doc);
      final move = buildBlockMoveDelta(doc, lines, 1, 2, 0);
      final inverted = move.invert(before);

      doc.compose(move, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('b', 'unchecked', 0),
        ('b1', 'unchecked', 1),
        ('a', 'unchecked', 0),
      ]);
      doc.compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });

    test('a mid-document block move leaves surrounding lines untouched', () {
      final doc = nestedDoc([
        ('intro', null, 0),
        ('a', 'unchecked', 0),
        ('a1', 'checked', 1),
        ('b', 'unchecked', 0),
        ('outro', null, 0),
      ]);
      final lines = parseDocumentLines(doc);
      final move = buildBlockMoveDelta(doc, lines, 1, 2, 4);
      doc.compose(move, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('intro', null, 0),
        ('b', 'unchecked', 0),
        ('a', 'unchecked', 0),
        ('a1', 'checked', 1),
        ('outro', null, 0),
      ]);
    });

    test('checking a parent sinks its whole subtree', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('b', 'checked', 0),
        ('b1', 'unchecked', 1),
        ('c', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      final order = checklistSortOrder(lines, 0, 3, 1);
      expect(order, [0, 3, 1, 2]);

      doc.compose(
        buildGroupReorderDelta(doc, lines, 0, order!),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('c', 'unchecked', 0),
        ('b', 'checked', 0),
        ('b1', 'unchecked', 1),
      ]);
    });

    test('checking a child re-sorts only within its parent', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('c2', 'unchecked', 1),
        ('q', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      final order = checklistSortOrder(lines, 0, 3, 1);
      expect(order, [0, 2, 1, 3]);

      doc.compose(
        buildGroupReorderDelta(doc, lines, 0, order!),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
        ('c1', 'checked', 1),
        ('q', 'unchecked', 0),
      ]);
    });

    test('a sorted child block carries its deeper subtree', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('g1', 'unchecked', 2),
        ('c2', 'unchecked', 1),
      ]);
      final lines = parseDocumentLines(doc);
      final order = checklistSortOrder(lines, 0, 3, 1);
      expect(order, [0, 3, 1, 2]);

      doc.compose(
        buildGroupReorderDelta(doc, lines, 0, order!),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
        ('c1', 'checked', 1),
        ('g1', 'unchecked', 2),
      ]);
    });

    test('checklistSortOrder is null for an ordered nested group', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'unchecked', 1),
        ('c2', 'checked', 1),
        ('q', 'checked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistSortOrder(lines, 0, 3, 2), isNull);
      expect(checklistSortOrder(lines, 0, 3, 3), isNull);
    });

    test('drop gaps: flat groups allow every gap', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'unchecked'),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistDropGaps(lines, 0, 2, 1, 1), const [
        ChecklistGap(0, 0, 0),
        ChecklistGap(1, 0, 1),
        ChecklistGap(2, 0, 1),
        ChecklistGap(3, 0, 1),
      ]);
    });

    test(
      'drop gaps: every gap carries the indent range the block may take',
      () {
        final doc = nestedDoc([
          ('a', 'unchecked', 0),
          ('a1', 'unchecked', 1),
          ('a2', 'unchecked', 1),
          ('b', 'unchecked', 0),
        ]);
        final lines = parseDocumentLines(doc);
        // Dragging b.
        expect(checklistDropGaps(lines, 0, 3, 3, 3), const [
          ChecklistGap(0, 0, 0),
          ChecklistGap(1, 0, 1),
          ChecklistGap(2, 0, 2),
          ChecklistGap(3, 0, 2),
          ChecklistGap(4, 0, 2),
        ]);
        // Dragging a's block: the deepest child caps the range at
        // maxListIndent - 1.
        expect(checklistDropGaps(lines, 0, 3, 0, 2), const [
          ChecklistGap(0, 0, 0),
          ChecklistGap(3, 0, 0),
          ChecklistGap(4, 0, 1),
        ]);
      },
    );

    test('drop gaps: a child may move between parents or out to the top', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('a2', 'unchecked', 1),
        ('b', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistDropGaps(lines, 0, 3, 1, 1), const [
        ChecklistGap(0, 0, 0),
        ChecklistGap(1, 0, 1),
        ChecklistGap(2, 0, 1),
        ChecklistGap(3, 0, 2),
        ChecklistGap(4, 0, 1),
      ]);
    });

    test('a moved block re-indents to the target level with its subtree', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'unchecked', 1),
        ('g1', 'unchecked', 2),
        ('c2', 'unchecked', 1),
      ]);
      final before = doc.toDelta();
      final lines = parseDocumentLines(doc);
      final move = buildBlockMoveDelta(doc, lines, 1, 2, 0, indentDelta: -1);
      final inverted = move.invert(before);

      doc.compose(move, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('c1', 'unchecked', 0),
        ('g1', 'unchecked', 1),
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
      ]);
      doc.compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });

    test('a re-indented move into the end of the document round-trips', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('a2', 'unchecked', 1),
        ('b', 'unchecked', 0),
      ]);
      final before = doc.toDelta();
      final lines = parseDocumentLines(doc);
      final move = buildBlockMoveDelta(doc, lines, 1, 1, 4, indentDelta: -1);
      final inverted = move.invert(before);

      doc.compose(move, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('a2', 'unchecked', 1),
        ('b', 'unchecked', 0),
        ('a1', 'unchecked', 0),
      ]);
      doc.compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });

    test('buildBlockReindentDelta shifts a block in place', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('a2', 'unchecked', 1),
        ('b', 'unchecked', 0),
      ]);
      final before = doc.toDelta();
      final lines = parseDocumentLines(doc);
      final reindent = buildBlockReindentDelta(lines, 3, 3, 1);
      final inverted = reindent.invert(before);

      doc.compose(reindent, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('a2', 'unchecked', 1),
        ('b', 'unchecked', 1),
      ]);
      doc.compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });
  });

  group('buildListIndentDelta', () {
    Delta? indent(Document doc, int start, int end, {required bool increase}) {
      return buildListIndentDelta(
        parseDocumentLines(doc),
        start,
        end,
        increase: increase,
      );
    }

    test('indents a list line one level under its predecessor', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'unchecked'),
      ]);
      final delta = indent(doc, 'a\nb'.length, 'a\nb'.length, increase: true);
      doc.compose(delta!, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 1),
        ('c', 'unchecked', 0),
      ]);
    });

    test('cannot indent deeper than one level below the line above', () {
      final doc = nestedDoc([('a', 'unchecked', 0), ('b', 'unchecked', 1)]);
      expect(indent(doc, 'a\nb'.length, 'a\nb'.length, increase: true), isNull);
    });

    test('the first list line cannot indent', () {
      final doc = docFrom([('intro', null), ('a', 'unchecked')]);
      expect(indent(doc, 0, 0, increase: true), isNull);
      final pos = 'intro\na'.length;
      expect(indent(doc, pos, pos, increase: true), isNull);
    });

    test('caps at maxListIndent', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 1),
        ('c', 'unchecked', 2),
        ('d', 'unchecked', 3),
      ]);
      final pos = 'a\nb\nc\nd'.length;
      expect(indent(doc, pos, pos, increase: true), isNull);
    });

    test('outdenting level 1 removes the indent attribute entirely', () {
      final doc = nestedDoc([('a', 'unchecked', 0), ('b', 'unchecked', 1)]);
      final delta = indent(doc, 'a\nb'.length, 'a\nb'.length, increase: false);
      doc.compose(delta!, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 0),
      ]);
      final attrs = parseDocumentLines(doc)[1].newlineAttributes;
      expect(attrs, isNot(contains('indent')));
    });

    test('outdenting a top-level line is a no-op', () {
      final doc = docFrom([('a', 'unchecked'), ('b', 'unchecked')]);
      expect(indent(doc, 0, 0, increase: false), isNull);
    });

    test('a multi-line selection indents with chained clamping', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('c', 'unchecked'),
      ]);
      final delta = indent(doc, 'a\n'.length, 'a\nb\nc'.length, increase: true);
      doc.compose(delta!, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 1),
        ('c', 'unchecked', 1),
      ]);
    });

    test('paragraph lines inside the selection are untouched', () {
      final doc = docFrom([
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('note', null),
      ]);
      final delta = indent(doc, 0, 'a\nb\nnote'.length, increase: true);
      doc.compose(delta!, ChangeSource.local);
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('b', 'unchecked', 1),
        ('note', null, 0),
      ]);
    });

    test('an indent change survives an undo round-trip', () {
      final doc = docFrom([('a', 'unchecked'), ('b', 'unchecked')]);
      final before = doc.toDelta();
      final delta = indent(doc, 'a\nb'.length, 'a\nb'.length, increase: true);
      final inverted = delta!.invert(before);
      doc
        ..compose(delta, ChangeSource.local)
        ..compose(inverted, ChangeSource.local);
      expect(doc.toDelta(), before);
    });
  });
}
