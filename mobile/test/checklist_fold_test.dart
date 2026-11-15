import 'dart:convert';

import 'package:anchor/app/app_bootstrap.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/theme/anchor_density.dart';
import 'package:anchor/core/theme/note_typography.dart';
import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:anchor/features/notes/presentation/checked_folds_controller.dart';
import 'package:anchor/features/notes/presentation/editor/checklist_fold.dart';
import 'package:anchor/features/notes/presentation/editor/document_lines.dart';
import 'package:anchor/features/notes/presentation/editor/editor_palette.dart';
import 'package:anchor/features/notes/presentation/editor/list_markers.dart';
import 'package:anchor/features/notes/presentation/editor/rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

final _plain = AnchorColors.light.notes['none']!;

final typography = NoteTypography(
  lineHeight: AnchorDensity.standard.noteLineHeight,
);

final palette = EditorPalette(
  muted: _plain.muted,
  surface: _plain.surface,
  border: _plain.border,
  background: _plain.bg,
  highlightFill: (name) => AnchorColors.light.highlights[name]!.fill,
  highlightInk: (name) => AnchorColors.light.highlights[name]!.ink!,
);

/// Lines of (text, list, indent); a null list is a paragraph.
String note(List<(String, String?, int)> lines) => jsonEncode({
  'ops': [
    for (final (text, list, indent) in lines) ...[
      if (text.isNotEmpty) {'insert': text},
      {
        'insert': '\n',
        if (list != null)
          'attributes': {'list': list, if (indent > 0) 'indent': indent},
      },
    ],
  ],
});

class _Host extends StatefulWidget {
  const _Host({
    required this.content,
    required this.sort,
    required this.folded,
    required this.canEdit,
    required this.focus,
    required this.onFold,
  });

  final String content;
  final bool sort;
  final bool folded;
  final bool canEdit;
  final FocusNode focus;
  final ValueChanged<bool> onFold;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _scroll = ScrollController();
  late bool _folded = widget.folded;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    child: RichTextEditor(
      initialContent: widget.content,
      focusNode: widget.focus,
      canEdit: widget.canEdit,
      scrollController: _scroll,
      palette: palette,
      sortChecklistItems: widget.sort,
      isCheckedFolded: _folded,
      onCheckedFoldChanged: (folded) {
        widget.onFold(folded);
        setState(() => _folded = folded);
      },
    ),
  );
}

void main() {
  final folds = <bool>[];
  late FocusNode focus;

  Future<RichTextEditorState> pumpNote(
    WidgetTester tester,
    List<(String, String?, int)> lines, {
    bool sort = true,
    bool folded = false,
    bool canEdit = true,
  }) async {
    folds.clear();
    focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        home: Scaffold(
          body: _Host(
            content: note(lines),
            sort: sort,
            folded: folded,
            canEdit: canEdit,
            focus: focus,
            onFold: folds.add,
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<RichTextEditorState>(find.byType(RichTextEditor));
  }

  Rect textOf(WidgetTester tester, String words) => tester.getRect(
    find.descendant(
      of: find.byType(QuillEditor),
      matching: find.text(words, findRichText: true),
    ),
  );

  Finder checkboxOf(String words) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == words,
  );

  const groceries = [
    ('Oat milk', 'unchecked', 0),
    ('Coffee beans', 'unchecked', 0),
    ('Eggs', 'checked', 0),
    ('Butter', 'checked', 0),
    ('After the list', null, 0),
  ];

  testWidgets('checking a parent checks its sub-items', (tester) async {
    final state = await pumpNote(tester, const [
      ('A', 'unchecked', 0),
      ('A1', 'unchecked', 1),
      ('B', 'unchecked', 0),
    ]);

    await tester.tap(checkboxOf('A'));
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    final lines = parseDocumentLines(state.controller.document);
    expect(lines[0].isChecked, isTrue);
    expect(lines[1].isChecked, isTrue);
    expect(lines[2].isChecked, isFalse);
  });

  testWidgets('unchecking a parent unchecks its sub-items', (tester) async {
    final state = await pumpNote(tester, const [
      ('A', 'checked', 0),
      ('A1', 'checked', 1),
      ('B', 'unchecked', 0),
    ]);

    await tester.tap(checkboxOf('A'));
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    final lines = parseDocumentLines(state.controller.document);
    expect(lines[0].isChecked, isFalse);
    expect(lines[1].isChecked, isFalse);
    expect(lines[2].isChecked, isFalse);
  });

  testWidgets('checking a parent keeps a hidden checked item hidden', (
    tester,
  ) async {
    final state = await pumpNote(tester, const [
      ('A', 'unchecked', 0),
      ('A1', 'unchecked', 1),
      ('B', 'unchecked', 0),
      ('B1', 'checked', 1),
    ], folded: true);

    await tester.tap(checkboxOf('A'));
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    expect(checkboxOf('B1'), findsNothing);
    expect(checkboxOf('A'), findsOneWidget);
    expect(checkboxOf('A1'), findsOneWidget);
    expect(state.getPlainText(), startsWith('A\nA1\nB\nB1'));
  });

  testWidgets('a flat item still moves to the bottom when checked', (
    tester,
  ) async {
    final state = await pumpNote(tester, const [
      ('A', 'unchecked', 0),
      ('B', 'unchecked', 0),
      ('C', 'unchecked', 0),
    ]);

    await tester.tap(checkboxOf('A'));
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    expect(state.getPlainText(), startsWith('B\nC\nA'));
  });

  testWidgets('a child tap then a parent tap keeps the parent in place', (
    tester,
  ) async {
    final state = await pumpNote(tester, const [
      ('A', 'unchecked', 0),
      ('A1', 'unchecked', 1),
      ('B', 'unchecked', 0),
      ('B1', 'checked', 1),
    ], folded: true);

    await tester.tap(checkboxOf('A1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(checkboxOf('A'));
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    expect(state.getPlainText(), startsWith('A\nA1\nB\nB1'));
    expect(checkboxOf('B1'), findsNothing);
  });

  testWidgets('list lines keep one rhythm across indents, ticks and kinds', (
    tester,
  ) async {
    await pumpNote(tester, const [
      ('One', 'unchecked', 0),
      ('Two', 'unchecked', 1),
      ('Three', 'checked', 1),
      ('Four', 'unchecked', 0),
      ('Five', 'bullet', 0),
      ('Six', 'bullet', 1),
      ('Seven', 'ordered', 0),
      ('After', null, 0),
    ], sort: false);

    final tops = [
      for (final words in ['One', 'Two', 'Three', 'Four'])
        textOf(tester, words).top,
    ];
    final step = tops[1] - tops[0];
    for (var i = 2; i < tops.length; i++) {
      expect(tops[i] - tops[i - 1], moreOrLessEquals(step, epsilon: 0.01));
    }
    expect(
      textOf(tester, 'Five').top - tops.last,
      moreOrLessEquals(step + typography.listEndGap, epsilon: 0.01),
    );
    expect(
      textOf(tester, 'Six').top - textOf(tester, 'Five').top,
      moreOrLessEquals(step, epsilon: 0.01),
    );
    expect(
      textOf(tester, 'After').top - textOf(tester, 'Seven').top,
      moreOrLessEquals(
        step - typography.listLinePadding + typography.listEndGap,
        epsilon: 0.01,
      ),
    );
  });

  testWidgets('the checked items at the bottom sit under a row that counts '
      'them', (tester) async {
    await pumpNote(tester, groceries);

    expect(find.text('2 checked items'), findsOneWidget);
    final row = tester.getRect(find.byType(CheckedFoldRow));
    expect(
      row.height,
      moreOrLessEquals(AnchorTokens.sizeControlMedium, epsilon: 0.01),
    );
    final coffee = textOf(tester, 'Coffee beans');
    final eggs = textOf(tester, 'Eggs');
    final butter = textOf(tester, 'Butter');
    expect(
      eggs.top - coffee.top - AnchorTokens.sizeControlMedium,
      moreOrLessEquals(butter.top - eggs.top, epsilon: 0.01),
    );
    expect(row.top, greaterThan(coffee.bottom));
    expect(row.bottom, lessThan(eggs.top));
  });

  testWidgets('one checked item says so in the singular', (tester) async {
    await pumpNote(tester, const [
      ('Oat milk', 'unchecked', 0),
      ('Eggs', 'checked', 0),
    ]);
    expect(find.text('1 checked item'), findsOneWidget);
  });

  testWidgets('a checked item with an open one after it has no row', (
    tester,
  ) async {
    await pumpNote(tester, const [
      ('Pack', 'checked', 0),
      ('Chargers', 'unchecked', 1),
    ]);
    expect(find.byType(CheckedFoldRow), findsNothing);
  });

  testWidgets('with Move checked items to the bottom off there is no row', (
    tester,
  ) async {
    await pumpNote(tester, groceries, sort: false);
    expect(find.byType(CheckedFoldRow), findsNothing);
  });

  testWidgets('tapping the row folds the checked items away and remembers', (
    tester,
  ) async {
    final state = await pumpNote(tester, groceries);
    final rowBefore = tester.getRect(find.byType(CheckedFoldRow));
    final afterBefore = textOf(tester, 'After the list');
    final selectionBefore = state.controller.selection;

    await tester.tap(find.byType(CheckedFoldRow));
    await tester.pump();

    expect(folds, [true]);
    final row = tester.getRect(find.byType(CheckedFoldRow));
    expect(row.top, moreOrLessEquals(rowBefore.top, epsilon: 0.01));
    final after = textOf(tester, 'After the list');
    expect(
      after.top,
      moreOrLessEquals(row.bottom + typography.listEndGap, epsilon: 0.5),
    );
    expect(checkboxOf('Eggs'), findsNothing);
    expect(state.getContent(), contains('"list":"checked"'));
    expect(state.getPlainText(), contains('Butter'));
    expect(focus.hasFocus, isFalse);
    expect(state.controller.selection, selectionBefore);

    await tester.tap(find.byType(CheckedFoldRow));
    await tester.pump();
    expect(folds, [true, false]);
    expect(
      textOf(tester, 'After the list').top,
      moreOrLessEquals(afterBefore.top, epsilon: 0.01),
    );
    expect(checkboxOf('Eggs'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a note you can only view folds too', (tester) async {
    await pumpNote(tester, groceries, canEdit: false);

    await tester.tap(find.byType(CheckedFoldRow));
    await tester.pump();

    expect(folds, [true]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an item ticked while folded joins the folded ones', (
    tester,
  ) async {
    final state = await pumpNote(tester, groceries, folded: true);
    expect(find.text('2 checked items'), findsOneWidget);

    await tester.tap(checkboxOf('Oat milk'));
    await tester.pump();
    expect(checkboxOf('Oat milk'), findsOneWidget);
    await tester.pump(AnchorTokens.motionDurationSinkDelay);

    expect(find.text('3 checked items'), findsOneWidget);
    expect(checkboxOf('Oat milk'), findsNothing);
    expect(state.getPlainText(), startsWith('Coffee beans\nEggs\nButter\nOat'));
    expect(folds, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the caret reaching a folded item unfolds it', (tester) async {
    final state = await pumpNote(tester, groceries, folded: true);
    final text = state.controller.document.toPlainText();

    state.controller.updateSelection(
      TextSelection.collapsed(offset: text.indexOf('Butter') + 2),
      ChangeSource.local,
    );
    await tester.pump();

    expect(folds, [false]);
    expect(checkboxOf('Butter'), findsOneWidget);
  });

  testWidgets('going on at the end stops before folded items there', (
    tester,
  ) async {
    final state = await pumpNote(tester, const [
      ('Oat milk', 'unchecked', 0),
      ('Eggs', 'checked', 0),
      ('Butter', 'checked', 0),
    ], folded: true);
    final text = state.controller.document.toPlainText();

    state.focusEnd();
    await tester.pump();

    expect(folds, isEmpty);
    expect(
      state.selection,
      TextSelection.collapsed(offset: text.indexOf('Oat milk') + 8),
    );
  });

  testWidgets('typing at the end of the last open item keeps the fold', (
    tester,
  ) async {
    final state = await pumpNote(tester, const [
      ('Oat milk', 'unchecked', 0),
      ('Eggs', 'checked', 0),
      ('Butter', 'checked', 0),
    ], folded: true);
    const end = 'Oat milk'.length;
    state.controller.updateSelection(
      const TextSelection.collapsed(offset: end),
      ChangeSource.local,
    );
    await tester.pump();

    state.controller.replaceText(
      end,
      0,
      's',
      const TextSelection.collapsed(offset: end + 1),
    );
    await tester.pump();
    state.controller.replaceText(
      end + 1,
      0,
      '\n',
      const TextSelection.collapsed(offset: end + 2),
    );
    await tester.pump();

    expect(folds, isEmpty);
    expect(find.text('2 checked items'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  group('the fold is kept on this device per note', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('starts from what the app read at start', () {
      final container = ProviderContainer(
        overrides: [
          appBootstrapProvider.overrideWithValue(
            const AppBootstrap(foldedChecklistNotes: ['n1']),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(checkedFoldsProvider), {'n1'});
    });

    test('a fold and an unfold are saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final folds = container.read(checkedFoldsProvider.notifier);

      await folds.setFolded('n1', isFolded: true);
      await folds.setFolded('n2', isFolded: true);
      await folds.setFolded('n1', isFolded: false);

      expect(container.read(checkedFoldsProvider), {'n2'});
      final saved = await container
          .read(preferencesRepositoryProvider)
          .getFoldedChecklistNotes();
      expect(saved, ['n2']);
    });
  });
}
