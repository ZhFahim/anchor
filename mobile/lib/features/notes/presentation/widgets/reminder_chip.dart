import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_opacity.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../domain/note.dart';
import '../../domain/reminder_schedule.dart';

/// The reminder on a note, as a compact chip.
class ReminderChip extends StatelessWidget {
  const ReminderChip({
    super.key,
    required this.reminder,
    this.onTap,
    this.compact = false,
  });

  final NoteReminder reminder;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;

    final now = DateTime.now();
    final next = nextOccurrence(reminder, from: now);
    final isOverdue = next == null;
    final color = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: AppOpacity.secondary);

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? LucideIcons.bellOff : LucideIcons.bell,
          size: compact ? AppIconSizes.xs : AppIconSizes.sm,
          color: color,
        ),
        SizedBox(width: dims.xxs),
        Flexible(
          child: Text(
            reminderChipLabel(reminder, now: now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.bodySmall)
                    ?.copyWith(color: color),
          ),
        ),
      ],
    );

    if (compact) return label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dims.xs,
            vertical: dims.xxs,
          ),
          child: label,
        ),
      ),
    );
  }
}

/// Short, human text for a reminder: the next time it rings, plus how often.
String reminderChipLabel(NoteReminder reminder, {required DateTime now}) {
  final next = nextOccurrence(reminder, from: now);
  final at = next ?? parseWallClock(reminder.remindAt);
  if (at == null) return 'Reminder';

  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  final when = sameDay
      ? DateFormat.jm().format(at)
      : at.year == now.year
      ? '${DateFormat.MMMd().format(at)}, ${DateFormat.jm().format(at)}'
      : '${DateFormat.yMMMd().format(at)}, ${DateFormat.jm().format(at)}';

  if (!reminder.recurrence.repeats) return when;
  return '$when · ${reminder.recurrence.label}';
}
