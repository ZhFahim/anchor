import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';

import '../motion/haptics.dart';
import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'pressable.dart';
import 'pretty_text.dart';
import 'switch_row.dart';

class SheetSurface extends InheritedWidget {
  const SheetSurface({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetSurface>() != null;

  @override
  bool updateShouldNotify(SheetSurface oldWidget) => false;
}

class GroupedList extends StatelessWidget {
  const GroupedList({super.key, required this.children, this.semanticLabel});

  final List<Widget> children;
  final String? semanticLabel;

  static bool _isRow(Widget child) =>
      child is GroupedListTile ||
      child is SwitchRow ||
      child is StackedListTile ||
      child is GroupedListRow;

  static Color fillOf(BuildContext context) {
    final colors = context.anchor;
    return SheetSurface.of(context)
        ? Color.alphaBlend(
            colors.appText.withValues(alpha: context.isDark ? 0.05 : 0.045),
            colors.appSurface,
          )
        : colors.appSurface;
  }

  static BoxDecoration decorationOf(BuildContext context) => BoxDecoration(
    color: fillOf(context),
    borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
    boxShadow: SheetSurface.of(context) ? null : context.anchor.shadowXs,
  );

  /// [row] with the line between it and the row above drawn over its top,
  /// starting at [start].
  static Widget lineAbove(
    BuildContext context,
    Widget row, {
    double start = GroupedListTile.inset,
  }) => Stack(
    children: [
      row,
      PositionedDirectional(
        top: 0,
        start: start,
        end: 0,
        child: Container(
          height: 1,
          color: context.anchor.appBorder.withValues(alpha: 0.8),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final row = children[i];
      if (i > 0 && _isRow(children[i - 1])) {
        final indent = switch (row) {
          GroupedListTile(icon: null, leading: null) ||
          SwitchRow(icon: null) ||
          StackedListTile() => GroupedListTile.inset,
          GroupedListTile(:final leadingWidth) =>
            GroupedListTile.inset + leadingWidth + AnchorTokens.space12,
          GroupedListRow(:final dividerStart) => dividerStart,
          _ => GroupedListTile.textStart,
        };
        rows.add(lineAbove(context, row, start: indent));
      } else {
        rows.add(row);
      }
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: decorationOf(context),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}

/// A row of a screen's own making in a [GroupedList], with the line above it
/// starting at [dividerStart].
abstract class GroupedListRow extends StatelessWidget {
  const GroupedListRow({super.key});

  double get dividerStart;
}

class GroupedListTile extends StatelessWidget {
  const GroupedListTile({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.leading,
    this.leadingWidth = AnchorTokens.sizeIconMedium,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.checked,
    this.isDanger = false,
    this.enabled = true,
    this.semanticLabel,
    this.maxLines,
    this.labelWeight,
  });

  final String label;
  final String? subtitle;
  final FontWeight? labelWeight;

  /// For the label and the subtitle each; null lets them wrap.
  final int? maxLines;
  final IconData? icon;

  /// Drawn in place of [icon].
  final Widget? leading;

  /// How wide [leading] is, so the line above the row starts at its text.
  final double leadingWidth;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  /// Non-null makes this a choice.
  final bool? checked;
  final bool isDanger;
  final bool enabled;
  final String? semanticLabel;

  static const double inset = AnchorTokens.space16;

  static const double textStart =
      inset + AnchorTokens.sizeIconMedium + AnchorTokens.space12;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final color = isDanger ? colors.statusDanger : colors.appText;
    final iconColor = isDanger
        ? colors.statusDanger
        : checked == true
        ? colors.accentStrong
        : colors.appMuted;
    final density = context.density;
    final body = ConstrainedBox(
      constraints: BoxConstraints(minHeight: density.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: inset),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, size: AnchorTokens.sizeIconMedium, color: iconColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: density.space12),
                child: _TileText(
                  label: label,
                  subtitle: subtitle,
                  maxLines: maxLines,
                  color: color,
                  labelWeight: labelWeight,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: AppTypography.secondary.tabular.copyWith(
                  color: colors.appMuted,
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (checked != null) ...[
              const SizedBox(width: 12),
              _CheckIcon(isOn: checked!),
            ],
            if (showChevron) ...[
              SizedBox(width: value != null ? 8 : 12),
              Icon(
                LucideIcons.chevronRight,
                size: AnchorTokens.sizeIconSmall,
                color: colors.appMuted.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
    final row = Opacity(
      opacity: enabled ? 1 : DisabledOpacity.row,
      child: body,
    );
    if (onTap == null) {
      return Semantics(label: semanticLabel, child: row);
    }
    return Pressable(
      style: PressStyle.row,
      onTap: enabled ? _tap : null,
      tintRadius: BorderRadius.zero,
      semanticLabel: semanticLabel,
      selected: checked,
      child: row,
    );
  }

  void _tap() {
    if (checked == false) Haptics.selection();
    onTap!();
  }
}

class StackedListTile extends StatelessWidget {
  const StackedListTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.child,
  });

  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: GroupedListTile.inset,
      vertical: context.density.space12,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _TileText(
          label: label,
          subtitle: subtitle,
          color: context.anchor.appText,
        ),
        child,
      ],
    ),
  );
}

class _TileText extends StatelessWidget {
  const _TileText({
    required this.label,
    required this.subtitle,
    required this.color,
    this.maxLines,
    this.labelWeight,
  });

  final String label;
  final String? subtitle;
  final Color color;
  final int? maxLines;
  final FontWeight? labelWeight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      PrettyText(
        label,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: AppTypography.row.copyWith(
          fontWeight: labelWeight,
          color: color,
        ),
      ),
      if (subtitle != null)
        PrettyText(
          subtitle!,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: AppTypography.secondary.copyWith(
            color: context.anchor.appMuted,
          ),
        ),
    ],
  );
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isOn ? 1 : 0.5,
      duration: context.motion(Spring.pop.duration),
      curve: Spring.pop.curve,
      child: AnimatedOpacity(
        opacity: isOn ? 1 : 0,
        duration: context.motion(AnchorTokens.motionDurationHover),
        child: Icon(
          LucideIcons500.check,
          size: AnchorTokens.sizeIconMedium,
          color: context.anchor.accentStrong,
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.label,
    required this.child,
    this.isBoxed = true,
  });

  final String label;
  final Widget child;

  /// False lines the label up with content that isn't in a box.
  final bool isBoxed;

  static double gapOf(BuildContext context) => context.density.space24;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: context.density.space8,
    children: [
      SectionHeader(label, padding: isBoxed ? null : EdgeInsets.zero),
      child,
    ],
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.text, {
    super.key,
    this.padding,
    this.icon,
    this.count,
    this.trailing,
  });

  final String text;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final style = AppTypography.label.copyWith(color: colors.appMuted);
    final label = Semantics(
      header: true,
      label: count == null ? null : '$text, $count',
      excludeSemantics: count != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: AnchorTokens.sizeIconSmall,
              color: colors.appMuted,
            ),
          Flexible(child: Text(text.toUpperCase(), style: style)),
          if (count != null)
            Text(
              '$count',
              style: style.tabular.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: GroupedListTile.inset),
      child: trailing == null
          ? Align(alignment: AlignmentDirectional.centerStart, child: label)
          : Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: label,
                  ),
                ),
                trailing!,
              ],
            ),
    );
  }
}

class SectionFooter extends StatelessWidget {
  const SectionFooter(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: GroupedListTile.inset),
      child: Text(
        text,
        style: AppTypography.secondary.copyWith(color: context.anchor.appMuted),
      ),
    );
  }
}
