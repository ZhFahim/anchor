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
  _FakeServer(this.respond, {this.onRequest});

  final Future<ResponseBody> Function() respond;
  final void Function(RequestOptions options)? onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    onRequest?.call(options);
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

AuthService _answeringBody(int status, Map<String, Object?> body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://anchor.test'))
    ..httpClientAdapter = _FakeServer(
      () async => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  return AuthService(dio);
}

Future<AuthFailure> _failureOf(Future<Object?> request) async {
  try {
    await request;
  } on AuthFailure catch (failure) {
    return failure;
  }
  throw StateError('The request worked');
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

  group('the second step of signing in', () {
    Future<AuthFailure> login(int status, Map<String, Object?> body) =>
        _failureOf(
          _answeringBody(status, body).login('ada@example.com', 'secret'),
        );

    Future<AuthFailure> verify(int status, Map<String, Object?> body) =>
        _failureOf(
          _answeringBody(
            status,
            body,
          ).loginWithTwoFactor('challenge-1', code: '123456'),
        );

    test('a login that wants a code carries the challenge', () async {
      final failure = await login(401, {
        'statusCode': 401,
        'message': 'Two-factor code required',
        'error': 'Unauthorized',
        'twoFactorRequired': true,
        'challenge': 'challenge-1',
      });

      expect(failure, isA<TwoFactorRequiredFailure>());
      expect((failure as TwoFactorRequiredFailure).challenge, 'challenge-1');
    });

    test('a login that needs two-factor set up first', () async {
      final failure = await login(403, {
        'statusCode': 403,
        'message': 'Two-factor setup required',
        'error': 'Forbidden',
        'twoFactorSetupRequired': true,
        'challenge': 'enroll-1',
        'methods': {'totp': true, 'passkey': false},
      });

      expect(failure, isA<TwoFactorSetupRequiredFailure>());
    });

    test('a login that only a passkey can finish', () async {
      final failure = await login(403, {
        'statusCode': 403,
        'message': 'Sign in with your passkey',
        'error': 'Forbidden',
        'passkeyRequired': true,
      });

      expect(failure, isA<PasskeyRequiredFailure>());
      // Without the flag it's the usual refusal.
      expect(
        await login(403, {'message': 'Sign in with your passkey'}),
        isA<ServerFailure>(),
      );
    });

    test('the requests carry the challenge and one kind of code', () async {
      final bodies = <Object?>[];
      final service = AuthService(
        Dio(BaseOptions(baseUrl: 'https://anchor.test'))
          ..httpClientAdapter = _FakeServer(
            () async => ResponseBody.fromString(
              jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
            onRequest: (options) => bodies.add(options.data),
          ),
      );

      await service.loginWithTwoFactor('c1', code: '123456');
      await service.loginWithTwoFactor('c1', recoveryCode: 'k7m2-9xqp');

      expect(bodies, [
        {'challenge': 'c1', 'code': '123456'},
        {'challenge': 'c1', 'recoveryCode': 'k7m2-9xqp'},
      ]);
    });

    test('a wrong code and an expired challenge are told apart', () async {
      expect(
        await verify(401, {'message': 'Invalid code'}),
        isA<InvalidTwoFactorCodeFailure>(),
      );
      final expired = await verify(401, {'message': 'Challenge expired'});

      expect(expired, isA<ChallengeExpiredFailure>());
      expect(
        authErrorMessageOf(expired, _english).text,
        'Your sign-in timed out. Enter your email and password again.',
      );
    });

    test('too many wrong codes says how long to wait', () async {
      final failure = await verify(429, {
        'message': 'Too many attempts. Try again later.',
        'retryAfterSeconds': 600,
      });

      expect(failure, isA<TwoFactorLockedFailure>());
      expect(
        (failure as TwoFactorLockedFailure).retryAfter,
        const Duration(minutes: 10),
      );
      expect(
        authErrorMessageOf(failure, _english).text,
        'Too many wrong codes. Try again in 10 minutes.',
      );
    });

    test('a wait is rounded up to whole minutes', () {
      expect(lockMinutes(const Duration(seconds: 1)), 1);
      expect(lockMinutes(const Duration(seconds: 61)), 2);
      expect(lockMinutes(Duration.zero), 1);
      expect(
        _english.authCodeLockedUseRecovery(1),
        'Too many wrong codes. Try again in 1 minute.',
      );
      expect(
        _english.authCodeLockedUseRecovery(10),
        'Too many wrong codes. Try again in 10 minutes.',
      );
    });

    test('bodies from older or other servers fall back to the usual '
        'failures', () async {
      // A challenge without its flag, and the flag without a challenge.
      expect(
        await login(401, {'message': 'Invalid credentials', 'challenge': 'x'}),
        isA<InvalidCredentialsFailure>(),
      );
      expect(
        await login(401, {
          'message': 'Two-factor code required',
          'twoFactorRequired': true,
        }),
        isA<ServerFailure>(),
      );
      expect(
        await login(403, {
          'message': 'Two-factor setup required',
          'twoFactorSetupRequired': true,
        }),
        isA<ServerFailure>(),
      );
      // A rate limit that isn't about codes.
      expect(
        await login(429, {'message': 'ThrottlerException: Too Many Requests'}),
        isA<ServerFailure>(),
      );
      expect(
        await login(429, {'message': 'Slow down', 'retryAfterSeconds': 30}),
        isA<ServerFailure>(),
      );
      expect(await login(500, {'message': 'Oops'}), isA<ServerFailure>());
    });

    test('a body that is not an object is a plain server failure', () async {
      final service = AuthService(
        Dio(BaseOptions(baseUrl: 'https://anchor.test'))
          ..httpClientAdapter = _FakeServer(
            () async => ResponseBody.fromString(
              'Unauthorized',
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.textPlainContentType],
              },
            ),
          ),
      );

      expect(
        await _failureOf(service.login('ada@example.com', 'secret')),
        isA<ServerFailure>(),
      );
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
