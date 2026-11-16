import 'dart:convert';

import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:anchor/features/notes/presentation/editor/document_lines.dart';
import 'package:anchor/features/notes/presentation/editor/editor_format.dart';
import 'package:anchor/features/notes/presentation/editor/editor_link.dart';
import 'package:anchor/features/notes/presentation/editor/editor_palette.dart';
import 'package:anchor/features/notes/presentation/editor/line_kind.dart';
import 'package:anchor/features/notes/presentation/editor/rich_text_editor.dart';
import 'package:anchor/features/notes/presentation/editor/slash_hint.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
// Quill doesn't export its line's render object.
// ignore: implementation_imports
import 'package:flutter_quill/src/editor/widgets/text/text_line.dart'
    show RenderEditableTextLine;
import 'package:flutter_test/flutter_test.dart';

const _shortNote = '{"ops":[{"insert":"hi\\n"}]}';
const _boldNote =
    '{"ops":[{"insert":"bold","attributes":{"bold":true}},{"insert":" plain\\n"}]}';
const _linkNote =
    '{"ops":[{"insert":"site","attributes":{"link":"https://example.com"}},{"insert":" end\\n"}]}';

final _plain = AnchorColors.light.notes['none']!;

final palette = EditorPalette(
  muted: _plain.muted,
  surface: _plain.surface,
  border: _plain.border,
  background: _plain.bg,
  highlightFill: (name) => AnchorColors.light.highlights[name]!.fill,
  highlightInk: (name) => AnchorColors.light.highlights[name]!.ink!,
);

Widget wrap(Widget Function(ScrollController scroll) builder) {
  return MaterialApp(
    localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
    home: Scaffold(body: _Scroller(builder: builder)),
  );
}

class _Scroller extends StatefulWidget {
  const _Scroller({required this.builder});

  final Widget Function(ScrollController scroll) builder;

  @override
  State<_Scroller> createState() => _ScrollerState();
}

class _ScrollerState extends State<_Scroller> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    child: widget.builder(_scroll),
  );
}

bool showsCaret(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderEditableTextLine>()
    .first
    .cursorCont
    .blink
    .value;

Finder checkboxSlot(int index) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.checked != null)
    .at(index);

void main() {
  Future<(RichTextEditorState, FocusNode)> pumpEditor(
    WidgetTester tester, {
    String content = _shortNote,
    bool canEdit = true,
    bool sortChecklistItems = true,
    VoidCallback? onChanged,
    ValueChanged<bool>? onEditingChanged,
    ValueChanged<EditorLink>? onLinkTap,
    VoidCallback? onReadOnlyTap,
    bool hasSlashHint = false,
    ValueChanged<bool>? onBlankChanged,
    ValueChanged<String>? onBackspaceAtStart,
    bool isCheckedFolded = false,
    ValueChanged<bool>? onCheckedFoldChanged,
  }) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      wrap(
        (scroll) => RichTextEditor(
          initialContent: content,
          focusNode: focusNode,
          canEdit: canEdit,
          sortChecklistItems: sortChecklistItems,
          onChanged: onChanged,
          onEditingChanged: onEditingChanged,
          onLinkTap: onLinkTap,
          onReadOnlyTap: onReadOnlyTap,
          hasSlashHint: hasSlashHint,
          onBlankChanged: onBlankChanged,
          onBackspaceAtStart: onBackspaceAtStart,
          isCheckedFolded: isCheckedFolded,
          onCheckedFoldChanged: onCheckedFoldChanged,
          scrollController: scroll,
          palette: palette,
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<RichTextEditorState>(
      find.byType(RichTextEditor),
    );
    return (state, focusNode);
  }

  testWidgets('focusEnd focuses and moves the caret to the end', (
    tester,
  ) async {
    final (state, focusNode) = await pumpEditor(tester);
    expect(focusNode.hasFocus, isFalse);

    state.focusEnd();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(showsCaret(tester), isTrue);
    expect(
      state.controller.selection,
      TextSelection.collapsed(offset: state.controller.document.length - 1),
    );
  });

  testWidgets('the caret blinks when a tap brings focus back from the title '
      'to where it was', (tester) async {
    final focusNode = FocusNode();
    final titleFocus = FocusNode();
    addTearDown(focusNode.dispose);
    addTearDown(titleFocus.dispose);
    await tester.pumpWidget(
      wrap(
        (scroll) => Column(
          children: [
            TextField(focusNode: titleFocus),
            RichTextEditor(
              initialContent: _shortNote,
              focusNode: focusNode,
              scrollController: scroll,
              palette: palette,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<RichTextEditorState>(
      find.byType(RichTextEditor),
    );
    Offset pastTheEnd() {
      final editor = tester.allRenderObjects.whereType<RenderEditor>().first;
      final end = editor.getLocalRectForCaret(const TextPosition(offset: 2));
      return editor.localToGlobal(end.centerRight) + const Offset(40, 0);
    }

    await tester.tapAt(pastTheEnd());
    await tester.pumpAndSettle();
    titleFocus.requestFocus();
    await tester.pumpAndSettle();
    expect(titleFocus.hasFocus, isTrue);
    await tester.tapAt(pastTheEnd());
    await tester.pump(const Duration(milliseconds: 400));

    expect(focusNode.hasFocus, isTrue);
    expect(state.selection.baseOffset, 2);
    expect(showsCaret(tester), isTrue);
  });

  testWidgets('a read-only editor never counts as editing', (tester) async {
    final editing = <bool>[];
    final (_, focusNode) = await pumpEditor(
      tester,
      canEdit: false,
      onEditingChanged: editing.add,
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(editing, isEmpty);
    expect(showsCaret(tester), isFalse);
  });

  testWidgets('a tap on a read-only note is reported', (tester) async {
    var taps = 0;
    await pumpEditor(tester, canEdit: false, onReadOnlyTap: () => taps++);

    await tester.tap(find.text('hi', findRichText: true));
    await tester.pump(const Duration(seconds: 1));

    expect(taps, 1);
  });

  testWidgets('onEditingChanged follows focus', (tester) async {
    final editing = <bool>[];
    final (state, focusNode) = await pumpEditor(
      tester,
      onEditingChanged: editing.add,
    );

    state.focusEnd();
    await tester.pump();
    focusNode.unfocus();
    await tester.pump();

    expect(editing, [true, false]);
    expect(showsCaret(tester), isFalse);
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

  testWidgets('typing does not rebuild the editor subtree', (tester) async {
    final (state, _) = await pumpEditor(tester);
    state.focusEnd();
    await tester.pump();

    final before = tester.widget(find.byType(QuillEditor));
    state.controller.replaceText(0, 0, 'x', null);
    await tester.pump();
    final after = tester.widget(find.byType(QuillEditor));

    expect(identical(before, after), isTrue);
  });

  testWidgets('typing in one item leaves the other items\' boxes as they were', (
    tester,
  ) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"checked"}}]}';
    final (state, _) = await pumpEditor(tester, content: checklist);
    state.focusEnd();
    await tester.pump();
    final second = tester.widget(checkboxSlot(1));

    state.controller.replaceText(1, 0, 'x', null);
    await tester.pump();

    expect(identical(tester.widget(checkboxSlot(1)), second), isTrue);
    expect(tester.widget<Semantics>(checkboxSlot(0)).properties.label, 'ax');
    expect(tester.widget<Semantics>(checkboxSlot(1)).properties.checked, true);
  });

  testWidgets('list lines keep their spacing while typing', (tester) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"checked"}}]}';
    final (state, _) = await pumpEditor(tester, content: checklist);
    state.focusEnd();
    await tester.pump();
    final boxes = [for (var i = 0; i < 3; i++) tester.getRect(checkboxSlot(i))];

    state.controller.replaceText(1, 0, 'x', null);
    await tester.pump();

    expect([
      for (var i = 0; i < 3; i++) tester.getRect(checkboxSlot(i)),
    ], boxes);
  });

  testWidgets('typing above a list leaves its lines laid out', (tester) async {
    const note =
        '{"ops":[{"insert":"x\\n"},'
        '{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"checked"}}]}';
    final (state, _) = await pumpEditor(tester, content: note);
    state.focusEnd();
    await tester.pump();
    RenderEditableTextLine lineOf(String words) {
      RenderObject? box = tester.renderObject(
        find.text(words, findRichText: true),
      );
      while (box is! RenderEditableTextLine) {
        box = box!.parent;
      }
      return box;
    }

    state.controller.replaceText(1, 0, 'y', null);
    await tester.pump(null, EnginePhase.build);

    expect(lineOf('a').debugNeedsLayout, isFalse);
    expect(lineOf('b').debugNeedsLayout, isFalse);
    await tester.pump();
  });

  testWidgets('list numbers follow a line that stops being numbered', (
    tester,
  ) async {
    const numbered =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"ordered"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"ordered"}},'
        '{"insert":"c"},{"insert":"\\n","attributes":{"list":"ordered"}}]}';
    final (state, _) = await pumpEditor(tester, content: numbered);
    expect(find.text('3.'), findsOneWidget);

    state.controller.formatText(1, 0, Attribute.clone(Attribute.ol, null));
    await tester.pump();

    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('3.'), findsNothing);
  });

  testWidgets('a change repaints the highlights in its own frame', (
    tester,
  ) async {
    const marked =
        '{"ops":[{"insert":"Draft the "},'
        '{"insert":"release notes","attributes":{"highlight":"green"}},'
        '{"insert":"\\n"}]}';
    final (state, _) = await pumpEditor(tester, content: marked);

    state.controller.replaceText(0, 0, 'x', null);
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('formatting at the caret reads from the controller', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: _boldNote);
    state.focusEnd();
    await tester.pump();
    expect(state.controller.isOn(Attribute.bold), isFalse);

    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );
    await tester.pump();
    expect(state.controller.isOn(Attribute.bold), isTrue);
  });

  testWidgets('a tap on a link reports the whole link', (tester) async {
    final links = <EditorLink>[];
    await pumpEditor(tester, content: _linkNote, onLinkTap: links.add);

    final text = tester.getTopLeft(find.text('site end', findRichText: true));
    await tester.tapAt(text + const Offset(8, 10));
    await tester.pump(const Duration(seconds: 1));

    expect(links, hasLength(1));
    expect(links.single.url, 'https://example.com');
    expect(links.single.start, 0);
    expect(links.single.length, 4);
  });

  testWidgets('a link in two formats is still one link', (tester) async {
    const splitLink =
        '{"ops":[{"insert":"si","attributes":{"link":"https://example.com","bold":true}},'
        '{"insert":"te","attributes":{"link":"https://example.com"}},'
        '{"insert":" end\\n"}]}';
    final links = <EditorLink>[];
    await pumpEditor(tester, content: splitLink, onLinkTap: links.add);

    final text = tester.getTopLeft(find.text('site end', findRichText: true));
    await tester.tapAt(text + const Offset(24, 10));
    await tester.pump(const Duration(seconds: 1));

    expect(links, hasLength(1));
    expect(links.single.start, 0);
    expect(links.single.length, 4);
  });

  testWidgets('a tap past a link reports nothing', (tester) async {
    final links = <EditorLink>[];
    await pumpEditor(tester, content: _linkNote, onLinkTap: links.add);

    final text = tester.getRect(find.text('site end', findRichText: true));
    await tester.tapAt(Offset(text.right - 4, text.top + 10));
    await tester.pump(const Duration(seconds: 1));

    expect(links, isEmpty);
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
    // On a device, a late controller notification opens the keyboard.
    var lateNotifications = 0;
    state.controller.addListener(() => lateNotifications++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(state.getPlainText(), 'a\nb\nc');
    expect(state.getContent(), contains('"list":"checked"'));
    expect(lateNotifications, 0);

    await tester.pump(AnchorTokens.motionDurationSinkDelay);
    await tester.pump();
    expect(state.getPlainText(), 'b\nc\na');
    expect(focusNode.hasFocus, isFalse);
    expect(state.controller.selection, selectionBefore);
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

    // The box is narrower than its tap target.
    final glyph = tester.getRect(
      find
          .descendant(
            of: checkboxSlot(2),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    await tester.tapAt(Offset(glyph.right + 4, glyph.center.dy));
    await tester.pump();

    expect(state.getContent(), contains('"list":"checked"'));
    expect(state.controller.selection, selectionBefore);
    expect(focusNode.hasFocus, isFalse);

    await tester.tap(find.text('b', findRichText: true));
    await tester.pump();
    expect(state.controller.selection, isNot(selectionBefore));
    // Let the tap recognizer's double-tap window expire.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the box takes taps 44 wide over its whole line, and a tick '
      'pops only the check mark', (tester) async {
    const checklist =
        '{"ops":[{"insert":"a"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
        '{"insert":"b"},{"insert":"\\n","attributes":{"list":"unchecked"}}]}';
    final (state, _) = await pumpEditor(
      tester,
      content: checklist,
      sortChecklistItems: false,
    );

    final target = tester.getRect(checkboxSlot(1));
    final first = tester.getRect(checkboxSlot(0));
    expect(target.width, AnchorTokens.sizeControlMedium);
    expect(target.top, moreOrLessEquals(first.bottom, epsilon: 0.1));

    await tester.tapAt(Offset(target.right - 2, target.top + 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(state.getContent(), contains('"list":"checked"'));

    final scales = find.descendant(
      of: checkboxSlot(1),
      matching: find.byType(Transform),
    );
    expect(scales, findsOneWidget);
    expect(
      find.descendant(of: scales, matching: find.byType(Icon)),
      findsOneWidget,
    );
    expect(tester.widget<Transform>(scales).transform.entry(0, 0), lessThan(1));
    await tester.pump(AnchorTokens.motionDurationTick);
    expect(
      tester.widget<Transform>(scales).transform.entry(0, 0),
      moreOrLessEquals(1),
    );
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

    List<bool?> renderedChecks() => [
      for (var i = 0; i < 3; i++)
        tester.widget<Semantics>(checkboxSlot(i)).properties.checked,
    ];

    await tester.tap(checkboxSlot(0));
    await tester.pump();
    expect(renderedChecks(), [true, false, false]);
    await tester.pump(AnchorTokens.motionDurationSinkDelay);
    expect(renderedChecks(), [false, false, true]);

    await tester.tap(checkboxSlot(2));
    await tester.pump();
    await tester.pump(AnchorTokens.motionDurationSinkDelay);
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
        .widget<RichTextEditor>(find.byType(RichTextEditor))
        .scrollController;
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
    // editor a second time.
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
          (scroll) => StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RichTextEditor(
                initialContent: current,
                focusNode: focusNode,
                onChanged: onChanged,
                scrollController: scroll,
                palette: palette,
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
      // The new text is applied after the frame that brings it.
      await tester.pump();
      await tester.pump();
      expect(changes, 0);

      await tester.tap(checkboxSlot(0));
      await tester.pump();
      await tester.pump(AnchorTokens.motionDurationSinkDelay);

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

  group('pasting an address', () {
    Future<bool> paste(
      WidgetTester tester,
      RichTextEditorState state,
      String text,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async =>
            call.method == 'Clipboard.getData' ? {'text': text} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final onPaste =
          // ignore: experimental_member_use
          state.controller.config.clipboardConfig!.onClipboardPaste!;
      final handled = await onPaste();
      await tester.pump();
      return handled;
    }

    testWidgets('at the caret inserts it as a link', (tester) async {
      final (state, _) = await pumpEditor(tester);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 2),
        ChangeSource.local,
      );

      expect(await paste(tester, state, ' https://example.com '), isTrue);

      expect(state.getPlainText(), 'hihttps://example.com');
      expect(jsonDecode(state.getContent())['ops'], [
        {'insert': 'hi'},
        {
          'insert': 'https://example.com',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': '\n'},
      ]);
      expect(
        state.controller.selection,
        const TextSelection.collapsed(offset: 21),
      );
    });

    testWidgets('over selected words links them', (tester) async {
      final (state, _) = await pumpEditor(tester);
      state.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 2),
        ChangeSource.local,
      );

      expect(await paste(tester, state, 'www.example.com'), isTrue);

      expect(state.getPlainText(), 'hi');
      expect(jsonDecode(state.getContent())['ops'], [
        {
          'insert': 'hi',
          'attributes': {'link': 'https://www.example.com'},
        },
        {'insert': '\n'},
      ]);
      expect(
        state.controller.selection,
        const TextSelection.collapsed(offset: 2),
      );
    });

    testWidgets('starting with www. keeps its words and links over https', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 2),
        ChangeSource.local,
      );

      expect(await paste(tester, state, 'www.example.com/a'), isTrue);

      expect(jsonDecode(state.getContent())['ops'], [
        {'insert': 'hi'},
        {
          'insert': 'www.example.com/a',
          'attributes': {'link': 'https://www.example.com/a'},
        },
        {'insert': '\n'},
      ]);
    });

    testWidgets('leaves other text to the normal paste', (tester) async {
      final (state, _) = await pumpEditor(tester);

      for (final text in ['just words', 'example.com', 'see www.example.com']) {
        expect(await paste(tester, state, text), isFalse, reason: text);
      }

      expect(state.getPlainText(), 'hi');
    });

    testWidgets('leaves code to the normal paste', (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content:
            '{"ops":[{"insert":"let a"},'
            '{"insert":"\\n","attributes":{"code-block":true}}]}',
      );
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );

      expect(await paste(tester, state, 'https://example.com'), isFalse);
    });
  });

  testWidgets('a plain-text note opens with its text as paragraphs', (
    tester,
  ) async {
    final (state, _) = await pumpEditor(tester, content: 'milk\neggs');

    expect(state.getPlainText(), 'milk\neggs');
    expect(find.text('milk', findRichText: true), findsOneWidget);
    expect(state.matchesContent('milk\neggs'), isTrue);
  });

  testWidgets('a delta stored as the bare list opens too', (tester) async {
    final (state, _) = await pumpEditor(
      tester,
      content: '[{"insert":"hi there\\n"}]',
    );

    expect(state.getPlainText(), 'hi there');
  });

  group('commands for the writing tools', () {
    testWidgets('setLink links the words in a range, or inserts at the '
        'caret', (tester) async {
      final (state, _) = await pumpEditor(tester);

      state.setLink(
        const TextRange(start: 0, end: 2),
        'Our site',
        'https://example.com',
      );
      await tester.pump();
      expect(state.getPlainText(), 'Our site');

      state.setLink(
        const TextRange.collapsed(8),
        ' more',
        'https://example.org',
      );
      await tester.pump();

      expect(jsonDecode(state.getContent())['ops'], [
        {
          'insert': 'Our site',
          'attributes': {'link': 'https://example.com'},
        },
        {
          'insert': ' more',
          'attributes': {'link': 'https://example.org'},
        },
        {'insert': '\n'},
      ]);
      expect(state.selection, const TextSelection.collapsed(offset: 13));
    });

    testWidgets('removeLink keeps the words and drops the address', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester, content: _linkNote);

      state.removeLink(
        const EditorLink(
          url: 'https://example.com',
          start: 0,
          length: 4,
          rect: Rect.zero,
        ),
      );
      await tester.pump();

      expect(state.getPlainText(), 'site end');
      expect(state.getContent(), isNot(contains('link')));
    });

    testWidgets('textIn reads a range, and nothing for a caret', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester, content: _linkNote);

      expect(state.textIn(const TextRange(start: 5, end: 8)), 'end');
      expect(state.textIn(const TextRange.collapsed(3)), '');
    });

    testWidgets('applyLineKind adds a line at the end when nothing is '
        'being edited', (tester) async {
      final (state, focusNode) = await pumpEditor(tester);

      state.applyLineKind(LineKind.checklist);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(state.getPlainText(), 'hi');
      expect(state.getContent(), contains('"list":"unchecked"'));
      expect(state.controller.document.toPlainText(), 'hi\n\n');

      state.applyLineKind(LineKind.bullet);
      await tester.pump();
      expect(state.controller.lineKind, LineKind.bullet);
      expect(state.controller.document.toPlainText(), 'hi\n\n');
    });

    testWidgets('paintHighlight paints the selected words and keeps them '
        'selected, and clearHighlight takes it off', (tester) async {
      final (state, _) = await pumpEditor(tester);
      const words = TextSelection(baseOffset: 0, extentOffset: 2);
      state.controller.updateSelection(words, ChangeSource.local);
      expect(state.hasSelection, isTrue);

      state.paintHighlight('green');
      expect(state.controller.highlight, 'green');
      expect(state.selection, words);

      state.paintHighlight('pink');
      expect(state.controller.highlight, 'pink');

      state.clearHighlight();
      expect(state.controller.highlight, isNull);
      expect(state.getContent(), isNot(contains('highlight')));
    });

    testWidgets('startLineAtTop adds a line of that kind above the text and '
        'puts the caret on it', (tester) async {
      final (state, focusNode) = await pumpEditor(tester);

      state.startLineAtTop(LineKind.checklist);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(state.controller.document.toPlainText(), '\nhi\n');
      expect(state.selection, const TextSelection.collapsed(offset: 0));
      expect(state.controller.lineKind, LineKind.checklist);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 1),
        ChangeSource.local,
      );
      expect(state.controller.lineKind, LineKind.text);
    });

    testWidgets('startLineAtTop uses an empty first line of text', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
      );

      state.startLineAtTop(LineKind.bullet);
      await tester.pump();

      expect(state.controller.document.toPlainText(), '\n');
      expect(state.controller.lineKind, LineKind.bullet);
    });

    testWidgets('a new line at the top doesn\'t take the first line\'s style', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(
        tester,
        content:
            '{"ops":[{"insert":"Plan"},'
            '{"insert":"\\n","attributes":{"header":1}}]}',
      );

      state.startLineAtTop(LineKind.bullet);
      await tester.pump();

      expect(state.controller.document.toPlainText(), '\nPlan\n');
      expect(state.controller.lineKind, LineKind.bullet);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 2),
        ChangeSource.local,
      );
      expect(state.controller.lineKind, LineKind.h1);
    });

    testWidgets('onSelectionChanged follows the caret, not typing that '
        'keeps it', (tester) async {
      final seen = <TextSelection>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        wrap(
          (scroll) => RichTextEditor(
            initialContent: _shortNote,
            focusNode: focusNode,
            scrollController: scroll,
            palette: palette,
            onSelectionChanged: seen.add,
          ),
        ),
      );
      final state = tester.state<RichTextEditorState>(
        find.byType(RichTextEditor),
      );

      state.controller.formatText(0, 2, Attribute.bold);
      expect(seen, isEmpty);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 1),
        ChangeSource.local,
      );
      expect(seen, [const TextSelection.collapsed(offset: 1)]);
    });

    void type(RichTextEditorState state, int offset, String text) {
      for (var index = 0; index < text.length; index++) {
        state.controller.replaceText(
          offset + index,
          0,
          text[index],
          TextSelection.collapsed(offset: offset + index + 1),
        );
      }
    }

    testWidgets('slashQuery follows a slash while writing, and clearSlash '
        'takes it out', (tester) async {
      final (state, focusNode) = await pumpEditor(tester);
      state.focusEnd();
      await tester.pump();

      type(state, 2, '\n/todo');
      expect(state.slashQuery.value, 'todo');

      state.clearSlash();
      expect(state.slashQuery.value, isNull);
      expect(state.controller.document.toPlainText(), 'hi\n\n');

      type(state, 3, '/x');
      expect(state.slashQuery.value, 'x');
      await tester.pump();
      focusNode.unfocus();
      await tester.pump();
      expect(state.slashQuery.value, isNull);
    });

    testWidgets('slashQuery answers only a slash that was typed', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester);
      state.focusEnd();
      await tester.pump();

      // Pasted.
      state.controller.replaceText(
        2,
        0,
        '\nx /todo',
        const TextSelection.collapsed(offset: 10),
      );
      expect(state.slashQuery.value, isNull);

      type(state, 10, ' /x');
      expect(state.slashQuery.value, 'x');

      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      expect(state.slashQuery.value, isNull);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 13),
        ChangeSource.local,
      );
      expect(state.slashQuery.value, isNull);
    });

    testWidgets('slashQuery answers a slash typed on a list line or a '
        'heading, but not in code', (tester) async {
      const kinds = <String, (Map<String, Object>, bool)>{
        'checklist': ({'list': 'unchecked'}, true),
        'bullet': ({'list': 'bullet'}, true),
        'numbered': ({'list': 'ordered'}, true),
        'heading': ({'header': 1}, true),
        'quote': ({'blockquote': true}, true),
        'code': ({'code-block': true}, false),
      };
      for (final MapEntry(key: kind, value: (attributes, opens))
          in kinds.entries) {
        final (state, _) = await pumpEditor(
          tester,
          content: jsonEncode({
            'ops': [
              {'insert': 'eggs'},
              {'insert': '\n', 'attributes': attributes},
            ],
          }),
        );
        state.focusEnd();
        await tester.pump();

        type(state, 4, ' /b');
        expect(state.slashQuery.value, opens ? 'b' : isNull, reason: kind);
      }
    });

    testWidgets('a space right after the slash closes it', (tester) async {
      final (state, _) = await pumpEditor(tester);
      state.focusEnd();
      await tester.pump();

      type(state, 2, ' /');
      expect(state.slashQuery.value, '');

      type(state, 4, ' ');
      expect(state.slashQuery.value, isNull);
    });

    testWidgets('caretRect waits for a new line to be laid out', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester);
      state.focusEnd();
      await tester.pump();

      state.controller.replaceText(
        2,
        0,
        '\nmore',
        const TextSelection.collapsed(offset: 7),
      );
      expect(state.caretRect(), isNull);

      await tester.pump();
      expect(state.caretRect(), isNotNull);
    });
  });

  group('typing on the keyboard', () {
    Future<void> type(WidgetTester tester, String text) async {
      final editor = tester.state<RichTextEditorState>(
        find.byType(RichTextEditor),
      );
      for (final character in text.split('')) {
        final value = editor.controller.plainTextEditingValue;
        final at = value.selection.start;
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: value.text.replaceRange(at, value.selection.end, character),
            selection: TextSelection.collapsed(offset: at + 1),
          ),
        );
        await tester.pump();
      }
    }

    Future<RichTextEditorState> startTyping(
      WidgetTester tester, {
      String content = '{"ops":[{"insert":"\\n"}]}',
    }) async {
      final (state, focusNode) = await pumpEditor(tester, content: content);
      focusNode.requestFocus();
      await tester.pump();
      return state;
    }

    List<Map<String, dynamic>> opsOf(RichTextEditorState state) => [
      for (final op in state.controller.document.toDelta().toList())
        op.toJson(),
    ];

    testWidgets('a starter and a space start a line of that kind', (
      tester,
    ) async {
      final state = await startTyping(tester);

      await type(tester, '- milk');

      expect(state.controller.lineKind, LineKind.bullet);
      expect(state.controller.document.toPlainText(), 'milk\n');

      await type(tester, '\n[x] eggs');
      expect(opsOf(state), [
        {'insert': 'milk'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'eggs'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'},
        },
      ]);
    });

    testWidgets('Undo right after a starter gives back what was typed', (
      tester,
    ) async {
      final state = await startTyping(tester);

      await type(tester, '1. ');
      expect(state.controller.lineKind, LineKind.numbered);

      state.controller.undo();
      await tester.pump();

      expect(state.controller.document.toPlainText(), '1. \n');
      expect(state.controller.lineKind, LineKind.text);
    });

    testWidgets('a starter in a code block stays text', (tester) async {
      final state = await startTyping(
        tester,
        content: '{"ops":[{"insert":"\\n","attributes":{"code-block":true}}]}',
      );

      await type(tester, '# ');

      expect(state.controller.document.toPlainText(), '# \n');
      expect(state.controller.lineKind, LineKind.code);
    });

    testWidgets('an address links once a space follows it, without the '
        'brackets and punctuation around it', (tester) async {
      final state = await startTyping(tester);

      await type(tester, 'see (www.example.com/a). ok');

      expect(opsOf(state), [
        {'insert': 'see ('},
        {
          'insert': 'www.example.com/a',
          'attributes': {'link': 'https://www.example.com/a'},
        },
        {'insert': '). ok\n'},
      ]);
    });

    testWidgets('an address with its scheme and an email link at a line '
        'break', (tester) async {
      final state = await startTyping(tester);

      await type(tester, 'https://example.com\nhi@example.com\n');

      expect(opsOf(state), [
        {
          'insert': 'https://example.com',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': '\n'},
        {
          'insert': 'hi@example.com',
          'attributes': {'link': 'mailto:hi@example.com'},
        },
        {'insert': '\n\n'},
      ]);
    });

    testWidgets('nothing links letter by letter or on a bare name', (
      tester,
    ) async {
      final state = await startTyping(tester);

      await type(tester, 'https://example.com');
      expect(state.getContent(), isNot(contains('link')));

      await type(tester, ' and example.com ');
      expect(opsOf(state), [
        {
          'insert': 'https://example.com',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': ' and example.com \n'},
      ]);
    });

    testWidgets('an address in bold keeps its bold', (tester) async {
      final state = await startTyping(
        tester,
        content:
            '{"ops":[{"insert":"www.example.com","attributes":{"bold":true}},'
            '{"insert":"\\n"}]}',
      );
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 15),
        ChangeSource.local,
      );
      await tester.pump();

      await type(tester, ' ');

      expect(opsOf(state).first, {
        'insert': 'www.example.com',
        'attributes': {'bold': true, 'link': 'https://www.example.com'},
      });
    });

    testWidgets('an address in code or already linked stays as it is', (
      tester,
    ) async {
      final code = await startTyping(
        tester,
        content: '{"ops":[{"insert":"\\n","attributes":{"code-block":true}}]}',
      );
      await type(tester, 'www.example.com ');
      expect(code.getContent(), isNot(contains('link')));

      final linked = await startTyping(
        tester,
        content:
            '{"ops":[{"insert":"www.example.com",'
            '"attributes":{"link":"https://other.example"}},'
            '{"insert":"\\n"}]}',
      );
      linked.controller.updateSelection(
        const TextSelection.collapsed(offset: 15),
        ChangeSource.local,
      );
      await tester.pump();
      await type(tester, ' ');
      expect(linked.getContent(), contains('https://other.example'));
      expect(linked.getContent(), isNot(contains('https://www.')));
    });

    testWidgets('Undo right after a link takes off only the link', (
      tester,
    ) async {
      final state = await startTyping(tester);

      await type(tester, 'www.example.com ');
      expect(state.getContent(), contains('link'));

      state.controller.undo();
      await tester.pump();

      expect(state.controller.document.toPlainText(), 'www.example.com \n');
      expect(state.getContent(), isNot(contains('link')));

      await type(tester, 'x');
      expect(state.getContent(), isNot(contains('link')));
    });

    testWidgets('links nothing that the app itself puts in', (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"www.example.com\\n"}]}',
      );

      state.applyLineKind(LineKind.checklist);
      await tester.pump();

      expect(state.getContent(), isNot(contains('link')));
    });
  });

  group('the first line', () {
    testWidgets('addFirstLine puts words on an empty first line of text, '
        'with the caret at its start', (tester) async {
      final (state, focusNode) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\nmore\\n"}]}',
      );

      state.addFirstLine('plan');
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(state.controller.document.toPlainText(), 'plan\nmore\n');
      expect(state.selection, const TextSelection.collapsed(offset: 0));
    });

    testWidgets('addFirstLine adds a line of plain text above a heading or '
        'a list', (tester) async {
      for (final line in ['{"header":1}', '{"list":"bullet"}']) {
        final (state, _) = await pumpEditor(
          tester,
          content:
              '{"ops":[{"insert":"Plan"},'
              '{"insert":"\\n","attributes":$line}]}',
        );
        state.controller.updateSelection(
          const TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );

        state.addFirstLine('later');
        await tester.pump();

        expect(state.controller.document.toPlainText(), 'later\nPlan\n');
        expect(state.selection, const TextSelection.collapsed(offset: 0));
        expect(state.controller.lineKind, LineKind.text, reason: line);
        expect(
          state.controller.document.toDelta().last.attributes,
          jsonDecode(line),
          reason: line,
        );
      }
    });

    testWidgets('addFirstLine with no words adds an empty line on top', (
      tester,
    ) async {
      final (state, _) = await pumpEditor(tester);

      state.addFirstLine('');
      await tester.pump();

      expect(state.controller.document.toPlainText(), '\nhi\n');
      expect(state.selection, const TextSelection.collapsed(offset: 0));

      state.controller.undo();
      await tester.pump();
      expect(state.controller.document.toPlainText(), 'hi\n');
    });

    testWidgets('startLineAtTop puts the caret on the new line wherever it '
        'was', (tester) async {
      final (state, _) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"one\\ntwo\\n"}]}',
      );
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );

      state.startLineAtTop(LineKind.checklist);
      await tester.pump();

      expect(state.controller.document.toPlainText(), '\none\ntwo\n');
      expect(state.selection, const TextSelection.collapsed(offset: 0));
      expect(state.controller.lineKind, LineKind.checklist);
      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );
      expect(state.controller.lineKind, LineKind.text);
    });

    group('Backspace at its start', () {
      Future<(RichTextEditorState, List<String>)> pressBackspace(
        WidgetTester tester,
        String content, {
        int caret = 0,
      }) async {
        final joined = <String>[];
        final (state, focusNode) = await pumpEditor(
          tester,
          content: content,
          onBackspaceAtStart: joined.add,
        );
        focusNode.requestFocus();
        await tester.pump();
        state.controller.updateSelection(
          TextSelection.collapsed(offset: caret),
          ChangeSource.local,
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        return (state, joined);
      }

      testWidgets('hands over a line of plain text and takes it out', (
        tester,
      ) async {
        final (state, joined) = await pressBackspace(
          tester,
          '{"ops":[{"insert":"plan "},{"insert":"b","attributes":{"bold":true}},'
          '{"insert":"\\nmore\\n"}]}',
        );

        expect(joined, ['plan b']);
        expect(state.controller.document.toPlainText(), 'more\n');
      });

      testWidgets('keeps one empty line when that was the only one', (
        tester,
      ) async {
        final (state, joined) = await pressBackspace(
          tester,
          '{"ops":[{"insert":"plan\\n"}]}',
        );

        expect(joined, ['plan']);
        expect(state.controller.document.toPlainText(), '\n');
      });

      testWidgets('takes the style off a styled first line before handing '
          'it over', (tester) async {
        for (final style in [
          '{"list":"bullet"}',
          '{"list":"unchecked"}',
          '{"header":1}',
          '{"blockquote":true}',
          '{"code-block":true}',
        ]) {
          final (state, joined) = await pressBackspace(
            tester,
            '{"ops":[{"insert":"milk"},'
            '{"insert":"\\n","attributes":$style},{"insert":"more\\n"}]}',
          );

          expect(joined, isEmpty, reason: style);
          expect(state.controller.document.toDelta().toJson(), [
            {'insert': 'milk\nmore\n'},
          ], reason: style);

          await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
          await tester.pump();
          expect(joined, ['milk'], reason: style);
        }
      });

      testWidgets('leaves the middle of a line to the usual Backspace', (
        tester,
      ) async {
        final (state, joined) = await pressBackspace(
          tester,
          '{"ops":[{"insert":"plan\\n"}]}',
          caret: 2,
        );

        expect(joined, isEmpty);
        expect(state.controller.document.toPlainText(), 'pan\n');
      });
    });
  });

  testWidgets('a tap in the margin below the words or beside folded checked '
      'items goes where a tap below the note goes', (tester) async {
    final folds = <bool>[];
    final (state, _) = await pumpEditor(
      tester,
      content:
          '{"ops":[{"insert":"Eggs"},{"insert":"\\n","attributes":{"list":"unchecked"}},'
          '{"insert":"Milk"},{"insert":"\\n","attributes":{"list":"checked"}},'
          '{"insert":"Bread"},{"insert":"\\n","attributes":{"list":"checked"}}]}',
      isCheckedFolded: true,
      onCheckedFoldChanged: folds.add,
    );
    final editor = tester.allRenderObjects.whereType<RenderEditor>().first;

    for (final y in [editor.size.height + 10, editor.size.height - 1]) {
      state.tapBeside(editor.localToGlobal(Offset(-1, y)));
      await tester.pumpAndSettle();

      expect(state.selection, const TextSelection.collapsed(offset: 4));
      expect(folds, isEmpty, reason: 'the checked items stay folded');
    }
  });

  group('dragging after a long-press', () {
    const words = 'The Quick Brown Fox Jumps';

    Offset charAt(WidgetTester tester, int offset) {
      final editor = tester.allRenderObjects.whereType<RenderEditor>().first;
      final left = editor.getLocalRectForCaret(TextPosition(offset: offset));
      final right = editor.getLocalRectForCaret(
        TextPosition(offset: offset + 1),
      );
      return editor.localToGlobal(
        Offset((left.left + right.left) / 2, left.center.dy),
      );
    }

    Future<String> dragFromFox(
      WidgetTester tester,
      Offset Function() to,
    ) async {
      final (state, focusNode) = await pumpEditor(
        tester,
        content: jsonEncode({
          'ops': [
            {'insert': '$words\n'},
          ],
        }),
      );
      focusNode.requestFocus();
      await tester.pump();
      final gesture = await tester.startGesture(
        charAt(tester, words.indexOf('Fox') + 1),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      expect(state.textIn(state.selection), 'Fox');
      await gesture.moveTo(to());
      await tester.pump();
      final selected = state.textIn(state.selection);
      await gesture.up();
      await tester.pump();
      return selected;
    }

    testWidgets('to the left keeps the pressed word and takes in the one '
        'under the finger', (tester) async {
      expect(
        await dragFromFox(
          tester,
          () => charAt(tester, words.indexOf('Brown') + 2),
        ),
        'Brown Fox',
      );
    });

    testWidgets('past the start of the line takes in its first word', (
      tester,
    ) async {
      expect(
        await dragFromFox(
          tester,
          () => charAt(tester, 0) - const Offset(40, 0),
        ),
        'The Quick Brown Fox',
      );
    });

    testWidgets('to the right still selects whole words', (tester) async {
      expect(
        await dragFromFox(
          tester,
          () => charAt(tester, words.indexOf('Jumps') + 1),
        ),
        'Fox Jumps',
      );
    });
  });

  group('Backspace at the start of a later line', () {
    const bullet = {'list': 'bullet'};

    Future<RichTextEditorState> pumpWithCaretAt(
      WidgetTester tester,
      List<(String, Map<String, dynamic>?)> lines,
      int caret,
    ) async {
      final (state, focusNode) = await pumpEditor(
        tester,
        content: jsonEncode({
          'ops': [
            for (final (text, attributes) in lines) ...[
              {'insert': text},
              {'insert': '\n', 'attributes': ?attributes},
            ],
          ],
        }),
      );
      focusNode.requestFocus();
      await tester.pump();
      state.controller.updateSelection(
        TextSelection.collapsed(offset: caret),
        ChangeSource.local,
      );
      await tester.pump();
      return state;
    }

    Future<void> backspace(
      WidgetTester tester, {
      bool selectsFirst = false,
    }) async {
      final state = tester.state<RichTextEditorState>(
        find.byType(RichTextEditor),
      );
      final value = state.controller.plainTextEditingValue;
      final at = value.selection.start;
      if (selectsFirst) {
        tester.testTextInput.updateEditingValue(
          value.copyWith(
            selection: TextSelection(baseOffset: at - 1, extentOffset: at),
          ),
        );
        await tester.pump();
      }
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: value.text.replaceRange(at - 1, at, ''),
          selection: TextSelection.collapsed(offset: at - 1),
        ),
      );
      await tester.pump();
    }

    List<(String, Object?, Object?)> linesOf(RichTextEditorState state) {
      final document = state.controller.document;
      final text = document.toPlainText();
      return [
        for (final line in parseDocumentLines(document))
          (
            text.substring(
              line.startOffset,
              line.startOffset + line.length - 1,
            ),
            line.newlineAttributes?['list'],
            line.newlineAttributes?['indent'],
          ),
      ];
    }

    testWidgets('takes the bullet off first, then joins the line to the one '
        'above', (tester) async {
      final state = await pumpWithCaretAt(tester, [
        ('Milk', bullet),
        ('Bread', bullet),
      ], 5);

      await backspace(tester);
      expect(linesOf(state), [('Milk', 'bullet', null), ('Bread', null, null)]);
      expect(state.selection, const TextSelection.collapsed(offset: 5));
      expect(
        tester.testTextInput.editingState?['text'],
        state.controller.plainTextEditingValue.text,
        reason: 'the keyboard is told the line break is still there',
      );

      await backspace(tester);
      expect(linesOf(state), [('MilkBread', 'bullet', null)]);
    });

    testWidgets('moves an indented item out a level at a time, as the web '
        'does', (tester) async {
      final state = await pumpWithCaretAt(tester, [
        ('Trip', {'list': 'unchecked'}),
        ('Tickets', {'list': 'unchecked'}),
        ('Seats', {'list': 'checked', 'indent': 2}),
      ], 13);

      await backspace(tester);
      expect(linesOf(state).last, ('Seats', 'checked', 1));
      await backspace(tester);
      expect(linesOf(state).last, ('Seats', 'checked', null));
      await backspace(tester);
      expect(linesOf(state).last, ('Seats', null, null));
      await backspace(tester);
      expect(linesOf(state).last, ('TicketsSeats', 'unchecked', null));
    });

    testWidgets('joins lines inside a code block, and takes the code off its '
        'first line', (tester) async {
      const code = {'code-block': true};
      final state = await pumpWithCaretAt(tester, [
        ('note', null),
        ('a = 1', code),
        ('b = 2', code),
      ], 11);

      await backspace(tester);
      expect(state.controller.document.toPlainText(), 'note\na = 1b = 2\n');

      state.controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );
      await tester.pump();
      await backspace(tester);
      expect(state.controller.document.toDelta().toJson().first, {
        'insert': 'note\na = 1b = 2\n',
      });
    });

    testWidgets('the iPhone keyboard, which selects the line break before '
        'taking it out, does the same', (tester) async {
      final state = await pumpWithCaretAt(tester, [
        ('Milk', bullet),
        ('Bread', bullet),
      ], 5);

      await backspace(tester, selectsFirst: true);
      expect(linesOf(state), [('Milk', 'bullet', null), ('Bread', null, null)]);
      expect(state.selection, const TextSelection.collapsed(offset: 5));

      await backspace(tester, selectsFirst: true);
      expect(linesOf(state), [('MilkBread', 'bullet', null)]);
    });

    testWidgets('a hardware keyboard\'s Backspace does the same', (
      tester,
    ) async {
      final state = await pumpWithCaretAt(tester, [
        ('Milk', bullet),
        ('Bread', bullet),
      ], 5);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(linesOf(state), [('Milk', 'bullet', null), ('Bread', null, null)]);
    });

    testWidgets('one Undo gives the bullet back', (tester) async {
      final state = await pumpWithCaretAt(tester, [
        ('Milk', bullet),
        ('Bread', bullet),
      ], 5);

      await backspace(tester);
      state.controller.undo();
      await tester.pump();

      expect(linesOf(state), [
        ('Milk', 'bullet', null),
        ('Bread', 'bullet', null),
      ]);
    });
  });

  group('words on an empty note', () {
    String? placeholder(WidgetTester tester) =>
        tester.widget<QuillEditor>(find.byType(QuillEditor)).config.placeholder;

    Finder slashHint() => find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is SlashHint,
    );

    testWidgets('"Start writing" shows only while the empty text waits', (
      tester,
    ) async {
      final (state, focusNode) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
      );
      expect(placeholder(tester), 'Start writing');

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(placeholder(tester), isNull);

      focusNode.unfocus();
      await tester.pump();
      await tester.pump();
      expect(placeholder(tester), 'Start writing');

      state.applyLineKind(LineKind.checklist);
      await tester.pump();
      focusNode.unfocus();
      await tester.pump();
      await tester.pump();
      expect(placeholder(tester), isNull);
    });

    testWidgets('a note you can only view has no "Start writing"', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
        canEdit: false,
      );

      expect(placeholder(tester), isNull);
    });

    testWidgets('"Type / for more" shows on the empty line of plain text the '
        'caret is on', (tester) async {
      final (state, focusNode) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
        hasSlashHint: true,
      );
      final hint = tester.renderObject(slashHint());
      expect(hint, paintsNothing);

      focusNode.requestFocus();
      await tester.pump();
      expect(hint, paints..paragraph(offset: Offset.zero));

      state.controller.replaceText(
        0,
        0,
        'a',
        const TextSelection.collapsed(offset: 1),
      );
      await tester.pump();
      expect(hint, paintsNothing);

      state.controller.replaceText(
        1,
        0,
        '\n',
        const TextSelection.collapsed(offset: 2),
      );
      await tester.pump();
      expect(hint, paints..paragraph());

      state.applyLineKind(LineKind.checklist);
      await tester.pump();
      expect(hint, paintsNothing);
    });

    testWidgets('only a note opened as new has "Type / for more"', (
      tester,
    ) async {
      final (_, focusNode) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
      );
      focusNode.requestFocus();
      await tester.pump();

      expect(slashHint(), findsNothing);
    });

    testWidgets('onBlankChanged follows whether the note holds anything', (
      tester,
    ) async {
      final blank = <bool>[];
      final (state, _) = await pumpEditor(
        tester,
        content: '{"ops":[{"insert":"\\n"}]}',
        onBlankChanged: blank.add,
      );

      state.controller.replaceText(0, 0, '  \n', null);
      await tester.pump();
      expect(blank, isEmpty);

      state.controller.replaceText(0, 0, 'a', null);
      await tester.pump();
      state.controller.replaceText(0, 1, '', null);
      await tester.pump();
      expect(blank, [false, true]);

      state.applyLineKind(LineKind.checklist);
      await tester.pump();
      expect(blank, [false, true, false]);
      expect(state.isBlank, isFalse);
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
