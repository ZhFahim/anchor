import 'dart:async';

import 'package:anchor/core/motion/reorder_animation.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/note_morph_route.dart';
import 'package:anchor/features/notes/presentation/widgets/card_registry.dart';
import 'package:anchor/features/notes/presentation/widgets/note_card.dart';
import 'package:anchor/features/notes/presentation/widgets/note_card_content.dart';
import 'package:anchor/features/notes/presentation/widgets/notes_bottom_bar.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final order = ValueNotifier<List<String>>(const []);
  final navigator = GlobalKey<NavigatorState>();
  final listKey = GlobalKey();

  Note note(String id) => Note(
    id: id,
    title: 'Note $id',
    content: '{"ops":[{"insert":"Some words for note $id\\n"}]}',
  );

  late ReorderPositions memory;

  Future<void> pumpList(WidgetTester tester, List<String> ids) async {
    memory = ReorderPositions();
    tester.view.physicalSize = const Size(360, 792);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    order.value = ids;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagsControllerProvider.overrideWith(TagsController.new),
          serverUrlProvider.overrideWithValue('https://example.test'),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light(),
          home: Scaffold(
            floatingActionButton: SizedBox.square(
              key: CardRegistry.newNoteButton,
              dimension: 52,
            ),
            body: ValueListenableBuilder<List<String>>(
              valueListenable: order,
              builder: (context, ids, _) => ReorderAnimationScope(
                generation: Object.hashAll(ids),
                contentKey: listKey,
                child: ListView(
                  key: listKey,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final id in ids)
                      Padding(
                        key: ValueKey(id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 140,
                          child: ReorderAnimatedBox(
                            id: id,
                            memory: memory,
                            child: NoteCard(note: note(id), tags: const []),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, String id) async {
    navigator.currentState!.push(
      NoteMorphRoute(
        settings: const RouteSettings(),
        noteId: id,
        builder: (_) => ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: const [SizedBox(height: 2000, child: Text('The note'))],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder morph() => find.ancestor(
    of: find.byType(SnapshotWidget),
    matching: find.byType(ClipRRect),
  );

  Future<List<Rect>> closeFrames(WidgetTester tester) async {
    navigator.currentState!.pop();
    final frames = <Rect>[];
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (morph().evaluate().isEmpty) {
        if (frames.isNotEmpty) break;
        continue;
      }
      frames.add(tester.getRect(morph().first));
    }
    return frames;
  }

  testWidgets('with reduced motion, a note closed through the router is '
      'gone at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('The list')),
        ),
        GoRoute(
          path: '/note',
          pageBuilder: (_, _) =>
              const NoteMorphPage(child: Scaffold(body: Text('The note'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    unawaited(router.push('/note'));
    await tester.pumpAndSettle();
    expect(find.text('The note'), findsOneWidget);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('The note', skipOffstage: false), findsNothing);
    expect(find.text('The list').hitTestable(), findsOneWidget);
  });

  group('on iPhone', () {
    Future<void> openOnIPhone(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 792);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('The list')),
          ),
          GoRoute(
            path: '/note',
            pageBuilder: (_, _) => const NoteMorphPage(
              child: Scaffold(body: Center(child: Text('The note'))),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
          routerConfig: router,
        ),
      );
      unawaited(router.push('/note'));
      await tester.pumpAndSettle();
    }

    Future<void> dragFromEdge(WidgetTester tester, double distance) async {
      final gesture = await tester.startGesture(const Offset(2, 300));
      for (var moved = 0.0; moved < distance; moved += 40) {
        await gesture.moveBy(const Offset(40, 0));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a swipe from the left edge closes the note', (tester) async {
      await openOnIPhone(tester);
      await dragFromEdge(tester, 240);
      expect(find.text('The note'), findsNothing);
      expect(find.text('The list'), findsOneWidget);
    });

    testWidgets('a short swipe from the left edge puts the note back', (
      tester,
    ) async {
      await openOnIPhone(tester);
      final atRest = tester.getCenter(find.text('The note'));
      await dragFromEdge(tester, 80);
      expect(tester.getCenter(find.text('The note')), atRest);
    });
  });

  testWidgets('a note closes into its card after the card moved', (
    tester,
  ) async {
    await pumpList(tester, ['a', 'b', 'c']);
    final before = CardRegistry.rectOf('c')!;
    await open(tester, 'c');
    order.value = ['c', 'a', 'b'];
    await tester.pumpAndSettle();

    final frames = await closeFrames(tester);
    final card = CardRegistry.rectOf('c')!;
    expect(card.top, lessThan(before.top));
    expect((frames.last.center - card.center).distance, lessThan(4));
    expect((frames.last.width - card.width).abs(), lessThan(4));
    expect((frames.last.height - card.height).abs(), lessThan(4));
  });

  testWidgets('a new note waits for its card and lands on it', (tester) async {
    await pumpList(tester, ['a', 'b']);
    await open(tester, 'new');
    navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    order.value = ['new', 'a', 'b'];

    final frames = <Rect>[];
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (morph().evaluate().isNotEmpty) frames.add(tester.getRect(morph()));
    }
    final card = CardRegistry.rectOf('new')!;
    expect(frames, isNotEmpty);
    expect((frames.last.center - card.center).distance, lessThan(4));
  });

  Future<NoteMorphRoute> openNew(WidgetTester tester) async {
    final route = NoteMorphRoute(
      settings: const RouteSettings(),
      builder: (_) => const ColoredBox(
        color: Colors.white,
        child: SizedBox.expand(child: Text('The note')),
      ),
    );
    navigator.currentState!.push(route);
    await tester.pumpAndSettle();
    return route;
  }

  testWidgets('an empty new note closes into New note as the button', (
    tester,
  ) async {
    await pumpList(tester, ['a', 'b']);
    await openNew(tester);
    final frames = await closeFrames(tester);
    final button = CardRegistry.newNoteRect()!;
    expect((frames.last.center - button.center).distance, lessThan(2));
    expect((frames.last.width - button.width).abs(), lessThan(2));

    navigator.currentState!.push(
      NoteMorphRoute(
        settings: const RouteSettings(),
        builder: (_) => const SizedBox.expand(),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    Color? fill;
    for (var i = 0; i < 120 && fill == null; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final shape = morph();
      if (shape.evaluate().isEmpty) continue;
      if (tester.getRect(shape.first).width > button.width + 4) continue;
      fill =
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: shape.first,
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      expect(find.byType(NewNoteIcon), findsWidgets);
    }
    final ink = AnchorColors.light.appInverse;
    expect(fill, isNotNull);
    expect(fill!.r, closeTo(ink.r, 0.08));
    expect(fill.g, closeTo(ink.g, 0.08));
    expect(fill.b, closeTo(ink.b, 0.08));
  });

  testWidgets('a new note saved as it closes waits for its card, then '
      'closes from rest', (tester) async {
    await pumpList(tester, ['a', 'b']);
    final route = await openNew(tester);
    route.isBlank = () => false;
    navigator.currentState!.pop();
    final frames = <Rect>[];
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (i == 2) route.noteId.value = 'new';
      if (i == 5) order.value = ['new', 'a', 'b'];
      if (morph().evaluate().isNotEmpty) frames.add(tester.getRect(morph()));
    }
    final card = CardRegistry.rectOf('new')!;
    expect(frames.length, greaterThan(10));
    expect(frames.first.width, greaterThan(340), reason: 'starts from rest');
    expect((frames.last.center - card.center).distance, lessThan(4));
    for (var i = 1; i < frames.length; i++) {
      expect(
        (frames[i].center - frames[i - 1].center).distance,
        lessThan(40),
        reason: 'frame $i jumped',
      );
    }
  });

  testWidgets('the card face shows as the note lands on the card', (
    tester,
  ) async {
    await pumpList(tester, ['a', 'b']);
    await open(tester, 'b');
    navigator.currentState!.pop();
    var sawContent = false;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (morph().evaluate().isEmpty) continue;
      final cards = find.byType(NoteCardContent);
      if (cards.evaluate().length == 3) {
        sawContent = true;
        final title = tester.element(find.text('Note b').last);
        expect(
          DefaultTextStyle.of(title).style.decoration,
          isNot(TextDecoration.underline),
        );
      }
    }
    expect(sawContent, isTrue);
    expect(find.byType(NoteCardContent), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the list shows under a note pulled down', (tester) async {
    await pumpList(tester, ['a', 'b']);
    await open(tester, 'b');
    expect(find.text('Note a'), findsNothing);

    final gesture = await tester.startGesture(const Offset(180, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(find.text('Note a'), findsOneWidget);
    final card = find.ancestor(
      of: find.text('Note b'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(card.first).opacity, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Note a'), findsNothing);
  });

  testWidgets('a note pulled down far enough closes', (tester) async {
    await pumpList(tester, ['a', 'b']);
    await open(tester, 'b');

    final gesture = await tester.startGesture(const Offset(180, 200));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('The note'), findsNothing);
  });

  testWidgets('a card off the screen closes with a fade', (tester) async {
    await pumpList(tester, [for (var i = 0; i < 12; i++) '$i']);
    await open(tester, '0');
    final list = tester.state<ScrollableState>(
      find.byType(Scrollable, skipOffstage: false).first,
    );
    list.position.jumpTo(300);
    await tester.pump();
    final frames = await closeFrames(tester);
    expect(frames, isEmpty);
    expect(find.text('The note'), findsNothing);
  });

  test('a card stays hidden while any note over it is open', () {
    CardRegistry.hide('x');
    CardRegistry.hide('x');
    CardRegistry.show('x');
    expect(CardRegistry.hidden.value, contains('x'));
    CardRegistry.show('x');
    expect(CardRegistry.hidden.value, isNot(contains('x')));
  });
}
