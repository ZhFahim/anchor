import 'package:anchor/core/notifications/reminder_scheduler.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the device should be holding, given the notes it has.
void main() {
  final now = DateTime(2026, 9, 4, 12);

  Note note({
    required String id,
    required int slot,
    String? remindAt,
    ReminderRecurrence recurrence = ReminderRecurrence.none,
    NoteState state = NoteState.active,
    bool isArchived = false,
    String title = 'Groceries',
  }) => Note(
    id: id,
    title: title,
    state: state,
    isArchived: isArchived,
    reminderSlot: slot,
    reminder: remindAt == null
        ? null
        : NoteReminder(remindAt: remindAt, recurrence: recurrence),
  );

  test('schedules a future reminder against its slot', () {
    final desired = desiredReminders([
      note(id: 'n1', slot: 7, remindAt: '2026-09-04T18:00'),
    ], now: now);

    expect(desired, hasLength(1));
    expect(desired.single.id, 7);
    expect(desired.single.at, DateTime(2026, 9, 4, 18));
    expect(desired.single.noteId, 'n1');
    expect(desired.single.title, 'Groceries');
  });

  test('drops a note with no reminder', () {
    expect(desiredReminders([note(id: 'n1', slot: 1)], now: now), isEmpty);
  });

  test('drops a one-off whose time has passed', () {
    final desired = desiredReminders([
      note(id: 'n1', slot: 1, remindAt: '2026-09-04T09:00'),
    ], now: now);
    expect(desired, isEmpty);
  });

  test('keeps a repeating reminder anchored in the past', () {
    final desired = desiredReminders([
      note(
        id: 'n1',
        slot: 1,
        remindAt: '2026-09-01T09:00',
        recurrence: ReminderRecurrence.daily,
      ),
    ], now: now);
    expect(desired.single.at, DateTime(2026, 9, 5, 9));
    expect(desired.single.repeat, DateTimeComponents.time);
  });

  test('drops trashed and archived notes', () {
    final desired = desiredReminders([
      note(
        id: 'n1',
        slot: 1,
        remindAt: '2026-09-04T18:00',
        state: NoteState.trashed,
      ),
      note(id: 'n2', slot: 2, remindAt: '2026-09-04T18:00', isArchived: true),
    ], now: now);
    expect(desired, isEmpty);
  });

  test('skips a reminder that has no slot yet', () {
    final orphan = Note(
      id: 'n1',
      title: 'no slot',
      reminder: const NoteReminder(remindAt: '2026-09-04T18:00'),
    );
    expect(desiredReminders([orphan], now: now), isEmpty);
  });

  test('orders soonest first', () {
    final desired = desiredReminders([
      note(id: 'late', slot: 1, remindAt: '2026-09-06T09:00'),
      note(id: 'soon', slot: 2, remindAt: '2026-09-04T18:00'),
      note(id: 'mid', slot: 3, remindAt: '2026-09-05T09:00'),
    ], now: now);

    expect(desired.map((item) => item.noteId), ['soon', 'mid', 'late']);
  });

  test('caps at the soonest maxScheduledReminders', () {
    final notes = [
      for (var i = 0; i < maxScheduledReminders + 20; i++)
        note(id: 'n$i', slot: i + 1, remindAt: '2026-09-04T18:00'),
    ];

    expect(desiredReminders(notes, now: now), hasLength(maxScheduledReminders));
  });

  test('maps every recurrence onto an OS repeat', () {
    expect(matchComponentsFor(ReminderRecurrence.none), isNull);
    expect(
      matchComponentsFor(ReminderRecurrence.daily),
      DateTimeComponents.time,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.weekly),
      DateTimeComponents.dayOfWeekAndTime,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.monthly),
      DateTimeComponents.dayOfMonthAndTime,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.yearly),
      DateTimeComponents.dateAndTime,
    );
  });
}
