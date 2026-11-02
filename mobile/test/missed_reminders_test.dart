import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/reminders/data/missed_reminders.dart';
import 'package:anchor/features/reminders/data/notification_gateway.dart';
import 'package:anchor/features/reminders/data/reminder_background_check.dart';
import 'package:anchor/features/sync/data/sync_response.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class ShowingGateway implements NotificationGateway {
  final shown = <int>[];

  @override
  Future<void> show(ScheduledNotification notification) async =>
      shown.add(notification.id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class MemoryRungReminders implements RungReminders {
  MemoryRungReminders([this.keys]);

  Set<String>? keys;

  @override
  Future<Set<String>?> read() async => keys == null ? null : {...keys!};

  @override
  Future<void> write(Set<String> keys) async => this.keys = {...keys};
}

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  final now = DateTime(2026, 11, 2, 2, 22);

  Note note(
    String id, {
    int? slot = 1,
    String? remindAt = '2026-11-02T02:21',
    ReminderRecurrence recurrence = ReminderRecurrence.none,
    bool isArchived = false,
  }) => Note(
    id: id,
    title: 'Call the bank',
    isArchived: isArchived,
    reminderSlot: slot,
    reminder: remindAt == null
        ? null
        : NoteReminder(remindAt: remindAt, recurrence: recurrence),
  );

  group('missedReminders', () {
    List<String> missedIds(List<Note> notes, {Set<String> rung = const {}}) =>
        missedReminders(
          notes,
          now: now,
          rung: rung,
          l10n: _english,
        ).map((item) => item.noteId).toList();

    test('finds a one-off whose time passed without ringing here', () {
      expect(missedIds([note('n1')]), ['n1']);
    });

    test('leaves one this phone set an alarm for or rang', () {
      expect(
        missedIds([note('n1')], rung: {rungKey('n1', '2026-11-02T02:21')}),
        isEmpty,
      );
    });

    test('rings a reminder moved to a new time again', () {
      expect(
        missedIds([note('n1')], rung: {rungKey('n1', '2026-11-01T09:00')}),
        ['n1'],
      );
    });

    test('leaves future, stale, repeating and archived reminders', () {
      expect(
        missedIds([
          note('future', remindAt: '2026-11-02T09:00'),
          note('stale', remindAt: '2026-10-31T09:00'),
          note(
            'daily',
            remindAt: '2026-11-01T02:21',
            recurrence: ReminderRecurrence.daily,
          ),
          note('archived', isArchived: true),
          note('no slot', slot: null),
        ]),
        isEmpty,
      );
    });
  });

  group('ringMissedReminders', () {
    test('rings a late reminder once and takes note of it', () async {
      final gateway = ShowingGateway();
      final store = MemoryRungReminders({});

      for (var pass = 0; pass < 2; pass++) {
        await ringMissedReminders(
          gateway,
          store,
          [note('n1', slot: 4)],
          scheduled: const [],
          now: now,
          l10n: _english,
        );
      }

      expect(gateway.shown, [4]);
      expect(store.keys, {rungKey('n1', '2026-11-02T02:21')});
    });

    test('takes note of the alarms set, so they never ring late', () async {
      final gateway = ShowingGateway();
      final store = MemoryRungReminders({});
      final soon = note('n1', remindAt: '2026-11-02T02:30');
      final scheduled = missedReminders(
        [note('n1')],
        now: now,
        rung: const {},
        l10n: _english,
      );

      await ringMissedReminders(
        gateway,
        store,
        [soon],
        scheduled: scheduled,
        now: now,
        l10n: _english,
      );
      await ringMissedReminders(
        gateway,
        store,
        [note('n1', remindAt: '2026-11-02T02:30')],
        scheduled: const [],
        now: DateTime(2026, 11, 2, 2, 31),
        l10n: _english,
      );

      expect(gateway.shown, isEmpty);
    });

    test('forgets reminders only once too old to ring late', () async {
      final store = MemoryRungReminders({
        rungKey('old', '2026-10-31T09:00'),
        // Seen by the background check, not yet by the app's notes.
        rungKey('new', '2026-11-02T02:15'),
      });

      await ringMissedReminders(
        ShowingGateway(),
        store,
        [note('n1', remindAt: null)],
        scheduled: const [],
        now: now,
        l10n: _english,
      );

      expect(store.keys, {rungKey('new', '2026-11-02T02:15')});
    });

    test('rings nothing the app catches up on after the check', () async {
      final gateway = ShowingGateway();
      final store = MemoryRungReminders({rungKey('n1', '2026-11-02T02:21')});

      // The app's first pass, before its sync brings the note in.
      await ringMissedReminders(
        gateway,
        store,
        [note('other', remindAt: null)],
        scheduled: const [],
        now: now,
        l10n: _english,
      );
      await ringMissedReminders(
        gateway,
        store,
        [note('other', remindAt: null), note('n1')],
        scheduled: const [],
        now: now,
        l10n: _english,
      );

      expect(gateway.shown, isEmpty);
    });

    test('waits for the notes before the first note-taking', () async {
      final store = MemoryRungReminders();

      await ringMissedReminders(
        ShowingGateway(),
        store,
        const [],
        scheduled: const [],
        now: now,
        l10n: _english,
      );

      expect(store.keys, isNull);
    });
  });

  group('background check', () {
    SyncEntry entry(Map<String, dynamic> json) => SyncEntry.fromJson(json)!;

    test('takes a reminder set on the web for a note here', () {
      final notes = {'n1': note('n1', remindAt: null)};

      applyPeekedEntry(
        notes,
        entry({
          'entityType': 'reminder',
          'entityId': 'n1',
          'op': 'upsert',
          'reminder': {'remindAt': '2026-11-02T02:30', 'version': 2},
        }),
        unsentReminders: const {},
      );

      expect(notes['n1']!.reminder?.remindAt, '2026-11-02T02:30');
    });

    test('takes a note made on the web with its reminder', () {
      final notes = <String, Note>{};

      applyPeekedEntry(
        notes,
        entry({
          'entityType': 'note',
          'entityId': 'n2',
          'op': 'upsert',
          'note': {
            'id': 'n2',
            'title': 'Issue 204 web reminder',
            'state': 'active',
            'reminder': {'remindAt': '2026-11-02T02:30'},
          },
        }),
        unsentReminders: const {},
      );

      expect(notes['n2']!.title, 'Issue 204 web reminder');
      expect(notes['n2']!.reminder?.remindAt, '2026-11-02T02:30');
      expect(notes['n2']!.reminderSlot, isNull);
    });

    test('keeps a reminder set here and not yet sent', () {
      final notes = {'n1': note('n1', remindAt: '2026-11-03T09:00')};

      applyPeekedEntry(
        notes,
        entry({'entityType': 'reminder', 'entityId': 'n1', 'op': 'remove'}),
        unsentReminders: const {'n1'},
      );

      expect(notes['n1']!.reminder?.remindAt, '2026-11-03T09:00');
    });

    test('drops a removed reminder and a removed note', () {
      final notes = {'n1': note('n1'), 'n2': note('n2')};

      applyPeekedEntry(
        notes,
        entry({'entityType': 'reminder', 'entityId': 'n1', 'op': 'remove'}),
        unsentReminders: const {},
      );
      applyPeekedEntry(
        notes,
        entry({'entityType': 'note', 'entityId': 'n2', 'op': 'remove'}),
        unsentReminders: const {},
      );

      expect(notes['n1']!.reminder, isNull);
      expect(notes.containsKey('n2'), isFalse);
    });

    test('gives new reminders notification ids above those taken', () {
      final slotted = withReminderSlots([
        note('a', slot: 5),
        note('b', slot: null),
        note('c', slot: null, remindAt: null),
        note('d', slot: null),
      ]);

      expect(slotted.map((note) => note.reminderSlot), [5, 6, null, 7]);
    });
  });
}
