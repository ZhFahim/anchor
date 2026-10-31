import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/page_bar.dart';
import 'package:anchor/features/server/presentation/harbor_illustration.dart';
import 'package:anchor/features/server/presentation/server_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isOnlineProvider.overrideWithValue(true)],
        child: MaterialApp(theme: AppTheme.light(), home: home),
      ),
    );
    await tester.pump();
  }

  String addressOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  /// The server page is tall; give it a window it fully fits in.
  void tallWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// The harbor illustration sways forever, so there is no settling; a pair
  /// of pumps is enough for a reveal to grow to its full size.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> openAdvanced(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Advanced'));
    await tester.tap(find.text('Advanced'));
    await settle(tester);
  }

  testWidgets('the first start asks for the server with no way back', (
    tester,
  ) async {
    await pumpApp(tester, const ServerConfigScreen());

    expect(find.byType(HarborIllustration), findsOneWidget);
    expect(find.text('Welcome to Anchor'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(PageBackButton), findsNothing);
    expect(addressOf(tester), isEmpty);
  });

  testWidgets('from sign in, the same page opens with the address and a '
      'way back', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ServerConfigScreen(
                initialUrl: 'https://anchor.example.com',
              ),
            ),
          ),
          child: const Text('Sign in'),
        ),
      ),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HarborIllustration), findsOneWidget);
    expect(find.text('Welcome to Anchor'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(PageBackButton), findsOneWidget);
    expect(addressOf(tester), 'anchor.example.com');
  });

  testWidgets('custom headers sit under the self-signed switch in Advanced, '
      'up to ten of them', (tester) async {
    tallWindow(tester);
    await pumpApp(tester, const ServerConfigScreen());
    await openAdvanced(tester);

    expect(find.text('Allow self-signed certificates'), findsOneWidget);
    expect(find.text('Custom headers'), findsOneWidget);
    expect(find.text('Add header'), findsOneWidget);

    final add = find.text('Add header');
    for (var i = 0; i < maxCustomHeaders + 2; i++) {
      await tester.ensureVisible(add);
      await tester.tap(add);
      await settle(tester);
    }

    // Each row has a name and a value field; the address makes one more.
    expect(
      find.byType(TextField),
      findsNWidgets(maxCustomHeaders * 2 + 1),
    );
    expect(find.text('Up to 10 headers.'), findsOneWidget);
  });

  testWidgets('a custom header with a value but no name is told so before '
      'connecting', (tester) async {
    tallWindow(tester);
    await pumpApp(tester, const ServerConfigScreen());

    await tester.enterText(
      find.byType(TextField).first,
      'notes.example.com',
    );

    await openAdvanced(tester);

    await tester.tap(find.text('Add header'));
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Value'), 'ada');

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'Enter a name with only letters, numbers, and dashes, like '
        'X-Anchor-User.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a named custom header is kept and can be removed', (tester) async {
    tallWindow(tester);
    await pumpApp(tester, const ServerConfigScreen());
    await openAdvanced(tester);

    await tester.tap(find.text('Add header'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'X-Anchor-User',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Value'),
      'ada',
    );

    // The row is removed with its trash button.
    final trash = find.byIcon(LucideIcons.trash2);
    expect(trash, findsOneWidget);
    await tester.tap(trash);
    await tester.pump();
    expect(find.text('Name'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
