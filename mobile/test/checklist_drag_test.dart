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

String nestedChecklist(List<(String, String, int)> items) => jsonEncode({
  'ops': [
    for (final (text, state, indent) in items) ...[
      {'insert': text},
      {
        'insert': '\n',
        'attributes': {'list': state, if (indent > 0) 'indent': indent},
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

  List<(String, String?, int)> nestedLines(RichTextEditorState state) {
    final doc = state.controller.document;
    final text = doc.toPlainText();
    return [
      for (final line in parseDocumentLines(doc))
        (
          text.substring(line.startOffset, line.startOffset + line.length - 1),
          line.listType,
          line.indent,
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

  const nestedAbcd = [
    ('a', 'unchecked', 0),
    ('a1', 'unchecked', 1),
    ('a2', 'unchecked', 1),
    ('b', 'unchecked', 0),
  ];

  testWidgets('dragging a parent carries its indented children', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(
      tester,
      content: nestedChecklist(nestedAbcd),
    );

    final gesture = await lift(tester, checkboxSlot(0));
    expect(state.dragFeedbackChildCount, 2);

    // The dim scrim covers the whole block, not just the parent line.
    final dimRect = tester.getRect(find.byKey(const Key('checklist-drag-dim')));
    final a2Top = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(QuillEditor),
            matching: find.text('a2', findRichText: true),
          ),
        )
        .dy;
    expect(dimRect.bottom, greaterThan(a2Top));

    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(3)) + const Offset(0, 5),
    );
    await gesture.up();
    await tester.pump();

    expect(nestedLines(state), [
      ('b', 'unchecked', 0),
      ('a', 'unchecked', 0),
      ('a1', 'unchecked', 1),
      ('a2', 'unchecked', 1),
    ]);
  });

  testWidgets('a child reorders within its parent keeping its indent', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(
      tester,
      content: nestedChecklist(nestedAbcd),
    );

    final gesture = await lift(tester, checkboxSlot(1));
    expect(state.dragFeedbackChildCount, 0);
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(2)) + const Offset(0, 5),
    );

    // Checkbox column of an indent-1 line: 36 slot + 24 nesting - 27 inset.
    final editorLeft = tester.getTopLeft(find.byType(RichTextEditor)).dx;
    final indicatorLeft = tester
        .getTopLeft(find.byKey(const Key('checklist-drag-indicator')))
        .dx;
    expect(indicatorLeft, editorLeft + 36 + 24 - 27);

    await gesture.up();
    await tester.pump();

    expect(nestedLines(state), [
      ('a', 'unchecked', 0),
      ('a2', 'unchecked', 1),
      ('a1', 'unchecked', 1),
      ('b', 'unchecked', 0),
    ]);
  });

  testWidgets('dragging sideways re-indents the item in place', (tester) async {
    final (state, _) = await pumpEditor(tester, content: checklist(abcd));

    final gesture = await lift(tester, checkboxSlot(1));
    expect(state.dragIndicatorTop, isNull);
    await dragTo(
      tester,
      gesture,
      tester.getCenter(checkboxSlot(1)) + const Offset(30, 0),
    );

    // The indicator previews the new level: the indent-1 checkbox column.
    expect(state.dragIndicatorTop, isNotNull);
    final editorLeft = tester.getTopLeft(find.byType(RichTextEditor)).dx;
    final indicatorLeft = tester
        .getTopLeft(find.byKey(const Key('checklist-drag-indicator')))
        .dx;
    expect(indicatorLeft, editorLeft + 36 + 24 - 27);

    await gesture.up();
    await tester.pump();

    expect(nestedLines(state), [
      ('a', 'unchecked', 0),
      ('b', 'unchecked', 1),
      ('c', 'unchecked', 0),
      ('d', 'unchecked', 0),
    ]);
  });

  testWidgets('a drop can re-indent the block to the hovered gap level', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(
      tester,
      content: nestedChecklist(nestedAbcd),
    );

    final gesture = await lift(tester, checkboxSlot(3));
    final start = tester.getCenter(checkboxSlot(3));
    // The seam between a and a1, shifted one indent step to the right.
    final gapY = tester.getTopLeft(checkboxSlot(1)).dy;
    await dragTo(tester, gesture, Offset(start.dx + 30, gapY));
    await gesture.up();
    await tester.pump();

    expect(nestedLines(state), [
      ('a', 'unchecked', 0),
      ('b', 'unchecked', 1),
      ('a1', 'unchecked', 1),
      ('a2', 'unchecked', 1),
    ]);
  });

  testWidgets('a parent whose subtree fills the group does not lift', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(
      tester,
      content: nestedChecklist(const [
        ('p', 'unchecked', 0),
        ('c1', 'unchecked', 1),
        ('c2', 'unchecked', 1),
      ]),
    );

    final gesture = await lift(tester, checkboxSlot(0));
    expect(state.isDraggingChecklistItem, isFalse);
    await gesture.up();
    await tester.pump();
    expect(nestedLines(state).map((l) => l.$1), ['p', 'c1', 'c2']);
  });

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
