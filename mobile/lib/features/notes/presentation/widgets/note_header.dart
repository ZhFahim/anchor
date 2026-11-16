import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/tags_controller.dart';
import '../../domain/note.dart';
import '../../domain/note_dates.dart';
import '../../domain/user_summary.dart';
import '../editor/line_kind.dart';
import '../note_labels.dart';
import 'note_chips.dart';
import 'note_surface.dart';

class NoteMetaLine extends StatelessWidget {
  const NoteMetaLine({
    super.key,
    required this.note,
    required this.appearance,
    required this.words,
    required this.sharedWith,
  });

  /// Null for a new note not saved yet.
  final Note? note;
  final NoteAppearance appearance;
  final ValueNotifier<int> words;
  final List<UserSummary>? sharedWith;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    final style = AppTypography.secondary.copyWith(
      color: appearance.colors.muted,
    );
    final dot = Text('·', style: style);
    final updatedAt = note == null ? DateTime.now() : note.updatedAt;
    final edited = updatedAt == null
        ? null
        : editedDayLabel(updatedAt, context.l10n);
    final sharedBy = note?.sharedBy;
    return ValueListenableBuilder<int>(
      valueListenable: words,
      builder: (context, count, _) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AnchorTokens.space8,
        runSpacing: AnchorTokens.space4,
        children: [
          if (note?.isArchived ?? false) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AnchorTokens.space4,
              children: [
                Icon(
                  LucideIcons.archive,
                  size: AnchorTokens.sizeIconSmall,
                  color: appearance.colors.muted,
                ),
                Flexible(
                  child: Text(
                    context.l10n.noteArchived,
                    style: style.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            dot,
          ],
          if (edited != null) ...[Text(edited, style: style), dot],
          Text(context.l10n.wordsCount(count), style: style),
          if (sharedBy != null) ...[
            dot,
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                PersonAvatar(
                  name: sharedBy.name,
                  imageUrl: sharedBy.profileImage,
                  size: PersonAvatar.inline,
                  ring: appearance.colors.bg,
                ),
                Flexible(
                  child: Text(
                    context.l10n.shareSharedBy(firstNameOf(sharedBy.name)),
                    style: style,
                  ),
                ),
              ],
            ),
          ] else if (note != null && note.isOwner && note.hasShares) ...[
            dot,
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (sharedWith case final people? when people.isNotEmpty) ...[
                  for (final person in people.take(3))
                    PersonAvatar(
                      name: person.name,
                      imageUrl: person.profileImage,
                      size: PersonAvatar.inline,
                      ring: appearance.colors.bg,
                    ),
                  Flexible(
                    child: Text(
                      context.l10n.shareSharedWithNames(
                        namesLabel([
                          for (final person in people) firstNameOf(person.name),
                        ], context.l10n),
                      ),
                      style: style,
                    ),
                  ),
                ] else ...[
                  Icon(
                    LucideIcons.users,
                    size: AnchorTokens.sizeIconSmall,
                    color: appearance.colors.muted,
                  ),
                  Flexible(
                    child: Text(
                      context.l10n.shareSharedWithCount(note.shareIds!.length),
                      style: style,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class NoteTagRow extends ConsumerWidget {
  const NoteTagRow({
    super.key,
    required this.tagIds,
    required this.reminder,
    required this.appearance,
    required this.readOnly,
    required this.onAdd,
    required this.onRemove,
    required this.onReminder,
  });

  final List<String> tagIds;
  final NoteReminder? reminder;
  final NoteAppearance appearance;
  final bool readOnly;
  final VoidCallback onAdd;
  final ValueChanged<Tag>? onRemove;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(tagsControllerProvider).value ?? const <Tag>[];
    final tags = tagsByName(tagIds, {for (final tag in all) tag.id: tag});
    final reminder = this.reminder;
    if (tags.isEmpty && readOnly) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final t in tags)
          TagChip(
            tag: t,
            appearance: appearance,
            onRemove: onRemove == null ? null : () => onRemove!(t),
          ),
        if (reminder != null && !readOnly)
          ReminderChip(
            reminder: reminder,
            appearance: appearance,
            onTap: onReminder,
          ),
        if (!readOnly)
          Pressable(
            style: PressStyle.barButton,
            onTap: onAdd,
            semanticLabel: context.l10n.tagAdd,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AnchorTokens.sizeControlSmall,
              ),
              // Alone on its row, it lines up with the title.
              padding: EdgeInsets.only(
                left: tags.isEmpty && reminder == null
                    ? 0
                    : AnchorTokens.space10, // off-scale: chip
                right: AnchorTokens.space10, // off-scale: chip
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AnchorTokens.space6, // off-scale: chip
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 14, // off-scale: chip
                    color: appearance.colors.muted,
                  ),
                  Text(
                    context.l10n.tagAdd,
                    style: AppTypography.chip.copyWith(
                      fontWeight: AnchorTokens.fontWeightRegular,
                      color: appearance.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyNoteActions extends StatelessWidget {
  const EmptyNoteActions({
    super.key,
    required this.appearance,
    required this.onChecklist,
    required this.onList,
    required this.onAdd,
  });

  final NoteAppearance appearance;
  final VoidCallback onChecklist;
  final VoidCallback onList;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    Widget actionButton(IconData icon, String label, VoidCallback onPressed) =>
        PillButton(
          icon: icon,
          label: label,
          kind: PillKind.outlined,
          colors: appearance.pillColors,
          onPressed: onPressed,
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        actionButton(
          LineKind.checklist.icon,
          context.l10n.lineChecklist,
          onChecklist,
        ),
        actionButton(LineKind.bullet.icon, context.l10n.starterList, onList),
        actionButton(
          LucideIcons.imagePlus,
          context.l10n.starterAttachment,
          onAdd,
        ),
      ],
    );
  }
}
