import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/anchor_dialog.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/notice.dart';
import '../../../l10n/l10n.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen>
    with FormSubmit {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _delete({String? password}) => submit(
    () => ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: password),
    onSuccess: () => TextInput.finishAutofillContext(shouldSave: false),
    successMessage: context.l10n.deleteAccountDone,
    onFailure: (error) {
      final errorMessage = authErrorMessageOf(error, context.l10n);
      showError(errorMessage.text, field: errorMessage.field);
      if (errorMessage.field == AuthField.currentPassword) {
        _password.clear();
        _passwordFocus.requestFocus();
      }
    },
  );

  Future<void> _confirmThenDelete() async {
    final l10n = context.l10n;
    final isConfirmed = await showAnchorDialog(
      context,
      title: l10n.deleteAccountDialogTitle,
      message: l10n.deleteAccountDialogMessage,
      confirmLabel: l10n.deleteAccountConfirm,
      isDanger: true,
    );
    if (isConfirmed && mounted) await _delete();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final hasPassword =
        ref.watch(authControllerProvider).value?.hasPassword ?? true;
    final canDelete =
        isOnline &&
        !isSubmitting() &&
        (!hasPassword || _password.text.isNotEmpty);
    final density = context.density;
    final l10n = context.l10n;

    void onDelete() {
      if (hasPassword) {
        _delete(password: _password.text);
      } else {
        _confirmThenDelete();
      }
    }

    return FormPage(
      title: l10n.deleteAccountTitle,
      bottomBar: AppButton(
        label: l10n.deleteAccountConfirm,
        busyLabel: l10n.deleteAccountDeleting,
        kind: AppButtonKind.danger,
        isBusy: isSubmitting(),
        hasShadow: true,
        onPressed: canDelete ? onDelete : null,
      ),
      children: [
        FormNotices(
          errorMessage: errorMessage,
          offlineText: l10n.deleteAccountOffline,
        ),
        Notice(
          icon: LucideIcons.triangleAlert,
          kind: NoticeKind.danger,
          title: l10n.deleteAccountWarning,
          text: l10n.deleteAccountMessage,
        ),
        SizedBox(height: density.space16),
        Text(
          l10n.deleteAccountExport,
          style: AppTypography.secondary.copyWith(
            color: context.anchor.appMuted,
          ),
        ),
        if (hasPassword) ...[
          SizedBox(height: density.space16),
          AppTextField(
            controller: _password,
            focusNode: _passwordFocus,
            label: l10n.fieldPassword,
            isPassword: true,
            enabled: isOnline,
            error: errorOf(AuthField.currentPassword),
            help: l10n.deleteAccountPasswordHelp,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onChanged: (_) => clearError(AuthField.currentPassword),
            onSubmitted: (_) {
              if (canDelete) onDelete();
            },
          ),
        ],
      ],
    );
  }
}
