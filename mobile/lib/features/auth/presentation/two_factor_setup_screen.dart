import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/links/link_utils.dart';
import '../../../core/network/server_address.dart';
import '../../../core/network/server_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../l10n/l10n.dart';

/// The admin asks for two-factor and the account has none. It is set up on
/// the web; the phone only says so and opens the server. With
/// [needsPasskey] the account has passkeys only, which sign in on the web.
class TwoFactorSetupScreen extends ConsumerWidget {
  const TwoFactorSetupScreen({super.key, this.needsPasskey = false});

  final bool needsPasskey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final density = context.density;
    final colors = context.anchor;
    final server = ref.watch(serverUrlProvider);
    final title = needsPasskey ? l10n.authPasskeyTitle : l10n.authSetupTitle;
    return FormPage(
      title: title,
      isTitleShown: false,
      showBack: false,
      topPadding: density.space32,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: density.space8,
        children: [
          if (server != null)
            AppButton(
              label: l10n.authSetupOpen(hostOf(server)),
              icon: LucideIcons.externalLink,
              hasShadow: true,
              onPressed: () => launchExternal(context, server),
            ),
          AppButton(
            label: l10n.authBackToSignIn,
            kind: AppButtonKind.secondary,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: AnchorTokens.space48,
            height: AnchorTokens.space48,
            decoration: BoxDecoration(
              color: colors.accentStrong.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: AnchorTokens.sizeIconLarge,
              color: colors.accentInk,
            ),
          ),
        ),
        SizedBox(height: density.space16),
        PageHeading(
          title: title,
          subtitle: needsPasskey
              ? l10n.authPasskeyMessage
              : l10n.authSetupMessage,
        ),
      ],
    );
  }
}
