import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/presentation/editor/checklist_note_editor.dart';
import 'package:anchor/features/notes/presentation/editor/editor_palette.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const palette = EditorPalette(
  muted: Colors.grey,
  surface: Colors.white,
  border: Colors.grey,
  background: Colors.white,
  highlightFill: _color,
  highlightInk: _color,
);
Color _color(String _) => Colors.yellow;

void main() {
  final initial = writeChecklist([
    const ChecklistTask(text: 'Milk'),
    const ChecklistTask(text: 'Bread', done: true),
  ]);

  Future<ChecklistNoteEditorState> pumpEditor(
    WidgetTester tester, {
    bool canEdit = true,
    VoidCallback? onChanged,
    String? content,
  }) async {
    final key = GlobalKey<ChecklistNoteEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChecklistNoteEditor(
              key: key,
              initialContent: content ?? initial,
              canEdit: canEdit,
              palette: palette,
              onChanged: onChanged ?? () {},
            ),
          ),
        ),
      ),
    );
    return key.currentState!;
  }

  testWidgets('checking hides a task and unchecking restores it', (
    tester,
  ) async {
    var changes = 0;
    final state = await pumpEditor(tester, onChanged: () => changes++);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsNothing);
    expect(find.text('Completed (1)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Completed (2)'), findsOneWidget);
    expect(
      readChecklist(state.getContent()).every((task) => task.done),
      isTrue,
    );
    await tester.tap(find.text('Completed (2)'));
    await tester.pump();
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(readChecklist(state.getContent()).first.done, isFalse);
    expect(changes, 2);
  });

  testWidgets('editing, Enter and multiline paste store tasks', (tester) async {
    final state = await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'Coffee');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(1), 'Apples\nPears');
    await tester.pump();
    expect(
      readChecklist(
        state.getContent(),
      ).where((task) => !task.done).map((task) => task.text),
      ['Coffee', 'Apples', 'Pears'],
    );
    expect(readChecklist(state.getContent()).last.text, 'Bread');
  });

  testWidgets('viewers cannot edit, reorder or complete tasks', (tester) async {
    var changes = 0;
    await pumpEditor(tester, canEdit: false, onChanged: () => changes++);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    expect(find.widgetWithText(TextButton, 'Add a task'), findsNothing);
    expect(changes, 0);
  });

  testWidgets('active tasks can be reordered without losing completed tasks', (
    tester,
  ) async {
    final state = await pumpEditor(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Add a task'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Coffee');
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(1, 0);
    await tester.pump();
    expect(readChecklist(state.getContent()).map((task) => task.text), [
      'Coffee',
      'Bread',
      'Milk',
    ]);
  });

  testWidgets('arrow keys move between visible tasks without editing', (
    tester,
  ) async {
    var changes = 0;
    final state = await pumpEditor(
      tester,
      content: writeChecklist([
        const ChecklistTask(text: 'First task'),
        const ChecklistTask(text: 'Hidden', done: true),
        const ChecklistTask(text: 'Second task'),
        const ChecklistTask(text: 'Hi'),
        const ChecklistTask(),
      ]),
      onChanged: () => changes++,
    );
    final before = state.getContent();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    fields.first.focusNode!.requestFocus();
    fields.first.controller!.selection = const TextSelection.collapsed(
      offset: 4,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(fields.first.focusNode!.hasFocus, isTrue);
    expect(fields.first.controller!.selection.extentOffset, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields[1].focusNode!.hasFocus, isTrue);
    expect(fields[1].controller!.selection.extentOffset, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(fields.first.focusNode!.hasFocus, isTrue);
    expect(fields.first.controller!.selection.extentOffset, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields[2].focusNode!.hasFocus, isTrue);
    expect(fields[2].controller!.selection.extentOffset, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields.last.focusNode!.hasFocus, isTrue);
    expect(fields.last.controller!.selection.extentOffset, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields.last.focusNode!.hasFocus, isTrue);
    expect(state.getContent(), before);
    expect(changes, 0);
  });

  testWidgets('expanded completed tasks participate in display order', (
    tester,
  ) async {
    await pumpEditor(tester, canEdit: false);
    await tester.tap(find.text('Completed (1)'));
    await tester.pump();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    fields.first.focusNode!.requestFocus();
    fields.first.controller!.selection = const TextSelection.collapsed(
      offset: 2,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields.last.focusNode!.hasFocus, isTrue);
    expect(fields.last.controller!.selection.extentOffset, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(fields.first.focusNode!.hasFocus, isTrue);
  });

  testWidgets('wrapped task arrows move inside the task before leaving', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      content: writeChecklist([
        const ChecklistTask(text: 'Start'),
        ChecklistTask(text: List.filled(40, 'wrapped text').join(' ')),
        const ChecklistTask(text: 'End'),
      ]),
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    final wrapped = fields[1];
    wrapped.focusNode!.requestFocus();
    wrapped.controller!.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(wrapped.focusNode!.hasFocus, isTrue);
    expect(wrapped.controller!.selection.extentOffset, greaterThan(2));
    wrapped.controller!.selection = TextSelection.collapsed(
      offset: wrapped.controller!.text.length,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(wrapped.focusNode!.hasFocus, isTrue);
    expect(
      wrapped.controller!.selection.extentOffset,
      lessThan(wrapped.controller!.text.length),
    );
    wrapped.controller!.selection = TextSelection.collapsed(
      offset: wrapped.controller!.text.length,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fields.last.focusNode!.hasFocus, isTrue);
  });

  Future<void> shortcut(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool alt = false,
    bool shift = false,
    bool meta = false,
  }) async {
    final modifier = alt
        ? LogicalKeyboardKey.altLeft
        : meta
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
  }

  testWidgets('Alt arrows reorder from text, retain selection, and undo/redo', (
    tester,
  ) async {
    var changes = 0;
    final state = await pumpEditor(
      tester,
      content: writeChecklist([
        const ChecklistTask(text: 'First'),
        const ChecklistTask(text: 'Hidden', done: true),
        const ChecklistTask(text: 'Second'),
        const ChecklistTask(text: 'Third'),
      ]),
      onChanged: () => changes++,
    );
    final before = state.getContent();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    field.focusNode!.requestFocus();
    field.controller!.selection = const TextSelection(
      baseOffset: 1,
      extentOffset: 3,
    );
    await tester.pump();
    await shortcut(tester, LogicalKeyboardKey.arrowUp, alt: true);
    expect(changes, 0);
    await shortcut(tester, LogicalKeyboardKey.arrowDown, alt: true);
    expect(readChecklist(state.getContent()).map((task) => task.text), [
      'Second',
      'Hidden',
      'First',
      'Third',
    ]);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 1, extentOffset: 3),
    );
    await shortcut(tester, LogicalKeyboardKey.keyZ);
    expect(state.getContent(), before);
    expect(field.focusNode!.hasFocus, isTrue);
    await shortcut(tester, LogicalKeyboardKey.keyZ, shift: true);
    expect(readChecklist(state.getContent()).first.text, 'Second');
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 1, extentOffset: 3),
    );
    await shortcut(tester, LogicalKeyboardKey.keyZ, meta: true);
    expect(state.getContent(), before);
    await shortcut(tester, LogicalKeyboardKey.keyY);
    expect(readChecklist(state.getContent()).first.text, 'Second');
  });

  testWidgets('text, add, paste, completion and deletion share one history', (
    tester,
  ) async {
    final state = await pumpEditor(tester);
    final versions = [state.getContent()];
    await tester.enterText(find.byType(TextField).first, 'Coffee');
    versions.add(state.getContent());
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    versions.add(state.getContent());
    await tester.enterText(find.byType(TextField).last, 'Apples\nPears');
    await tester.pump();
    versions.add(state.getContent());
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    versions.add(state.getContent());
    await tester.tap(find.byTooltip('Delete task').first);
    await tester.pump();
    versions.add(state.getContent());
    for (final version in versions.reversed.skip(1)) {
      expect(state.undo(), isTrue);
      await tester.pump();
      expect(state.getContent(), version);
    }
    expect(state.undo(), isFalse);
    for (final version in versions.skip(1)) {
      expect(state.redo(), isTrue);
      await tester.pump();
      expect(state.getContent(), version);
    }
    expect(state.redo(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new edits after undo discard redo', (tester) async {
    final state = await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'Coffee');
    await tester.enterText(find.byType(TextField).first, 'Tea');
    state.undo();
    await tester.pump();
    expect(state.canRedo, isTrue);
    await tester.enterText(find.byType(TextField).first, 'Water');
    expect(state.canRedo, isFalse);
    expect(state.redo(), isFalse);
    state.undo();
    await tester.pump();
    expect(readChecklist(state.getContent()).first.text, 'Coffee');
  });

  testWidgets(
    'undo restores the pre-edit caret and redo restores the new caret',
    (tester) async {
      final state = await pumpEditor(tester);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      await tester.showKeyboard(find.byType(TextField).first);
      field.controller!.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'MiXlk',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(readChecklist(state.getContent()).first.text, 'MiXlk');
      await shortcut(tester, LogicalKeyboardKey.keyZ);
      expect(field.controller!.text, 'Milk');
      expect(field.controller!.selection.extentOffset, 2);
      await shortcut(tester, LogicalKeyboardKey.keyY);
      expect(field.controller!.text, 'MiXlk');
      expect(field.controller!.selection.extentOffset, 3);
    },
  );

  testWidgets('remote replacement clears history; save echoes retain it', (
    tester,
  ) async {
    final key = GlobalKey<ChecklistNoteEditorState>();
    var content = initial;
    var version = 0;
    Future<void> pump() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ChecklistNoteEditor(
              key: key,
              initialContent: content,
              contentVersion: version,
              canEdit: true,
              palette: palette,
              onChanged: () {},
            ),
          ),
        ),
      );
    }

    await pump();
    await tester.enterText(find.byType(TextField).first, 'Coffee');
    content = key.currentState!.getContent();
    version++;
    await pump();
    expect(key.currentState!.canUndo, isTrue);
    content = writeChecklist([const ChecklistTask(text: 'Remote')]);
    version++;
    await pump();
    expect(key.currentState!.canUndo, isFalse);
    expect(key.currentState!.canRedo, isFalse);
    expect(key.currentState!.undo(), isFalse);
    expect(readChecklist(key.currentState!.getContent()).single.text, 'Remote');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ctrl/Cmd Enter completes the current task and is undoable', (
    tester,
  ) async {
    final state = await pumpEditor(
      tester,
      content: writeChecklist([
        const ChecklistTask(text: 'First'),
        const ChecklistTask(text: 'Second'),
      ]),
    );
    for (final meta in [false, true]) {
      final field = tester.widget<TextField>(find.byType(TextField).first);
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      await shortcut(tester, LogicalKeyboardKey.enter, meta: meta);
      expect(readChecklist(state.getContent()).map((task) => task.text), [
        'First',
        'Second',
      ]);
      expect(readChecklist(state.getContent()).first.done, isTrue);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await shortcut(tester, LogicalKeyboardKey.keyZ);
      expect(readChecklist(state.getContent()).map((task) => task.text), [
        'First',
        'Second',
      ]);
      final restored = tester.widget<TextField>(find.byType(TextField).first);
      expect(restored.focusNode!.hasFocus, isTrue);
      expect(restored.controller!.selection.extentOffset, 2);
      expect(readChecklist(state.getContent()).first.done, isFalse);
    }
  });

  testWidgets(
    'Ctrl Enter restores completed tasks and completing the last task remains undoable',
    (tester) async {
      final state = await pumpEditor(tester);
      await tester.tap(find.text('Completed (1)'));
      await tester.pump();
      final completed = tester.widget<TextField>(find.byType(TextField).last);
      completed.focusNode!.requestFocus();
      await tester.pump();
      await shortcut(tester, LogicalKeyboardKey.enter);
      expect(readChecklist(state.getContent()).last.done, isFalse);
      await shortcut(tester, LogicalKeyboardKey.enter);
      expect(readChecklist(state.getContent()).last.done, isTrue);
      await shortcut(tester, LogicalKeyboardKey.enter);
      expect(
        readChecklist(state.getContent()).every((task) => task.done),
        isTrue,
      );
      await shortcut(tester, LogicalKeyboardKey.keyZ);
      expect(readChecklist(state.getContent()).first.done, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('read-only checklists cannot reorder or use history', (
    tester,
  ) async {
    var changes = 0;
    final state = await pumpEditor(
      tester,
      canEdit: false,
      onChanged: () => changes++,
    );
    final field = tester.widget<TextField>(find.byType(TextField).first);
    field.focusNode!.requestFocus();
    field.controller!.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();
    await shortcut(tester, LogicalKeyboardKey.arrowDown, alt: true);
    await shortcut(tester, LogicalKeyboardKey.keyZ);
    expect(state.undo(), isFalse);
    expect(state.redo(), isFalse);
    expect(changes, 0);
  });

  testWidgets('modified arrows and IME composition do not change task focus', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      content: writeChecklist([
        const ChecklistTask(text: 'First'),
        const ChecklistTask(text: 'Second'),
      ]),
    );
    final first = tester.widget<TextField>(find.byType(TextField).first);
    first.focusNode!.requestFocus();
    first.controller!.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    for (final modifier in [
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft,
    ]) {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      expect(first.focusNode!.hasFocus, isTrue);
    }
    first.controller!.value = const TextEditingValue(
      text: 'First',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 0, end: 3),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(first.focusNode!.hasFocus, isTrue);
  });
}
