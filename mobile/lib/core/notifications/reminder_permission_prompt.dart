import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import 'reminder_permissions.dart';

/// What prompted the ask.
enum ReminderPermissionTrigger {
  /// The user just set a reminder on this device.
  userSet,

  /// A reminder reached this device from another one.
  synced,
}

/// Walks the device through whatever it still needs before a reminder rings:
/// notifications first, then a one-time offer of exact alarms.
Future<void> ensureReminderPermissions(
  BuildContext context,
  WidgetRef ref, {
  required ReminderPermissionTrigger trigger,
}) async {
  final controller = ref.read(reminderPermissionsControllerProvider.notifier);
  controller.promptedThisRun = true;
  var permissions = await controller.refresh();

  if (!permissions.canNotify) {
    if (trigger == ReminderPermissionTrigger.synced) {
      if (!context.mounted) return;
      final proceed = await ConfirmDialog.show(
        context: context,
        icon: LucideIcons.bellRing,
        title: 'Remind you on this device?',
        message:
            'Anchor needs permission to notify you before reminders can '
            'arrive on this device.',
        cancelText: 'Not now',
        confirmText: 'Continue',
      );
      if (proceed != true) return;
    }

    if (!await controller.requestNotifications()) {
      if (context.mounted) {
        AppSnackbar.showWarning(
          context,
          message: 'Turn on notifications in system settings',
        );
      }
      return;
    }
    permissions = await controller.refresh();
  }

  if (!permissions.exactMatters || permissions.canBeExact) return;
  if (await controller.hasOfferedExact()) return;
  // Declining counts as an answer.
  await controller.markExactOffered();

  if (!context.mounted) return;
  final open = await ConfirmDialog.show(
    context: context,
    icon: LucideIcons.alarmClock,
    title: 'Remind you at the exact minute?',
    message:
        'Android may delay reminders to save battery. '
        'Exact alarms arrive on time.',
    cancelText: 'Not now',
    confirmText: 'Open settings',
  );
  if (open == true) await controller.openExactSettings();
}
