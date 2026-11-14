import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anchor/core/network/api_error.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';
import 'package:anchor/features/auth/domain/auth_failure.dart';
import 'package:anchor/features/auth/domain/oidc_config.dart';
import 'package:anchor/features/auth/presentation/auth_error_message.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.respond);

  final Future<ResponseBody> Function() respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return respond();
  }

  @override
  void close({bool force = false}) {}
}

AuthService _answering(int status, Object message) {
  final dio = Dio(BaseOptions(baseUrl: 'https://anchor.test'))
    ..httpClientAdapter = _FakeServer(
      () async => ResponseBody.fromString(
        jsonEncode({'statusCode': status, 'message': message}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  return AuthService(dio);
}

Future<AuthFailure> _loginFailure(int status, Object message) async {
  try {
    await _answering(status, message).login('ada@example.com', 'secret');
  } on AuthFailure catch (failure) {
    return failure;
  }
  throw StateError('Signing in worked');
}

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  group('the server’s sign-in options', () {
    test('a server too old to have them offers passwords only', () async {
      expect(
        await _answering(404, 'Not Found').getOidcConfig(),
        const OidcConfig(),
      );
      expect(await _answering(404, 'Not Found').getRegistrationMode(), isNull);
    });

    test('a server that can’t be reached is not taken for one without '
        'them', () async {
      final unreachable = AuthService(
        Dio(BaseOptions(baseUrl: 'https://anchor.test'))
          ..httpClientAdapter = _FakeServer(
            () async => throw const SocketException('Connection refused'),
          ),
      );
      await expectLater(
        unreachable.getOidcConfig(),
        throwsA(isA<UnreachableFailure>()),
      );
      await expectLater(
        unreachable.getRegistrationMode(),
        throwsA(isA<UnreachableFailure>()),
      );
    });
  });

  test('deleting the only admin reads as its own failure', () {
    final failure = AuthFailure.fromResponse(
      409,
      'Make someone else an admin before deleting this account',
      error: const ServerApiError(),
    );

    expect(failure, isA<LastAdminFailure>());
  });

  group('the server’s answers', () {
    test('a wrong password', () async {
      expect(
        await _loginFailure(401, 'Invalid credentials'),
        isA<InvalidCredentialsFailure>(),
      );
    });

    test('password sign-in turned off is not a wrong password', () async {
      final failure = await _loginFailure(
        403,
        'Email and password sign-in is turned off. Sign in with Pocket ID.',
      );

      expect(failure, isA<PasswordSignInDisabledFailure>());
      expect(
        authErrorMessageOf(failure, _english).text,
        'Email and password sign-in is turned off. Sign in with Pocket ID.',
      );
    });

    test('password sign-up turned off names the provider too', () {
      final failure = AuthFailure.fromResponse(
        403,
        'Email and password sign-up is turned off. Sign up with Pocket ID.',
        error: const ServerApiError(),
      );

      expect(
        authErrorMessageOf(failure, _english).text,
        'Email and password sign-up is turned off. Sign up with Pocket ID.',
      );
    });

    test('an account waiting for approval', () async {
      expect(
        await _loginFailure(
          403,
          'Account pending approval. Please wait for an administrator to '
          'approve your account.',
        ),
        isA<PendingApprovalFailure>(),
      );
    });

    test('an account that signs in with a provider', () async {
      expect(
        await _loginFailure(
          401,
          'This account uses OIDC authentication. Please use the OIDC login '
          'option.',
        ),
        isA<PasswordlessAccountFailure>(),
      );
    });

    test('a malformed email goes under the email field', () async {
      final failure = await _loginFailure(400, ['email must be an email']);

      expect(failure, isA<InvalidInputFailure>());
      expect(authErrorMessageOf(failure, _english), (
        text: 'Enter a valid email address.',
        field: AuthField.email,
      ));
    });

    test('a taken email goes under the email field', () async {
      try {
        await _answering(
          409,
          'User already exists',
        ).register('ada@example.com', 'long enough', 'Ada');
        fail('Signing up worked');
      } on AuthFailure catch (failure) {
        expect(failure, isA<EmailTakenFailure>());
        expect(authErrorMessageOf(failure, _english).field, AuthField.email);
      }
    });

    test('a wrong current password and a reused one are told apart', () {
      final wrong = AuthFailure.fromResponse(
        403,
        'Current password is incorrect',
        error: const ServerApiError(),
      );
      final reused = AuthFailure.fromResponse(
        400,
        'New password must be different from current password',
        error: const ServerApiError(),
      );

      expect(
        authErrorMessageOf(wrong, _english).field,
        AuthField.currentPassword,
      );
      expect(authErrorMessageOf(reused, _english).field, AuthField.newPassword);
    });

    test('anything else shows the general message for the answer', () {
      final failure = AuthFailure.fromResponse(
        500,
        null,
        error: const ServerApiError(),
      );

      expect(failure, isA<ServerFailure>());
      expect(authErrorMessageOf(failure, _english), (
        text: 'Something went wrong. Try again.',
        field: null,
      ));
    });
  });

  test('no connection reads as an unreachable server', () {
    final failure = authFailureOf(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(failure, isA<UnreachableFailure>());
    expect(authErrorMessageOf(failure, _english).field, isNull);
  });
}
