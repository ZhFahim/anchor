import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../l10n/l10n.dart';
import '../domain/auth_failure.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';
import 'widgets/auth_widgets.dart';

/// What the second step of signing in needs. Lives in the route only, never
/// on disk.
class TwoFactorChallenge {
  const TwoFactorChallenge({required this.email, required this.challenge});

  final String email;
  final String challenge;
}

const _codeLength = 6;

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key, required this.challenge});

  final TwoFactorChallenge challenge;

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen>
    with FormSubmit {
  final _code = TextEditingController();
  final _recovery = TextEditingController();
  final _codeFocus = FocusNode();
  final _recoveryFocus = FocusNode();
  bool _isRecovery = false;

  // Too many wrong codes: which step it was on, and until the timer is up.
  ({Duration retryAfter, bool isRecovery})? _lock;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _code.dispose();
    _recovery.dispose();
    _codeFocus.dispose();
    _recoveryFocus.dispose();
    super.dispose();
  }

  bool get _isLocked => _lock?.isRecovery == _isRecovery;

  void _switchStep() {
    // The error of the other step doesn't belong here.
    checkFields(const []);
    setState(() => _isRecovery = !_isRecovery);
  }

  void _locked(TwoFactorLockedFailure failure) {
    _lockTimer?.cancel();
    _lockTimer = Timer(failure.retryAfter, () {
      if (!mounted) return;
      setState(() => _lock = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isRecovery) _codeFocus.requestFocus();
      });
    });
    setState(
      () => _lock = (retryAfter: failure.retryAfter, isRecovery: _isRecovery),
    );
  }

  void _failed(Object error) {
    final controller = _isRecovery ? _recovery : _code;
    final focus = _isRecovery ? _recoveryFocus : _codeFocus;
    switch (error) {
      case ChallengeExpiredFailure():
        // Signing in starts over; the sign-in page says why.
        if (context.canPop()) {
          context.pop<AuthFailure>(error);
        } else {
          context.go(AppRoutes.login);
        }
        return;
      case TwoFactorLockedFailure():
        controller.clear();
        _locked(error);
      case InvalidTwoFactorCodeFailure():
        controller.clear();
        focus.requestFocus();
        final errorMessage = authErrorMessageOf(error, context.l10n);
        showError(errorMessage.text);
      default:
        final errorMessage = authErrorMessageOf(error, context.l10n);
        showError(errorMessage.text);
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    final String? code;
    final String? recoveryCode;
    if (_isRecovery) {
      code = null;
      recoveryCode = _recovery.text.trim();
      if (recoveryCode.isEmpty) return _incomplete(l10n.authEnterRecoveryCode);
    } else {
      code = _code.text;
      recoveryCode = null;
      if (code.length != _codeLength) {
        return _incomplete(l10n.authEnterCode);
      }
    }
    await submit(
      () => ref
          .read(authControllerProvider.notifier)
          .loginWithTwoFactor(
            widget.challenge.challenge,
            code: code,
            recoveryCode: recoveryCode,
          ),
      onSuccess: Haptics.success,
      onFailure: _failed,
    );
  }

  void _incomplete(String text) {
    Haptics.warning();
    showError(text);
    (_isRecovery ? _recoveryFocus : _codeFocus).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final density = context.density;
    final isBusy = isSubmitting();
    final isLocked = _isLocked;
    final lockedText = switch (_lock) {
      (:final retryAfter, :final isRecovery) when isLocked =>
        isRecovery
            ? l10n.authCodeLocked(lockMinutes(retryAfter))
            : l10n.authCodeLockedUseRecovery(lockMinutes(retryAfter)),
      _ => null,
    };
    final notice = lockedText ?? errorMessage;

    return FormPage(
      title: _isRecovery ? l10n.authRecoveryTitle : l10n.authTwoFactorTitle,
      isTitleShown: false,
      topPadding: density.space32,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: l10n.authVerify,
            busyLabel: l10n.authVerifying,
            isBusy: isBusy,
            hasShadow: true,
            onPressed: isBusy || isLocked ? null : _verify,
          ),
          AuthTextLink(
            label: _isRecovery
                ? l10n.authUseAuthenticatorCode
                : l10n.authUseRecoveryCode,
            onTap: isBusy ? null : _switchStep,
          ),
        ],
      ),
      children: [
        PageHeading(
          title: _isRecovery ? l10n.authRecoveryTitle : l10n.authTwoFactorTitle,
          subtitle: _isRecovery
              ? l10n.authRecoverySubtitle
              : l10n.authTwoFactorSubtitle(widget.challenge.email),
        ),
        SizedBox(height: density.space24),
        FormNotices(errorMessage: notice, offlineText: l10n.authCodeOffline),
        if (_isRecovery)
          AppTextField(
            key: const ValueKey('recovery'),
            controller: _recovery,
            focusNode: _recoveryFocus,
            label: l10n.fieldRecoveryCode,
            hint: 'xxxxx-xxxxx',
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _verify(),
          )
        else
          CodeBoxes(
            key: const ValueKey('code'),
            controller: _code,
            focusNode: _codeFocus,
            semanticLabel: l10n.authTwoFactorCodeLabel,
            enabled: !isLocked,
            hasError: errorMessage != null && !isLocked,
            onSubmitted: (_) => _verify(),
          ),
      ],
    );
  }
}
