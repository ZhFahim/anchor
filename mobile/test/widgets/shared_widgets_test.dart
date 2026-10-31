import 'dart:async';

import 'package:anchor/core/motion/page_transitions.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:anchor/core/widgets/anchor_dialog.dart';
import 'package:anchor/core/widgets/anchor_menu.dart';
import 'package:anchor/core/widgets/check_circle.dart';
import 'package:anchor/core/widgets/choice_sheet.dart';
import 'package:anchor/core/widgets/notice.dart';
import 'package:anchor/core/widgets/page_bar.dart';
import 'package:anchor/core/widgets/person_avatar.dart';
import 'package:anchor/core/widgets/pressable.dart';
import 'package:anchor/core/widgets/selection_bar.dart';
import 'package:anchor/core/widgets/switch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

Widget app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('the selection bar switcher is as tall as the one showing', (
    tester,
  ) async {
    Widget switcher({required bool isSelecting}) => app(
      Align(
        alignment: Alignment.bottomCenter,
        child: SelectionBarSwitcher(
          isSelecting: isSelecting,
          bottomBar: const SizedBox(height: 52, child: Text('Dock')),
          selectionBar: const SizedBox(height: 64, child: Text('Bar')),
        ),
      ),
    );
    final size = find.byType(SelectionBarSwitcher);

    await tester.pumpWidget(switcher(isSelecting: false));
    expect(tester.getSize(size).height, 52);

    await tester.pumpWidget(switcher(isSelecting: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(size).height, 64);
    expect(find.text('Dock', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a check circle shows a check, a dash for some, or nothing', (
    tester,
  ) async {
    Future<void> pump(bool? value) =>
        tester.pumpWidget(app(Center(child: CheckCircle(value: value))));
    Icon icon() => tester.widget<Icon>(find.byType(Icon));

    await pump(true);
    expect(icon().icon, LucideIcons600.check);
    await pump(null);
    expect(icon().icon, LucideIcons600.minus);
    await pump(false);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
  });

  testWidgets('a notice reads its bold lead and its words as one', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        Notice(
          title: 'Signed out.',
          text: 'Sign in again.',
          kind: NoticeKind.warn,
          onTap: () => taps++,
        ),
      ),
    );

    expect(
      find.text('Signed out. Sign in again.', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Signed out. Sign in again.'));
    expect(taps, 1);
  });

  testWidgets('a quick tap on a row in a list still shows its press', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListView(
          children: [
            Pressable(
              style: PressStyle.row,
              onTap: () {},
              child: const SizedBox(height: 52, child: Text('Password')),
            ),
          ],
        ),
      ),
    );
    Color tint() {
      final box = tester.renderObject<RenderDecoratedBox>(
        find
            .descendant(
              of: find.byType(AnimatedContainer),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    await tester.tap(find.text('Password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tint().a, greaterThan(0.03));

    await tester.pumpAndSettle();
    expect(tint().a, 0);
  });

  testWidgets('a screen reader can long press what a finger can', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var longPresses = 0;
    await tester.pumpWidget(
      app(
        Pressable(
          style: PressStyle.row,
          semanticLabel: 'Work',
          onTap: () {},
          onLongPress: () => longPresses++,
          child: const SizedBox(height: 52, child: Text('Work')),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(Pressable));
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
    );
    node.owner!.performAction(node.id, SemanticsAction.longPress);
    expect(longPresses, 1);
    semantics.dispose();
  });

  testWidgets('a page closing on Android is mostly gone halfway through', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {TargetPlatform.android: AnchorPageTransitionsBuilder()},
          ),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ColoredBox(
                  key: ValueKey('next'),
                  color: Colors.teal,
                  child: SizedBox.expand(),
                ),
              ),
            ),
            child: const Text('Next'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final width = tester.getSize(find.byKey(const ValueKey('next'))).width;

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(
      const AnchorPageTransitionsBuilder().reverseTransitionDuration ~/ 2,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('next'))).dx,
      greaterThan(width * 0.8),
    );
  });

  testWidgets('a switch row flips from anywhere on it', (tester) async {
    var value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => app(
          SwitchRow(
            label: 'Repeat',
            value: value,
            onChanged: (on) => setState(() => value = on),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Repeat'));
    await tester.pump();
    expect(value, isTrue);
    expect(find.bySemanticsLabel('Repeat, on'), findsOneWidget);
  });

  testWidgets('a choice sheet returns the row chosen', (tester) async {
    String? selected;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => selected = await showChoiceSheet<String>(
              context,
              title: 'Photo',
              choices: const [
                SheetChoice(
                  value: 'take',
                  icon: LucideIcons.camera,
                  label: 'Take a photo',
                ),
                null,
                SheetChoice(
                  value: 'remove',
                  icon: LucideIcons.trash2,
                  label: 'Remove photo',
                  isDanger: true,
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(selected, 'remove');
    expect(find.text('Take a photo'), findsNothing);
  });

  testWidgets('a dialog and a menu leave faster than they came', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => showAnchorDialog(
                  context,
                  title: 'Sign out?',
                  message: 'Your notes stay on this phone.',
                  confirmLabel: 'Sign out',
                ),
                child: const Text('Dialog'),
              ),
              TextButton(
                onPressed: () => showAnchorMenu<String>(
                  context,
                  items: const [
                    AnchorMenuItem(
                      value: 'view',
                      icon: LucideIcons.eye,
                      label: 'Can view',
                    ),
                  ],
                ),
                child: const Text('Menu'),
              ),
            ],
          ),
        ),
      ),
    );
    final exit =
        AnchorTokens.motionDurationExit + const Duration(milliseconds: 1);

    await tester.tap(find.text('Dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(exit);
    expect(find.text('Sign out?'), findsNothing);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Can view'));
    await tester.pump();
    await tester.pump(exit);
    expect(find.text('Can view'), findsNothing);
  });

  testWidgets('the page bar sets the status bar for its page', (tester) async {
    await tester.pumpWidget(
      app(
        PageBar(
          systemBars: SystemUiOverlayStyle.light,
          title: const Text('Title'),
        ),
      ),
    );

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value, SystemUiOverlayStyle.light);
  });

  testWidgets('initials keep their size at a larger text size', (tester) async {
    Future<double> initialsWidth(double scale) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [serverUrlProvider.overrideWithValue(null)],
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: app(
              const Center(
                child: PersonAvatar(name: 'Mia Mobile', size: PersonAvatar.row),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.text('MM')).width;
    }

    final width = await initialsWidth(1);
    expect(await initialsWidth(1.3), width);
    expect(width, lessThan(PersonAvatar.row - 4));
  });

  testWidgets('a dialog that waits keeps its button busy until it is done', (
    tester,
  ) async {
    final signingOut = Completer<void>();
    late Future<bool> confirmed;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => confirmed = showAnchorDialog(
              context,
              title: 'Sign out?',
              message: 'Your notes stay on this phone.',
              confirmLabel: 'Sign out',
              busyLabel: 'Signing out…',
              onConfirm: () => signingOut.future,
            ),
            child: const Text('Dialog'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Signing out…'), findsOneWidget);
    await tester.tap(find.text('Cancel'), warnIfMissed: false);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Signing out…'), findsOneWidget);

    signingOut.complete();
    await tester.pumpAndSettle();
    expect(find.text('Signing out…'), findsNothing);
    expect(await confirmed, isTrue);
  });

  testWidgets('on Android, dialog buttons that do not fit side by side '
      'stack with the action on top', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAnchorDialog(
              context,
              title: 'Permanently delete this note?',
              message: 'This can’t be undone.',
              confirmLabel: 'Delete permanently',
              isDanger: true,
            ),
            child: const Text('Dialog'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dialog'));
    await tester.pumpAndSettle();

    final action = tester.getRect(find.text('Delete permanently'));
    final cancel = tester.getRect(find.text('Cancel'));
    expect(action.bottom, lessThan(cancel.top));
    expect(action.right, moreOrLessEquals(cancel.right, epsilon: 16));
  });
}
