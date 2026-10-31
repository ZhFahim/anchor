import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/presentation/editor/checklist_note_editor.dart';
import 'package:anchor/features/notes/presentation/editor/editor_palette.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
              initialContent: initial,
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
}
