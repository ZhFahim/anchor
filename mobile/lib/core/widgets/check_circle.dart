import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../motion/springs.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';

/// A null [value] draws a dash for "on some".
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.value,
    this.background,
    this.ringColor,
    this.hasShadow = false,
  });

  final bool? value;

  /// Fills the empty ring and colors the check.
  final Color? background;

  final Color? ringColor;

  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final isOn = value != false;
    return AnimatedContainer(
      duration: context.motion(AnchorTokens.motionDurationFade),
      width: AnchorTokens.sizeIconLarge,
      height: AnchorTokens.sizeIconLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn ? colors.accentStrong : background,
        border: isOn
            ? null
            : Border.all(color: ringColor ?? colors.appMuted, width: 1.5),
        boxShadow: hasShadow ? colors.shadowKnob : null,
      ),
      child: AnimatedScale(
        scale: isOn ? 1 : 0.4,
        duration: context.motion(Spring.pop.duration),
        curve: Spring.pop.curve,
        child: AnimatedOpacity(
          opacity: isOn ? 1 : 0,
          duration: context.motion(AnchorTokens.motionDurationHover),
          child: Icon(
            value == null ? LucideIcons600.minus : LucideIcons600.check,
            size: AnchorTokens.sizeIconSmall,
            color: background ?? colors.checkMark,
          ),
        ),
      ),
    );
  }
}
