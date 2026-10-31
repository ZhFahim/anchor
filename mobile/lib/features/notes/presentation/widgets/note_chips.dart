import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/expanded_hit_area.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';
import '../../../reminders/domain/reminder_times.dart';
import '../../../reminders/presentation/reminder_labels.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/tag_colors.dart';
import '../../domain/note.dart';
import 'note_surface.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    required this.appearance,
    this.isSmall = false,
    this.onRemove,
    this.onTap,
  });

  final Tag tag;
  final NoteAppearance appearance;
  final bool isSmall;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hash = tagColorsOf(context, tag.color).hash;
    final chip = _ChipShell(
      appearance: appearance,
      isSmall: isSmall,
      // The remove button's own padding makes up the rest of the edge.
      padding: onRemove == null
          ? null
          : const EdgeInsets.fromLTRB(9, 0, 4, 0), // off-scale: chip
      children: [
        Icon(
          isSmall ? LucideIcons600.hash : LucideIcons500.hash,
          size: isSmall ? 11 : 12, // off-scale: chip
          color: hash,
        ),
        Flexible(
          child: Text(
            tag.name,
            semanticsLabel: '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (isSmall
                        ? AppTypography.chip.withSize(
                            11.5, // off-scale: card chip
                          )
                        : AppTypography.chip)
                    .copyWith(color: context.anchor.appText),
          ),
        ),
        if (onRemove != null)
          ExpandedHitArea(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            // off-scale: a tap area the size of a small control
            child: Pressable(
              style: PressStyle.plain,
              onTap: onRemove,
              semanticLabel: context.l10n.tagRemoveNamed(tag.name),
              child: Padding(
                padding: const EdgeInsets.all(AnchorTokens.space4),
                child: Icon(
                  LucideIcons.x,
                  size: 12, // off-scale: chip
                  color: appearance.colors.muted,
                ),
              ),
            ),
          ),
      ],
    );
    if (onTap == null && onRemove != null) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: Semantics(
          label: context.l10n.tagSheetLabel(tag.name),
          child: chip,
        ),
      );
    }
    if (onTap == null) {
      return Semantics(
        label: context.l10n.tagSheetLabel(tag.name),
        child: ExcludeSemantics(child: chip),
      );
    }
    return Pressable(
      style: PressStyle.button,
      onTap: onTap,
      semanticLabel: context.l10n.tagSheetLabel(tag.name),
      child: chip,
    );
  }
}

class MoreChip extends StatelessWidget {
  const MoreChip({super.key, required this.count, required this.appearance});

  final int count;
  final NoteAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return _ChipShell(
      appearance: appearance,
      isSmall: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 7, // off-scale: card chip
      ),
      children: [
        Text(
          '+$count',
          style: AppTypography.chip
              .withSize(11.5) // off-scale: card chip
              .copyWith(color: appearance.colors.muted),
        ),
      ],
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.appearance,
    required this.isSmall,
    required this.children,
    this.padding,
    this.fill,
    this.hasBorder = true,
  });

  final NoteAppearance appearance;
  final bool isSmall;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final Color? fill;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isSmall
            ? AnchorTokens.sizeChipCard
            : AnchorTokens.sizeControlSmall,
      ),
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            isSmall ? 7 : 9, // off-scale: chip
            0,
            8,
            0,
          ),
      decoration: BoxDecoration(
        color: fill ?? appearance.colors.surface,
        borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
      ),
      foregroundDecoration: hasBorder
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
              border: Border.all(
                color: appearance.colors.border.withValues(alpha: 0.55),
              ),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: isSmall ? 4 : 5, // off-scale: chip
        children: children,
      ),
    );
  }
}

class ReminderChip extends StatelessWidget {
  const ReminderChip({
    super.key,
    required this.reminder,
    required this.appearance,
    this.isSmall = false,
    this.onTap,
  });

  final NoteReminder reminder;
  final NoteAppearance appearance;
  final bool isSmall;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final isOverdue = isReminderOverdue(reminder);
    final label = reminderChipLabel(reminder, context.l10n);
    final color = isOverdue ? colors.statusLate : colors.appText;
    final iconColor = isOverdue ? colors.statusLate : appearance.colors.muted;
    final fill = isOverdue
        ? Color.alphaBlend(
            colors.statusLate.withValues(
              alpha: AnchorTokens.blendLateChip / 100,
            ),
            appearance.colors.surface,
          )
        : null;
    final chip = _ChipShell(
      appearance: appearance,
      isSmall: isSmall,
      fill: fill,
      hasBorder: !isOverdue,
      children: [
        Icon(
          isOverdue
              ? LucideIcons.bellRing
              : reminder.recurrence.repeats
              ? LucideIcons.repeat
              : LucideIcons.bell,
          size: isSmall ? 11 : 12, // off-scale: chip
          color: iconColor,
        ),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (isSmall
                        ? AppTypography.chip.withSize(
                            11.5, // off-scale: card chip
                          )
                        : AppTypography.chip)
                    .copyWith(color: color),
          ),
        ),
      ],
    );
    final name = reminderSpokenLabel(reminder, context.l10n);
    if (onTap == null) {
      return Semantics(
        label: name,
        child: ExcludeSemantics(child: chip),
      );
    }
    return Pressable(
      style: PressStyle.button,
      onTap: onTap,
      semanticLabel: name,
      child: chip,
    );
  }
}
