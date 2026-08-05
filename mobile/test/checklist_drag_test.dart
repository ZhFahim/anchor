import 'dart:convert';

import 'package:anchor/core/widgets/editor/checklist_lines.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

String checklist(List<(String, String)> items) => jsonEncode({
  'ops': [
    for (final (text, state) in items) ...[
      {'insert': text},
      {
        'insert': '\n',
        'attributes': {'list': state},
      },
    ],
  ],
});

Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  Future<(RichTextEditorState, FocusNode)> pumpEditor(
    WidgetTester tester, {
    required String content,
    bool canEdit = true,
    bool sortChecklistItems = false,
    VoidCallback? onChanged,
  }) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      wrap(
        RichTextEditor(
          initialContent: content,
          focusNode: focusNode,
          canEdit: canEdit,
          sortChecklistItems: sortChecklistItems,
          onChanged: onChanged,
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<RichTextEditorState>(
      find.byType(RichTextEditor),
    );
    return (state, focusNode);
  }

  Finder checkboxSlot(int index) => find
      .ancestor(
        of: find.byType(QuillCheckboxPoint).at(index),
        matching: find.byType(GestureDetector),
      )
      .first;

  List<(String, String?)> lines(RichTextEditorState state) {
    final doc = state.controller.document;
    final text = doc.toPlainText();
    return [
      for (final line in parseDocumentLines(doc))
        (
          text.substring(line.startOffset, line.startOffset + line.length - 1),
          line.listType,
        ),
    ];
  }

  Future<TestGesture> lift(WidgetTester tester, Finder slot) async {
    final gesture = await tester.startGesture(tester.getCenter(slot));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
    return gesture;
  }

  Future<void> dragTo(
    WidgetTester tester,
    TestGesture gesture,
    Offset target,
  ) async {
    await gesture.moveTo(target);
    await tester.pump();
  }

  const abcd = [
    ('a', 'unchecked'),
    ('b', 'unchecked'),
    ('c', 'unchecked'),
    ('d', 'unchecked'),
  ];

  testWidgets('long-press lifts the item and shows its snapshot', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(1));
    expect(state.isDraggingChecklistItem, isTrue);
    expect(state.dragFeedbackText, 'b');

    final ghostWidth = tester
        .getSize(find.byKey(const Key('checklist-drag-ghost')))
        .width;
    final editorWidth = tester.getSize(find.byType(RichTextEditor)).width;
    expect(ghostWidth, lessThan(editorWidth / 2));

    final dimRect = tester.getRect(find.byKey(const Key('checklist-drag-dim')));
    // The ghost chip shows "b" too; measure the row inside the editor.
    final bTop = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(QuillEditor),
            matching: find.text('b', findRichText: true),
          ),
        )
        .dy;
    expect(dimRect.top, lessThanOrEqualTo(bTop));
    expect(dimRect.bottom, greaterThan(bTop));

    await gesture.up();
    await tester.pump();
    expect(state.isDraggingChecklistItem, isFalse);
  });

  testWidgets('dragging an item below a later line reorders the document', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(0));
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(2)) + const Offset(0, 5),
    );
    expect(state.dragIndicatorTop, isNotNull);
    expect(find.byKey(const Key('checklist-drag-indicator')), findsOneWidget);
    await gesture.up();
    await tester.pump();

    expect(lines(state), [
      ('b', 'unchecked'),
      ('c', 'unchecked'),
      ('a', 'unchecked'),
      ('d', 'unchecked'),
    ]);
    // The screen must show the new order, not just the document.
    final aTop = tester.getTopLeft(find.text('a', findRichText: true)).dy;
    final cTop = tester.getTopLeft(find.text('c', findRichText: true)).dy;
    expect(aTop, greaterThan(cTop));
  });

  testWidgets('dragging an item above an earlier line reorders the document', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(3));
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(1)) - const Offset(0, 5),
    );
    await gesture.up();
    await tester.pump();

    expect(lines(state), [
      ('a', 'unchecked'),
      ('d', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'unchecked'),
    ]);
  });

  testWidgets('dropping at the original position changes nothing', (
    tester,
  ) async {
    var changes = 0;
    final (state, _) = await pumpEditor(
      tester,
      content: checklist(abcd),
      onChanged: () => changes++,
    );

    final gesture = await lift(tester, checkboxSlot(1));
    expect(state.dragIndicatorTop, isNull);
    expect(find.byKey(const Key('checklist-drag-indicator')), findsNothing);
    await gesture.up();
    await tester.pump();

    expect(lines(state), abcd);
    expect(changes, 0);
  });

  testWidgets('a drag never moves the cursor or opens the keyboard', (
    tester,
  ) async {
    final (state, focusNode) = await pumpEditor(
      tester,
      content: checklist(abcd),
    );
    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 7),
      ChangeSource.local,
    );
    await tester.pump();

    final gesture = await lift(tester, checkboxSlot(0));
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(2)) + const Offset(0, 5),
    );
    await gesture.up();
    await tester.pump();

    expect(lines(state).map((l) => l.$1), ['b', 'c', 'a', 'd']);
    expect(focusNode.hasFocus, isFalse);
    expect(
      state.controller.selection,
      const TextSelection.collapsed(offset: 7),
    );
  });

  testWidgets(
    'with sorting on, items move freely across the checked boundary',
    (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: checklist(const [
          ('a', 'unchecked'),
          ('b', 'unchecked'),
          ('c', 'checked'),
          ('d', 'checked'),
        ]),
        sortChecklistItems: true,
      );

      final gesture = await lift(tester, checkboxSlot(0));
      await dragTo(
        tester,
        gesture,
        tester.getCenter(checkboxSlot(3)) + const Offset(0, 5),
      );
      await gesture.up();
      await tester.pump();

      expect(lines(state), [
        ('b', 'unchecked'),
        ('c', 'checked'),
        ('d', 'checked'),
        ('a', 'unchecked'),
      ]);
    },
  );

  testWidgets(
    'with sorting on, a checked item reorders within the checked section',
    (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: checklist(const [
          ('a', 'unchecked'),
          ('b', 'unchecked'),
          ('c', 'checked'),
          ('d', 'checked'),
        ]),
        sortChecklistItems: true,
      );

      final gesture = await lift(tester, checkboxSlot(3));
      await dragTo(
        tester,
        gesture,
        tester.getCenter(checkboxSlot(2)) - const Offset(0, 5),
      );
      await gesture.up();
      await tester.pump();

      expect(lines(state), [
        ('a', 'unchecked'),
        ('b', 'unchecked'),
        ('d', 'checked'),
        ('c', 'checked'),
      ]);
    },
  );

  testWidgets(
    'with sorting on, a mixed (unsorted) group has no section barrier',
    (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: checklist(const [
          ('a', 'unchecked'),
          ('b', 'checked'),
          ('c', 'unchecked'),
        ]),
        sortChecklistItems: true,
      );

      final gesture = await lift(tester, checkboxSlot(0));
      await dragTo(
        tester,
        gesture,
        tester.getCenter(checkboxSlot(2)) + const Offset(0, 5),
      );
      await gesture.up();
      await tester.pump();

      expect(lines(state), [
        ('b', 'checked'),
        ('c', 'unchecked'),
        ('a', 'unchecked'),
      ]);
    },
  );

  testWidgets('an item alone in its group does not lift', (tester) async {
    const loneItem =
        '{"ops":[{"insert":"intro\\n"},{"insert":"a"},'
        '{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"outro\\n"}]}';
    final (state, _) = await pumpEditor(tester, content: loneItem);

    final gesture = await lift(tester, checkboxSlot(0));
    expect(state.isDraggingChecklistItem, isFalse);
    await gesture.up();
    await tester.pump();

    expect(state.getContent(), contains('"list":"unchecked"'));
  });

  testWidgets('read-only editors do not lift items', (tester) async {
    final (state, _) = await pumpEditor(
      tester,
      content: checklist(abcd),
      canEdit: false,
    );

    final gesture = await lift(tester, checkboxSlot(0));
    expect(state.isDraggingChecklistItem, isFalse);
    await gesture.up();
    await tester.pump();
    expect(lines(state), abcd);
  });

  testWidgets('a drag is one undo entry and undo restores the order', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(0));
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(3)) + const Offset(0, 5),
    );
    await gesture.up();
    await tester.pump();
    expect(lines(state).map((l) => l.$1), ['b', 'c', 'd', 'a']);

    state.controller.undo();
    await tester.pump();
    expect(lines(state), abcd);
  });

  testWidgets('checkbox taps still toggle after a drag', (tester) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(0));
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(2)) + const Offset(0, 5),
    );
    await gesture.up();
    await tester.pump();

    await tester.tap(checkboxSlot(0));
    await tester.pump();
    expect(lines(state).first, ('b', 'checked'));
    // Drain the tap recognizer's double-tap timer.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
