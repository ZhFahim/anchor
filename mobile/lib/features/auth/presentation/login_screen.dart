import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/network/server_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../l10n/l10n.dart';
import '../../server/presentation/server_link.dart';
import '../domain/auth_failure.dart';
import '../domain/registration_mode.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';
import 'oidc_config_provider.dart';
import 'registration_mode_provider.dart';
import 'two_factor_screen.dart';
import 'widgets/auth_widgets.dart';

enum _SignInMethod { password, provider }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with FormSubmit {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _failed(Object error) {
    switch (error) {
      case TwoFactorRequiredFailure(:final challenge):
        _continueWithCode(challenge);
        return;
      case TwoFactorSetupRequiredFailure():
        _password.clear();
        context.push(AppRoutes.twoFactorSetup);
        return;
      case PasskeyRequiredFailure():
        _password.clear();
        context.push(AppRoutes.passkeyOnWeb);
        return;
    }
    final errorMessage = authErrorMessageOf(error, context.l10n);
    showError(errorMessage.text, field: errorMessage.field);
    if (error is InvalidCredentialsFailure) {
      _password.clear();
      _passwordFocus.requestFocus();
    }
  }

  /// The password was right and the account has a second step. When that
  /// can't finish the sign-in starts over here, with the reason.
  Future<void> _continueWithCode(String challenge) async {
    final email = _email.text.trim();
    _password.clear();
    final ended = await context.push<AuthFailure>(
      AppRoutes.twoFactor,
      extra: TwoFactorChallenge(email: email, challenge: challenge),
    );
    if (ended != null && mounted) _failed(ended);
  }

  Future<void> _signIn() async {
    if (!checkFields([
      (AuthField.email, _emailFocus, emailError(_email.text, context.l10n)),
      (
        AuthField.password,
        _passwordFocus,
        passwordError(_password.text, context.l10n),
      ),
    ])) {
      return;
    }
    await submit(
      () => ref
          .read(authControllerProvider.notifier)
          .login(_email.text.trim(), _password.text),
      tag: _SignInMethod.password,
      onSuccess: Haptics.success,
      onFailure: _failed,
    );
  }

  Future<void> _signInWithProvider() => submit(
    () => ref.read(authControllerProvider.notifier).loginWithOidc(),
    tag: _SignInMethod.provider,
    onFailure: _failed,
  );

  @override
  Widget build(BuildContext context) {
    final isBusy = isSubmitting();
    final server = ref.watch(serverUrlProvider);
    final oidc = ref.watch(oidcConfigProvider).value;
    final registration = ref.watch(registrationModeProvider).value;
    final hasPasswords = oidc == null || !oidc.disableInternalAuth;
    final provider = oidc?.enabled == true ? oidc!.providerName : null;
    final density = context.density;
    final l10n = context.l10n;

    final providerButton = provider == null
        ? null
        : AppButton(
            label: l10n.authContinueWith(provider),
            busyLabel: l10n.authOpeningProvider(provider),
            isBusy: isSubmitting(_SignInMethod.provider),
            icon: LucideIcons.keyRound,
            kind: hasPasswords
                ? AppButtonKind.secondary
                : AppButtonKind.primary,
            hasShadow: !hasPasswords,
            onPressed: isBusy ? null : _signInWithProvider,
          );

    return FormPage(
      title: l10n.authSignIn,
      isTitleShown: false,
      showBack: false,
      topPadding: density.space32,
      bottomBar: hasPasswords
          ? AppButton(
              label: l10n.authSignIn,
              busyLabel: l10n.authSigningIn,
              isBusy: isSubmitting(_SignInMethod.password),
              hasShadow: true,
              onPressed: isBusy ? null : _signIn,
            )
          : providerButton,
      children: [
        PageHeading(
          title: l10n.authWelcomeBack,
          subtitle: server == null
              ? l10n.authSignInToAnchor
              : l10n.authSignInTo(PageHeading.linkSlot),
          subtitleLink: server == null
              ? null
              : ServerLink(
                  url: server,
                  onTap: () =>
                      context.push(AppRoutes.serverConfig, extra: server),
                ),
          hasIcon: true,
        ),
        SizedBox(height: density.space24),
        FormNotices(
          errorMessage: errorMessage,
          offlineText: l10n.authOfflineSignIn,
        ),
        if (providerButton != null && hasPasswords) ...[
          SizedBox(height: density.space8),
          providerButton,
          Padding(
            padding: EdgeInsets.symmetric(vertical: density.space16),
            child: const OrDivider(),
          ),
        ],
        if (hasPasswords) ...[
          AutofillGroup(
            child: Column(
              spacing: density.space16,
              children: [
                AppTextField(
                  controller: _email,
                  focusNode: _emailFocus,
                  label: l10n.fieldEmail,
                  error: errorOf(AuthField.email),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => clearError(AuthField.email),
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                AppTextField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  label: l10n.fieldPassword,
                  isPassword: true,
                  error: errorOf(AuthField.password),
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.go,
                  onChanged: (_) => clearError(AuthField.password),
                  onSubmitted: (_) => _signIn(),
                ),
              ],
            ),
          ),
        ],
        if (registration != RegistrationMode.disabled) ...[
          SizedBox(height: density.space16),
          AuthSwitchLink(
            text: l10n.authNewToAnchor,
            action: l10n.authCreateAnAccount,
            onTap: () => context.push(AppRoutes.register),
          ),
        ],
      ],
    );
  }
}
