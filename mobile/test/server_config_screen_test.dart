import 'dart:io';

import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/page_bar.dart';
import 'package:anchor/features/server/presentation/harbor_illustration.dart';
import 'package:anchor/features/server/presentation/server_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('when the server can\'t be reached', () {
    late _RefusingHttp http;
    final overrides = HttpOverrides.current;

    setUp(() => HttpOverrides.global = http = _RefusingHttp());
    tearDown(() => HttpOverrides.global = overrides);

    Future<void> settleRequest(WidgetTester tester) =>
        tester.pump(const Duration(milliseconds: 200));

    Future<void> connect(WidgetTester tester, String address) async {
      await tester.enterText(find.byType(TextField), address);
      await tester.tap(find.text('Continue'));
      await settleRequest(tester);
    }

    Future<void> comeBackToTheApp(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleRequest(tester);
    }

    testWidgets('coming back to the app tries the same address again', (
      tester,
    ) async {
      await pumpApp(tester, const ServerConfigScreen());
      await connect(tester, 'http://192.168.1.2:3001');
      expect(http.attempts, 1);
      expect(find.textContaining('Couldn’t reach'), findsOneWidget);

      await comeBackToTheApp(tester);
      expect(http.attempts, 2);
    });

    testWidgets('coming back doesn\'t try an address changed since', (
      tester,
    ) async {
      await pumpApp(tester, const ServerConfigScreen());
      await connect(tester, 'http://192.168.1.2:3001');
      await tester.enterText(find.byType(TextField), 'http://192.168.1.3');

      await comeBackToTheApp(tester);
      expect(http.attempts, 1);
    });
  });
}

class _RefusingHttp extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _RefusingClient(this);
}

class _RefusingClient implements HttpClient {
  _RefusingClient(this.http);

  final _RefusingHttp http;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    http.attempts++;
    return Future.error(const SocketException('Network is down'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
