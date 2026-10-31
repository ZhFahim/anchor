// Generated from design/tokens by design/build. Do not edit by hand.
//
// One tile of each note pattern, in its own coordinates. Tile it with
// [AnchorPatterns.tileSize] and draw it in the note palette's pattern color.

// dart format off

import 'dart:math' as math;

import 'package:flutter/painting.dart';

abstract final class AnchorPatterns {
  static Size tileSize(String kind) => switch (kind) {
        'dots' => const Size(20, 20),
        'waves' => const Size(40, 40),
        'grid' || 'lines' => const Size(24, 24),
        _ => const Size(60, 120),
      };

  static void paintTile(Canvas canvas, String kind, Color color) {
    switch (kind) {
      case 'dots':
        canvas.drawCircle(const Offset(10, 10), 2, Paint()..color = color);
      case 'grid':
        final line = _stroke(color, 1);
        canvas.drawLine(const Offset(0.5, 0), const Offset(0.5, 24), line);
        canvas.drawLine(const Offset(0, 0.5), const Offset(24, 0.5), line);
      case 'lines':
        canvas.drawLine(const Offset(0, 23.5), const Offset(24, 23.5), _stroke(color, 1));
      case 'waves':
        canvas.drawPath(
          Path()
            ..moveTo(0, 20)
            ..quadraticBezierTo(10, 10, 20, 20)
            ..quadraticBezierTo(30, 30, 40, 20),
          _stroke(color, 2),
        );
      case 'icon:shopping-bag:0':
        _icons(canvas, _shoppingBag, 0.0, color);
      case 'icon:music:0':
        _icons(canvas, _music, 0.0, color);
      case 'icon:plane:28.6':
        _icons(canvas, _plane, 28.6, color);
      case 'icon:code:0':
        _icons(canvas, _code, 0.0, color);
    }
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Three icons per tile: one at (8, 8), two at y 68.
  static void _icons(Canvas canvas, Path icon, double rotation, Color color) {
    final paint = _stroke(color, 2);
    for (final at in const [Offset(8, 8), Offset(38, 68), Offset(-22, 68)]) {
      canvas
        ..save()
        ..translate(at.dx + 12, at.dy + 12)
        ..rotate(rotation * math.pi / 180)
        ..translate(-12, -12)
        ..drawPath(icon, paint)
        ..restore();
    }
  }

  static final Path _shoppingBag = Path()
    ..moveTo(16.0, 10.0)
    ..arcToPoint(Offset(8.0, 10.0), radius: Radius.elliptical(4.0, 4.0), rotation: 0.0, largeArc: false, clockwise: true)
    ..moveTo(3.103, 6.034)
    ..lineTo(20.897, 6.034)
    ..moveTo(3.4, 5.467)
    ..arcToPoint(Offset(3.0, 6.667), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(3.0, 20.0)
    ..arcToPoint(Offset(5.0, 22.0), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(19.0, 22.0)
    ..arcToPoint(Offset(21.0, 20.0), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(21.0, 6.667)
    ..arcToPoint(Offset(20.6, 5.467), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(18.6, 2.8)
    ..arcToPoint(Offset(17.0, 2.0), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(7.0, 2.0)
    ..arcToPoint(Offset(5.4, 2.8), radius: Radius.elliptical(2.0, 2.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..close();

  static final Path _music = Path()
    ..moveTo(21.0, 16.0)
    ..lineTo(21.0, 3.0)
    ..arcToPoint(Offset(19.72, 2.04), radius: Radius.elliptical(1.0, 1.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(9.72, 4.957)
    ..arcToPoint(Offset(9, 5.917), radius: Radius.elliptical(1.0, 1.0), rotation: 0.0, largeArc: false, clockwise: false)
    ..lineTo(9, 19.0)
    ..addOval(Rect.fromCircle(center: Offset(18.0, 16.0), radius: 3.0))
    ..addOval(Rect.fromCircle(center: Offset(6.0, 19.0), radius: 3.0));

  static final Path _plane = Path()
    ..moveTo(17.8, 19.2)
    ..lineTo(16.0, 11.0)
    ..lineTo(19.5, 7.5)
    ..cubicTo(21.0, 6.0, 21.5, 4.0, 21.0, 3.0)
    ..cubicTo(20.0, 2.5, 18.0, 3.0, 16.5, 4.5)
    ..lineTo(13.0, 8.0)
    ..lineTo(4.8, 6.2)
    ..cubicTo(4.3, 6.1, 3.9, 6.3, 3.7, 6.7)
    ..lineTo(3.4, 7.2)
    ..cubicTo(3.2, 7.7, 3.3, 8.2, 3.7, 8.5)
    ..lineTo(9.0, 12.0)
    ..lineTo(7.0, 15.0)
    ..lineTo(4.0, 15.0)
    ..lineTo(3.0, 16.0)
    ..lineTo(6.0, 18.0)
    ..lineTo(8.0, 21.0)
    ..lineTo(9.0, 20.0)
    ..lineTo(9.0, 17.0)
    ..lineTo(12.0, 15.0)
    ..lineTo(15.5, 20.3)
    ..cubicTo(15.8, 20.7, 16.3, 20.8, 16.8, 20.6)
    ..lineTo(17.3, 20.4)
    ..cubicTo(17.7, 20.1, 17.9, 19.7, 17.8, 19.2)
    ..close();

  static final Path _code = Path()
    ..moveTo(16.0, 18.0)
    ..lineTo(22.0, 12.0)
    ..lineTo(16.0, 6.0)
    ..moveTo(8.0, 6.0)
    ..lineTo(2.0, 12.0)
    ..lineTo(8.0, 18.0);
}
