import 'dart:async';

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

/// Keeps the OS's pending notifications in step with the reminders in Drift.
///
/// Diffs what the device should hold against what it does hold, cancelling
/// the difference rather than rescheduling everything.
@Riverpod(keepAlive: true)
class ReminderScheduler extends _$ReminderScheduler {
  Timer? _settle;
  List<DesiredReminder> _lastApplied = const [];
  List<domain.Note> _latest = const [];
  Future<void>? _cleared;
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    // appDatabaseProvider throws while auth is still resolving the user.
    if (ref.watch(authControllerProvider).isLoading) return;

    final gateway = ref.watch(notificationGatewayProvider);
    final userId = ref.watch(activeUserIdProvider);

    // OS ids are per app, reminder slots per user: a user switch clears both.
    _lastApplied = const [];
    _latest = const [];
    _cleared = gateway.cancelAll();
    if (userId == null) return;

    final repo = ref.watch(notesRepositoryProvider);
    final subscription = repo.watchNotes().listen(_onNotes);

    _lifecycle = AppLifecycleListener(
      // The device may have crossed a time zone while we were away.
      onResume: () => unawaited(_onResume(gateway)),
    );

    ref.onDispose(() {
      _settle?.cancel();
      _settle = null;
      _lifecycle?.dispose();
      _lifecycle = null;
      subscription.cancel();
    });
  }

  Future<void> _onResume(NotificationGateway gateway) async {
    await syncLocalTimeZone();
    _lastApplied = const [];
    await _reconcile();
  }

  void _onNotes(List<domain.Note> notes) {
    _latest = notes;
    _settle?.cancel();
    _settle = Timer(_settleWindow, () {
      _settle = null;
      unawaited(_reconcile());
    });
  }

  Future<void> _reconcile() async {
    final gateway = ref.read(notificationGatewayProvider);
    try {
      await _cleared;
      await gateway.initialize();
      final desired = desiredReminders(_latest, now: DateTime.now());

      if (_sameAs(desired)) return;

      final pending = (await gateway.pendingIds()).toSet();
      final wanted = {for (final item in desired) item.id};

      for (final id in pending.difference(wanted)) {
        await gateway.cancel(id);
      }

      for (final item in desired) {
        await gateway.schedule(item.toNotification());
      }

      _lastApplied = desired;
      AppLogger.instance.info(
        _tag,
        'reconciled scheduled=${desired.length} cancelled='
        '${pending.difference(wanted).length}',
      );
    } catch (error, stack) {
      _lastApplied = const [];
      AppLogger.instance.error(
        _tag,
        'Reconcile failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  bool _sameAs(List<DesiredReminder> next) {
    if (_lastApplied.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (_lastApplied[i] != next[i]) return false;
    }
    return true;
  }
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
