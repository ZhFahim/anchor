import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Global snackbar utility for consistent styling across the app
class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(
    BuildContext context, {
    required String message,
    IconData icon = LucideIcons.checkCircle,
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // Success color: green with theme-aware tinting
    final successColor = theme.brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);

    messenger.showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          icon: icon,
          iconColor: successColor,
          message: message,
          theme: theme,
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    IconData icon = LucideIcons.alertCircle,
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // Error color: red with theme-aware tinting
    final errorColor = theme.brightness == Brightness.dark
        ? const Color(0xFFEF5350)
        : const Color(0xFFC62828);

    messenger.showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          icon: icon,
          iconColor: errorColor,
          message: message,
          theme: theme,
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    IconData icon = LucideIcons.info,
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          icon: icon,
          iconColor: theme.colorScheme.primary,
          message: message,
          theme: theme,
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    IconData icon = LucideIcons.alertTriangle,
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // Warning color: orange with theme-aware tinting
    final warningColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFF9800)
        : const Color(0xFFE65100);

    messenger.showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          icon: icon,
          iconColor: warningColor,
          message: message,
          theme: theme,
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _SnackbarContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final ThemeData theme;

  const _SnackbarContent({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon container with subtle background
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        // Message text
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dismiss button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
