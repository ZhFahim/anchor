import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../l10n/l10n.dart';
import '../presentation/notification_launch.dart';
import 'reminder_actions.dart';

part 'notification_gateway.g.dart';

@Riverpod(keepAlive: true)
NotificationGateway notificationGateway(Ref ref) =>
    LocalNotificationGateway(notificationsPlugin);

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.repeat,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;

  /// Local wall-clock time, resolved against the device's zone at schedule time.
  final DateTime at;
  final DateTimeComponents? repeat;
  final String payload;
}

abstract class NotificationGateway {
  Future<void> initialize();
  Future<List<int>> pendingIds();
  Future<void> schedule(ScheduledNotification notification);

  /// Rings [notification] now, whatever its time.
  Future<void> show(ScheduledNotification notification);
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  bool get requiresExactAlarmPermission;

  /// Android 14+ keeps exact alarms behind a separate grant.
  Future<bool> canScheduleExact();
  Future<void> requestExactPermission();
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'anchor_reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await initializeTimeZonesOnce();
    _initialized = true;
  }

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((request) => request.id).toList();
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    final at = tz.TZDateTime.from(notification.at, tz.local);
    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: at,
      notificationDetails: _details(),
      androidScheduleMode: mode,
      matchDateTimeComponents: notification.repeat,
      payload: notification.payload,
    );
  }

  @override
  Future<void> show(ScheduledNotification notification) => _plugin.show(
    id: notification.id,
    title: notification.title,
    body: notification.body,
    notificationDetails: _details(),
    payload: notification.payload,
  );

  NotificationDetails _details() {
    final l10n = deviceL10n();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        // Must be a flat vector: Android masks the icon to alpha.
        icon: 'ic_stat_reminder',
        color: AnchorTokens.colorBrandOrange,
        actions: [reminderDoneAction(l10n)],
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<bool> hasPermission() async {
    try {
      final android = await _android?.areNotificationsEnabled();
      final ios = (await _ios?.checkPermissions())?.isEnabled;
      return android ?? ios ?? true;
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.notifications,
        'Notification permission check failed',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = await _android?.requestNotificationsPermission();
      final ios = await _ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return android ?? ios ?? true;
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.notifications,
        'Notification permission request failed',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  bool get requiresExactAlarmPermission => Platform.isAndroid;

  @override
  Future<bool> canScheduleExact() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestExactPermission() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.notifications,
        'Exact alarm request failed',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

bool _timeZonesReady = false;

/// Loads the timezone database once; sets `tz.local` to the device's zone on
/// every call.
Future<void> initializeTimeZonesOnce() async {
  if (!_timeZonesReady) {
    tzdata.initializeTimeZones();
    _timeZonesReady = true;
  }
  await syncLocalTimeZone();
}

Future<void> syncLocalTimeZone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (error) {
    // An unknown IANA name throws; UTC is the fallback.
    AppLogger.instance.warn(
      LogTags.notifications,
      'Falling back to UTC: $error',
    );
  }
}
