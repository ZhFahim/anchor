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
import '../../../core/widgets/app_snackbar.dart';
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
  final Map<_HeaderRow, CustomHeaderIssue> _headerIssues = {};
  bool _isAdvancedOpen = false;
  late final AppLifecycleListener _lifecycle;
  String? _unreachableAddress;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl;
    if (initial != null && initial.isNotEmpty) {
      _address.text = initial.startsWith('http://') ? initial : hostOf(initial);
    }
    _lifecycle = AppLifecycleListener(onResume: _retryUnreachable);
    _isAdvancedOpen = ref.read(allowSelfSignedCertProvider).value ?? false;
    final stored = ref.read(customHeadersProvider).value;
    if (stored != null) {
      _showStoredHeaders(stored);
    } else {
      Future.microtask(_loadHeaders);
    }
  }

  Future<void> _loadHeaders() async {
    final stored = await ref.read(customHeadersProvider.future);
    if (!mounted || _headerRows.isNotEmpty) return;
    setState(() => _showStoredHeaders(stored));
  }

  void _showStoredHeaders(List<CustomHeader> stored) {
    for (final header in stored) {
      _headerRows.add(_HeaderRow(name: header.name, value: header.value));
    }
    if (stored.isNotEmpty) _isAdvancedOpen = true;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _address.dispose();
    _focus.dispose();
    for (final row in _headerRows) {
      row.dispose();
    }
    super.dispose();
  }

  Iterable<_HeaderRow> get _liveRows =>
      _headerRows.where((row) => !row.isRemoved);

  void _addHeaderRow() {
    if (_liveRows.length >= maxCustomHeaders) return;
    final row = _HeaderRow(isShown: false);
    setState(() => _headerRows.add(row));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => row.isShown = true);
      row.nameFocus.requestFocus();
    });
  }

  void _removeHeaderRow(_HeaderRow row) {
    if (row.nameFocus.hasFocus || row.valueFocus.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      row.isRemoved = true;
      _headerIssues.remove(row);
    });
    _saveHeaders();
    AppSnackbar.show(
      context,
      context.l10n.serverHeaderRemoved,
      actionLabel: context.l10n.commonUndo,
      onAction: () {
        if (!mounted || _liveRows.length >= maxCustomHeaders) return;
        setState(() => row.isRemoved = false);
        _saveHeaders();
      },
      onClosed: (isUndone) {
        if (isUndone || !mounted || !row.isRemoved) return;
        setState(() => _headerRows.remove(row));
        WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
      },
    );
  }

  void _headerChanged(_HeaderRow row) {
    setState(() => _headerIssues.remove(row));
    _saveHeaders();
  }

  void _saveHeaders() {
    ref
        .read(customHeadersProvider.notifier)
        .set(validCustomHeadersOf([for (final row in _liveRows) row.header]));
  }

  bool _checkHeaders() {
    final rows = _liveRows.toList();
    final headers = [for (final row in rows) row.header];
    final issues = <_HeaderRow, CustomHeaderIssue>{
      for (var i = 0; i < rows.length; i++)
        rows[i]: ?customHeaderIssueOf(i, headers),
    };
    if (issues.isEmpty) return true;
    Haptics.warning();
    setState(() {
      _isAdvancedOpen = true;
      _headerIssues
        ..clear()
        ..addAll(issues);
    });
    final MapEntry(key: row, value: issue) = issues.entries.first;
    final isValueWrong = issue == CustomHeaderIssue.invalidValue;
    (isValueWrong ? row.valueFocus : row.nameFocus).requestFocus();
    return false;
  }

  void _retryUnreachable() {
    if (_address.text == _unreachableAddress && !isSubmitting()) _connect();
  }

  Future<void> _connect() async {
    _unreachableAddress = null;
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
        _unreachableAddress = _address.text;
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

  String? _headerNameError(_HeaderRow row) {
    final l10n = context.l10n;
    return switch (_headerIssues[row]) {
      CustomHeaderIssue.missingName => l10n.serverHeaderMissingName,
      CustomHeaderIssue.invalidName => l10n.serverHeaderInvalidName,
      CustomHeaderIssue.reservedName => l10n.serverHeaderReserved,
      CustomHeaderIssue.duplicateName => l10n.serverHeaderDuplicate,
      CustomHeaderIssue.invalidValue || null => null,
    };
  }

  String? _headerValueError(_HeaderRow row) =>
      _headerIssues[row] == CustomHeaderIssue.invalidValue
      ? context.l10n.serverHeaderInvalidValue
      : null;

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
                    children: [
                      for (final row in _headerRows)
                        Reveal(
                          key: ObjectKey(row),
                          visible: row.isShown && !row.isRemoved,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: density.space16),
                            child: _HeaderFields(
                              row: row,
                              nameError: _headerNameError(row),
                              valueError: _headerValueError(row),
                              onChanged: () => _headerChanged(row),
                              onRemove: () => _removeHeaderRow(row),
                            ),
                          ),
                        ),
                      _AddHeader(
                        isFull: _liveRows.length >= maxCustomHeaders,
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

class _HeaderRow {
  _HeaderRow({String name = '', String value = '', this.isShown = true})
    : nameField = TextEditingController(text: name),
      valueField = TextEditingController(text: value);

  final TextEditingController nameField;
  final TextEditingController valueField;
  final FocusNode nameFocus = FocusNode();
  final FocusNode valueFocus = FocusNode();

  bool isShown;
  bool isRemoved = false;

  CustomHeader get header => CustomHeader.of(nameField.text, valueField.text);

  void dispose() {
    nameField.dispose();
    valueField.dispose();
    nameFocus.dispose();
    valueFocus.dispose();
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.row,
    required this.nameError,
    required this.valueError,
    required this.onChanged,
    required this.onRemove,
  });

  final _HeaderRow row;
  final String? nameError;
  final String? valueError;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final density = context.density;
    final name = row.header.name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: density.space8,
            children: [
              AppTextField(
                controller: row.nameField,
                focusNode: row.nameFocus,
                semanticLabel: l10n.serverHeaderNameLabel,
                hint: l10n.serverHeaderNameHint,
                error: nameError,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(headerNameCharacter),
                ],
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => row.valueFocus.requestFocus(),
              ),
              AppTextField(
                controller: row.valueField,
                focusNode: row.valueFocus,
                semanticLabel: l10n.serverHeaderValueLabel,
                hint: l10n.serverHeaderValueHint,
                error: valueError,
                isPassword: true,
                showLabel: l10n.serverShowHeaderValue,
                hideLabel: l10n.serverHideHeaderValue,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(headerValueCharacter),
                ],
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: density.control,
          child: Center(
            child: BarButton(
              icon: LucideIcons.trash2,
              label: name.isEmpty
                  ? l10n.serverRemoveHeader
                  : l10n.serverRemoveNamedHeader(name),
              size: BarButtonSize.medium,
              color: context.anchor.appMuted,
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddHeader extends StatelessWidget {
  const _AddHeader({required this.isFull, required this.onAdd});

  final bool isFull;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      spacing: 12,
      children: [
        AppButton(
          label: l10n.serverAddHeader,
          icon: LucideIcons.plus,
          kind: AppButtonKind.secondary,
          size: AppButtonSize.medium,
          isExpanded: false,
          onPressed: isFull ? null : onAdd,
        ),
        if (isFull)
          Flexible(
            child: Text(
              l10n.serverHeaderLimit(maxCustomHeaders),
              style: AppTypography.secondary.copyWith(
                color: context.anchor.appMuted,
              ),
            ),
          ),
      ],
    );
  }
}
