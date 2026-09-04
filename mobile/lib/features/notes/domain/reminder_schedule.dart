/// Turns a stored reminder into the instant it should next fire.
///
/// A reminder is a local wall clock with no zone, resolved against the
/// device's current zone every time.
library;

import 'note.dart';

/// Formats a local [DateTime] as the stored wall clock, to the minute.
String toWallClock(DateTime local) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
      '${two(local.day)}T${two(local.hour)}:${two(local.minute)}';
}

final _wallClock = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$');

/// Reads a stored wall clock as a local [DateTime], or null if it is malformed.
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

/// The next time [reminder] should fire, at or after [from], in local time,
/// or null for a one-off whose moment has passed.
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

/// Steps whole days forward, rebuilding from calendar parts so the wall-clock
/// time survives a daylight-saving change.
DateTime _advanceDays(DateTime anchor, DateTime from, int step) {
  var next = anchor;
  while (next.isBefore(from)) {
    final day = DateTime(next.year, next.month, next.day + step);
    next = DateTime(day.year, day.month, day.day, anchor.hour, anchor.minute);
  }
  return next;
}

/// Steps whole months (or years) forward, clamped to the end of short months.
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
