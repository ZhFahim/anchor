import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/session/active_user_id_provider.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_blocks.dart';
import '../../notes/presentation/notes_controller.dart';
import '../domain/reminder_schedule.dart';
import 'missed_reminders.dart';
import 'notification_gateway.dart';

part 'reminder_scheduler.g.dart';

/// iOS keeps only the soonest 64 pending notifications.
const int maxScheduledReminders = 60;

const Duration _settleWindow = Duration(milliseconds: 500);

const List<Duration> _retryDelays = [
  Duration(seconds: 2),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(minutes: 2),
  Duration(minutes: 10),
];

/// The wait before the [attempt]th try, levelling off at the last delay.
Duration reminderRetryDelay(int attempt) =>
    _retryDelays[min(attempt, _retryDelays.length) - 1];

@Riverpod(keepAlive: true)
class ReminderScheduler extends _$ReminderScheduler {
  Timer? _settle;
  Timer? _retry;
  List<DesiredReminder>? _lastApplied;
  List<Note> _latest = const [];

  /// Whether [_latest] holds the notes yet, rather than nothing loaded.
  bool _hasNotes = false;
  Future<void>? _cleared;
  AppLifecycleListener? _lifecycle;

  /// Passes never overlap.
  Future<void>? _active;
  bool _rerunRequested = false;
  bool _forced = false;
  int _failures = 0;

  @override
  void build() {
    // appDatabaseProvider throws while auth is still resolving the user.
    if (ref.watch(authControllerProvider).isLoading) return;

    final gateway = ref.watch(notificationGatewayProvider);
    final userId = ref.watch(activeUserIdProvider);

    _lastApplied = null;
    _latest = const [];
    _hasNotes = false;
    if (userId == null) {
      _cleared = _cancelAll(gateway);
      return;
    }

    ref.listen(allActiveNotesProvider, (_, notes) {
      if (notes case AsyncData(:final value)) _onNotes(value);
    }, fireImmediately: true);

    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_onResume(gateway)),
    );

    ref.onDispose(() {
      _settle?.cancel();
      _settle = null;
      _retry?.cancel();
      _retry = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
  }

  /// Must never throw: every later pass awaits it.
  Future<void> _cancelAll(NotificationGateway gateway) async {
    try {
      await gateway.cancelAll();
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.reminders,
        'Clearing the notifications failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _onResume(NotificationGateway gateway) async {
    await syncLocalTimeZone();
    await _reconcile(force: true);
  }

  void _onNotes(List<Note> notes) {
    _latest = notes;
    _hasNotes = true;
    _settle?.cancel();
    _settle = Timer(_settleWindow, () {
      _settle = null;
      unawaited(_reconcile());
    });
  }

  Future<void> _reconcile({bool force = false}) {
    _forced = _forced || force;

    final active = _active;
    if (active != null) {
      _rerunRequested = true;
      return active;
    }

    final pass = _runPasses();
    _active = pass;
    return pass;
  }

  Future<void> _runPasses() async {
    try {
      do {
        _rerunRequested = false;
        await _runPass();
      } while (_rerunRequested);
    } finally {
      _active = null;
    }
  }

  Future<void> _runPass() async {
    final gateway = ref.read(notificationGatewayProvider);
    if (_forced) {
      _forced = false;
      _lastApplied = null;
    }
    try {
      await _cleared;
      await gateway.initialize();
      final now = DateTime.now();
      final l10n = deviceL10n();
      final desired = desiredReminders(_latest, now: now, l10n: l10n);

      // A reminder that came in after its time changes no alarm.
      if (_hasNotes) {
        await ringMissedReminders(
          gateway,
          ref.read(rungRemindersProvider),
          _latest,
          scheduled: desired,
          now: now,
          l10n: l10n,
        );
      }

      if (_sameAs(desired)) return;

      final pending = (await gateway.pendingIds()).toSet();
      final report = await applyReminders(gateway, desired, pending: pending);

      // Only a pass with no failures is remembered.
      _lastApplied = report.failed == 0 ? desired : null;
      AppLogger.instance.info(
        LogTags.reminders,
        'reconciled scheduled=${desired.length} '
        'cancelled=${report.cancelled} failed=${report.failed}',
      );
      _armRetry(report.failed > 0);
    } catch (error, stack) {
      _lastApplied = null;
      AppLogger.instance.error(
        LogTags.reminders,
        'Reconcile failed',
        error: error,
        stackTrace: stack,
      );
      _armRetry(true);
    }
  }

  void _armRetry(bool failed) {
    _retry?.cancel();
    _retry = null;

    if (!failed) {
      _failures = 0;
      return;
    }

    _failures++;
    final delay = reminderRetryDelay(_failures);
    AppLogger.instance.warn(
      LogTags.reminders,
      'retrying in ${delay.inSeconds}s',
    );
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(_reconcile());
    });
  }

  bool _sameAs(List<DesiredReminder> next) {
    final last = _lastApplied;
    if (last == null || last.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (last[i] != next[i]) return false;
    }
    return true;
  }
}

Future<ReminderSyncReport> applyReminders(
  NotificationGateway gateway,
  List<DesiredReminder> desired, {
  required Set<int> pending,
}) async {
  final wanted = {for (final item in desired) item.id};
  final orphans = pending.difference(wanted);
  var failed = 0;

  for (final id in orphans) {
    try {
      await gateway.cancel(id);
    } catch (error, stack) {
      failed++;
      AppLogger.instance.error(
        LogTags.reminders,
        'Cancelling notification $id failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  for (final item in desired) {
    try {
      await gateway.schedule(item.toNotification());
    } catch (error, stack) {
      failed++;
      AppLogger.instance.error(
        LogTags.reminders,
        'Scheduling the reminder on note ${item.noteId} failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  return ReminderSyncReport(cancelled: orphans.length, failed: failed);
}

class ReminderSyncReport {
  const ReminderSyncReport({required this.cancelled, required this.failed});

  final int cancelled;
  final int failed;
}

/// The note's title, or else the first line of its text (but never a
/// locked note's: notifications show on the lock screen).
String? reminderHeading(Note note) {
  if (note.hasTitle) return note.title;
  if (note.isLocked) return null;
  final firstLine = snippetTextOf(note.content).split('\n').first;
  return firstLine.isEmpty ? null : firstLine;
}

/// The line under the heading; nothing of a locked note's text.
String reminderBody(Note note) {
  if (note.isLocked) return '';
  final lines = snippetTextOf(
    note.content,
  ).split('\n').where((l) => l.trim().isNotEmpty).toList();
  final rest = note.hasTitle ? lines : lines.skip(1).toList();
  return rest.isEmpty ? '' : rest.first;
}

List<DesiredReminder> desiredReminders(
  List<Note> notes, {
  required DateTime now,
  required AppLocalizations l10n,
}) {
  final desired = <DesiredReminder>[];
  for (final note in notes) {
    final reminder = note.reminder;
    // Trashed and archived notes keep their reminder but stop ringing.
    if (reminder == null || !note.isActive || note.isArchived) continue;

    final at = nextOccurrence(reminder, from: now);
    if (at == null) continue;

    final slot = note.reminderSlot;
    if (slot == null) {
      AppLogger.instance.warn(
        LogTags.reminders,
        'No notification id for note ${note.id}',
      );
      continue;
    }

    final heading = reminderHeading(note);
    desired.add(
      DesiredReminder(
        id: slot,
        at: at,
        title: heading ?? l10n.reminderTitle,
        body: heading == null ? '' : reminderBody(note),
        repeat: repeatFor(reminder, at: at, now: now),
        noteId: note.id,
      ),
    );
  }

  desired.sort((a, b) => a.at.compareTo(b.at));
  return desired.take(maxScheduledReminders).toList();
}

/// The OS repeats a notification only once its next two firings are the
/// reminder's; until then it rings once at [at] and a later pass hands the
/// series over.
///
/// The OS keeps only the matched parts of [at] and rings at the first match
/// from now, so a monthly reminder starting next March would ring on the
/// coming day with the same day of the month.
DateTimeComponents? repeatFor(
  NoteReminder reminder, {
  required DateTime at,
  required DateTime now,
}) {
  final components = matchComponentsFor(reminder.recurrence);
  if (components == null) return null;

  final after = at.add(const Duration(minutes: 1));
  final follows = nextOccurrence(reminder, from: after);
  final keepsSeries =
      osFiring(at, components, from: now) == at &&
      osFiring(at, components, from: after) == follows;
  return keepsSeries ? components : null;
}

/// The first time at or after [from] that matches [at]'s [components], as
/// flutter_local_notifications picks it on Android and iOS.
DateTime? osFiring(
  DateTime at,
  DateTimeComponents components, {
  required DateTime from,
}) {
  // A yearly Feb 29 matches within four years.
  for (var offset = 0; offset <= 4 * 366; offset++) {
    final firing = DateTime(
      from.year,
      from.month,
      from.day + offset,
      at.hour,
      at.minute,
    );
    if (firing.isBefore(from)) continue;
    final matches = switch (components) {
      DateTimeComponents.time => true,
      DateTimeComponents.dayOfWeekAndTime => firing.weekday == at.weekday,
      DateTimeComponents.dayOfMonthAndTime => firing.day == at.day,
      DateTimeComponents.dateAndTime =>
        firing.month == at.month && firing.day == at.day,
    };
    if (matches) return firing;
  }
  return null;
}

DateTimeComponents? matchComponentsFor(ReminderRecurrence recurrence) =>
    switch (recurrence) {
      ReminderRecurrence.none => null,
      ReminderRecurrence.daily => DateTimeComponents.time,
      ReminderRecurrence.weekly => DateTimeComponents.dayOfWeekAndTime,
      ReminderRecurrence.monthly => DateTimeComponents.dayOfMonthAndTime,
      ReminderRecurrence.yearly => DateTimeComponents.dateAndTime,
    };

@immutable
class DesiredReminder {
  const DesiredReminder({
    required this.id,
    required this.at,
    required this.title,
    this.body = '',
    required this.repeat,
    required this.noteId,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final DateTimeComponents? repeat;
  final String noteId;

  ScheduledNotification toNotification() => ScheduledNotification(
    id: id,
    title: title,
    body: body,
    at: at,
    repeat: repeat,
    payload: noteId,
  );

  @override
  bool operator ==(Object other) =>
      other is DesiredReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.repeat == repeat &&
      other.noteId == noteId;

  @override
  int get hashCode => Object.hash(id, at, title, body, repeat, noteId);
}
