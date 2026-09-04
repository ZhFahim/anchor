import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';
import '../theme/tokens/app_opacity.dart';
import '../theme/tokens/app_radius.dart';
import 'app_icon_chip.dart';

/// The grab bar at the top of a modal sheet.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  static const double _width = 40;
  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: context.dims.sm),
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: AppOpacity.activeFill),
          borderRadius: AppRadius.handleBorder,
        ),
      ),
    );
  }
}

/// Shared chrome for modal bottom sheets: gradient surface, rounded top,
/// drag handle, and an optional icon/title header.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.icon,
    this.iconColor,
    this.title,
    this.subtitle,
    this.trailing,
    this.showDone = false,
    this.contentPadding = EdgeInsets.zero,
    this.maxHeightFactor,
    this.avoidKeyboard = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    required this.child,
  });

  final IconData? icon;

  /// Accent for the header icon chip; defaults to the primary color.
  final Color? iconColor;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  /// Shows a tonal "Done" button that pops the sheet.
  final bool showDone;
  final EdgeInsetsGeometry contentPadding;

  /// Caps the sheet at a fraction of screen height.
  final double? maxHeightFactor;

  /// Lifts the sheet above the keyboard (sheets with text input).
  final bool avoidKeyboard;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget child;

  static const double _titleSize = 20;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.colorTokens;
    final hasHeader = title != null || icon != null;

    Widget sheet = Container(
      constraints: maxHeightFactor != null
          ? BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor!,
            )
          : null,
      decoration: BoxDecoration(
        gradient: tokens.sheetGradient,
        borderRadius: AppRadius.sheetTopBorder,
        boxShadow: [tokens.sheetShadow],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            const SheetDragHandle(),
            if (hasHeader) _buildHeader(theme, context),
            Flexible(
              child: Padding(padding: contentPadding, child: child),
            ),
          ],
        ),
      ),
    );

    if (avoidKeyboard) {
      sheet = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: sheet,
      );
    }
    return sheet;
  }

  Widget _buildHeader(ThemeData theme, BuildContext context) {
    final accent = iconColor ?? theme.colorScheme.primary;
    final hasTrailing = trailing != null || showDone;
    final dims = context.dims;
    final headerPadding = dims.sheetHeaderPadding;

    return Padding(
      padding: hasTrailing
          ? headerPadding.copyWith(right: dims.md)
          : headerPadding,
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconChip(icon: icon!, color: accent),
            SizedBox(width: dims.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: _titleSize,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: AppOpacity.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showDone)
            const SheetDoneButton(),
        ],
      ),
    );
  }
}

/// Tonal "Done" button that dismisses the sheet it sits in.
class SheetDoneButton extends StatelessWidget {
  const SheetDoneButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => Navigator.pop(context),
      child: const Text('Done'),
    );
  }
}

/// Cancel/confirm button pair used at the bottom of action sheets.
class SheetActionButtons extends StatelessWidget {
  const SheetActionButtons({
    super.key,
    this.cancelText = 'Cancel',
    required this.confirmText,
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.confirmColor,
  });

  /// Null drops the cancel button, leaving the confirm button full width.
  final String? cancelText;

  final String confirmText;

  /// Null greys the confirm button out.
  final VoidCallback? onConfirm;

  /// Defaults to popping the route.
  final VoidCallback? onCancel;

  /// Shorthand for a confirm button in the error color.
  final bool isDestructive;

  /// Overrides the confirm button's background; the label color follows.
  final Color? confirmColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor =
        this.confirmColor ?? (isDestructive ? theme.colorScheme.error : null);

    return Row(
      children: [
        if (cancelText != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              child: Text(cancelText!),
            ),
          ),
          SizedBox(width: context.dims.sm),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onConfirm,
            style: confirmColor == null
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: confirmColor,
                    // Keep the label legible on any confirm color.
                    foregroundColor: confirmColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
            child: Text(confirmText),
          ),
        ),
      ],
    );
  }
}
