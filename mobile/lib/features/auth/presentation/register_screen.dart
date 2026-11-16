import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../l10n/l10n.dart';
import '../../notes/domain/note_dates.dart';
import '../domain/account_rules.dart';
import '../domain/auth_failure.dart';
import '../domain/registration_mode.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';
import 'registration_mode_provider.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with FormSubmit {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isWaitingForApproval = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password]) {
      controller.dispose();
    }
    for (final focus in [_nameFocus, _emailFocus, _passwordFocus]) {
      focus.dispose();
    }
    super.dispose();
  }

  FocusNode? _focusOf(AuthField? field) => switch (field) {
    AuthField.name => _nameFocus,
    AuthField.email => _emailFocus,
    AuthField.password => _passwordFocus,
    _ => null,
  };

  Future<void> _create() async {
    if (!checkFields([
      (AuthField.name, _nameFocus, nameError(_name.text, context.l10n)),
      (AuthField.email, _emailFocus, emailError(_email.text, context.l10n)),
      (
        AuthField.password,
        _passwordFocus,
        newPasswordError(_password.text, context.l10n),
      ),
    ])) {
      return;
    }
    final name = _name.text.trim();
    var isSignedIn = false;
    final isCreated = await submit(
      () async => isSignedIn = await ref
          .read(authControllerProvider.notifier)
          .register(_email.text.trim(), _password.text, name),
      onFailure: (error) {
        if (error is TwoFactorSetupRequiredFailure) {
          // The account exists; two-factor is set up on the web.
          context.push(AppRoutes.twoFactorSetup);
          return;
        }
        final errorMessage = authErrorMessageOf(error, context.l10n);
        showError(errorMessage.text, field: errorMessage.field);
        _focusOf(errorMessage.field)?.requestFocus();
      },
    );
    if (!isCreated || !mounted) return;
    if (isSignedIn) {
      // The router opens the notes now that the app is signed in.
      AppSnackbar.show(
        context,
        context.l10n.authWelcomeName(firstNameOf(name)),
        kind: SnackbarKind.success,
      );
    } else {
      setState(() => _isWaitingForApproval = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWaitingForApproval) return const _WaitingForApprovalPage();
    final isBusy = isSubmitting();
    final isReviewed =
        ref.watch(registrationModeProvider).value == RegistrationMode.review;
    final density = context.density;
    final l10n = context.l10n;
    return FormPage(
      title: l10n.authCreateAccount,
      isTitleShown: false,
      topPadding: density.space32,
      bottomBar: AppButton(
        label: l10n.authCreateAccount,
        busyLabel: l10n.authCreatingAccount,
        isBusy: isBusy,
        hasShadow: true,
        onPressed: isBusy ? null : _create,
      ),
      children: [
        PageHeading(
          hasIcon: true,
          title: l10n.authCreateYourAccount,
          subtitle: isReviewed
              ? l10n.authApprovalNeeded
              : l10n.authRegisterSubtitle,
        ),
        SizedBox(height: density.space24),
        FormNotices(errorMessage: errorMessage),
        AutofillGroup(
          child: Column(
            spacing: density.space16,
            children: [
              AppTextField(
                controller: _name,
                focusNode: _nameFocus,
                label: l10n.fieldName,
                hint: l10n.fieldNameHint,
                error: errorOf(AuthField.name),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                inputFormatters: [
                  LengthLimitingTextInputFormatter(maxNameLength),
                ],
                textInputAction: TextInputAction.next,
                onChanged: (_) => clearError(AuthField.name),
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              AppTextField(
                controller: _email,
                focusNode: _emailFocus,
                label: l10n.fieldEmail,
                hint: l10n.fieldEmailHint,
                error: errorOf(AuthField.email),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
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
                help: l10n.passwordHelp(minPasswordLength),
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.go,
                onChanged: (_) => clearError(AuthField.password),
                onSubmitted: (_) => _create(),
              ),
            ],
          ),
        ),
        SizedBox(height: density.space16),
        AuthSwitchLink(
          text: l10n.authAlreadyHaveAccount,
          action: l10n.authSignIn,
          onTap: () => context.pop(),
        ),
      ],
    );
  }
}

class _WaitingForApprovalPage extends StatelessWidget {
  const _WaitingForApprovalPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final density = context.density;
    final l10n = context.l10n;
    return FormPage(
      title: l10n.authWaitingTitle,
      isTitleShown: false,
      showBack: false,
      topPadding: density.space48,
      children: [
        Center(
          child: SizedBox(
            width: 132, // off-scale: the empty-state drawing
            height: 96, // off-scale: as above
            child: Stack(
              children: [
                const EmptyStateIllustration(kind: EmptyStateKind.notes),
                Positioned(
                  right: 16,
                  bottom: 2, // off-scale: on the drawing's corner
                  child: Container(
                    width: AnchorTokens.sizeControlSmall,
                    height: AnchorTokens.sizeControlSmall,
                    decoration: BoxDecoration(
                      color: colors.appSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.appBorder),
                    ),
                    child: Icon(
                      LucideIcons.hourglass,
                      size: AnchorTokens.sizeIconSmall,
                      color: colors.accentStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: density.space24),
        PageHeading(
          title: l10n.authWaitingTitle,
          subtitle: l10n.authWaitingMessage,
          isCentered: true,
        ),
        SizedBox(height: density.space24),
        Center(
          child: AppButton(
            label: l10n.authBackToSignIn,
            icon: LucideIcons.arrowLeft,
            kind: AppButtonKind.secondary,
            isExpanded: false,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      ],
    );
  }
}
