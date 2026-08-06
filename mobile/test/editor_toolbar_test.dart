import 'package:anchor/core/widgets/editor/editor_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

const checklistOps = [
  {'insert': 'a'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked'},
  },
  {'insert': 'b'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked'},
  },
];

const nestedOps = [
  {'insert': 'a'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked'},
  },
  {'insert': 'b'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked', 'indent': 1},
  },
];

void main() {
  Future<QuillController> pumpToolbar(
    WidgetTester tester,
    List<Map<String, dynamic>> ops,
    int offset,
  ) async {
    final controller = QuillController(
      document: Document.fromJson(ops),
      selection: TextSelection.collapsed(offset: offset),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        home: Scaffold(
          body: EditorToolbar(
            controller: controller,
            state: EditorFormattingState.fromController(controller),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('the indent button nests the selected list line', (tester) async {
    // Cursor on line "b".
    final controller = await pumpToolbar(tester, checklistOps, 3);
    await tester.tap(find.byTooltip('Indent'));
    await tester.pump();

    expect(
      controller.document.toDelta().toJson(),
      anyElement(
        equals({
          'insert': '\n',
          'attributes': {'list': 'unchecked', 'indent': 1},
        }),
      ),
    );
  });

  testWidgets('indenting the first list line is a no-op', (tester) async {
    final controller = await pumpToolbar(tester, checklistOps, 0);
    final before = controller.document.toDelta();
    await tester.tap(find.byTooltip('Indent'));
    await tester.pump();
    expect(controller.document.toDelta(), before);
  });

  testWidgets('the outdent button lifts a nested line back out', (
    tester,
  ) async {
    final controller = await pumpToolbar(tester, nestedOps, 3);
    await tester.tap(find.byTooltip('Outdent'));
    await tester.pump();

    final json = controller.document.toDelta().toJson();
    for (final op in json) {
      expect((op['attributes'] as Map?) ?? {}, isNot(contains('indent')));
    }
  });

  testWidgets('outdent is disabled on top-level lines', (tester) async {
    final controller = await pumpToolbar(tester, checklistOps, 3);
    final before = controller.document.toDelta();
    await tester.tap(find.byTooltip('Outdent'));
    await tester.pump();
    expect(controller.document.toDelta(), before);
  });
}
