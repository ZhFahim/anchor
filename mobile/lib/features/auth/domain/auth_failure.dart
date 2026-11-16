import '../../../core/network/api_error.dart';

sealed class AuthFailure implements Exception {
  const AuthFailure();

  /// [message] is a sentence, or a list for fields the server turned down.
  /// [body] is the whole answer, for the second step of signing in.
  /// [error] stands for any answer not matched here.
  factory AuthFailure.fromResponse(
    int? status,
    Object? message, {
    required ApiError error,
    Map<dynamic, dynamic>? body,
  }) {
    final challenge = body?['challenge'];
    if (challenge is String && challenge.isNotEmpty) {
      if (status == 401 && body?['twoFactorRequired'] == true) {
        return TwoFactorRequiredFailure(challenge);
      }
      if (status == 403 && body?['twoFactorSetupRequired'] == true) {
        return const TwoFactorSetupRequiredFailure();
      }
    }
    if (status == 403 && body?['passkeyRequired'] == true) {
      return const PasskeyRequiredFailure();
    }
    final retryAfter = body?['retryAfterSeconds'];
    if (status == 429 &&
        retryAfter is num &&
        message is String &&
        message.startsWith('Too many attempts')) {
      return TwoFactorLockedFailure(
        Duration(seconds: retryAfter.isFinite ? retryAfter.ceil() : 0),
      );
    }
    if (status == 400 && message is List) {
      return InvalidInputFailure([
        for (final item in message) '$item'.split(' ').first,
      ]);
    }
    final serverMessage = message is String ? message : null;
    return switch ((status, serverMessage)) {
      (401, 'Invalid credentials') => const InvalidCredentialsFailure(),
      (401, 'Invalid code') => const InvalidTwoFactorCodeFailure(),
      (401, 'Challenge expired') => const ChallengeExpiredFailure(),
      (401, final text?) when text.startsWith('This account uses OIDC') =>
        const PasswordlessAccountFailure(),
      (401 || 403, final text?) when text.startsWith('Account pending') =>
        const PendingApprovalFailure(),
      (403, final text?) when text.startsWith('Email and password sign-') =>
        PasswordSignInDisabledFailure(
          provider: _providerPattern.firstMatch(text)?.group(1),
          isSignUp: text.startsWith('Email and password sign-up'),
        ),
      (403, 'Registration is disabled') => const RegistrationClosedFailure(),
      (403, 'Current password is incorrect') =>
        const WrongCurrentPasswordFailure(),
      (400, 'New password must be different from current password') =>
        const SamePasswordFailure(),
      (409, 'User already exists') => const EmailTakenFailure(),
      _ => ServerFailure(error),
    };
  }
}

/// The server ends with "Sign in with Pocket ID." or "Sign up with …".
final _providerPattern = RegExp(r'with (.+)\.$');

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class PasswordlessAccountFailure extends AuthFailure {
  const PasswordlessAccountFailure();
}

final class PendingApprovalFailure extends AuthFailure {
  const PendingApprovalFailure();
}

final class PasswordSignInDisabledFailure extends AuthFailure {
  const PasswordSignInDisabledFailure({this.provider, this.isSignUp = false});

  /// Null when the server's answer doesn't name it.
  final String? provider;
  final bool isSignUp;
}

final class RegistrationClosedFailure extends AuthFailure {
  const RegistrationClosedFailure();
}

final class EmailTakenFailure extends AuthFailure {
  const EmailTakenFailure();
}

final class WrongCurrentPasswordFailure extends AuthFailure {
  const WrongCurrentPasswordFailure();
}

final class SamePasswordFailure extends AuthFailure {
  const SamePasswordFailure();
}

/// [fields] are the server's field names, like `email` or `newPassword`.
final class InvalidInputFailure extends AuthFailure {
  const InvalidInputFailure(this.fields);

  final List<String> fields;
}

/// Signing in goes on with a code. The [challenge] stays in memory only.
final class TwoFactorRequiredFailure extends AuthFailure {
  const TwoFactorRequiredFailure(this.challenge);

  final String challenge;
}

/// The admin asks for a second factor that this account has not set up yet.
/// Mobile can't do that; the server's challenge is of no use here.
final class TwoFactorSetupRequiredFailure extends AuthFailure {
  const TwoFactorSetupRequiredFailure();
}

/// The admin asks for a second factor and the account has only passkeys,
/// which sign in on the web; a password alone is not enough.
final class PasskeyRequiredFailure extends AuthFailure {
  const PasskeyRequiredFailure();
}

final class InvalidTwoFactorCodeFailure extends AuthFailure {
  const InvalidTwoFactorCodeFailure();
}

/// The challenge ran out of time or of attempts; signing in starts over.
final class ChallengeExpiredFailure extends AuthFailure {
  const ChallengeExpiredFailure();
}

/// Too many wrong codes in a row.
final class TwoFactorLockedFailure extends AuthFailure {
  const TwoFactorLockedFailure(this.retryAfter);

  final Duration retryAfter;
}

final class UnreachableFailure extends AuthFailure {
  const UnreachableFailure();
}

final class ProviderNotSetUpFailure extends AuthFailure {
  const ProviderNotSetUpFailure();
}

final class ProviderSignInFailure extends AuthFailure {
  const ProviderSignInFailure([this.detail]);

  final String? detail;
}

final class ServerFailure extends AuthFailure {
  const ServerFailure(this.error);

  final ApiError error;
}
