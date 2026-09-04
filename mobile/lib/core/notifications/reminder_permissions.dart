import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/settings/presentation/controllers/editor_preferences_controller.dart';
import 'notification_gateway.dart';

part 'reminder_permissions.g.dart';

/// What this device is allowed to do with a reminder right now.
@immutable
class ReminderPermissions {
  const ReminderPermissions({
    required this.canNotify,
    required this.canBeExact,
    required this.exactMatters,
  });

  /// The OS will post what we schedule.
  final bool canNotify;

  /// Reminders land on the minute rather than in the next batch.
  final bool canBeExact;

  /// Only Android gates exact timing; elsewhere it is always on.
  final bool exactMatters;

  /// Whether a reminder set now would ring, and ring when it says it will.
  bool get ringsOnTime => canNotify && (canBeExact || !exactMatters);

  @override
  bool operator ==(Object other) =>
      other is ReminderPermissions &&
      other.canNotify == canNotify &&
      other.canBeExact == canBeExact &&
      other.exactMatters == exactMatters;

  @override
  int get hashCode => Object.hash(canNotify, canBeExact, exactMatters);
}

/// Reads and asks for the grants a reminder needs, re-reading on resume.
@Riverpod(keepAlive: true)
class ReminderPermissionsController extends _$ReminderPermissionsController {
  AppLifecycleListener? _lifecycle;

  /// Whether the ask flow has already run this app run.
  bool promptedThisRun = false;

  @override
  Future<ReminderPermissions> build() {
    _lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    return _read();
  }

  Future<ReminderPermissions> _read() async {
    final gateway = ref.read(notificationGatewayProvider);
    return ReminderPermissions(
      canNotify: await gateway.hasPermission(),
      canBeExact: await gateway.canScheduleExact(),
      exactMatters: gateway.gatesExactAlarms,
    );
  }

  Future<ReminderPermissions> refresh() async {
    final permissions = await _read();
    state = AsyncData(permissions);
    return permissions;
  }

  /// The system dialog only appears the first time; later calls return the
  /// standing answer.
  Future<bool> requestNotifications() async {
    final granted = await ref
        .read(notificationGatewayProvider)
        .requestPermission();
    await refresh();
    return granted;
  }

  /// Opens Android's alarms screen, returning when it opens rather than when
  /// the user decides.
  Future<void> openExactSettings() =>
      ref.read(notificationGatewayProvider).requestExactPermission();

  Future<bool> hasOfferedExact() =>
      ref.read(preferencesRepositoryProvider).getExactAlarmsOffered();

  Future<void> markExactOffered() =>
      ref.read(preferencesRepositoryProvider).setExactAlarmsOffered(true);
}
