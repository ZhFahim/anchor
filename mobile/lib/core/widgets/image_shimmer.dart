import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for image loading states.
/// Adapts to theme for cards/grids, or use [dark] for lightbox/overlays.
class ImageShimmer extends StatelessWidget {
  const ImageShimmer({super.key, this.dark = false});

  /// Use [dark] on dark backgrounds (e.g. lightbox overlay).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (base, highlight) = switch ((dark, isDark)) {
      (true, _) => (
        Colors.white.withValues(alpha: 0.06),
        Colors.white.withValues(alpha: 0.14),
      ),
      (false, false) => (
        const Color(0xFFE5E9EE), // Soft cool grey
        const Color(0xFFF2F4F8), // Lighter sweep
      ),
      (false, true) => (
        const Color(0xFF3A3E4A), // Elevated dark surface
        const Color(0xFF484D5A), // Subtle lift
      ),
    };

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(color: base),
    );
  }
}
