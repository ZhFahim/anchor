import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/anchor_sheet.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget opener(Widget sheet, {ValueChanged<Object?>? onResult}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async {
            final result = await showAnchorSheet<Object?>(
              context,
              builder: (_) => sheet,
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Widget recordingFooter({required double width}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: SheetFooter(
          children: [
            const AppButton(label: 'Discard', kind: AppButtonKind.dangerText),
            AppButton(
              label: 'Again',
              icon: LucideIcons.rotateCcw,
              kind: AppButtonKind.secondary,
              onPressed: () {},
            ),
            AppButton(label: 'Save', onPressed: () {}),
          ],
        ),
      ),
    ),
  ),
);

List<String> cutLabels(WidgetTester tester) => [
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  ))
    if (paragraph.didExceedMaxLines) paragraph.text.toPlainText(),
];

void main() {
  testWidgets('showAnchorSheet returns the value the sheet pops with', (
    tester,
  ) async {
    Object? result;
    await tester.pumpWidget(
      opener(
        Builder(
          builder: (sheetContext) => TextButton(
            onPressed: () => Navigator.pop(sheetContext, 'chosen'),
            child: const Text('Choose'),
          ),
        ),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose'), findsOneWidget);

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();

    expect(result, 'chosen');
    expect(find.text('Choose'), findsNothing);
  });

  testWidgets('onGone comes once a closing sheet is off the screen, before '
      'its spring comes to rest', (tester) async {
    var goneCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAnchorSheet<void>(
                context,
                onGone: () => goneCount++,
                builder: (sheetContext) => TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close'));
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    while (goneCount == 0) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      tester.getRect(find.text('Close')).top,
      greaterThanOrEqualTo(screen),
    );
    expect(find.text('Close'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
    expect(goneCount, 1);
  });

  testWidgets('with reduced motion, a closed sheet is gone at once', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showAnchorSheet<void>(
                    context,
                    builder: (_) => const SheetHeader(title: 'Sheet title'),
                  ),
                  child: const Text('Open'),
                ),
                TextButton(
                  onPressed: () => taps++,
                  child: const Text('Behind'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Sheet title'), findsOneWidget);

    Navigator.of(tester.element(find.text('Sheet title'))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Behind'), warnIfMissed: false);

    expect(find.text('Sheet title', skipOffstage: false), findsNothing);
    expect(taps, 1);
  });

  testWidgets('a tap outside the sheet closes it with no value', (
    tester,
  ) async {
    var closed = false;
    Object? result = 'unset';
    await tester.pumpWidget(
      opener(
        const SheetHeader(title: 'Sheet title'),
        onResult: (value) {
          closed = true;
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
    expect(find.text('Sheet title'), findsNothing);
  });

  testWidgets('SheetHeader shows its title, subtitle and Done', (tester) async {
    await tester.pumpWidget(
      opener(
        const SheetHeader(
          title: 'Sheet title',
          subtitle: 'Sheet subtitle',
          showDone: true,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet title'), findsOneWidget);
    expect(find.text('Sheet subtitle'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet title'), findsNothing);
  });

  testWidgets('SheetHeader has no Done unless asked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: SheetHeader(title: 'Sheet title')),
      ),
    );

    expect(find.text('Sheet title'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('SheetFooter sets its buttons side by side at equal width', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SheetFooter(
            children: [
              const AppButton(label: 'Cancel', kind: AppButtonKind.secondary),
              AppButton(label: 'Save', onPressed: () => saved = true),
            ],
          ),
        ),
      ),
    );

    final cancel = tester.getRect(find.byType(AppButton).first);
    final save = tester.getRect(find.byType(AppButton).last);
    expect(cancel.top, save.top);
    expect(cancel.width, moreOrLessEquals(save.width));
    expect(cancel.right, lessThan(save.left));

    await tester.tap(find.text('Save'));
    expect(saved, isTrue);
  });

  testWidgets('SheetFooter gives a longer label the room it needs', (
    tester,
  ) async {
    await tester.pumpWidget(recordingFooter(width: 480));

    final discard = tester.getRect(find.byType(AppButton).at(0));
    final again = tester.getRect(find.byType(AppButton).at(1));
    final save = tester.getRect(find.byType(AppButton).at(2));
    expect([discard.top, again.top], [save.top, save.top]);
    expect(again.width, greaterThan(save.width));
    expect(cutLabels(tester), isEmpty);
  });

  testWidgets('SheetFooter stacks its buttons, the last on top, when they '
      'don\'t fit side by side', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(recordingFooter(width: 360));

    final discard = tester.getRect(find.byType(AppButton).at(0));
    final again = tester.getRect(find.byType(AppButton).at(1));
    final save = tester.getRect(find.byType(AppButton).at(2));
    expect(save.bottom, lessThan(again.top));
    expect(again.bottom, lessThan(discard.top));
    expect([discard.width, again.width], [save.width, save.width]);
    expect(cutLabels(tester), isEmpty);
  });
}
