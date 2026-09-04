import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logging/app_logger.dart';
import 'notification_launch.dart';

part 'notification_gateway.g.dart';

const _tag = 'Notifications';

@Riverpod(keepAlive: true)
NotificationGateway notificationGateway(Ref ref) =>
    LocalNotificationGateway(notificationsPlugin);

/// One scheduled reminder, as the OS should hold it.
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

  /// Null for a one-off.
  final DateTimeComponents? repeat;
  final String payload;
}

/// The seam between the reminder scheduler and the plugin.
abstract class NotificationGateway {
  Future<void> initialize();
  Future<List<int>> pendingIds();
  Future<void> schedule(ScheduledNotification notification);
  Future<void> cancel(int id);
  Future<void> cancelAll();

  /// Whether the OS currently lets us post notifications.
  Future<bool> hasPermission();

  /// Asks for that grant; the system dialog only appears the first time.
  Future<bool> requestPermission();

  /// Whether this platform gates exact timing at all.
  bool get gatesExactAlarms;

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
    // Inexact unless the user has opted in and the grant is still in place.
    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          channelDescription: 'Reminders you set on your notes',
          importance: Importance.high,
          priority: Priority.high,
          // Android masks the icon to alpha, so this is a flat vector.
          icon: 'ic_stat_reminder',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: mode,
      matchDateTimeComponents: notification.repeat,
      payload: notification.payload,
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
        _tag,
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
        _tag,
        'Notification permission request failed',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  bool get gatesExactAlarms => Platform.isAndroid;

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
    // Returns when the settings screen opens, not when the user decides.
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (error, stack) {
      AppLogger.instance.error(
        _tag,
        'Exact alarm request failed',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

bool _timeZonesReady = false;

/// Loads the timezone database and points `tz.local` at the device's zone.
///
/// Re-run on every resume, in case the device has moved zone.
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
    AppLogger.instance.warn(_tag, 'Falling back to UTC: $error');
  }
}
