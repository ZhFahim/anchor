import 'dart:convert';

import 'package:anchor/core/widgets/editor/editor_toolbar.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

const _shortNote = '{"ops":[{"insert":"hi\\n"}]}';
const _boldNote =
    '{"ops":[{"insert":"bold","attributes":{"bold":true}},{"insert":" plain\\n"}]}';
const _linkNote =
    '{"ops":[{"insert":"site","attributes":{"link":"https://example.com"}},{"insert":" end\\n"}]}';

Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  Future<(RichTextEditorState, FocusNode)> pumpEditor(
    WidgetTester tester, {
    String content = _shortNote,
    bool canEdit = true,
    bool sortChecklistItems = true,
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

  // The tappable checkbox is the GestureDetector wrapping the (pointer-
  // absorbed) glyph.
  Finder checkboxSlot(int index) => find
      .ancestor(
        of: find.byType(QuillCheckboxPoint).at(index),
        matching: find.byType(GestureDetector),
      )
      .first;

  Future<void> tapBelowContent(WidgetTester tester) async {
    final rect = tester.getRect(find.byType(RichTextEditor));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 40));
    await tester.pump();
  }

  testWidgets('tapping below short content focuses and moves cursor to end', (
    tester,
  ) async {
    final (state, focusNode) = await pumpEditor(tester);
    expect(focusNode.hasFocus, isFalse);

    await tapBelowContent(tester);

    expect(focusNode.hasFocus, isTrue);
    expect(
      state.controller.selection,
      TextSelection.collapsed(offset: state.controller.document.length - 1),
    );
  });

  testWidgets('tapping below content works when editor is already focused', (
    tester,
  ) async {
    final (state, focusNode) = await pumpEditor(tester);
    await tapBelowContent(tester);
    expect(focusNode.hasFocus, isTrue);

    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    await tester.pump();

    await tapBelowContent(tester);

    expect(focusNode.hasFocus, isTrue);
    expect(
      state.controller.selection,
      TextSelection.collapsed(offset: state.controller.document.length - 1),
    );
  });

  testWidgets('background tap does nothing when read-only', (tester) async {
    final (state, focusNode) = await pumpEditor(tester, canEdit: false);

    await tapBelowContent(tester);

    expect(focusNode.hasFocus, isFalse);
    expect(state.isEditing, isFalse);
  });

  testWidgets('toolbar expands on focus and collapses on unfocus', (
    tester,
  ) async {
    final (_, focusNode) = await pumpEditor(tester);
    expect(find.byType(EditorToolbar), findsNothing);

    await tapBelowContent(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditorToolbar), findsOneWidget);

    focusNode.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditorToolbar), findsNothing);
  });

  testWidgets('onChanged fires on document changes, not selection changes', (
    tester,
  ) async {
    var changes = 0;
    final (state, _) = await pumpEditor(tester, onChanged: () => changes++);

    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 1),
      ChangeSource.local,
    );
    await tester.pump();
    expect(changes, 0);

    state.controller.replaceText(0, 0, 'x', null);
    await tester.pump();
    expect(changes, 1);
  });

  testWidgets('typing rebuilds the chrome but not the editor subtree', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester);
    await tapBelowContent(tester);
    await tester.pump(const Duration(milliseconds: 300));

    final before = tester.widget(find.byType(QuillEditor));
    state.controller.replaceText(0, 0, 'x', null);
    await tester.pump();
    final after = tester.widget(find.byType(QuillEditor));

    expect(identical(before, after), isTrue);
  });

  testWidgets('toolbar reflects formatting at the cursor', (tester) async {
    final (state, _) = await pumpEditor(tester, content: _boldNote);
    await tapBelowContent(tester);
    await tester.pump(const Duration(milliseconds: 300));

    EditorToolbar toolbar() =>
        tester.widget<EditorToolbar>(find.byType(EditorToolbar));
    expect(toolbar().state.isBold, isFalse);

    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );
    await tester.pump();
    expect(toolbar().state.isBold, isTrue);
  });

  testWidgets('link bubble follows the cursor in and out of a link', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: _linkNote);
    await tapBelowContent(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('https://example.com'), findsNothing);

    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );
    await tester.pump();
    expect(find.text('https://example.com'), findsOneWidget);
  });

  testWidgets('checkbox tap toggles without focus, selection, or late '
      'notifications', (tester) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';
    final (state, focusNode) = await pumpEditor(tester, content: checklist);
    expect(focusNode.hasFocus, isFalse);
    final selectionBefore = state.controller.selection;

    await tester.tap(checkboxSlot(0));
    // A controller notification after the tap's own microtasks is the device
    // path that requests the keyboard; the keyboard branch itself is
    // unreachable in tests.
    var lateNotifications = 0;
    state.controller.addListener(() => lateNotifications++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(state.getPlainText(), 'b\nc\na');
    expect(state.getContent(), contains('"list":"checked"'));
    expect(focusNode.hasFocus, isFalse);
    expect(state.controller.selection, selectionBefore);
    expect(lateNotifications, 0);
    // Guards must be released so the next tap can open the keyboard.
    expect(state.controller.skipRequestKeyboard, isFalse);
  });

  testWidgets('tap beside the checkbox glyph toggles instead of falling '
      'through to the editor', (tester) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';
    final (state, focusNode) = await pumpEditor(
      tester,
      content: checklist,
      sortChecklistItems: false,
    );
    final selectionBefore = state.controller.selection;

    // The glyph's own InkWell is only fontSize wide; a tap beside it in the
    // leading slot must still toggle instead of reaching the editor.
    final glyph = tester.getRect(
      find.descendant(
        of: find.byType(QuillCheckboxPoint).at(2),
        matching: find.byType(InkWell),
      ),
    );
    await tester.tapAt(Offset(glyph.left - 4, glyph.center.dy));
    await tester.pump();

    expect(state.getContent(), contains('"list":"checked"'));
    expect(state.controller.selection, selectionBefore);
    expect(focusNode.hasFocus, isFalse);

    // A tap on the line's text is not part of the slot: it must still move
    // the cursor.
    await tester.tap(find.text('b', findRichText: true));
    await tester.pump();
    expect(state.controller.selection, isNot(selectionBefore));
    // Let the tap recognizer's double-tap window expire.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('checkbox tap repaints the editor and stays tappable', (
    tester,
  ) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';
    final (state, _) = await pumpEditor(tester, content: checklist);

    List<bool> renderedChecks() => tester
        .widgetList<QuillCheckboxPoint>(find.byType(QuillCheckboxPoint))
        .map((w) => w.value)
        .toList();

    // The rendered checkboxes must reflect the toggle and the sort, not
    // just the document.
    await tester.tap(checkboxSlot(0));
    await tester.pump();
    expect(renderedChecks(), [false, false, true]);

    // A follow-up tap must hit the re-rendered tree, not a stale line.
    await tester.tap(checkboxSlot(2));
    await tester.pump();
    expect(renderedChecks(), [false, false, false]);
    expect(state.getPlainText(), 'b\nc\na');
    expect(state.getContent(), isNot(contains('"list":"checked"')));
  });

  testWidgets('checkbox tap preserves scroll position in a long list', (
    tester,
  ) async {
    final ops = [
      for (var i = 0; i < 40; i++) ...[
        {'insert': 'item $i'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ],
    ];
    await pumpEditor(tester, content: jsonEncode({'ops': ops}));

    final scrollController = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!;
    scrollController.jumpTo(200);
    await tester.pump();

    await tester.tap(checkboxSlot(10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(scrollController.offset, 200);
  });

  group('editor-level duplicate of a checkbox tap', () {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';

    // Quill's transparent tap recognizer delivers a checkbox tap to the
    // editor a second time; unconsumed, the duplicate moves the cursor to
    // the tapped line and opens the keyboard on a device.
    testWidgets('cannot drag the cursor to the tapped line', (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: checklist,
        sortChecklistItems: false,
      );
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 3),
        ChangeSource.local,
      );
      await tester.pump();

      await tester.tap(checkboxSlot(0));
      await tester.pump();

      expect(state.getContent(), contains('"list":"checked"'));
      expect(
        state.controller.selection,
        const TextSelection.collapsed(offset: 3),
      );
    });

    testWidgets('consumption does not leak into later editor taps', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(
        tester,
        content: checklist,
        sortChecklistItems: false,
      );

      await tester.tap(checkboxSlot(0));
      await tester.pump();

      final onTapUp = tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .config
          .onTapUp!;
      expect(
        onTapUp(
          TapUpDetails(kind: PointerDeviceKind.touch),
          (_) => const TextPosition(offset: 0),
        ),
        isFalse,
      );

      // A genuine tap on the line's text must still move the cursor.
      final selectionBefore = state.controller.selection;
      await tester.tap(find.text('b', findRichText: true));
      await tester.pump();
      expect(state.controller.selection, isNot(selectionBefore));
      // Let the tap recognizer's double-tap window expire.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('external content sync', () {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';

    Future<(RichTextEditorState, FocusNode, void Function(String))> pumpHost(
      WidgetTester tester, {
      String content = _shortNote,
      VoidCallback? onChanged,
    }) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var current = content;
      late StateSetter rebuild;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RichTextEditor(
                initialContent: current,
                focusNode: focusNode,
                onChanged: onChanged,
              );
            },
          ),
        ),
      );
      await tester.pump();
      final state = tester.state<RichTextEditorState>(
        find.byType(RichTextEditor),
      );
      return (state, focusNode, (next) => rebuild(() => current = next));
    }

    testWidgets('reload replaces the document without focus or onChanged', (
      tester,
    ) async {
      var changes = 0;
      final (state, focusNode, setContent) = await pumpHost(
        tester,
        onChanged: () => changes++,
      );
      expect(state.getPlainText(), 'hi');

      setContent('{"ops":[{"insert":"hello world\\n"}]}');
      await tester.pump();
      await tester.pump();

      expect(state.getPlainText(), 'hello world');
      expect(find.text('hello world', findRichText: true), findsOneWidget);
      expect(changes, 0);
      expect(focusNode.hasFocus, isFalse);
      expect(state.controller.skipRequestKeyboard, isFalse);
    });

    testWidgets('rebuild with equivalent content leaves the editor untouched', (
      tester,
    ) async {
      var changes = 0;
      final (state, _, setContent) = await pumpHost(
        tester,
        onChanged: () => changes++,
      );
      final docBefore = state.controller.document;

      // Same delta, different JSON string.
      setContent('{"ops": [{"insert": "hi\\n"}]}');
      await tester.pump();

      expect(identical(state.controller.document, docBefore), isTrue);
      expect(changes, 0);
    });

    testWidgets('editing keeps working after a reload: onChanged and '
        'checklist sorting are rebound to the new document', (tester) async {
      var changes = 0;
      final (state, _, setContent) = await pumpHost(
        tester,
        onChanged: () => changes++,
      );

      setContent(checklist);
      await tester.pump();
      expect(changes, 0);

      await tester.tap(checkboxSlot(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.getPlainText(), 'b\nc\na');
      expect(state.getContent(), contains('"list":"checked"'));
      expect(changes, greaterThan(0));
    });

    testWidgets('selection is clamped when the reloaded document is shorter', (
      tester,
    ) async {
      final (state, _, setContent) = await pumpHost(
        tester,
        content: '{"ops":[{"insert":"a long first line\\n"}]}',
      );
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 15),
        ChangeSource.local,
      );
      await tester.pump();

      setContent('{"ops":[{"insert":"ab\\n"}]}');
      await tester.pump();

      expect(state.controller.selection.extentOffset, 2);
      expect(
        state.controller.selection.extentOffset,
        lessThan(state.controller.document.length),
      );
    });
  });

  testWidgets('content round-trips through getContent', (tester) async {
    final (state, _) = await pumpEditor(tester);
    final decoded = jsonDecode(state.getContent()) as Map<String, dynamic>;
    expect(decoded['ops'], [
      {'insert': 'hi\n'},
    ]);
  });
}
