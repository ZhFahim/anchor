import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../l10n/app_localizations.dart';
import '../../notes/domain/note.dart';
import '../domain/reminder_schedule.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';

part 'missed_reminders.g.dart';

/// How late a one-time reminder may reach this phone and still ring.
const Duration missedReminderWindow = Duration(hours: 24);

@Riverpod(keepAlive: true)
RungReminders rungReminders(Ref ref) => FileRungReminders();

/// The one-time reminders this phone has set an alarm for or rung, so each
/// rings once. Shared by the app and its background check.
abstract class RungReminders {
  /// Null until the first pass on this phone has written it.
  Future<Set<String>?> read();
  Future<void> write(Set<String> keys);
}

/// A file rather than secure storage: the background check runs in its own
/// engine, and secure storage there and in the app each keep their own copy
/// in memory, so neither saw the other's writes.
class FileRungReminders implements RungReminders {
  static const _name = 'reminders_rung.json';

  Future<File> _file() async =>
      File(p.join((await getApplicationSupportDirectory()).path, _name));

  @override
  Future<Set<String>?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      return Set<String>.from(jsonDecode(await file.readAsString()) as List);
    } catch (_) {
      return null;
    }
  }

  /// Written aside and moved in, so a reader never sees half of it.
  @override
  Future<void> write(Set<String> keys) async {
    final file = await _file();
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(jsonEncode(keys.toList()), flush: true);
    await pending.rename(file.path);
  }
}

String rungKey(String noteId, String remindAt) => '$noteId@$remindAt';

/// One-time reminders whose time passed within [missedReminderWindow] and
/// that this phone neither set an alarm for nor rang: they reached it late.
List<DesiredReminder> missedReminders(
  List<Note> notes, {
  required DateTime now,
  required Set<String> rung,
  required AppLocalizations l10n,
}) {
  final missed = <DesiredReminder>[];
  for (final note in notes) {
    final reminder = note.reminder;
    if (reminder == null || reminder.recurrence.repeats) continue;
    if (!note.isActive || note.isArchived) continue;
    final slot = note.reminderSlot;
    if (slot == null) continue;
    if (rung.contains(rungKey(note.id, reminder.remindAt))) continue;

    final at = parseWallClock(reminder.remindAt);
    if (at == null || at.isAfter(now)) continue;
    if (now.difference(at) > missedReminderWindow) continue;

    final heading = reminderHeading(note);
    missed.add(
      DesiredReminder(
        id: slot,
        at: at,
        title: heading ?? l10n.reminderTitle,
        body: heading == null ? '' : reminderBody(note),
        repeat: null,
        noteId: note.id,
      ),
    );
  }
  return missed;
}

/// Rings the reminders that reached this phone after their time, and notes
/// the alarms just set in [scheduled] so they don't ring again once due.
///
/// The first pass on a phone only takes note of what is due, ringing
/// nothing: those reminders rang, or were missed, before this existed.
Future<void> ringMissedReminders(
  NotificationGateway gateway,
  RungReminders store,
  List<Note> notes, {
  required List<DesiredReminder> scheduled,
  required DateTime now,
  required AppLocalizations l10n,
}) async {
  final Set<String>? stored;
  try {
    stored = await store.read();
  } catch (error, stack) {
    AppLogger.instance.error(
      LogTags.reminders,
      'Reading the rung reminders failed',
      error: error,
      stackTrace: stack,
    );
    return;
  }
  // Nothing to take note of yet; an empty list would ring everything later.
  if (stored == null && notes.isEmpty) return;
  final rung = {...?stored};
  final missed = stored == null
      ? const <DesiredReminder>[]
      : missedReminders(notes, now: now, rung: rung, l10n: l10n);

  for (final item in missed) {
    try {
      await gateway.show(item.toNotification());
      AppLogger.instance.info(
        LogTags.reminders,
        'Rang the late reminder on note ${item.noteId}',
      );
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.reminders,
        'Ringing the late reminder on note ${item.noteId} failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  final remindAts = {for (final note in notes) note.id: note.reminder};
  final next = <String>{
    // Forgotten only once too old to ring late: the notes here may not have
    // caught up with what the background check saw.
    for (final key in rung)
      if (_canStillBeLate(key, now)) key,
    for (final item in [...missed, ...scheduled])
      if (remindAts[item.noteId] case final reminder?
          when !reminder.recurrence.repeats)
        rungKey(item.noteId, reminder.remindAt),
    if (stored == null)
      for (final note in notes)
        if (note.reminder case final reminder?
            when !reminder.recurrence.repeats)
          rungKey(note.id, reminder.remindAt),
  };

  if (stored != null && _sameSet(next, stored)) return;
  try {
    await store.write(next);
  } catch (error, stack) {
    AppLogger.instance.error(
      LogTags.reminders,
      'Saving the rung reminders failed',
      error: error,
      stackTrace: stack,
    );
  }
}

bool _canStillBeLate(String key, DateTime now) {
  final at = parseWallClock(key.substring(key.indexOf('@') + 1));
  return at != null && now.difference(at) <= missedReminderWindow;
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
