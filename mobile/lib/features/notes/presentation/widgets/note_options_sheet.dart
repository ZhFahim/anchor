import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_opacity.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

class NoteOptionsSheet extends StatelessWidget {
  final bool isReadOnly;
  final bool isNew;
  final bool isOwner;
  final bool isArchived;
  final VoidCallback onTagsTap;
  final VoidCallback onBackgroundTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onDeleteTap;

  /// Null hides the option, for notes that have no history to read.
  final VoidCallback? onHistoryTap;

  const NoteOptionsSheet({
    super.key,
    required this.isReadOnly,
    required this.isNew,
    required this.isOwner,
    required this.isArchived,
    required this.onTagsTap,
    required this.onBackgroundTap,
    required this.onAttachmentTap,
    required this.onArchiveTap,
    required this.onDeleteTap,
    this.onHistoryTap,
  });

  static const double _maxTileWidth = 104;

  /// Scaled by the user's text scale so long labels keep their two lines.
  static const double _minTileWidth = 76;

  static const int _minColumns = 2;
  static const int _maxColumns = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;

    final canManage = !isReadOnly && isOwner && !isNew;
    final options = <_OptionSpec>[
      if (!isReadOnly)
        _OptionSpec(icon: LucideIcons.tags, label: 'Tags', onTap: onTagsTap),
      if (!isReadOnly)
        _OptionSpec(
          icon: LucideIcons.palette,
          label: 'Background',
          onTap: onBackgroundTap,
        ),
      if (!isReadOnly)
        _OptionSpec(
          icon: LucideIcons.paperclip,
          label: 'Attachment',
          onTap: onAttachmentTap,
        ),
      if (onHistoryTap != null)
        _OptionSpec(
          icon: LucideIcons.history,
          label: 'History',
          onTap: onHistoryTap!,
        ),
      if (canManage) ...[
        _OptionSpec(
          icon: isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
          label: isArchived ? 'Unarchive' : 'Archive',
          onTap: onArchiveTap,
        ),
        _OptionSpec(
          icon: LucideIcons.trash2,
          label: 'Delete',
          onTap: onDeleteTap,
          isDestructive: true,
        ),
      ],
    ];

    return AppBottomSheet(
      icon: LucideIcons.moreHorizontal,
      title: 'More Options',
      subtitle: 'Customize and manage your note',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(dims.xl, 0, dims.xl, dims.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = dims.sm;
            final minTile = MediaQuery.textScalerOf(
              context,
            ).scale(_minTileWidth);
            final columns = _columnsFor(
              count: options.length,
              width: constraints.maxWidth,
              minTileWidth: minTile,
              spacing: spacing,
            );
            final tileWidth = math.min(
              (constraints.maxWidth - spacing * (columns - 1)) / columns,
              _maxTileWidth,
            );

            return Wrap(
              spacing: spacing,
              runSpacing: dims.lg,
              children: [
                for (final option in options)
                  SizedBox(
                    width: tileWidth,
                    child: _GridOptionTile(
                      option: option,
                      color: option.isDestructive
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _columnsFor({
    required int count,
    required double width,
    required double minTileWidth,
    required double spacing,
  }) {
    final fitting = ((width + spacing) / (minTileWidth + spacing))
        .floor()
        .clamp(_minColumns, _maxColumns);
    return math.max(math.min(count, fitting), 1);
  }
}

class _OptionSpec {
  const _OptionSpec({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class _GridOptionTile extends StatelessWidget {
  const _GridOptionTile({required this.option, this.color});

  final _OptionSpec option;

  /// Accent for a highlighted action; defaults to the neutral icon colour.
  final Color? color;

  static const double _minCircle = 52;
  static const double _maxCircle = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;
    final labelColor = color ?? theme.colorScheme.onSurface;
    final background = color == null
        ? theme.colorScheme.surfaceContainerHigh
        : color!.withValues(alpha: AppOpacity.subtleFill);

    return LayoutBuilder(
      builder: (context, constraints) {
        final circle = constraints.maxWidth.clamp(_minCircle, _maxCircle);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: background,
              shape: CircleBorder(
                side: BorderSide(
                  color: accent.withValues(alpha: AppOpacity.hairline),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  option.onTap();
                },
                highlightColor: accent.withValues(alpha: AppOpacity.activeFill),
                splashColor: accent.withValues(alpha: AppOpacity.activeFill),
                child: SizedBox(
                  width: circle,
                  height: circle,
                  child: Center(
                    child: Icon(
                      option.icon,
                      size: AppIconSizes.lg,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.dims.xs),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
