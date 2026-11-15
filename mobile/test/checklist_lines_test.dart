import 'package:anchor/features/notes/presentation/editor/checklist_lines.dart';
import 'package:anchor/features/notes/presentation/editor/document_lines.dart';
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
  CheckedSectionPlan? planOf(Document doc, {int? prefer}) {
    final lines = parseDocumentLines(doc);
    return checklistCheckedSectionPlan(
      lines,
      0,
      lines.length - 1,
      prefer: prefer,
    );
  }

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

    test('a checked parent with an unchecked child stays in place', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('b', 'checked', 0),
        ('b1', 'unchecked', 1),
        ('c', 'unchecked', 0),
      ]);
      expect(planOf(doc, prefer: 1), isNull);
    });

    test('a fully checked parent sinks its whole subtree', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('b', 'checked', 0),
        ('b1', 'checked', 1),
        ('c', 'unchecked', 0),
      ]);
      final plan = planOf(doc, prefer: 1)!;
      expect(plan.order, [0, 3, 1, 2]);

      doc.compose(
        buildCheckedSectionDelta(doc, parseDocumentLines(doc), 0, plan),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('c', 'unchecked', 0),
        ('b', 'checked', 0),
        ('b1', 'checked', 1),
      ]);
    });

    test('a checked child leaves its parent for the checked section', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('c2', 'unchecked', 1),
        ('q', 'unchecked', 0),
      ]);
      final plan = planOf(doc, prefer: 1)!;
      expect(plan.order, [0, 2, 3, 1]);

      doc.compose(
        buildCheckedSectionDelta(doc, parseDocumentLines(doc), 0, plan),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
        ('q', 'unchecked', 0),
        ('c1', 'checked', 0),
      ]);
    });

    test('a checked child with an unchecked descendant stays in place', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('g1', 'unchecked', 2),
        ('c2', 'unchecked', 1),
      ]);
      expect(planOf(doc, prefer: 1), isNull);
    });

    test('a fully checked child carries its deeper subtree to the section', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('g1', 'checked', 2),
        ('c2', 'unchecked', 1),
      ]);
      final plan = planOf(doc, prefer: 1)!;
      expect(plan.order, [0, 3, 1, 2]);
      expect(plan.indents, [0, 1, 0, 1]);

      doc.compose(
        buildCheckedSectionDelta(doc, parseDocumentLines(doc), 0, plan),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
        ('c1', 'checked', 0),
        ('g1', 'checked', 1),
      ]);
    });

    test('checklistCheckedSectionPlan is null for an ordered group', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 0),
        ('c2', 'checked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistCheckedSectionPlan(lines, 0, 2), isNull);
      // The same order with the toggled line last in the section.
      expect(checklistCheckedSectionPlan(lines, 0, 2, prefer: 2), isNull);
    });

    test('unchecking the only child of a checked parent keeps it in place', () {
      // The parent has an unchecked descendant, so it waits in the open list.
      final doc = nestedDoc([
        ('p', 'checked', 0),
        ('c', 'unchecked', 1),
        ('q', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      expect(checklistCheckedSectionPlan(lines, 0, 2, prefer: 1), isNull);
    });

    test('a checked child under an unchecked parent always re-indents', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'unchecked', 1),
        ('c2', 'checked', 1),
        ('q', 'checked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      final plan = checklistCheckedSectionPlan(lines, 0, 3);
      expect(plan, isNotNull);
      expect(plan!.order, [0, 1, 2, 3]);
      expect(plan.indents, [0, 1, 0, 0]);
      // With the toggled line last in its section, q leaves c2 behind.
      final sorted = checklistCheckedSectionPlan(lines, 0, 3, prefer: 2);
      expect(sorted!.order, [0, 1, 3, 2]);
      expect(sorted.indents, [0, 1, 0, 0]);
      expect(checklistCheckedSectionPlan(lines, 0, 3, prefer: 3), isNotNull);
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
        // Dragging a's block.
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

  group('uncheck all and delete checked', () {
    Document applied(Document doc, Delta? Function(List<ParsedLine>) build) {
      final before = doc.toDelta();
      final delta = build(parseDocumentLines(doc))!;
      doc.compose(delta, ChangeSource.local);
      final after = doc.toDelta();
      final undone = Document.fromDelta(after)
        ..compose(delta.invert(before), ChangeSource.local);
      expect(undone.toDelta(), before);
      return doc;
    }

    test('both are null when nothing is checked', () {
      final lines = parseDocumentLines(
        docFrom([('a', 'unchecked'), ('b', null)]),
      );
      expect(buildUncheckAllDelta(lines), isNull);
      expect(buildDeleteCheckedDelta(lines), isNull);
    });

    test('uncheck all clears every checklist and keeps nesting', () {
      final doc = nestedDoc([
        ('Shop', null, 0),
        ('milk', 'checked', 0),
        ('oat', 'checked', 1),
        ('eggs', 'unchecked', 0),
        ('Pack', null, 0),
        ('socks', 'checked', 0),
      ]);
      expect(nestedLinesOf(applied(doc, buildUncheckAllDelta)), [
        ('Shop', null, 0),
        ('milk', 'unchecked', 0),
        ('oat', 'unchecked', 1),
        ('eggs', 'unchecked', 0),
        ('Pack', null, 0),
        ('socks', 'unchecked', 0),
      ]);
    });

    test('delete checked keeps the open items and the text around them', () {
      final doc = docFrom([
        ('Shop', null),
        ('milk', 'checked'),
        ('eggs', 'unchecked'),
        ('bread', 'checked'),
        ('tea', 'unchecked'),
        ('Thanks', null),
      ]);
      expect(linesOf(applied(doc, buildDeleteCheckedDelta)), [
        ('Shop', null),
        ('eggs', 'unchecked'),
        ('tea', 'unchecked'),
        ('Thanks', null),
      ]);
    });

    test('checked items that end the note go, and the last line stays', () {
      final doc = nestedDoc([
        ('eggs', 'unchecked', 0),
        ('large', 'unchecked', 1),
        ('milk', 'checked', 0),
        ('bread', 'checked', 0),
      ]);
      expect(nestedLinesOf(applied(doc, buildDeleteCheckedDelta)), [
        ('eggs', 'unchecked', 0),
        ('large', 'unchecked', 1),
      ]);
    });

    test('a note of only checked items keeps one empty item', () {
      final doc = nestedDoc([('milk', 'checked', 0), ('oat', 'checked', 1)]);
      expect(nestedLinesOf(applied(doc, buildDeleteCheckedDelta)), [
        ('', 'unchecked', 0),
      ]);
    });

    test('open sub-items move up one level for each deleted item above', () {
      final doc = nestedDoc([
        ('trip', 'checked', 0),
        ('bags', 'checked', 1),
        ('passport', 'unchecked', 2),
        ('tickets', 'unchecked', 1),
        ('home', 'unchecked', 0),
        ('plants', 'checked', 1),
        ('water', 'unchecked', 2),
        ('keys', 'unchecked', 1),
      ]);
      expect(nestedLinesOf(applied(doc, buildDeleteCheckedDelta)), [
        ('passport', 'unchecked', 0),
        ('tickets', 'unchecked', 0),
        ('home', 'unchecked', 0),
        ('water', 'unchecked', 1),
        ('keys', 'unchecked', 1),
      ]);
    });

    test('a bullet under a deleted item moves up with the open ones', () {
      final doc = nestedDoc([
        ('cake', 'checked', 0),
        ('flour', 'bullet', 1),
        ('jam', 'unchecked', 0),
      ]);
      expect(nestedLinesOf(applied(doc, buildDeleteCheckedDelta)), [
        ('flour', 'bullet', 0),
        ('jam', 'unchecked', 0),
      ]);
    });

    test(
      'the last kept line moves up when the items under it end the note',
      () {
        final doc = nestedDoc([
          ('trip', 'checked', 0),
          ('passport', 'unchecked', 1),
          ('bags', 'checked', 1),
        ]);
        expect(nestedLinesOf(applied(doc, buildDeleteCheckedDelta)), [
          ('passport', 'unchecked', 0),
        ]);
      },
    );

    test('checking a parent block checks every checklist descendant', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('a2', 'unchecked', 2),
        ('b', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      doc.compose(
        buildChecklistToggleDelta(lines, 0, true),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('a', 'checked', 0),
        ('a1', 'checked', 1),
        ('a2', 'checked', 2),
        ('b', 'unchecked', 0),
      ]);
    });

    test('unchecking a parent block unchecks every checklist descendant', () {
      final doc = nestedDoc([
        ('a', 'checked', 0),
        ('a1', 'checked', 1),
        ('b', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      doc.compose(
        buildChecklistToggleDelta(lines, 0, false),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('a', 'unchecked', 0),
        ('a1', 'unchecked', 1),
        ('b', 'unchecked', 0),
      ]);
    });

    test('a non-checklist child under a parent keeps its list state', () {
      final doc = nestedDoc([
        ('a', 'unchecked', 0),
        ('note', null, 1),
        ('a1', 'unchecked', 1),
      ]);
      final lines = parseDocumentLines(doc);
      doc.compose(
        buildChecklistToggleDelta(lines, 0, true),
        ChangeSource.local,
      );
      expect(nestedLinesOf(doc), [
        ('a', 'checked', 0),
        ('note', null, 1),
        ('a1', 'checked', 1),
      ]);
    });
  });

  group('checklistCheckedSectionPlan', () {
    test('a checked item moves to the bottom', () {
      final plan = planOf(
        nestedDoc([
          ('a', 'unchecked', 0),
          ('b', 'checked', 0),
          ('c', 'unchecked', 0),
        ]),
      );
      expect(plan, isNotNull);
      expect(plan!.order, [0, 2, 1]);
      expect(plan.indents, [0, 0, 0]);
    });

    test('a checked block drops below an unchecked block', () {
      final plan = planOf(
        nestedDoc([
          ('a', 'unchecked', 0),
          ('a1', 'unchecked', 1),
          ('b', 'checked', 0),
          ('b1', 'checked', 1),
        ]),
      );
      expect(plan, isNull);
    });

    test('a checked block ahead of an unchecked one drops below it', () {
      final plan = planOf(
        nestedDoc([
          ('a', 'checked', 0),
          ('a1', 'checked', 1),
          ('b', 'unchecked', 0),
          ('b1', 'unchecked', 1),
        ]),
      );
      expect(plan!.order, [2, 3, 0, 1]);
      expect(plan.indents, [0, 1, 0, 1]);
    });

    test('a checked child leaves an unchecked parent', () {
      final plan = planOf(
        nestedDoc([
          ('p', 'unchecked', 0),
          ('c1', 'checked', 1),
          ('c2', 'unchecked', 1),
          ('q', 'unchecked', 0),
        ]),
      );
      expect(plan!.order, [0, 2, 3, 1]);
      expect(plan.indents, [0, 1, 0, 0]);
    });

    test('a checked grandchild leaves to the checked section', () {
      final plan = planOf(
        nestedDoc([
          ('p', 'unchecked', 0),
          ('c', 'unchecked', 1),
          ('g', 'checked', 2),
          ('q', 'unchecked', 0),
        ]),
      );
      expect(plan!.order, [0, 1, 3, 2]);
      expect(plan.indents, [0, 1, 0, 0]);
    });

    test('indents are absolute when the group starts indented', () {
      final plan = planOf(
        nestedDoc([
          ('p', 'unchecked', 1),
          ('c', 'checked', 2),
          ('q', 'unchecked', 1),
        ]),
      );
      expect(plan!.order, [0, 2, 1]);
      expect(plan.indents, [1, 1, 0]);
    });

    test('an already ordered group has no plan', () {
      final plan = planOf(
        nestedDoc([
          ('a', 'unchecked', 0),
          ('b', 'checked', 0),
          ('c', 'checked', 0),
        ]),
      );
      expect(plan, isNull);
    });

    test('a non-checklist group has no plan', () {
      final plan = planOf(
        nestedDoc([('a', 'bullet', 0), ('b', 'bullet', 0), ('c', 'bullet', 0)]),
      );
      expect(plan, isNull);
    });
  });

  group('buildCheckedSectionDelta', () {
    Document appliedPlan(Document doc, CheckedSectionPlan plan) {
      final lines = parseDocumentLines(doc);
      final delta = buildCheckedSectionDelta(doc, lines, 0, plan);
      doc.compose(delta, ChangeSource.local);
      return doc;
    }

    test('the delta writes the checked section order and indents', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('c2', 'unchecked', 1),
        ('q', 'unchecked', 0),
      ]);
      final plan = planOf(doc)!;
      expect(nestedLinesOf(appliedPlan(doc, plan)), [
        ('p', 'unchecked', 0),
        ('c2', 'unchecked', 1),
        ('q', 'unchecked', 0),
        ('c1', 'checked', 0),
      ]);
    });

    test('the delta undoes in one step', () {
      final doc = nestedDoc([
        ('a', 'checked', 0),
        ('a1', 'checked', 1),
        ('b', 'unchecked', 0),
      ]);
      final before = doc.toDelta();
      final plan = planOf(doc)!;
      final delta = buildCheckedSectionDelta(
        doc,
        parseDocumentLines(doc),
        0,
        plan,
      );
      doc.compose(delta, ChangeSource.local);
      doc.compose(delta.invert(before), ChangeSource.local);
      expect(doc.toDelta(), before);
    });

    test('a checked parent block sinks whole with its subtree', () {
      final doc = nestedDoc([
        ('a', 'checked', 0),
        ('a1', 'checked', 1),
        ('b', 'unchecked', 0),
        ('b1', 'unchecked', 1),
      ]);
      final plan = planOf(doc)!;
      expect(nestedLinesOf(appliedPlan(doc, plan)), [
        ('b', 'unchecked', 0),
        ('b1', 'unchecked', 1),
        ('a', 'checked', 0),
        ('a1', 'checked', 1),
      ]);
    });

    test('a checked block leaves an indented group at the checked root', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 1),
        ('c', 'checked', 2),
        ('q', 'unchecked', 1),
      ]);
      final plan = planOf(doc)!;
      expect(nestedLinesOf(appliedPlan(doc, plan)), [
        ('p', 'unchecked', 1),
        ('q', 'unchecked', 1),
        ('c', 'checked', 0),
      ]);
    });

    test('a plan that only changes indents applies', () {
      final doc = nestedDoc([('p', 'unchecked', 0), ('c', 'checked', 1)]);
      final plan = planOf(doc)!;
      expect(plan.order, [0, 1]);
      expect(plan.indents, [0, 0]);
      expect(nestedLinesOf(appliedPlan(doc, plan)), [
        ('p', 'unchecked', 0),
        ('c', 'checked', 0),
      ]);
    });

    test('the delta keeps inline formatting', () {
      final doc = nestedDoc([
        ('p', 'unchecked', 0),
        ('c1', 'checked', 1),
        ('q', 'unchecked', 0),
      ]);
      final lines = parseDocumentLines(doc);
      final c1Start = lines[1].startOffset;
      doc.compose(
        Delta()
          ..retain(c1Start + 1)
          ..retain(1, {'bold': true}),
        ChangeSource.local,
      );
      final plan = planOf(doc)!;
      appliedPlan(doc, plan);

      final moved = parseDocumentLines(doc);
      final c1 = moved.firstWhere(
        (line) =>
            doc.toPlainText().substring(
              line.startOffset,
              line.startOffset + line.length - 1,
            ) ==
            'c1',
      );
      final boldOffset = c1.startOffset + 1;
      final bold = doc.toDelta().slice(boldOffset, boldOffset + 1).first;
      expect(bold.data, '1');
      expect(bold.attributes, containsPair('bold', true));
    });
  });
}
