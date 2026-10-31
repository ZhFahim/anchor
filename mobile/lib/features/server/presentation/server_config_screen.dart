import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/network/custom_headers.dart';
import '../../../core/network/server_address.dart';
import '../../../core/network/server_config_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_dialog.dart';
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
import '../../sync/data/sync_compatibility.dart';
import '../../sync/presentation/compatibility_messages.dart';
import '../data/server_connector.dart';
import 'harbor_illustration.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key, this.initialUrl});

  /// The server in use, when opened from sign in.
  final String? initialUrl;

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen>
    with FormSubmit {
  static const _addressField = #address;

  final _address = TextEditingController();
  final _focus = FocusNode();
  final List<_HeaderRow> _headerRows = [];
  final Map<int, CustomHeaderIssue> _headerIssues = {};
  bool _isAdvancedOpen = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl;
    if (initial != null && initial.isNotEmpty) {
      _address.text = initial.startsWith('http://') ? initial : hostOf(initial);
    }
    Future.microtask(_loadHeaders);
  }

  Future<void> _loadHeaders() async {
    final stored = await ref.read(customHeadersProvider.future);
    if (!mounted || _headerRows.isNotEmpty) return;
    setState(() {
      for (final header in stored) {
        _headerRows.add(_HeaderRow(name: header.name, value: header.value));
      }
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _focus.dispose();
    for (final row in _headerRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addHeaderRow() {
    if (_headerRows.length >= maxCustomHeaders) return;
    Haptics.selection();
    setState(() => _headerRows.add(_HeaderRow()));
    _saveHeaders();
  }

  void _removeHeaderRow(int index) {
    Haptics.selection();
    setState(() => _headerRows.removeAt(index));
    // The rows below shift up, so old errors can't be trusted anymore.
    _headerIssues.clear();
    _saveHeaders();
  }

  void _headerChanged(int index) {
    setState(() => _headerIssues.remove(index));
    _saveHeaders();
  }

  List<CustomHeader> get _headers => [
    for (final row in _headerRows) row.header,
  ];

  /// Keeps what's stored to what's safe to send.
  void _saveHeaders() {
    ref.read(customHeadersProvider.notifier).set(validCustomHeadersOf(_headers));
  }

  /// False when a row still has a problem; the errors are shown under it.
  bool _checkHeaders() {
    final issues = <int, CustomHeaderIssue>{};
    final headers = _headers;
    for (var i = 0; i < headers.length; i++) {
      final issue = customHeaderIssueOf(i, headers);
      if (issue != null) issues[i] = issue;
    }
    if (issues.isEmpty) return true;
    Haptics.warning();
    setState(() => _headerIssues..clear()..addAll(issues));
    return false;
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
    if (!_checkHeaders()) return;
    await submit(
      () => _connectTo(
        url!,
        isSchemeAdded:
            !typed.startsWith('http://') && !typed.startsWith('https://'),
      ),
      onFailure: (_) => showError(context.l10n.serverConnectFailed),
    );
  }

  Future<void> _connectTo(String url, {required bool isSchemeAdded}) async {
    final l10n = context.l10n;
    final host = hostOf(url);
    final allowSelfSigned =
        ref.read(allowSelfSignedCertProvider).value ?? false;
    final customHeaders =
        ref.read(customHeadersProvider).value ?? const <CustomHeader>[];
    final check = await ServerConnector(
      allowSelfSigned: allowSelfSigned,
      customHeaders: customHeaders,
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
    if (words != null) {
      if (!mounted) return;
      final isConfirmed = await showAnchorDialog(
        context,
        title: words.title,
        message: words.message,
        confirmLabel: l10n.serverConnectAnyway,
      );
      if (!isConfirmed) return;
    }
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

  void _fail(String errorMessage) {
    Haptics.warning();
    showError(errorMessage);
  }

  String? _headerIssueText(int index) {
    final issue = _headerIssues[index];
    if (issue == null) return null;
    final l10n = context.l10n;
    return switch (issue) {
      CustomHeaderIssue.invalidName => l10n.serverHeaderInvalidName,
      CustomHeaderIssue.reservedName =>
        l10n.serverHeaderReserved(_headerRows[index].header.name),
      CustomHeaderIssue.duplicateName => l10n.serverHeaderDuplicate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final isSelfSignedAllowed =
        ref.watch(allowSelfSignedCertProvider).value ?? false;
    final isBusy = isSubmitting();
    final density = context.density;
    final l10n = context.l10n;
    return FormPage(
      title: l10n.serverTitle,
      isTitleShown: false,
      cover: const HarborIllustration(),
      topPadding: density.space16,
      bottomBar: AppButton(
        label: l10n.commonContinue,
        busyLabel: l10n.serverConnecting,
        isBusy: isBusy,
        hasShadow: true,
        onPressed: isBusy ? null : _connect,
      ),
      children: [
        PageHeading(title: l10n.serverWelcome, subtitle: l10n.serverSubtitle),
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
                StackedListTile(
                  label: l10n.serverCustomHeaders,
                  subtitle: l10n.serverCustomHeadersHint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: density.space8,
                    children: [
                      for (var i = 0; i < _headerRows.length; i++)
                        _HeaderFields(
                          key: ValueKey(_headerRows[i]),
                          row: _headerRows[i],
                          error: _headerIssueText(i),
                          // Only a freshly added row is empty, and only it
                          // takes the focus.
                          autofocus: _headerRows[i].isEmpty,
                          onChanged: () => _headerChanged(i),
                          onRemove: () => _removeHeaderRow(i),
                        ),
                      _AddHeader(
                        count: _headerRows.length,
                        onAdd: _addHeaderRow,
                      ),
                    ],
                  ),
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

/// The name and value fields of one custom header.
class _HeaderRow {
  _HeaderRow({String name = '', String value = ''})
    : nameField = TextEditingController(text: name),
      valueField = TextEditingController(text: value);

  final TextEditingController nameField;
  final TextEditingController valueField;
  final FocusNode valueFocus = FocusNode();

  bool get isEmpty => nameField.text.isEmpty && valueField.text.isEmpty;

  CustomHeader get header => CustomHeader.of(nameField.text, valueField.text);

  void dispose() {
    nameField.dispose();
    valueField.dispose();
    valueFocus.dispose();
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    super.key,
    required this.row,
    required this.error,
    required this.autofocus,
    required this.onChanged,
    required this.onRemove,
  });

  final _HeaderRow row;
  final String? error;
  final bool autofocus;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  /// The characters a header name may hold; the rest are dropped as typed.
  static final RegExp _nameCharacters = RegExp(r"[!#$%&'*+\-.^_`|~0-9A-Za-z]");

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final l10n = context.l10n;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              flex: 2,
              child: _HeaderInput(
                controller: row.nameField,
                hint: l10n.serverHeaderNameHint,
                autofocus: autofocus,
                isError: hasError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(_nameCharacters),
                ],
                onChanged: onChanged,
                onSubmitted: (_) => row.valueFocus.requestFocus(),
              ),
            ),
            Expanded(
              flex: 3,
              child: _HeaderInput(
                controller: row.valueField,
                focusNode: row.valueFocus,
                hint: l10n.serverHeaderValueHint,
                isError: hasError,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                ],
                onChanged: onChanged,
              ),
            ),
            BarButton(
              icon: LucideIcons.trash2,
              label: l10n.serverRemoveHeader,
              size: BarButtonSize.medium,
              color: colors.appMuted,
              onPressed: onRemove,
            ),
          ],
        ),
        if (hasError)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              SizedBox(
                height: 16,
                child: Icon(
                  LucideIcons.circleAlert,
                  size: AnchorTokens.sizeIconSmall,
                  color: colors.statusDanger,
                ),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: AppTypography.secondary.copyWith(
                      color: colors.statusDanger,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _HeaderInput extends StatelessWidget {
  const _HeaderInput({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.autofocus = false,
    this.isError = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isError;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Container(
      height: AnchorTokens.sizeControlMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.appText.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
        border: Border.all(
          color: isError ? colors.statusDanger : colors.appFieldLine,
          width: isError ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: onSubmitted == null
            ? TextInputAction.done
            : TextInputAction.next,
        inputFormatters: inputFormatters,
        onChanged: onChanged == null ? null : (_) => onChanged!(),
        onSubmitted: onSubmitted,
        style: AppTypography.row.copyWith(color: colors.appText),
        cursorColor: colors.accentStrong,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppTypography.row.copyWith(color: colors.appMuted),
        ),
      ),
    );
  }
}

class _AddHeader extends StatelessWidget {
  const _AddHeader({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final l10n = context.l10n;
    final isFull = count >= maxCustomHeaders;
    return Row(
      spacing: 12,
      children: [
        BarTextButton(
          label: l10n.serverAddHeader,
          onPressed: isFull ? null : onAdd,
        ),
        Text(
          isFull
              ? l10n.serverHeaderLimit(maxCustomHeaders)
              : l10n.serverHeaderCount(count, maxCustomHeaders),
          style: AppTypography.secondary.copyWith(color: colors.appMuted),
        ),
      ],
    );
  }
}
