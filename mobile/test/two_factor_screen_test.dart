import 'package:anchor/app/router/app_routes.dart';
import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:anchor/features/auth/domain/auth_failure.dart';
import 'package:anchor/features/auth/domain/oidc_config.dart';
import 'package:anchor/features/auth/domain/registration_mode.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/auth/presentation/login_screen.dart';
import 'package:anchor/features/auth/presentation/oidc_config_provider.dart';
import 'package:anchor/features/auth/presentation/registration_mode_provider.dart';
import 'package:anchor/features/auth/presentation/two_factor_screen.dart';
import 'package:anchor/features/auth/presentation/two_factor_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Answers the second step of signing in with whatever [onVerify] throws.
class _Account extends AuthController {
  _Account({this.onVerify, this.needsCode = true, this.needsPasskey = false});

  final bool needsPasskey;

  final Object? Function(String? code, String? recoveryCode)? onVerify;
  final bool needsCode;
  final verified = <(String challenge, String? code, String? recoveryCode)>[];
  int logins = 0;

  @override
  Future<User?> build() async => null;

  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (needsPasskey) throw const PasskeyRequiredFailure();
    throw needsCode
        ? const TwoFactorRequiredFailure('challenge-1')
        : const TwoFactorSetupRequiredFailure();
  }

  @override
  Future<void> loginWithTwoFactor(
    String challenge, {
    String? code,
    String? recoveryCode,
  }) async {
    verified.add((challenge, code, recoveryCode));
    final failure = onVerify?.call(code, recoveryCode);
    if (failure != null) throw failure;
  }
}

late GoRouter _router;

Future<void> _pump(
  WidgetTester tester,
  _Account account, {
  String initialLocation = AppRoutes.login,
}) async {
  _router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.twoFactor,
        builder: (context, state) => TwoFactorScreen(
          challenge: const TwoFactorChallenge(
            email: 'ada@example.com',
            challenge: 'challenge-1',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.passkeyOnWeb,
        builder: (context, state) =>
            const TwoFactorSetupScreen(needsPasskey: true),
      ),
      GoRoute(
        path: AppRoutes.twoFactorSetup,
        builder: (context, state) => const TwoFactorSetupScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isOnlineProvider.overrideWithValue(true),
        authControllerProvider.overrideWith(() => account),
        serverUrlProvider.overrideWithValue('https://anchor.example.com'),
        oidcConfigProvider.overrideWith((ref) async => const OidcConfig()),
        registrationModeProvider.overrideWith(
          (ref) async => RegistrationMode.enabled,
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: _router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _signInWithPassword(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'ada@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'secret');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

String _typed(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

bool _isEnabled(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label)).onPressed !=
    null;

Future<void> _verifyCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

void main() {
  group('the code step', () {
    testWidgets('a login that wants a code opens it for that email', (
      tester,
    ) async {
      final account = _Account();
      await _pump(tester, account);
      await _signInWithPassword(tester);

      expect(account.logins, 1);
      expect(find.text('Check your authenticator app'), findsWidgets);
      expect(
        find.text('Enter the 6-digit code for ada@example.com.'),
        findsOne,
      );
      expect(find.text('Use a recovery code instead'), findsOneWidget);
    });

    testWidgets('the code goes with the challenge and signs in', (
      tester,
    ) async {
      final account = _Account();
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await _verifyCode(tester, '482913');

      expect(account.verified, [('challenge-1', '482913', null)]);
    });

    testWidgets('only digits are taken, up to six', (tester) async {
      await _pump(tester, _Account());
      await _signInWithPassword(tester);

      await tester.enterText(find.byType(TextField), '48a2-9137');

      expect(_typed(tester), '482913');
    });

    testWidgets('an unfinished code is not sent', (tester) async {
      final account = _Account();
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await _verifyCode(tester, '482');

      expect(account.verified, isEmpty);
      expect(find.text('Enter the 6-digit code.'), findsOneWidget);
    });

    testWidgets('a wrong code says so and clears the boxes', (tester) async {
      final account = _Account(
        onVerify: (_, _) => const InvalidTwoFactorCodeFailure(),
      );
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await _verifyCode(tester, '111111');

      expect(
        find.text('That code didn’t work. Check it and try again.'),
        findsOneWidget,
      );
      expect(_typed(tester), isEmpty);
      expect(find.text('Check your authenticator app'), findsWidgets);
      expect(_isEnabled(tester, 'Verify'), isTrue);
    });

    testWidgets('a recovery code goes in its own field', (tester) async {
      final account = _Account();
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await tester.tap(find.text('Use a recovery code instead'));
      await tester.pumpAndSettle();
      expect(find.text('Use a recovery code'), findsWidgets);
      expect(find.text('Use an authenticator code instead'), findsOneWidget);

      await tester.enterText(find.byType(TextField), ' k7m2-9xqp ');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(account.verified, [('challenge-1', null, 'k7m2-9xqp')]);
    });

    testWidgets('going back to the authenticator code drops the old '
        'error', (tester) async {
      final account = _Account(
        onVerify: (_, _) => const InvalidTwoFactorCodeFailure(),
      );
      await _pump(tester, account);
      await _signInWithPassword(tester);
      await _verifyCode(tester, '111111');

      await tester.tap(find.text('Use a recovery code instead'));
      await tester.pumpAndSettle();

      expect(find.textContaining('didn’t work'), findsNothing);

      await tester.tap(find.text('Use an authenticator code instead'));
      await tester.pumpAndSettle();
      expect(find.text('Check your authenticator app'), findsWidgets);
    });

    testWidgets('an expired challenge starts signing in over', (tester) async {
      final account = _Account(
        onVerify: (_, _) => const ChallengeExpiredFailure(),
      );
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await _verifyCode(tester, '123456');

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text(
          'Your sign-in timed out. Enter your email and password again.',
        ),
        findsOneWidget,
      );
      // The password is not kept for the next try.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('too many wrong codes lock the boxes, not the recovery '
        'code', (tester) async {
      final account = _Account(
        onVerify: (code, _) => code == null
            ? null
            : const TwoFactorLockedFailure(Duration(minutes: 10)),
      );
      await _pump(tester, account);
      await _signInWithPassword(tester);

      await _verifyCode(tester, '123456');

      expect(
        find.text('Too many wrong codes. Try again in 10 minutes.'),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(_isEnabled(tester, 'Verify'), isFalse);

      await tester.tap(find.text('Use a recovery code instead'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Too many wrong codes'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      expect(_isEnabled(tester, 'Verify'), isTrue);

      // Back on the boxes, the wait is still on.
      await tester.tap(find.text('Use an authenticator code instead'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Try again in 10 minutes'), findsOneWidget);
      expect(_isEnabled(tester, 'Verify'), isFalse);

      // They open again when the wait is over.
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      expect(find.textContaining('Too many wrong codes'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      expect(_isEnabled(tester, 'Verify'), isTrue);
    });

    testWidgets('a lock on the recovery code does not offer one', (
      tester,
    ) async {
      final account = _Account(
        onVerify: (_, recoveryCode) => recoveryCode == null
            ? null
            : const TwoFactorLockedFailure(Duration(seconds: 61)),
      );
      await _pump(tester, account);
      await _signInWithPassword(tester);
      await tester.tap(find.text('Use a recovery code instead'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'k7m2-9xqp');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many wrong codes. Try again in 2 minutes.'),
        findsOneWidget,
      );
      expect(_isEnabled(tester, 'Verify'), isFalse);

      // Leaves no timer behind.
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('two-factor on the web', () {
    testWidgets('a login that needs it opens the page, and back to sign in '
        'returns', (tester) async {
      final account = _Account(needsCode: false);
      await _pump(tester, account);
      await _signInWithPassword(tester);

      expect(find.text('Set up two-factor on the web'), findsWidgets);
      expect(find.textContaining('Settings → Security'), findsOneWidget);
      expect(find.text('Open anchor.example.com'), findsOneWidget);

      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('an account with only passkeys is sent to the web', (
      tester,
    ) async {
      await _pump(tester, _Account(needsPasskey: true));
      await _signInWithPassword(tester);

      expect(find.text('Use your passkey on the web'), findsWidgets);
      expect(
        find.text(
          'Sign in with your passkey on the web, or add an authenticator app '
          'there.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open anchor.example.com'), findsOneWidget);

      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}
