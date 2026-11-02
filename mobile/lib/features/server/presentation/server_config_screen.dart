import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/network/server_address.dart';
import '../../../core/network/server_config_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_dialog.dart';
import '../../../core/widgets/anchor_plus_mark.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/switch_row.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/magic_link.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../auth/presentation/magic_login_scan_screen.dart';
import '../../sync/data/sync_compatibility.dart';
import '../../sync/presentation/compatibility_messages.dart';
import '../data/server_connector.dart';
import 'harbor_illustration.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key, this.initialUrl, this.magicLink});

  /// The server in use, when opened from sign in.
  final String? initialUrl;

  /// A magic link opened on this phone, to sign in with at once.
  final MagicLink? magicLink;

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen>
    with FormSubmit {
  static const _addressField = #address;

  final _address = TextEditingController();
  final _focus = FocusNode();
  bool _isAdvancedOpen = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl;
    if (initial != null && initial.isNotEmpty) {
      _address.text = initial.startsWith('http://') ? initial : hostOf(initial);
    }
    if (widget.magicLink case final link?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _signInWith(link);
      });
    }
  }

  @override
  void didUpdateWidget(ServerConfigScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final link = widget.magicLink;
    if (link != null && link != oldWidget.magicLink) _signInWith(link);
  }

  @override
  void dispose() {
    _address.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final typed = _address.text.trim();
    final url = normalizeServerUrl(typed);
    final error = typed.isEmpty
        ? context.l10n.serverEnterAddress
        : url == null
        ? context.l10n.serverEnterValidAddress
        : null;
    if (!checkFields([(_addressField, _focus, error)])) return;
    await submit(
      () => _connectTo(
        url!,
        isSchemeAdded:
            !typed.startsWith('http://') && !typed.startsWith('https://'),
      ),
      onFailure: (_) => showError(context.l10n.serverConnectFailed),
    );
  }

  Future<void> _scan() async {
    final link = await MagicLoginScanScreen.open(context);
    if (link != null && mounted) await _signInWith(link);
  }

  /// The server and the one-time code come from the web's magic login.
  Future<void> _signInWith(MagicLink link) async {
    final url = link.serverUrl;
    _address.text = url.startsWith('http://') ? url : hostOf(url);
    final l10n = context.l10n;
    await submit(
      () async {
        if (!await _isServerUsable(url, isSchemeAdded: false)) return;
        await ref.read(serverConfigProvider.notifier).setServerUrl(url);
        // Signing in waits for the switch to the new server to settle.
        final auth = ref.read(authControllerProvider.notifier);
        await ref.read(authControllerProvider.future);
        await auth.loginWithMagicCode(link.code);
        Haptics.success();
        if (mounted) context.go(AppRoutes.home);
      },
      tag: #magicLink,
      onFailure: (error) => showError(authErrorMessageOf(error, l10n).text),
    );
  }

  Future<void> _connectTo(String url, {required bool isSchemeAdded}) async {
    if (!await _isServerUsable(url, isSchemeAdded: isSchemeAdded)) return;
    if (!mounted) return;
    final serverConfig = ref.read(serverConfigProvider.notifier);
    Haptics.success();
    if (context.canPop()) {
      // Leave this screen first, then switch servers.
      context.pop();
      await serverConfig.setServerUrl(url);
    } else {
      // Sign in can't open until there is a server.
      await serverConfig.setServerUrl(url);
      if (mounted) context.go(AppRoutes.login);
    }
  }

  /// Shows why not, when not.
  Future<bool> _isServerUsable(
    String url, {
    required bool isSchemeAdded,
  }) async {
    final l10n = context.l10n;
    final host = hostOf(url);
    final allowSelfSigned =
        ref.read(allowSelfSignedCertProvider).value ?? false;
    final check = await ServerConnector(
      allowSelfSigned: allowSelfSigned,
    ).check(url);
    final List<int> protocols;
    switch (check) {
      case ServerFound(:final info):
        protocols = info.protocols;
      case NotAnchorServer():
        return _fail(l10n.serverNotAnchor(host));
      case UntrustedCertificate():
        return _fail(l10n.serverUntrusted(host));
      case ServerUnreachable():
        return _fail(
          isSchemeAdded
              ? l10n.serverUnreachableNoScheme(host)
              : l10n.serverUnreachable(host),
        );
    }

    final words = compatibilityMessagesOf(compatibilityFor(protocols), l10n);
    if (words == null) return mounted;
    if (!mounted) return false;
    return showAnchorDialog(
      context,
      title: words.title,
      message: words.message,
      confirmLabel: l10n.serverConnectAnyway,
    );
  }

  bool _fail(String errorMessage) {
    Haptics.warning();
    showError(errorMessage);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final isSelfSignedAllowed =
        ref.watch(allowSelfSignedCertProvider).value ?? false;
    final isBusy = isSubmitting();
    final isSigningIn = isSubmitting(#magicLink);
    final density = context.density;
    final l10n = context.l10n;
    return FormPage(
      title: l10n.serverTitle,
      isTitleShown: false,
      cover: const HarborIllustration(),
      topPadding: density.space16,
      bottomBar: AppButton(
        label: l10n.commonContinue,
        busyLabel: isSigningIn
            ? l10n.magicLoginSigningIn
            : l10n.serverConnecting,
        isBusy: isBusy,
        hasShadow: true,
        onPressed: isBusy ? null : _connect,
      ),
      children: [
        PageHeading(
          title: l10n.serverWelcome,
          subtitle: l10n.serverSubtitle,
          titleMark: const AnchorPlusMark(size: AnchorPlusMark.titleSize),
        ),
        SizedBox(height: density.space24),
        FormNotices(errorMessage: errorMessage),
        AppTextField(
          controller: _address,
          focusNode: _focus,
          label: l10n.serverAddress,
          icon: LucideIcons.globe,
          hint: l10n.serverAddressHint,
          keyboardType: TextInputType.url,
          autocorrect: false,
          autofillHints: const [AutofillHints.url],
          textInputAction: TextInputAction.go,
          error: errorOf(_addressField),
          onChanged: (_) => clearError(_addressField),
          onSubmitted: (_) => _connect(),
        ),
        SizedBox(height: density.space12),
        AppButton(
          label: l10n.magicLoginScan,
          icon: LucideIcons.scanQrCode,
          kind: AppButtonKind.secondary,
          onPressed: isBusy ? null : _scan,
        ),
        SizedBox(height: density.space16),
        _AdvancedToggle(
          isOpen: _isAdvancedOpen,
          onTap: () => setState(() => _isAdvancedOpen = !_isAdvancedOpen),
        ),
        Reveal(
          visible: _isAdvancedOpen,
          child: Padding(
            padding: EdgeInsets.only(top: density.space8),
            child: GroupedList(
              children: [
                SwitchRow(
                  label: l10n.serverSelfSigned,
                  subtitle: isSelfSignedAllowed
                      ? l10n.serverSelfSignedWarning
                      : null,
                  value: isSelfSignedAllowed,
                  onChanged: (on) =>
                      ref.read(allowSelfSignedCertProvider.notifier).toggle(on),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: density.space24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              LucideIcons.info,
              size: AnchorTokens.sizeIconSmall,
              color: colors.appMuted,
            ),
            Flexible(
              child: Text(
                l10n.serverSelfHosted,
                style: AppTypography.secondary.copyWith(color: colors.appMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        style: PressStyle.plain,
        onTap: () {
          Haptics.selection();
          onTap();
        },
        semanticLabel: isOpen
            ? context.l10n.commonExpandedItem(context.l10n.serverAdvanced)
            : context.l10n.commonCollapsedItem(context.l10n.serverAdvanced),
        minSize: const Size.square(AnchorTokens.sizeTargetTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              AnimatedRotation(
                turns: isOpen ? 0.25 : 0,
                duration: context.motion(Spring.snappy.duration),
                curve: Spring.snappy.curve,
                child: Icon(
                  LucideIcons.chevronRight,
                  size: AnchorTokens.sizeIconSmall,
                  color: colors.appMuted,
                ),
              ),
              Text(
                context.l10n.serverAdvanced,
                style: AppTypography.secondary.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.appMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
