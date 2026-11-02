import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/network/api_error_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/account_rules.dart';
import '../domain/auth_failure.dart';

enum AuthField { name, email, password, currentPassword, newPassword }

/// A null [field] puts the text at the top of the form.
typedef AuthErrorMessage = ({String text, AuthField? field});

/// Any error other than an [AuthFailure] is logged as a bug.
AuthErrorMessage authErrorMessageOf(
  Object error,
  AppLocalizations l10n,
) => switch (error) {
  InvalidCredentialsFailure() => (
    text: l10n.authIncorrectCredentials,
    field: null,
  ),
  MagicCodeUsedFailure() => (text: l10n.authMagicCodeUsed, field: null),
  PasswordlessAccountFailure() => (text: l10n.authPasswordless, field: null),
  PendingApprovalFailure() => (text: l10n.authPendingApproval, field: null),
  PasswordSignInDisabledFailure(:final provider, :final isSignUp) => (
    text: switch ((provider, isSignUp)) {
      (final provider?, false) => l10n.authPasswordSignInOff(provider),
      (final provider?, true) => l10n.authPasswordSignUpOff(provider),
      (null, false) => l10n.authPasswordSignInOffHere,
      (null, true) => l10n.authPasswordSignUpOffHere,
    },
    field: null,
  ),
  RegistrationClosedFailure() => (
    text: l10n.authRegistrationClosed,
    field: null,
  ),
  EmailTakenFailure() => (text: l10n.authEmailTaken, field: AuthField.email),
  WrongCurrentPasswordFailure() => (
    text: l10n.authWrongCurrentPassword,
    field: AuthField.currentPassword,
  ),
  SamePasswordFailure() => (
    text: l10n.authSamePassword,
    field: AuthField.newPassword,
  ),
  InvalidInputFailure(:final fields) => _invalidInput(fields.firstOrNull, l10n),
  UnreachableFailure() => (text: l10n.authUnreachable, field: null),
  ProviderNotSetUpFailure() => (text: l10n.authProviderNotSetUp, field: null),
  ProviderSignInFailure(:final detail) => (
    text: detail == null
        ? l10n.authProviderFailed
        : l10n.authProviderFailedWith(detail),
    field: null,
  ),
  ServerFailure(error: final apiError) => (
    text: apiErrorText(apiError, l10n),
    field: null,
  ),
  _ => _unexpected(error, l10n),
};

String? nameError(String name, AppLocalizations l10n) =>
    isNameValid(name) ? null : l10n.authEnterName;

String? emailError(String email, AppLocalizations l10n) => email.trim().isEmpty
    ? l10n.authEnterEmail
    : isEmailValid(email)
    ? null
    : l10n.authEnterValidEmail;

String? passwordError(String password, AppLocalizations l10n) =>
    password.isEmpty ? l10n.authEnterPassword : null;

String? newPasswordError(String password, AppLocalizations l10n) =>
    isNewPasswordValid(password)
    ? null
    : l10n.authPasswordTooShort(minPasswordLength);

AuthErrorMessage _unexpected(Object error, AppLocalizations l10n) {
  AppLogger.instance.error(
    LogTags.auth,
    'Account request failed',
    error: error,
  );
  return (text: l10n.errorGeneric, field: null);
}

AuthErrorMessage _invalidInput(String? serverField, AppLocalizations l10n) =>
    switch (serverField) {
      'name' => (text: l10n.authEnterName, field: AuthField.name),
      'email' => (text: l10n.authEnterValidEmail, field: AuthField.email),
      'password' => (
        text: l10n.authPasswordTooShort(minPasswordLength),
        field: AuthField.password,
      ),
      'currentPassword' => (
        text: l10n.authEnterCurrentPassword,
        field: AuthField.currentPassword,
      ),
      'newPassword' => (
        text: l10n.authPasswordTooShort(minPasswordLength),
        field: AuthField.newPassword,
      ),
      _ => (text: l10n.errorCheckInput, field: null),
    };
