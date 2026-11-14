import 'dart:io';

import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:anchor/core/widgets/app_text_field.dart';
import 'package:anchor/core/widgets/pressable.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';
import 'package:anchor/features/auth/data/repository/auth_repository.dart';
import 'package:anchor/features/auth/domain/auth_failure.dart';
import 'package:anchor/features/auth/domain/oidc_config.dart';
import 'package:anchor/features/auth/domain/registration_mode.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/auth/presentation/change_password_screen.dart';
import 'package:anchor/features/auth/presentation/delete_account_screen.dart';
import 'package:anchor/features/auth/presentation/edit_profile_screen.dart';
import 'package:anchor/features/auth/presentation/login_screen.dart';
import 'package:anchor/features/auth/presentation/oidc_config_provider.dart';
import 'package:anchor/features/auth/presentation/registration_mode_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _RefusingRepository extends AuthRepository {
  _RefusingRepository(this.failure)
    : super(AuthService(Dio()), const FlutterSecureStorage());

  final AuthFailure failure;

  @override
  Future<void> changePassword(String currentPassword, String newPassword) =>
      Future.error(failure);
}

class _PhotoAccount extends AuthController {
  final calls = <String>[];

  @override
  Future<User?> build() async => const User(
    id: 'user-1',
    email: 'ada@example.com',
    name: 'Ada',
    profileImage: '/profiles/ada.jpg',
  );

  @override
  Future<void> setPhoto(File image) async => calls.add('setPhoto');

  @override
  Future<void> removePhoto() async => calls.add('removePhoto');
}

class _DeletingAccount extends AuthController {
  _DeletingAccount({this.hasPassword = true, this.failure});

  final bool hasPassword;
  final AuthFailure? failure;
  final passwords = <String?>[];

  @override
  Future<User?> build() async => User(
    id: 'user-1',
    email: 'ada@example.com',
    name: 'Ada',
    hasPassword: hasPassword,
  );

  @override
  Future<void> deleteAccount({String? password}) async {
    passwords.add(password);
    final failure = this.failure;
    if (failure != null) throw failure;
  }
}

class _WrongPassword extends AuthController {
  int attempts = 0;

  @override
  Future<User?> build() async => null;

  @override
  Future<void> login(String email, String password) async {
    attempts++;
    throw const InvalidCredentialsFailure();
  }
}

Finder _under(String fieldLabel, String text) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is AppTextField && widget.label == fieldLabel,
  ),
  matching: find.text(text),
);

String _textIn(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!.text;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  bool isOnline = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isOnlineProvider.overrideWithValue(isOnline), ...overrides],
      child: MaterialApp(theme: AppTheme.light(), home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new photo picked while Undo shows is the one kept', (
    tester,
  ) async {
    final picture = File('${Directory.systemTemp.createTempSync().path}/me.png')
      ..writeAsBytesSync([1, 2, 3]);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (_) async => picture.path,
    );
    final account = _PhotoAccount();
    await _pump(
      tester,
      const EditProfileScreen(),
      overrides: [authControllerProvider.overrideWith(() => account)],
    );

    await tester.tap(find.bySemanticsLabel('Change profile photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    Future<void> step() => tester.pump(const Duration(milliseconds: 1200));
    await step();
    await tester.tap(find.bySemanticsLabel('Change profile photo'));
    await step();
    tester
        .widget<Pressable>(
          find
              .ancestor(
                of: find.text('Choose photo'),
                matching: find.byType(Pressable),
              )
              .first,
        )
        .onTap!();
    await step();
    await tester.pump(const Duration(seconds: 11));

    expect(account.calls, ['setPhoto']);
  });

  group('Password', () {
    Future<void> change(WidgetTester tester, AuthFailure failure) async {
      await _pump(
        tester,
        const ChangePasswordScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _RefusingRepository(failure),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).at(0), 'old password');
      await tester.enterText(find.byType(TextField).at(1), 'new password');
      await tester.pump();
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();
    }

    testWidgets('a wrong current password says so under it', (tester) async {
      await change(tester, const WrongCurrentPasswordFailure());

      expect(
        _under('Current password', 'Your current password is incorrect.'),
        findsOneWidget,
      );
      expect(_textIn(tester, 0), isEmpty);

      await tester.enterText(find.byType(TextField).at(0), 'o');
      await tester.pump();
      expect(find.text('Your current password is incorrect.'), findsNothing);
    });

    testWidgets('offline, it says changing the password needs a connection', (
      tester,
    ) async {
      await _pump(tester, const ChangePasswordScreen(), isOnline: false);

      expect(
        find.text(
          'You’re offline. Connect to the internet to change your password.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reusing the password says so under the new one', (
      tester,
    ) async {
      await change(tester, const SamePasswordFailure());

      expect(
        _under(
          'New password',
          'Your new password must be different from your current one.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your current password is incorrect.'), findsNothing);
    });
  });

  group('Delete account', () {
    Future<_DeletingAccount> open(
      WidgetTester tester, {
      bool hasPassword = true,
      AuthFailure? failure,
      bool isOnline = true,
    }) async {
      final account = _DeletingAccount(
        hasPassword: hasPassword,
        failure: failure,
      );
      await _pump(
        tester,
        const DeleteAccountScreen(),
        isOnline: isOnline,
        overrides: [authControllerProvider.overrideWith(() => account)],
      );
      return account;
    }

    Finder button() => find.widgetWithText(AppButton, 'Delete account');
    bool isEnabled(WidgetTester tester) =>
        tester.widget<AppButton>(button()).onPressed != null;

    testWidgets('it says what goes, and waits for the password', (
      tester,
    ) async {
      final account = await open(tester);

      expect(
        find.textContaining('This can’t be undone', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('permanently deleted', findRichText: true),
        findsOneWidget,
      );
      expect(isEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'my password');
      await tester.pump();
      expect(isEnabled(tester), isTrue);

      await tester.tap(button());
      await tester.pump();
      expect(account.passwords, ['my password']);
    });

    testWidgets('no password manager offers to save a deleted account', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'my password');
      await tester.pump();
      await tester.tap(button());
      await tester.pump();

      expect(
        tester.testTextInput.log.where(
          (call) =>
              call.method == 'TextInput.finishAutofillContext' &&
              call.arguments == false,
        ),
        isNotEmpty,
      );
    });

    testWidgets('a wrong password says so under it and clears it', (
      tester,
    ) async {
      await open(tester, failure: const WrongCurrentPasswordFailure());

      await tester.enterText(find.byType(TextField), 'not it');
      await tester.pump();
      await tester.tap(button());
      await tester.pumpAndSettle();

      expect(
        _under('Password', 'Your current password is incorrect.'),
        findsOneWidget,
      );
      expect(_textIn(tester, 0), isEmpty);
    });

    testWidgets('the only admin is told what to do first', (tester) async {
      await open(tester, failure: const LastAdminFailure());

      await tester.enterText(find.byType(TextField), 'my password');
      await tester.pump();
      await tester.tap(button());
      await tester.pumpAndSettle();

      expect(find.textContaining('only admin on this server'), findsOneWidget);
    });

    testWidgets('offline, it says deleting needs a connection', (tester) async {
      await open(tester, isOnline: false);

      expect(find.textContaining('Connect to the internet'), findsOneWidget);
      expect(isEnabled(tester), isFalse);
    });

    group('with no password', () {
      testWidgets('there is no field, and a dialog confirms', (tester) async {
        final account = await open(tester, hasPassword: false);
        expect(find.byType(TextField), findsNothing);

        await tester.tap(button());
        await tester.pumpAndSettle();
        expect(find.text('Delete your account?'), findsOneWidget);
        expect(account.passwords, isEmpty);

        await tester.tap(button().last);
        await tester.pumpAndSettle();
        expect(account.passwords, [null]);
      });

      testWidgets('cancelling the dialog deletes nothing', (tester) async {
        final account = await open(tester, hasPassword: false);

        await tester.tap(button());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(account.passwords, isEmpty);
      });
    });
  });

  group('Sign in', () {
    late _WrongPassword auth;

    Future<void> pumpSignIn(WidgetTester tester, {bool isOnline = true}) {
      auth = _WrongPassword();
      return _pump(
        tester,
        const LoginScreen(),
        isOnline: isOnline,
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          serverUrlProvider.overrideWithValue('https://anchor.example.com'),
          oidcConfigProvider.overrideWith((ref) async => const OidcConfig()),
          registrationModeProvider.overrideWith(
            (ref) async => RegistrationMode.enabled,
          ),
        ],
      );
    }

    testWidgets('offline, it says signing in needs a connection', (
      tester,
    ) async {
      await pumpSignIn(tester, isOnline: false);

      expect(
        find.text('You’re offline. Connect to the internet to sign in.'),
        findsOneWidget,
      );
    });

    testWidgets('a malformed email is caught under the field', (tester) async {
      await pumpSignIn(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ada');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(_under('Email', 'Enter a valid email address.'), findsOneWidget);
      expect(auth.attempts, 0);
    });

    testWidgets('a wrong password says so above the fields', (tester) async {
      await pumpSignIn(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ada@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(auth.attempts, 1);
      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(_under('Password', 'Incorrect email or password.'), findsNothing);
      expect(_textIn(tester, 1), isEmpty);
    });

    testWidgets(
      'names the server after the title and rides Sign in on the keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(800 * 3, 900 * 3);
        tester.view.devicePixelRatio = 3;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        addTearDown(tester.view.reset);
        await pumpSignIn(tester);

        expect(find.text('Sign in to '), findsOneWidget);
        expect(find.text('anchor.example.com'), findsOneWidget);
        expect(
          tester.getRect(find.widgetWithText(AppButton, 'Sign in')).bottom,
          900 - 300 - 8,
        );
      },
    );
  });
}
