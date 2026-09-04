import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/app_bottom_sheet.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/widgets/reminder_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  late NoteReminder? saved;
  late bool changed;

  setUp(() {
    saved = null;
    changed = false;
  });

  /// Opens the sheet on a phone-sized surface.
  Future<void> openSheet(WidgetTester tester, {NoteReminder? reminder}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => AppBottomSheet.show(
                  context,
                  builder: (_) => ReminderPickerSheet(
                    reminder: reminder,
                    onReminderChanged: (value) {
                      changed = true;
                      saved = value;
                    },
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(of: find.text('Save'), matching: find.byType(FilledButton)),
  );

  Future<void> toggleRepeat(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on a list of times, with nothing else unfolded', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('No time set'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Next week'), findsOneWidget);
    expect(find.text('Repeat'), findsOneWidget);

    expect(find.text('Pick a date'), findsOneWidget);
    expect(find.byIcon(LucideIcons.calendar), findsNothing);

    for (final label in ['Daily', 'Weekly', 'Monthly', 'Yearly']) {
      expect(find.text(label), findsNothing);
    }

    expect(changed, isFalse, reason: 'opening commits nothing');
  });

  testWidgets('Save stays disabled until a time is chosen', (tester) async {
    await openSheet(tester);
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a preset only commits once Save is tapped', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    expect(changed, isFalse);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.remindAt, endsWith('T09:00'));
    expect(saved!.recurrence, ReminderRecurrence.none);
  });

  testWidgets('the summary resolves the chosen time', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tomorrow, '), findsOneWidget);
    expect(find.text('Just once'), findsOneWidget);
  });

  testWidgets('Pick a date unfolds the date and time fields', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
    expect(find.byIcon(LucideIcons.clock), findsWidgets);
    expect(find.text('Next week'), findsOneWidget);

    expect(find.textContaining('Tomorrow, '), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('choosing a preset folds the fields away again', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next week'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.calendar), findsNothing);
  });

  testWidgets('the repeat switch unfolds the recurrence options', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    await toggleRepeat(tester);

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Then every day'), findsOneWidget);
  });

  testWidgets('carries the chosen recurrence into the saved reminder', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    await toggleRepeat(tester);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved!.recurrence, ReminderRecurrence.weekly);
  });

  testWidgets('switching repeat off saves a one-off again', (tester) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(
        remindAt: '2026-12-04T09:00',
        recurrence: ReminderRecurrence.weekly,
      ),
    );

    expect(find.text('Weekly'), findsOneWidget);

    await toggleRepeat(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved!.recurrence, ReminderRecurrence.none);
  });

  testWidgets('the summary names what each recurrence is anchored to', (
    tester,
  ) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(
        remindAt: '2026-12-04T09:00',
        recurrence: ReminderRecurrence.daily,
      ),
    );

    expect(find.text('Then every day'), findsOneWidget);

    for (final (label, caption) in const [
      ('Weekly', 'Then every Friday'),
      ('Monthly', 'Then day 4 of every month'),
      ('Yearly', 'Then every Dec 4'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(caption), findsOneWidget, reason: label);
    }
  });

  testWidgets('a month-end reminder says how short months are handled', (
    tester,
  ) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(
        remindAt: '2026-12-31T09:00',
        recurrence: ReminderRecurrence.monthly,
      ),
    );

    expect(find.text("Then day 31, or the month's last day"), findsOneWidget);
  });

  testWidgets('an existing reminder opens with its own date unfolded', (
    tester,
  ) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(remindAt: '2026-12-04T09:00'),
    );

    expect(find.text('Fri, Dec 4'), findsOneWidget);
    expect(find.text('Next week'), findsOneWidget);
  });

  testWidgets('offers Remove only when a reminder is already set', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Remove'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Remove reports a cleared reminder', (tester) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(remindAt: '2026-12-04T09:00'),
    );

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(changed, isTrue);
    expect(saved, isNull);
  });

  testWidgets('says so when the chosen time has already passed', (
    tester,
  ) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(remindAt: '2020-01-01T09:00'),
    );

    expect(find.text('Already passed'), findsOneWidget);
  });

  testWidgets('a repeating reminder anchored in the past still has a next', (
    tester,
  ) async {
    await openSheet(
      tester,
      reminder: const NoteReminder(
        remindAt: '2020-01-01T09:00',
        recurrence: ReminderRecurrence.daily,
      ),
    );

    expect(find.text('Already passed'), findsNothing);
    expect(find.text('Then every day'), findsOneWidget);
  });
}
