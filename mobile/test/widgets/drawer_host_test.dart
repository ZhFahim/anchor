import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/notes/presentation/widgets/drawer_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the page takes touches as soon as the drawer starts closing', (
    tester,
  ) async {
    final drawer = GlobalKey<DrawerHostState>();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DrawerHost(
          key: drawer,
          drawerBuilder: (close) => const SizedBox(width: 300),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    drawer.currentState!.open();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(700, 300));
    expect(taps, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(drawer.currentState!.isOpen, isTrue);

    await tester.tapAt(const Offset(700, 300));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(drawer.currentState!.isOpen, isFalse);
  });

  testWidgets('the drawer builds once while it opens and closes', (
    tester,
  ) async {
    final drawer = GlobalKey<DrawerHostState>();
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DrawerHost(
          key: drawer,
          drawerBuilder: (close) => Builder(
            builder: (_) {
              builds++;
              return const SizedBox(width: 300);
            },
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    drawer.currentState!.open();
    await tester.pumpAndSettle();
    expect(builds, 1);

    drawer.currentState!.close();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(builds, 1);
  });

  testWidgets('Back closes the drawer instead of leaving the app', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final drawer = GlobalKey<DrawerHostState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DrawerHost(
          key: drawer,
          drawerBuilder: (close) => const SizedBox(width: 300),
          child: const SizedBox.expand(),
        ),
      ),
    );
    drawer.currentState!.open();
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(drawer.currentState!.isCovered, isFalse);
    expect(calls, isNot(contains('SystemNavigator.pop')));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('a screen reader reaches only the drawer while it is open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final drawer = GlobalKey<DrawerHostState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DrawerHost(
          key: drawer,
          drawerBuilder: (close) =>
              const SizedBox(width: 300, child: Text('Archive')),
          child: const Center(child: Text('A note')),
        ),
      ),
    );
    expect(find.semantics.byLabel('A note'), findsOne);

    drawer.currentState!.open();
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('A note'), findsNothing);
    expect(find.semantics.byLabel('Archive'), findsOne);

    drawer.currentState!.close();
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('A note'), findsOne);
    semantics.dispose();
  });
}
