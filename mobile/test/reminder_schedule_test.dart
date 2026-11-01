import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/reminders/domain/reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NoteReminder at(String remindAt, [ReminderRecurrence? every]) => NoteReminder(
    remindAt: remindAt,
    recurrence: every ?? ReminderRecurrence.none,
  );

  group('wall clock', () {
    test('round-trips through a local DateTime', () {
      expect(toWallClock(DateTime(2026, 9, 4, 9)), '2026-09-04T09:00');
      expect(parseWallClock('2026-09-04T09:00'), DateTime(2026, 9, 4, 9));
    });

    test('pads single-digit parts', () {
      expect(toWallClock(DateTime(2026, 1, 5, 7, 3)), '2026-01-05T07:03');
    });

    test('rejects anything carrying a zone, seconds or nonsense', () {
      expect(parseWallClock('2026-09-04T09:00:00Z'), isNull);
      expect(parseWallClock('2026-09-04T09:00:00'), isNull);
      expect(parseWallClock('2026-09-04 09:00'), isNull);
      expect(parseWallClock('tomorrow'), isNull);
      expect(parseWallClock(null), isNull);
    });

    test('rejects a date the calendar does not have', () {
      expect(parseWallClock('2026-02-31T09:00'), isNull);
    });
  });

  group('one-off', () {
    test('returns the anchor while it is still ahead', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00'),
        from: DateTime(2026, 9, 4, 8, 59),
      );
      expect(next, DateTime(2026, 9, 4, 9));
    });

    test('fires on the exact minute rather than skipping it', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00'),
        from: DateTime(2026, 9, 4, 9),
      );
      expect(next, DateTime(2026, 9, 4, 9));
    });

    test('is null once it has passed', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00'),
        from: DateTime(2026, 9, 4, 9, 1),
      );
      expect(next, isNull);
    });

    test('is null when the stored value is malformed', () {
      expect(nextOccurrence(at('nope'), from: DateTime(2026)), isNull);
    });
  });

  group('daily', () {
    test('rolls forward to the next day at the same wall time', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00', ReminderRecurrence.daily),
        from: DateTime(2026, 9, 4, 12),
      );
      expect(next, DateTime(2026, 9, 5, 9));
    });

    test('skips every occurrence that has already gone', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00', ReminderRecurrence.daily),
        from: DateTime(2026, 9, 7, 12),
      );
      expect(next, DateTime(2026, 9, 8, 9));
    });

    test('keeps the wall time across a daylight-saving change', () {
      final next = nextOccurrence(
        at('2026-03-28T09:00', ReminderRecurrence.daily),
        from: DateTime(2026, 3, 29, 8),
      );
      expect(next!.hour, 9);
      expect(next.minute, 0);
    });
  });

  group('weekly', () {
    test('lands on the same weekday', () {
      final anchor = DateTime(2026, 9, 4, 9);
      final next = nextOccurrence(
        at('2026-09-04T09:00', ReminderRecurrence.weekly),
        from: DateTime(2026, 9, 4, 12),
      );
      expect(next, DateTime(2026, 9, 11, 9));
      expect(next!.weekday, anchor.weekday);
    });
  });

  group('monthly', () {
    test('keeps the day of month', () {
      final next = nextOccurrence(
        at('2026-09-15T09:00', ReminderRecurrence.monthly),
        from: DateTime(2026, 9, 20),
      );
      expect(next, DateTime(2026, 10, 15, 9));
    });

    test('clamps to the last day of a short month', () {
      final next = nextOccurrence(
        at('2026-01-31T09:00', ReminderRecurrence.monthly),
        from: DateTime(2026, 2, 1),
      );
      expect(next, DateTime(2026, 2, 28, 9));
    });

    test('returns to the anchor day after a short month', () {
      final next = nextOccurrence(
        at('2026-01-31T09:00', ReminderRecurrence.monthly),
        from: DateTime(2026, 3, 1),
      );
      expect(next, DateTime(2026, 3, 31, 9));
    });

    test('clamps into a leap February', () {
      final next = nextOccurrence(
        at('2028-01-31T09:00', ReminderRecurrence.monthly),
        from: DateTime(2028, 2, 1),
      );
      expect(next, DateTime(2028, 2, 29, 9));
    });
  });

  group('yearly', () {
    test('lands on the same date next year', () {
      final next = nextOccurrence(
        at('2026-09-04T09:00', ReminderRecurrence.yearly),
        from: DateTime(2026, 9, 5),
      );
      expect(next, DateTime(2027, 9, 4, 9));
    });

    test('clamps a leap-day anchor into a non-leap year', () {
      final next = nextOccurrence(
        at('2028-02-29T09:00', ReminderRecurrence.yearly),
        from: DateTime(2028, 3, 1),
      );
      expect(next, DateTime(2029, 2, 28, 9));
    });
  });

  group('nextOccurrences', () {
    test('lists the dates from the first one on', () {
      expect(
        nextOccurrences(
          at('2027-03-01T09:00', ReminderRecurrence.monthly),
          from: DateTime(2026, 11, 1),
          count: 3,
        ),
        [
          DateTime(2027, 3, 1, 9),
          DateTime(2027, 4, 1, 9),
          DateTime(2027, 5, 1, 9),
        ],
      );
    });

    test('starts at the next date once the first has gone', () {
      expect(
        nextOccurrences(
          at('2026-09-04T09:00', ReminderRecurrence.weekly),
          from: DateTime(2026, 9, 5),
          count: 2,
        ),
        [DateTime(2026, 9, 11, 9), DateTime(2026, 9, 18, 9)],
      );
    });

    test('follows a month-end day through short months', () {
      expect(
        nextOccurrences(
          at('2027-01-31T09:00', ReminderRecurrence.monthly),
          from: DateTime(2026, 11, 1),
          count: 4,
        ),
        [
          DateTime(2027, 1, 31, 9),
          DateTime(2027, 2, 28, 9),
          DateTime(2027, 3, 31, 9),
          DateTime(2027, 4, 30, 9),
        ],
      );
    });

    test('a one-off has one date at most', () {
      final once = at('2027-03-01T09:00');

      expect(nextOccurrences(once, from: DateTime(2026, 11, 1), count: 12), [
        DateTime(2027, 3, 1, 9),
      ]);
      expect(
        nextOccurrences(once, from: DateTime(2027, 3, 2), count: 12),
        isEmpty,
      );
    });
  });

  group('canUseOsRepeat', () {
    bool canRepeat(String remindAt, ReminderRecurrence every, DateTime now) =>
        canUseOsRepeat(at(remindAt, every), now: now);

    test('not while a monthly repeat would match before its first date', () {
      expect(
        canRepeat(
          '2027-03-01T09:00',
          ReminderRecurrence.monthly,
          DateTime(2026, 10, 1),
        ),
        isFalse,
      );
    });

    test('not on the minute of the last match before the first date', () {
      expect(
        canRepeat(
          '2027-03-01T09:00',
          ReminderRecurrence.monthly,
          DateTime(2027, 2, 1, 9),
        ),
        isFalse,
      );
    });

    test('once the first date is the next match', () {
      expect(
        canRepeat(
          '2027-03-01T09:00',
          ReminderRecurrence.monthly,
          DateTime(2027, 2, 1, 9, 1),
        ),
        isTrue,
      );
    });

    test('after the first date has passed', () {
      expect(
        canRepeat(
          '2027-03-01T09:00',
          ReminderRecurrence.monthly,
          DateTime(2027, 3, 2),
        ),
        isTrue,
      );
    });

    test('a daily repeat from tomorrow waits for today\'s time to pass', () {
      const tomorrow = '2026-11-03T09:00';

      expect(
        canRepeat(tomorrow, ReminderRecurrence.daily, DateTime(2026, 11, 2, 8)),
        isFalse,
      );
      expect(
        canRepeat(
          tomorrow,
          ReminderRecurrence.daily,
          DateTime(2026, 11, 2, 10),
        ),
        isTrue,
      );
    });

    test('a weekly repeat waits for the last match before its first date', () {
      const start = '2026-11-15T09:00';

      expect(
        canRepeat(start, ReminderRecurrence.weekly, DateTime(2026, 11, 2)),
        isFalse,
      );
      expect(
        canRepeat(start, ReminderRecurrence.weekly, DateTime(2026, 11, 9)),
        isTrue,
      );
    });

    test('a yearly repeat waits for the last match before its first date', () {
      const start = '2028-03-01T09:00';

      expect(
        canRepeat(start, ReminderRecurrence.yearly, DateTime(2026, 11, 1)),
        isFalse,
      );
      expect(
        canRepeat(start, ReminderRecurrence.yearly, DateTime(2027, 3, 2)),
        isTrue,
      );
    });

    test('never for a day some months lack', () {
      for (final day in ['29', '30', '31']) {
        expect(
          canRepeat(
            '2026-01-${day}T09:00',
            ReminderRecurrence.monthly,
            DateTime(2026, 3, 5),
          ),
          isFalse,
          reason: 'day $day',
        );
      }
    });

    test('never for a date moved into a shorter month', () {
      expect(
        canRepeat(
          '2026-01-31T09:00',
          ReminderRecurrence.monthly,
          DateTime(2026, 2, 10),
        ),
        isFalse,
      );
    });

    test('for the 28th, which every month has', () {
      expect(
        canRepeat(
          '2026-01-28T09:00',
          ReminderRecurrence.monthly,
          DateTime(2026, 3, 5),
        ),
        isTrue,
      );
    });

    test('never for a leap day', () {
      expect(
        canRepeat(
          '2028-02-29T09:00',
          ReminderRecurrence.yearly,
          DateTime(2029, 1, 1),
        ),
        isFalse,
      );
    });

    test('never for a one-off or a malformed date', () {
      expect(
        canRepeat(
          '2026-11-03T09:00',
          ReminderRecurrence.none,
          DateTime(2026, 11, 2),
        ),
        isFalse,
      );
      expect(
        canRepeat('nope', ReminderRecurrence.daily, DateTime(2026, 11, 2)),
        isFalse,
      );
    });
  });

  group('ReminderRecurrence', () {
    test('falls back to a one-off on an unknown value', () {
      expect(
        ReminderRecurrence.fromString('fortnightly'),
        ReminderRecurrence.none,
      );
      expect(ReminderRecurrence.fromString(null), ReminderRecurrence.none);
    });

    test('reads the values it knows', () {
      expect(ReminderRecurrence.fromString('daily'), ReminderRecurrence.daily);
      expect(ReminderRecurrence.daily.repeats, isTrue);
      expect(ReminderRecurrence.none.repeats, isFalse);
    });
  });
}
