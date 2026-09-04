import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/app_routes.dart';

/// The one plugin instance the app uses.
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Taps that arrive while the app is running.
final StreamController<String> notificationTaps =
    StreamController<String>.broadcast();

/// Set by [initializeNotifications] when the app was launched by a tap, and
/// read once by `initializeApp` to pick the app's opening route.
String? pendingNotificationNoteId;

/// The route a tapped reminder should open, or null if the payload is not one.
///
/// Shares the widget note route: the editor opens as the only page on the
/// stack, so back leaves the app.
String? notificationRouteForPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  return '/widget/note/$payload';
}

/// Wires up the plugin and reports the route a cold-start tap asked for.
///
/// Safe to call before the first frame; does not touch the timezone database.
Future<String?> initializeNotifications() async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('ic_stat_reminder'),
    iOS: DarwinInitializationSettings(
      // Permission is asked for on first save, not on first launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  await notificationsPlugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (response) {
      final noteId = response.payload;
      if (noteId != null && noteId.isNotEmpty) {
        notificationTaps.add(noteId);
      }
    },
  );

  final launch = await notificationsPlugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    pendingNotificationNoteId = launch?.notificationResponse?.payload;
  }
  return notificationRouteForPayload(pendingNotificationNoteId);
}

String get remindersHomeRoute => AppRoutes.home;
