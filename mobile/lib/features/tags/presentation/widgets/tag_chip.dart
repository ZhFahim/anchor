import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool selected;
  final bool showDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.showDelete = false,
    this.onTap,
    this.onDelete,
  });

  Color _getTagColor(BuildContext context) {
    return parseTagColor(
      tag.color,
      fallback: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTagColor(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            left: 12,
            right: showDelete ? 4 : 12,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.hash, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                tag.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (showDelete) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(LucideIcons.x, size: 14, color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
