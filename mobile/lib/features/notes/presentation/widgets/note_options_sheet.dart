import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NoteOptionsSheet extends StatelessWidget {
  final bool isReadOnly;
  final bool isNew;
  final bool isOwner;
  final bool isArchived;
  final VoidCallback onBackgroundTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onDeleteTap;

  const NoteOptionsSheet({
    super.key,
    required this.isReadOnly,
    required this.isNew,
    required this.isOwner,
    required this.isArchived,
    required this.onBackgroundTap,
    required this.onAttachmentTap,
    required this.onArchiveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
              : [Colors.white, const Color(0xFFF8F9FC)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.moreHorizontal,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More Options',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Customize and manage your note',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 20,
                  runSpacing: 24,
                  alignment: WrapAlignment.start,
                  children: [
                    if (!isReadOnly)
                      _GridOptionTile(
                        icon: LucideIcons.palette,
                        title: 'Background',
                        onTap: () {
                          Navigator.pop(context);
                          onBackgroundTap();
                        },
                      ),

                    if (!isReadOnly && !isNew)
                      _GridOptionTile(
                        icon: LucideIcons.paperclip,
                        title: 'Attachment',
                        onTap: () {
                          Navigator.pop(context);
                          onAttachmentTap();
                        },
                      ),

                    if (!isReadOnly && isOwner && !isNew) ...[
                      _GridOptionTile(
                        icon: isArchived
                            ? LucideIcons.archiveRestore
                            : LucideIcons.archive,
                        title: isArchived ? 'Unarchive' : 'Archive',
                        onTap: () {
                          Navigator.pop(context);
                          onArchiveTap();
                        },
                      ),
                      _GridOptionTile(
                        icon: LucideIcons.trash2,
                        title: 'Delete',
                        iconColor: theme.colorScheme.error,
                        textColor: theme.colorScheme.error,
                        backgroundColor: theme.colorScheme.error.withValues(
                          alpha: 0.1,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onDeleteTap();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _GridOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  const _GridOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurface;
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.surface;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: effectiveBgColor,
            shape: CircleBorder(
              side: BorderSide(
                color: effectiveIconColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              highlightColor: effectiveIconColor.withValues(alpha: 0.1),
              splashColor: effectiveIconColor.withValues(alpha: 0.1),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: Icon(icon, size: 24, color: effectiveIconColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
