import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notes/data/repository/notes_repository.dart';
import '../../features/notes/domain/note.dart' as domain;
import '../../features/notes/domain/reminder_schedule.dart';
import '../logging/app_logger.dart';
import '../providers/active_user_id_provider.dart';
import 'notification_gateway.dart';

part 'reminder_scheduler.g.dart';

const _tag = 'Reminders';

/// iOS keeps only the soonest 64 pending notifications.
const int maxScheduledReminders = 60;

/// Settle window for the notes watch, which re-runs on every write.
const Duration _settleWindow = Duration(milliseconds: 500);

/// How long to wait before trying again after a pass that did not land.
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

/// Keeps the OS's pending notifications in step with the reminders in Drift.
///
/// Diffs what the device should hold against what it does hold, cancelling
/// the difference rather than rescheduling everything.
@Riverpod(keepAlive: true)
class ReminderScheduler extends _$ReminderScheduler {
  Timer? _settle;
  Timer? _retry;

  /// The set the last pass managed to apply, or null when none has run yet.
  List<DesiredReminder>? _lastApplied;
  List<domain.Note> _latest = const [];
  Future<void>? _cleared;
  AppLifecycleListener? _lifecycle;

  /// The pass running now; passes never overlap.
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
    if (userId == null) {
      // Signed out: nothing should be left ringing or waiting to.
      _cleared = _cancelAll(gateway);
      return;
    }

    final repo = ref.watch(notesRepositoryProvider);
    final subscription = repo.watchNotes().listen(_onNotes);

    _lifecycle = AppLifecycleListener(
      // The device may have crossed a time zone while we were away.
      onResume: () => unawaited(_onResume(gateway)),
    );

    ref.onDispose(() {
      _settle?.cancel();
      _settle = null;
      _retry?.cancel();
      _retry = null;
      _lifecycle?.dispose();
      _lifecycle = null;
      subscription.cancel();
    });
  }

  /// Clears the OS without ever failing, since every later pass waits on it.
  Future<void> _cancelAll(NotificationGateway gateway) async {
    try {
      await gateway.cancelAll();
    } catch (error, stack) {
      AppLogger.instance.error(
        _tag,
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

  void _onNotes(List<domain.Note> notes) {
    _latest = notes;
    _settle?.cancel();
    _settle = Timer(_settleWindow, () {
      _settle = null;
      unawaited(_reconcile());
    });
  }

  /// Joins the pass already running, if there is one, and asks it to go again.
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
      final desired = desiredReminders(_latest, now: DateTime.now());

      if (_sameAs(desired)) return;

      final pending = (await gateway.pendingIds()).toSet();
      final report = await applyReminders(gateway, desired, pending: pending);

      // A pass with a failure in it is not remembered, so the next one runs.
      _lastApplied = report.failed == 0 ? desired : null;
      AppLogger.instance.info(
        _tag,
        'reconciled scheduled=${desired.length} '
        'cancelled=${report.cancelled} failed=${report.failed}',
      );
      _armRetry(report.failed > 0);
    } catch (error, stack) {
      _lastApplied = null;
      AppLogger.instance.error(
        _tag,
        'Reconcile failed',
        error: error,
        stackTrace: stack,
      );
      _armRetry(true);
    }
  }

  /// Arms another try after a pass that fell short, or stands down.
  void _armRetry(bool failed) {
    _retry?.cancel();
    _retry = null;

    if (!failed) {
      _failures = 0;
      return;
    }

    _failures++;
    final delay = reminderRetryDelay(_failures);
    AppLogger.instance.warn(_tag, 'retrying in ${delay.inSeconds}s');
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

/// Cancels what the OS holds and we no longer want, then schedules the rest.
///
/// One call per reminder: a refusal costs only that one.
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
        _tag,
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
        _tag,
        'Scheduling the reminder on note ${item.noteId} failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  return ReminderSyncReport(cancelled: orphans.length, failed: failed);
}

/// What one pass over the OS's notifications managed.
class ReminderSyncReport {
  const ReminderSyncReport({required this.cancelled, required this.failed});

  final int cancelled;
  final int failed;
}

/// What the OS should be holding, soonest first and capped.
List<DesiredReminder> desiredReminders(
  List<domain.Note> notes, {
  required DateTime now,
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
      AppLogger.instance.warn(_tag, 'No notification id for note ${note.id}');
      continue;
    }

    desired.add(
      DesiredReminder(
        id: slot,
        at: at,
        title: note.displayTitle,
        repeat: matchComponentsFor(reminder.recurrence),
        noteId: note.id,
      ),
    );
  }

  desired.sort((a, b) => a.at.compareTo(b.at));
  return desired.take(maxScheduledReminders).toList();
}

/// How a recurrence maps onto the OS's own repeat.
DateTimeComponents? matchComponentsFor(domain.ReminderRecurrence recurrence) =>
    switch (recurrence) {
      domain.ReminderRecurrence.none => null,
      domain.ReminderRecurrence.daily => DateTimeComponents.time,
      domain.ReminderRecurrence.weekly => DateTimeComponents.dayOfWeekAndTime,
      domain.ReminderRecurrence.monthly => DateTimeComponents.dayOfMonthAndTime,
      domain.ReminderRecurrence.yearly => DateTimeComponents.dateAndTime,
    };

@immutable
class DesiredReminder {
  const DesiredReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.repeat,
    required this.noteId,
  });

  final int id;
  final DateTime at;
  final String title;
  final DateTimeComponents? repeat;
  final String noteId;

  ScheduledNotification toNotification() => ScheduledNotification(
    id: id,
    title: title,
    body: 'Reminder',
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
      other.repeat == repeat &&
      other.noteId == noteId;

  @override
  int get hashCode => Object.hash(id, at, title, repeat, noteId);
}
