import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LinkAction { open, copy, edit, remove }

class LinkActionsSheet extends StatelessWidget {
  final String text;
  final String url;

  const LinkActionsSheet({super.key, required this.text, required this.url});

  static Future<LinkAction?> show(
    BuildContext context, {
    required String text,
    required String url,
  }) {
    return showModalBottomSheet<LinkAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinkActionsSheet(text: text, url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HandleBar(theme: theme),
          _Header(theme: theme, text: text, url: url),
          _Action(
            icon: LucideIcons.externalLink,
            label: 'Open',
            onTap: () => Navigator.pop(context, LinkAction.open),
          ),
          _Action(
            icon: LucideIcons.copy,
            label: 'Copy link',
            onTap: () => Navigator.pop(context, LinkAction.copy),
          ),
          _Action(
            icon: LucideIcons.pencil,
            label: 'Edit',
            onTap: () => Navigator.pop(context, LinkAction.edit),
          ),
          _Action(
            icon: LucideIcons.unlink,
            label: 'Remove',
            destructive: true,
            onTap: () => Navigator.pop(context, LinkAction.remove),
          ),
          SizedBox(height: safeBottom > 0 ? safeBottom + 8 : 16),
        ],
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  final ThemeData theme;
  const _HandleBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ThemeData theme;
  final String text;
  final String url;

  const _Header({required this.theme, required this.text, required this.url});

  @override
  Widget build(BuildContext context) {
    final title = text.trim().isEmpty ? url : text;
    final showSubtitle = url.isNotEmpty && url != title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.link,
              color: theme.colorScheme.tertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.85)),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
