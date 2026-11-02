import '../../../core/network/api_error.dart';

sealed class AuthFailure implements Exception {
  const AuthFailure();

  /// [message] is a sentence, or a list for fields the server turned down.
  /// [error] stands for any answer not matched here.
  factory AuthFailure.fromResponse(
    int? status,
    Object? message, {
    required ApiError error,
  }) {
    if (status == 400 && message is List) {
      return InvalidInputFailure([
        for (final item in message) '$item'.split(' ').first,
      ]);
    }
    final serverMessage = message is String ? message : null;
    return switch ((status, serverMessage)) {
      (401, 'Invalid credentials') => const InvalidCredentialsFailure(),
      (401, final text?)
          when text.startsWith('This sign-in code has expired') =>
        const MagicCodeUsedFailure(),
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

/// A magic login code that ran out, or was used already.
final class MagicCodeUsedFailure extends AuthFailure {
  const MagicCodeUsedFailure();
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
