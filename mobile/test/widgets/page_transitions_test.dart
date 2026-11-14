import 'package:anchor/core/motion/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const home = ValueKey('home');
  const next = ValueKey('next');
  const screen = ValueKey('screen');

  Future<void> pumpPages(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: screen,
        child: MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.android,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: AnchorPageTransitionsBuilder(),
              },
            ),
          ),
          home: Builder(
            builder: (context) => ColoredBox(
              key: home,
              color: Colors.white,
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ColoredBox(
                        key: next,
                        color: Colors.teal,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> backGesture(
    WidgetTester tester,
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) {},
    );
  }

  Map<String, Object?> backEvent(SwipeEdge edge, double x, double progress) => {
    'touchOffset': [x, 400.0],
    'progress': progress,
    'swipeEdge': edge.index,
  };

  for (final edge in SwipeEdge.values) {
    testWidgets(
      'after a back swipe from the ${edge.name} edge the page leaves to the right',
      (tester) async {
        await pumpPages(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final startX = edge == SwipeEdge.left ? 4.0 : 386.0;
        final endX = edge == SwipeEdge.left ? 200.0 : 190.0;
        await backGesture(
          tester,
          'startBackGesture',
          backEvent(edge, startX, 0),
        );
        await tester.pump();
        await backGesture(
          tester,
          'updateBackGestureProgress',
          backEvent(edge, endX, 0.6),
        );
        await tester.pump();
        expect(tester.getTopLeft(find.byKey(home)).dx, 0);
        await backGesture(tester, 'commitBackGesture');
        await tester.pump();

        var lastX = tester.getTopLeft(find.byKey(next)).dx;
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (find.byKey(next).evaluate().isEmpty) break;
          final x = tester.getTopLeft(find.byKey(next)).dx;
          expect(x, greaterThan(lastX), reason: 'frame $frame');
          expect(tester.getTopLeft(find.byKey(home)).dx, 0);
          lastX = x;
        }
        expect(lastX, greaterThan(100));

        await tester.pumpAndSettle();
        expect(find.byKey(next), findsNothing);
        expect(tester.getTopLeft(find.byKey(home)).dx, 0);
      },
    );
  }

  testWidgets('a back swipe let go of early eases the page back in place', (
    tester,
  ) async {
    await pumpPages(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final width = tester.getRect(find.byKey(next)).width;

    await backGesture(
      tester,
      'startBackGesture',
      backEvent(SwipeEdge.left, 4, 0),
    );
    await tester.pump();
    await backGesture(
      tester,
      'updateBackGestureProgress',
      backEvent(SwipeEdge.left, 180, 0.5),
    );
    await tester.pump();
    var lastWidth = tester.getRect(find.byKey(next)).width;
    expect(lastWidth, lessThan(width));
    await backGesture(tester, 'cancelBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getRect(find.byKey(next)).width, lessThan(width - 4));

    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final box = tester.getRect(find.byKey(next));
      expect(box.left, lessThan(12), reason: 'frame $frame');
      expect(
        box.width,
        greaterThanOrEqualTo(lastWidth),
        reason: 'frame $frame',
      );
      lastWidth = box.width;
    }
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(next)),
      Offset.zero & const Size(390, 844),
    );
  });

  testWidgets('a page shrinking under a back swipe is drawn as a picture', (
    tester,
  ) async {
    await pumpPages(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    bool isPicture() => tester
        .widget<SnapshotWidget>(
          find.ancestor(
            of: find.byKey(next),
            matching: find.byType(SnapshotWidget),
          ),
        )
        .controller
        .allowSnapshotting;
    expect(isPicture(), isFalse);

    await backGesture(
      tester,
      'startBackGesture',
      backEvent(SwipeEdge.right, 386, 0),
    );
    await tester.pump();
    expect(isPicture(), isTrue);
    await backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(isPicture(), isFalse);
  });

  testWidgets('a page sliding in shows its own colors', (tester) async {
    await pumpPages(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final page = tester.renderObject<RenderBox>(find.byKey(next));
    final center = page.localToGlobal(page.size.center(Offset.zero));
    final shot = tester.renderObject<RenderRepaintBoundary>(find.byKey(screen));
    final color = await tester.runAsync(() async {
      final image = await shot.toImage();
      final bytes = await image.toByteData();
      final at = (center.dy.round() * image.width + center.dx.round()) * 4;
      return Color.fromARGB(
        255,
        bytes!.getUint8(at),
        bytes.getUint8(at + 1),
        bytes.getUint8(at + 2),
      );
    });
    expect(color!.toARGB32(), Colors.teal.toARGB32());
  });

  testWidgets('the page underneath moves a third of the way and comes back', (
    tester,
  ) async {
    await pumpPages(tester);
    final width = tester.getSize(find.byKey(home)).width;

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const AnchorPageTransitionsBuilder().transitionDuration);
    expect(
      tester.getTopLeft(find.byKey(home)).dx,
      moreOrLessEquals(-width / 3, epsilon: 4),
    );
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final underX = tester.getTopLeft(find.byKey(home)).dx;
    final nextX = tester.getTopLeft(find.byKey(next)).dx;
    expect(underX, inExclusiveRange(-width / 3, 0));
    expect(underX, moreOrLessEquals(nextX / 3 - width / 3, epsilon: 2));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(home)).dx, 0);
  });
}
