import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../l10n/l10n.dart';
import '../motion/haptics.dart';
import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'global_rect_of.dart';
import 'pressable.dart';

class AnchorMenuItem<T> {
  const AnchorMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.checked = false,
    this.isDanger = false,
  });

  final T value;
  final IconData icon;
  final String label;
  final bool checked;
  final bool isDanger;
}

/// A null item draws a line.
Future<T?> showAnchorMenu<T>(
  BuildContext anchor, {
  required List<AnchorMenuItem<T>?> items,
  String? semanticLabel,
}) {
  Haptics.light();
  final navigator = Navigator.of(anchor, rootNavigator: true);
  return navigator.push(
    _MenuRoute<T>(
      anchor: globalRectOf(anchor)!,
      items: items,
      semanticLabel: semanticLabel ?? anchor.l10n.commonMenu,
      closeLabel: anchor.l10n.commonCloseMenu,
      capturedThemes: InheritedTheme.capture(
        from: anchor,
        to: navigator.context,
      ),
    ),
  );
}

class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({
    required this.anchor,
    required this.items,
    required this.semanticLabel,
    required this.closeLabel,
    required this.capturedThemes,
  });

  final Rect anchor;
  final List<AnchorMenuItem<T>?> items;
  final String semanticLabel;
  final String closeLabel;
  final CapturedThemes capturedThemes;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => closeLabel;

  @override
  Duration get transitionDuration => Spring.snappy.duration;

  @override
  Duration get reverseTransitionDuration => AnchorTokens.motionDurationExit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final guessHeight =
        items.length * AnchorTokens.sizeControlMedium +
        context.density.space8 * 2;
    final fromLeft = anchor.center.dx < size.width / 2;
    final below =
        anchor.bottom + 6 + guessHeight <= size.height - padding.bottom - 40;
    final reduce = context.isMotionReduced;
    return capturedThemes.wrap(
      CustomSingleChildLayout(
        delegate: _MenuLayout(
          anchor: anchor,
          fromLeft: fromLeft,
          below: below,
          padding: padding,
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = animation.value;
            final scale = reduce
                ? 1.0
                : 0.9 + 0.1 * Spring.snappy.curve.transform(progress);
            return Opacity(
              opacity: AnchorTokens.motionEaseStandard.transform(
                math.min(1, progress * 2),
              ),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment(fromLeft ? -1 : 1, below ? -1 : 1),
                child: child,
              ),
            );
          },
          child: _Menu<T>(items: items, semanticLabel: semanticLabel),
        ),
      ),
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({
    required this.anchor,
    required this.fromLeft,
    required this.below,
    required this.padding,
  });

  final Rect anchor;
  final bool fromLeft;
  final bool below;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: 210, // off-scale: a menu's narrowest
        maxWidth: constraints.maxWidth - 24,
        maxHeight: constraints.maxHeight - padding.vertical - 24,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (fromLeft ? anchor.left : anchor.right - childSize.width)
        .clamp(12.0, math.max(12.0, size.width - childSize.width - 12))
        .toDouble();
    final y = below
        ? anchor.bottom + 6
        : math.max(padding.top + 12, anchor.top - childSize.height - 6);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.anchor != anchor || old.fromLeft != fromLeft || old.below != below;
}

class _Menu<T> extends StatelessWidget {
  const _Menu({required this.items, required this.semanticLabel});

  final List<AnchorMenuItem<T>?> items;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: IntrinsicWidth(
          child: MenuPanel(
            verticalPadding: context.density.space8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  if (item == null)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: colors.appBorder.withValues(alpha: 0.8),
                    )
                  else
                    MenuRow(
                      icon: item.icon,
                      label: item.label,
                      isChecked: item.checked,
                      isDanger: item.isDanger,
                      onPressed: () {
                        Haptics.selection();
                        Navigator.of(context).pop(item.value);
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    required this.child,
    this.width,
    this.maxHeight,
    this.verticalPadding = padding,
  });

  static const double padding = AnchorTokens.space8;

  final Widget child;
  final double? width;
  final double? maxHeight;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Container(
      width: width,
      constraints: maxHeight == null
          ? null
          : BoxConstraints(maxHeight: maxHeight!),
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: colors.appSurface,
        borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
        boxShadow: colors.shadowMenu,
      ),
      child: child,
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isChecked = false,
    this.isDanger = false,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isChecked;
  final bool isDanger;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Pressable(
      style: PressStyle.menuItem,
      onTap: onPressed,
      semanticLabel: label,
      selected: isChecked || isHighlighted,
      tintRadius: BorderRadius.circular(AnchorTokens.radiusLg),
      child: Container(
        height: AnchorTokens.sizeControlMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? colors.appText.withValues(alpha: 0.07) : null,
          borderRadius: BorderRadius.circular(AnchorTokens.radiusLg),
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(
              icon,
              size: AnchorTokens.sizeIconMedium,
              color: isDanger ? colors.statusDanger : colors.appMuted,
            ),
            Expanded(
              child: Text(
                label,
                style: AppTypography.row.copyWith(
                  color: isDanger ? colors.statusDanger : colors.appText,
                ),
              ),
            ),
            if (isChecked)
              Icon(
                LucideIcons600.check,
                size: AnchorTokens.sizeIconMedium,
                color: colors.accentStrong,
              ),
          ],
        ),
      ),
    );
  }
}
