import 'package:anchor/core/motion/snapshot_scale.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScale(WidgetTester tester, double scale) =>
      tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SnapshotScale(
              scale: scale,
              child: const SizedBox(width: 100, height: 40, child: Text('Hi')),
            ),
          ),
        ),
      );

  bool isPicture(WidgetTester tester) => tester
      .widget<SnapshotWidget>(find.byType(SnapshotWidget))
      .controller
      .allowSnapshotting;

  testWidgets('draws its child as a picture only while it is scaled', (
    tester,
  ) async {
    await pumpScale(tester, 1);
    expect(isPicture(tester), isFalse);

    await pumpScale(tester, 0.96);
    expect(isPicture(tester), isTrue);
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 40));
    expect(tester.getRect(find.byType(SizedBox)).width, closeTo(96, 0.01));

    await pumpScale(tester, 1);
    expect(isPicture(tester), isFalse);
  });

  testWidgets(
    'keeps one picture while a parent builds a new child each frame',
    (tester) async {
      const screen = ValueKey('screen');
      Future<void> pumpColor(Color color) => tester.pumpWidget(
        RepaintBoundary(
          key: screen,
          child: Center(
            child: SnapshotScale(
              scale: 0.9,
              child: SizedBox.square(
                dimension: 100,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ),
      );
      Future<Color> middle() async {
        final shot = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(screen),
        );
        final bytes = await tester.runAsync(() async {
          final image = await shot.toImage();
          return (await image.toByteData())!;
        });
        final at =
            ((shot.size.height ~/ 2) * shot.size.width.toInt() +
                shot.size.width ~/ 2) *
            4;
        return Color.fromARGB(
          255,
          bytes!.getUint8(at),
          bytes.getUint8(at + 1),
          bytes.getUint8(at + 2),
        );
      }

      await pumpColor(const Color(0xFFFF0000));
      expect(await middle(), const Color(0xFFFF0000));
      await pumpColor(const Color(0xFF00FF00));
      expect(await middle(), const Color(0xFFFF0000));
    },
  );

  testWidgets('starts as a picture when it starts scaled', (tester) async {
    await pumpScale(tester, 0.5);
    expect(isPicture(tester), isTrue);
  });
}
