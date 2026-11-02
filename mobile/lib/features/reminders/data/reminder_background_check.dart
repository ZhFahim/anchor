import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';

import '../../../app/bootstrap.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/session/active_user_id_provider.dart';
import '../../../core/session/session_expired_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../l10n/l10n.dart';
import '../../notes/data/repository/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../sync/data/sync_api.dart';
import '../presentation/notification_launch.dart';
import 'missed_reminders.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';

part 'reminder_background_check.g.dart';

const reminderCheckTask = 'anchor.reminderCheck';

/// Android runs periodic work no more often than this.
const Duration reminderCheckInterval = Duration(minutes: 15);

/// Pages of changes one check reads before leaving the rest to the app.
const int _maxPages = 20;

/// Keeps the background check registered while someone is signed in, so a
/// reminder set on another device rings here with the app closed.
@Riverpod(keepAlive: true)
void reminderBackgroundCheck(Ref ref) {
  final userId = ref.watch(activeUserIdProvider);
  if (!Platform.isAndroid) return;
  unawaited(
    _register(userId != null).catchError((Object error, StackTrace stack) {
      AppLogger.instance.error(
        LogTags.reminders,
        'Setting up the background reminder check failed',
        error: error,
        stackTrace: stack,
      );
    }),
  );
}

Future<void> _register(bool signedIn) async {
  final workmanager = Workmanager();
  await workmanager.initialize(reminderCheckDispatcher);
  if (!signedIn) {
    await workmanager.cancelByUniqueName(reminderCheckTask);
    return;
  }
  await workmanager.registerPeriodicTask(
    reminderCheckTask,
    reminderCheckTask,
    frequency: reminderCheckInterval,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

@pragma('vm:entry-point')
void reminderCheckDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != reminderCheckTask) return true;
    try {
      await runReminderCheck();
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.reminders,
        'Background reminder check failed',
        error: error,
        stackTrace: stack,
      );
    }
    await AppLogger.instance.flush();
    // A failed check waits for the next one rather than retrying sooner.
    return true;
  });
}

/// Reads what changed on the server since the app last synced, without
/// keeping it (the app's own sync still takes it in), and sets this phone's
/// reminder alarms from the notes as they now stand.
Future<void> runReminderCheck() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await AppLogger.instance.init();

  const storage = FlutterSecureStorage();
  final saved = await readAllStorage(storage);
  final serverUrl = saved[StorageKeys.serverUrl];
  final userId = _userIdOf(saved[StorageKeys.userData]);
  if (serverUrl == null ||
      serverUrl.isEmpty ||
      userId == null ||
      saved[StorageKeys.accessToken] == null) {
    return;
  }

  final container = ProviderContainer();
  final db = AppDatabase(userId);
  try {
    final state = await db.select(db.syncState).getSingleOrNull();
    final cursor = state?.cursor;
    // The first download isn't done: there is nothing to start from.
    if (cursor == null || state!.isSweeping) return;

    final rows = await db.select(db.notes).get();
    final notes = {for (final row in rows) row.id: noteFromRow(row)};
    final unsentReminders = {
      for (final row in rows)
        if (!row.isReminderSynced) row.id,
    };

    final api = SyncApi(
      createApiDio(
        serverUrl,
        allowSelfSigned: saved[StorageKeys.allowSelfSignedCert] == 'true',
        storage: storage,
        session: container.read(sessionExpiredProvider.notifier),
      ),
    );
    final pulled = await _peekChanges(api, cursor, notes, unsentReminders);

    final listed = withReminderSlots(
      notes.values,
    ).where((note) => note.isActive && !note.isArchived).toList();

    await initializeNotifications();
    final gateway = LocalNotificationGateway(notificationsPlugin);
    await gateway.initialize();
    final now = DateTime.now();
    final l10n = deviceL10n();
    final desired = desiredReminders(listed, now: now, l10n: l10n);
    final pending = (await gateway.pendingIds()).toSet();
    final report = await applyReminders(gateway, desired, pending: pending);
    await ringMissedReminders(
      gateway,
      FileRungReminders(),
      listed,
      scheduled: desired,
      now: now,
      l10n: l10n,
    );
    AppLogger.instance.info(
      LogTags.reminders,
      'Background check: pulled=$pulled scheduled=${desired.length} '
      'cancelled=${report.cancelled} failed=${report.failed}',
    );
  } finally {
    await db.close();
    container.dispose();
  }
}

String? _userIdOf(String? userData) {
  if (userData == null) return null;
  try {
    return (jsonDecode(userData) as Map<String, dynamic>)['id'] as String?;
  } catch (_) {
    return null;
  }
}

/// Lays the server's changes over [notes]; returns how many it read.
Future<int> _peekChanges(
  SyncApi api,
  String cursor,
  Map<String, Note> notes,
  Set<String> unsentReminders,
) async {
  var next = cursor;
  var pulled = 0;
  for (var page = 0; page < _maxPages; page++) {
    final response = await api.sync(cursor: next);
    // Starting over is the app's to do.
    if (response.resetRequired) break;
    for (final entry in response.entries) {
      applyPeekedEntry(notes, entry, unsentReminders: unsentReminders);
    }
    pulled += response.entries.length;
    final nextCursor = response.nextCursor;
    if (!response.hasMore || nextCursor == null) break;
    next = nextCursor;
  }
  return pulled;
}

/// What [entry] changes in [notes], as far as reminders go. A reminder set
/// here and not yet sent stays, as it does in the sync.
@visibleForTesting
void applyPeekedEntry(
  Map<String, Note> notes,
  SyncEntry entry, {
  required Set<String> unsentReminders,
}) {
  final id = entry.entityId;
  final keepsReminder = unsentReminders.contains(id);
  switch (entry.entityType) {
    case SyncEntityType.note:
      final server = entry.note;
      if (entry.isRemove || server == null) {
        notes.remove(id);
        return;
      }
      final local = notes[id];
      final reminder = keepsReminder || !server.hasReminderField
          ? local?.reminder
          : _reminderOf(server.reminder);
      notes[id] = (local ?? Note(id: id, title: server.title)).copyWith(
        title: server.title,
        content: server.content,
        isArchived: server.isArchived,
        state: NoteState.fromString(server.state),
        lock: server.hasLockField
            ? NoteLock.fromString(server.lock)
            : local?.lock,
        reminder: reminder,
      );
    case SyncEntityType.reminder:
      final local = notes[id];
      if (local == null || keepsReminder) return;
      notes[id] = local.copyWith(
        reminder: entry.isRemove ? null : _reminderOf(entry.reminder),
      );
    default:
      return;
  }
}

NoteReminder? _reminderOf(SyncServerReminder? reminder) => reminder == null
    ? null
    : NoteReminder(
        remindAt: reminder.remindAt,
        recurrence: reminder.recurrence,
        version: reminder.version,
      );

/// Gives each reminder this phone has no notification id for yet one above
/// those taken. The app's sync gives it its own later, and the next pass
/// moves the alarm over.
@visibleForTesting
List<Note> withReminderSlots(Iterable<Note> notes) {
  var highest = notes.fold<int>(
    0,
    (most, note) => max(most, note.reminderSlot ?? 0),
  );
  return [
    for (final note in notes)
      if (note.reminder != null && note.reminderSlot == null)
        note.copyWith(reminderSlot: ++highest)
      else
        note,
  ];
}
