import 'package:flutter/material.dart';

/// A reusable anchor icon widget with decorative container styling.
///
/// Displays the anchor icon from assets with a styled container background
/// featuring rotated layers and gradient effects.
class AnchorIcon extends StatelessWidget {
  /// The size of the container. The icon will be half this size.
  final double size;

  const AnchorIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = size / 2;
    final borderRadius = size / 4;
    final blurRadius = size / 9;
    final shadowOffset = size / 14;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                blurRadius: blurRadius,
                spreadRadius: 0,
                offset: Offset(0, shadowOffset),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/anchor_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
