import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'link_utils.dart';

class LinkEditSheet extends StatefulWidget {
  final String initialText;
  final String initialUrl;
  final void Function(String text, String url) onSubmit;
  final VoidCallback? onRemove;

  const LinkEditSheet({
    super.key,
    this.initialText = '',
    this.initialUrl = '',
    required this.onSubmit,
    this.onRemove,
  });

  static Future<void> show(
    BuildContext context, {
    String initialText = '',
    String initialUrl = '',
    required void Function(String text, String url) onSubmit,
    VoidCallback? onRemove,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  late final TextEditingController _textController;
  late final TextEditingController _urlController;
  late final FocusNode _urlFocus;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _urlController = TextEditingController(text: widget.initialUrl);
    _urlController.addListener(_onUrlChanged);
    _urlFocus = FocusNode();
    if (widget.initialUrl.isEmpty) {
      _maybePrefillFromClipboard();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _urlFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _textController.dispose();
    _urlController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _maybePrefillFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (!mounted) return;
      if (_urlController.text.isEmpty && isLikelyUrl(text)) {
        _urlController.text = text.trim();
      }
    } catch (_) {}
  }

  void _onUrlChanged() => setState(() {});

  bool get _isEditing => widget.initialUrl.isNotEmpty;

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    final text = _textController.text.trim().isEmpty
        ? url
        : _textController.text.trim();
    widget.onSubmit(text, url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final trimmedUrl = _urlController.text.trim();
    final canSubmit = trimmedUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
                : [Colors.white, const Color(0xFFF8F9FC)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HandleBar(theme: theme),
            _Header(
              theme: theme,
              isEditing: _isEditing,
              onClose: () => Navigator.pop(context),
            ),
            _TextField(
              controller: _textController,
              label: 'Text',
              hint: trimmedUrl.isEmpty ? 'Link text' : trimmedUrl,
              icon: LucideIcons.type,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            ),
            _TextField(
              controller: _urlController,
              focusNode: _urlFocus,
              label: 'URL',
              hint: 'https://...',
              icon: LucideIcons.globe,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            ),
            _Actions(
              theme: theme,
              isEditing: _isEditing,
              canSubmit: canSubmit,
              onSubmit: _submit,
              onRemove: widget.onRemove == null
                  ? null
                  : () {
                      widget.onRemove!.call();
                      Navigator.pop(context);
                    },
              bottomPadding: safeBottom > 0 ? safeBottom + 8 : 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  final ThemeData theme;
  const _HandleBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ThemeData theme;
  final bool isEditing;
  final VoidCallback onClose;

  const _Header({
    required this.theme,
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.link,
              color: theme.colorScheme.tertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isEditing ? 'Edit Link' : 'Insert Link',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final EdgeInsets padding;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.padding,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.dmSans(),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(),
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ThemeData theme;
  final bool isEditing;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback? onRemove;
  final double bottomPadding;

  const _Actions({
    required this.theme,
    required this.isEditing,
    required this.canSubmit,
    required this.onSubmit,
    required this.onRemove,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final showRemove = isEditing && onRemove != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      child: Row(
        children: [
          if (showRemove) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.unlink, size: 16),
                label: Text(
                  'Remove',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isEditing ? 'Save' : 'Insert',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
