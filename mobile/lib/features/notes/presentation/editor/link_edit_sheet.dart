import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/links/link_utils.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/anchor_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/l10n.dart';

class LinkEditSheet extends StatefulWidget {
  const LinkEditSheet({
    super.key,
    this.initialText = '',
    this.initialUrl = '',
    required this.onSubmit,
    this.onRemove,
  });

  final String initialText;
  final String initialUrl;
  final void Function(String text, String url) onSubmit;
  final VoidCallback? onRemove;

  static Future<void> show(
    BuildContext context, {
    String initialText = '',
    String initialUrl = '',
    required void Function(String text, String url) onSubmit,
    VoidCallback? onRemove,
  }) {
    return showAnchorSheet<void>(
      context,
      semanticLabel: initialUrl.isEmpty
          ? context.l10n.linkAdd
          : context.l10n.linkEdit,
      builder: (_) => LinkEditSheet(
        initialText: initialText,
        initialUrl: initialUrl,
        onSubmit: onSubmit,
        onRemove: onRemove,
      ),
    );
  }

  @override
  State<LinkEditSheet> createState() => _LinkEditSheetState();
}

class _LinkEditSheetState extends State<LinkEditSheet> {
  late final _text = TextEditingController(text: widget.initialText);
  late final _url = TextEditingController(text: widget.initialUrl);
  final _textFocus = FocusNode();
  final _urlFocus = FocusNode();

  bool get _isEditing => widget.initialUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
    if (!_isEditing) _prefillFromClipboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (widget.initialText.isEmpty && widget.initialUrl.isEmpty
              ? _textFocus
              : _urlFocus)
          .requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _url.dispose();
    _textFocus.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _prefillFromClipboard() async {
    try {
      final copied =
          (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
      if (mounted && _url.text.isEmpty && isLikelyUrl(copied)) {
        _url.text = copied.trim();
      }
    } catch (_) {}
  }

  bool get _canSave => isLikelyUrl(_url.text);

  void _save() {
    if (!_canSave) return;
    final url = normalizeUrl(_url.text.trim());
    final text = _text.text.trim().isEmpty
        ? _url.text.trim()
        : _text.text.trim();
    Haptics.success();
    widget.onSubmit(text, url);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: _isEditing ? l10n.linkEdit : l10n.linkAdd),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              spacing: context.density.space16,
              children: [
                AppTextField(
                  controller: _text,
                  focusNode: _textFocus,
                  icon: LucideIcons.type,
                  hint: l10n.linkTextHint,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _urlFocus.requestFocus(),
                ),
                AppTextField(
                  controller: _url,
                  focusNode: _urlFocus,
                  icon: LucideIcons.globe,
                  hint: 'https://',
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
        SheetFooter(
          children: [
            if (widget.onRemove != null)
              AppButton(
                label: l10n.commonRemove,
                icon: LucideIcons.unlink,
                kind: AppButtonKind.dangerText,
                onPressed: () {
                  widget.onRemove!();
                  Navigator.of(context).pop();
                },
              )
            else
              AppButton(
                label: l10n.commonCancel,
                kind: AppButtonKind.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            AppButton(
              label: _isEditing ? l10n.commonSave : l10n.linkAdd,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ],
    );
  }
}
