import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NoteBackground extends StatelessWidget {
  final String? styleId;
  final Widget child;
  final BorderRadius? borderRadius;

  const NoteBackground({
    super.key,
    required this.styleId,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgData = NoteBackgroundStyle.getStyle(styleId, theme);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve base color
    Color backgroundColor;
    if (bgData != null) {
      backgroundColor = isDark ? bgData.darkColor : bgData.lightColor;
    } else {
      backgroundColor = theme.colorScheme.surface;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CustomPaint(
          painter: bgData?.painterBuilder?.call(
            isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Helper to get the main color for a note (e.g. for card background)
  /// without rendering the pattern.
  static Color resolveColor(BuildContext context, String? styleId) {
    final theme = Theme.of(context);
    final bgData = NoteBackgroundStyle.getStyle(styleId, theme);
    final isDark = theme.brightness == Brightness.dark;

    if (bgData != null) {
      return isDark ? bgData.darkColor : bgData.lightColor;
    }

    return theme.colorScheme.surface;
  }
}

class NoteBackgroundData {
  final String id;
  final Color lightColor;
  final Color darkColor;
  final CustomPainter Function(Color color)? painterBuilder;

  const NoteBackgroundData({
    required this.id,
    required this.lightColor,
    required this.darkColor,
    this.painterBuilder,
  });
}

class NoteBackgroundStyle {
  static const String none = 'none';

  // Solid Colors
  static const String colorRed = 'color_red';
  static const String colorOrange = 'color_orange';
  static const String colorYellow = 'color_yellow';
  static const String colorGreen = 'color_green';
  static const String colorTeal = 'color_teal';
  static const String colorBlue = 'color_blue';
  static const String colorDarkBlue = 'color_dark_blue';
  static const String colorPurple = 'color_purple';
  static const String colorPink = 'color_pink';
  static const String colorBrown = 'color_brown';

  // Patterns
  static const String patternDots = 'pattern_dots';
  static const String patternGrid = 'pattern_grid';
  static const String patternLines = 'pattern_lines';
  static const String patternWaves = 'pattern_waves';
  static const String patternGroceries = 'pattern_groceries';
  static const String patternMusic = 'pattern_music';
  static const String patternTravel = 'pattern_travel';
  static const String patternCode = 'pattern_code';

  static List<NoteBackgroundData> get styles => [
    // Solid Colors
    const NoteBackgroundData(
      id: colorRed,
      lightColor: Color(0xFFFFEBEE), // Soft pink/red
      darkColor: Color(0xFF331D21), // Softer dark red
    ),
    const NoteBackgroundData(
      id: colorOrange,
      lightColor: Color(0xFFFFF3E0), // Soft orange/peach
      darkColor: Color(0xFF332B1E), // Softer dark orange
    ),
    const NoteBackgroundData(
      id: colorYellow,
      lightColor: Color(0xFFFFF8E1), // Soft yellow
      darkColor: Color(0xFF332B1E), // Softer dark yellow
    ),
    const NoteBackgroundData(
      id: colorGreen,
      lightColor: Color(0xFFE8F5E9), // Soft green
      darkColor: Color(0xFF1B3022), // Softer dark green
    ),
    const NoteBackgroundData(
      id: colorTeal,
      lightColor: Color(0xFFE0F7FA), // Soft cyan/teal
      darkColor: Color(0xFF193135), // Softer dark cyan
    ),
    const NoteBackgroundData(
      id: colorBlue,
      lightColor: Color(0xFFE3F2FD), // Soft blue
      darkColor: Color(0xFF192A3A), // Softer dark blue
    ),
    const NoteBackgroundData(
      id: colorDarkBlue,
      lightColor: Color(0xFFE8EAF6), // Soft indigo
      darkColor: Color(0xFF1A1F3A), // Softer dark indigo
    ),
    const NoteBackgroundData(
      id: colorPurple,
      lightColor: Color(0xFFF3E5F5), // Soft purple
      darkColor: Color(0xFF2D1D31), // Softer dark purple
    ),
    const NoteBackgroundData(
      id: colorPink,
      lightColor: Color(0xFFFCE4EC), // Soft pink
      darkColor: Color(0xFF331D21), // Softer dark pink
    ),
    const NoteBackgroundData(
      id: colorBrown,
      lightColor: Color(0xFFEFEBE9), // Soft beige/brown
      darkColor: Color(0xFF2E1F1A), // Softer dark brown
    ),

    // Patterns
    NoteBackgroundData(
      id: patternDots,
      lightColor: const Color(0xFFF5F5F5),
      darkColor: const Color(0xFF1E1E1E), // Soft dark
      painterBuilder: (c) => DotsPainter(color: c),
    ),
    NoteBackgroundData(
      id: patternGrid,
      lightColor: const Color(0xFFFFF8E1),
      darkColor: const Color(0xFF332B1E), // Soft dark brown
      painterBuilder: (c) => GridPainter(color: c),
    ),
    NoteBackgroundData(
      id: patternLines,
      lightColor: const Color(0xFFE3F2FD),
      darkColor: const Color(0xFF192A3A), // Soft dark blue
      painterBuilder: (c) => LinesPainter(color: c),
    ),
    NoteBackgroundData(
      id: patternWaves,
      lightColor: const Color(0xFFE8F5E9),
      darkColor: const Color(0xFF1B3022), // Soft dark green
      painterBuilder: (c) => WavesPainter(color: c),
    ),
    NoteBackgroundData(
      id: patternGroceries,
      lightColor: const Color(0xFFFFEBEE), // Light Pink
      darkColor: const Color(0xFF331D21), // Soft dark pink
      painterBuilder: (c) =>
          IconPatternPainter(color: c, icon: LucideIcons.shoppingBag),
    ),
    NoteBackgroundData(
      id: patternMusic,
      lightColor: const Color(0xFFF3E5F5), // Light Purple
      darkColor: const Color(0xFF2D1D31), // Soft dark purple
      painterBuilder: (c) =>
          IconPatternPainter(color: c, icon: LucideIcons.music),
    ),
    NoteBackgroundData(
      id: patternTravel,
      lightColor: const Color(0xFFE0F7FA), // Light Cyan
      darkColor: const Color(0xFF193135), // Soft dark cyan
      painterBuilder: (c) =>
          IconPatternPainter(color: c, icon: LucideIcons.plane, rotation: 0.5),
    ),
    NoteBackgroundData(
      id: patternCode,
      lightColor: const Color(0xFFECEFF1), // Light Blue Grey
      darkColor: const Color(0xFF1E2325), // Soft dark blue grey
      painterBuilder: (c) =>
          IconPatternPainter(color: c, icon: LucideIcons.code),
    ),
  ];

  static NoteBackgroundData? getStyle(String? id, ThemeData theme) {
    if (id == null) return null;
    try {
      return styles.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Painters

class DotsPainter extends CustomPainter {
  final Color color;
  DotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 24.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LinesPainter extends CustomPainter {
  final Color color;
  LinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 24.0;

    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavesPainter extends CustomPainter {
  final Color color;
  WavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const spacing = 40.0;

    for (double y = 20; y < size.height; y += spacing) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 40) {
        path.quadraticBezierTo(x + 10, y - 10, x + 20, y);
        path.quadraticBezierTo(x + 30, y + 10, x + 40, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IconPatternPainter extends CustomPainter {
  final Color color;
  final IconData icon;
  final double rotation;

  IconPatternPainter({
    required this.color,
    required this.icon,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();

    const spacing = 60.0;

    for (double y = 20; y < size.height + 40; y += spacing) {
      for (double x = 20; x < size.width + 40; x += spacing) {
        final offsetX = (y / spacing).floor().isEven ? 0.0 : spacing / 2;

        canvas.save();
        canvas.translate(x + offsetX, y);
        if (rotation != 0) {
          canvas.rotate(rotation);
        }
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
