/// A reminder is a local wall clock with no zone, resolved against the
/// device's current zone every time.
library;

import '../../notes/domain/note.dart';

String toWallClock(DateTime local) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${twoDigits(local.month)}-'
      '${twoDigits(local.day)}T${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

final _wallClock = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$');

DateTime? parseWallClock(String? value) {
  if (value == null) return null;
  final match = _wallClock.firstMatch(value);
  if (match == null) return null;

  final parts = [for (var i = 1; i <= 5; i++) int.parse(match.group(i)!)];
  final parsed = DateTime(parts[0], parts[1], parts[2], parts[3], parts[4]);
  // DateTime rolls 2026-02-31 into March rather than rejecting it.
  if (parsed.month != parts[1] || parsed.day != parts[2]) return null;
  return parsed;
}

/// At or after [from]; null when a one-time reminder has passed.
DateTime? nextOccurrence(NoteReminder reminder, {required DateTime from}) {
  final anchor = parseWallClock(reminder.remindAt);
  if (anchor == null) return null;
  if (!anchor.isBefore(from)) return anchor;
  if (!reminder.recurrence.repeats) return null;

  return switch (reminder.recurrence) {
    ReminderRecurrence.daily => _advanceDays(anchor, from, 1),
    ReminderRecurrence.weekly => _advanceDays(anchor, from, 7),
    ReminderRecurrence.monthly => _advanceMonths(anchor, from, 1),
    ReminderRecurrence.yearly => _advanceMonths(anchor, from, 12),
    ReminderRecurrence.none => null,
  };
}

List<DateTime> nextOccurrences(
  NoteReminder reminder, {
  required DateTime from,
  required int count,
}) {
  final dates = <DateTime>[];
  var next = nextOccurrence(reminder, from: from);
  while (next != null && dates.length < count) {
    dates.add(next);
    next = nextOccurrence(reminder, from: next.add(const Duration(minutes: 1)));
  }
  return dates;
}

/// The OS repeat has no start date and skips months that lack the day.
bool canUseOsRepeat(NoteReminder reminder, {required DateTime now}) {
  final anchor = parseWallClock(reminder.remindAt);
  final at = nextOccurrence(reminder, from: now);
  if (anchor == null || at == null) return false;

  final isLeapDay = anchor.month == 2 && anchor.day == 29;
  final previous = switch (reminder.recurrence) {
    ReminderRecurrence.daily => DateTime(
      at.year,
      at.month,
      at.day - 1,
      at.hour,
      at.minute,
    ),
    ReminderRecurrence.weekly => DateTime(
      at.year,
      at.month,
      at.day - 7,
      at.hour,
      at.minute,
    ),
    ReminderRecurrence.monthly when anchor.day <= 28 => DateTime(
      at.year,
      at.month - 1,
      at.day,
      at.hour,
      at.minute,
    ),
    ReminderRecurrence.yearly when !isLeapDay => DateTime(
      at.year - 1,
      at.month,
      at.day,
      at.hour,
      at.minute,
    ),
    _ => null,
  };
  return previous != null && previous.isBefore(now);
}

/// Rebuilds from calendar parts to keep the wall-clock time across daylight
/// saving.
DateTime _advanceDays(DateTime anchor, DateTime from, int step) {
  var next = anchor;
  while (next.isBefore(from)) {
    final day = DateTime(next.year, next.month, next.day + step);
    next = DateTime(day.year, day.month, day.day, anchor.hour, anchor.minute);
  }
  return next;
}

DateTime _advanceMonths(DateTime anchor, DateTime from, int step) {
  var months = anchor.year * 12 + (anchor.month - 1);
  var next = anchor;
  while (next.isBefore(from)) {
    months += step;
    final year = months ~/ 12;
    final month = months % 12 + 1;
    final day = anchor.day <= _daysInMonth(year, month)
        ? anchor.day
        : _daysInMonth(year, month);
    next = DateTime(year, month, day, anchor.hour, anchor.minute);
  }
  return next;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
