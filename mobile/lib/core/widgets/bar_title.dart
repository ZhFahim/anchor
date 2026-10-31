import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:lucide_icons_flutter/lucide_icons_500.dart';

import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'cap_height_text.dart';
import 'pressable.dart';

const double _lineGap = 8;

Widget _fitTitle({
  required BuildContext context,
  required double bar,
  required TextStyle title,
  TextStyle? line,
  required Widget child,
}) {
  double capsOf(TextStyle style) =>
      AppTypography.capHeightOf(style.fontFamily) * style.fontSize!;
  final gap = line == null ? 0.0 : _lineGap;
  final caps = capsOf(title) + (line == null ? 0.0 : capsOf(line));
  return MediaQuery.withClampedTextScaling(
    maxScaleFactor: (bar - gap) / caps,
    child: child,
  );
}

class BarTitle extends StatelessWidget {
  const BarTitle(
    this.title, {
    super.key,
    this.line,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.isCentered,
    this.style,
  });

  final String title;

  final Widget? line;
  final Widget? leading;
  final Widget? trailing;

  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Null: centered on iPhone, at the start on Android.
  final bool? isCentered;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final style =
        this.style ?? AppTypography.navTitle.copyWith(color: colors.appText);
    final centered = isCentered ?? context.isCupertino;
    Widget name = CapHeightText(title, style: style);
    if (leading != null || trailing != null) {
      name = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leading,
          Flexible(child: name),
          ?trailing,
        ],
      );
    }
    if (onTap != null) {
      name = Pressable(
        style: PressStyle.plain,
        onTap: onTap,
        semanticLabel: semanticLabel ?? title,
        minSize: const Size(0, AnchorTokens.sizeTargetTouch),
        child: name,
      );
    }
    final block = line == null
        ? name
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              name,
              const SizedBox(height: _lineGap),
              line!,
            ],
          );
    return _fitTitle(
      context: context,
      bar: context.density.bar,
      title: style,
      line: line == null ? null : AppTypography.footnote,
      child: Semantics(header: true, child: block),
    );
  }
}

class BarTitleLine extends StatelessWidget {
  const BarTitleLine(this.text, {super.key, this.leading, this.color});

  final String text;
  final Widget? leading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.footnote.copyWith(
      color: color ?? context.anchor.appMuted,
    );
    final words = CapHeightText(text, style: style);
    if (leading == null) return words;
    return SizedBox(
      height: CapHeightText.capHeightOf(context, style),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          OverflowBox(
            maxHeight: double.infinity,
            fit: OverflowBoxFit.deferToChild,
            child: leading,
          ),
          Flexible(child: words),
        ],
      ),
    );
  }
}

/// Also covers the status bar.
class LargeBarTitle extends StatelessWidget {
  const LargeBarTitle(
    this.title, {
    super.key,
    required this.line,
    required this.onTap,
    required this.semanticLabel,
    this.leading,
  });

  final String title;
  final Widget? line;
  final VoidCallback onTap;
  final String semanticLabel;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final style = AppTypography.largeTitle.copyWith(color: colors.appText);
    return _fitTitle(
      context: context,
      bar: context.density.largeBar,
      title: style,
      line: AppTypography.footnote,
      child: Builder(
        builder: (context) {
          final top = MediaQuery.paddingOf(context).top;
          final bar = context.density.largeBar;
          final titleCaps = CapHeightText.capHeightOf(context, style);
          final lineCaps = CapHeightText.capHeightOf(
            context,
            AppTypography.footnote,
          );
          final lineBlock = _lineGap + lineCaps;
          final blockTop =
              top + (bar - titleCaps - (line == null ? 0 : lineBlock)) / 2;
          final lineTop =
              top + (bar - titleCaps - lineBlock) / 2 + titleCaps + _lineGap;
          final buttonTop =
              blockTop + (titleCaps - AnchorTokens.sizeTargetTouch) / 2;
          return Semantics(
            header: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: context.motion(AnchorTokens.motionDurationMove),
                  curve: AnchorTokens.motionEaseStandard,
                  left: 0,
                  right: 0,
                  top: buttonTop,
                  height: AnchorTokens.sizeTargetTouch,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      style: PressStyle.plain,
                      onTap: onTap,
                      semanticLabel: semanticLabel,
                      minSize: const Size(0, AnchorTokens.sizeTargetTouch),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ?leading,
                          Flexible(child: CapHeightText(title, style: style)),
                          const SizedBox(width: 8),
                          const BarTitleChevron(),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: lineTop,
                  height: lineCaps,
                  child: AnimatedSwitcher(
                    duration: context.motion(AnchorTokens.motionDurationFade),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      clipBehavior: Clip.none,
                      children: [...previous, ?current],
                    ),
                    child: line ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BarTitleChevron extends StatelessWidget {
  const BarTitleChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Container(
      width: AnchorTokens.sizeIconLarge,
      height: AnchorTokens.sizeIconLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.appText.withValues(alpha: 0.07),
      ),
      child: Icon(
        LucideIcons500.chevronDown,
        size: AnchorTokens.sizeIconSmall,
        color: colors.appText,
      ),
    );
  }
}
