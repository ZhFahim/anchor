import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_snackbar.dart';
import 'editor/checklist_reorder_mixin.dart';
import 'editor/editor_styles.dart';
import 'editor/editor_toolbar.dart';
import 'editor/link_actions_sheet.dart';
import 'editor/link_edit_sheet.dart';
import 'editor/link_utils.dart';

/// A reusable rich text editor widget powered by flutter_quill.
///
/// Content is stored and loaded as JSON Delta format.
class RichTextEditor extends StatefulWidget {
  /// Initial content in JSON Delta format.
  final String? initialContent;

  /// Callback when content changes. Returns JSON Delta string.
  final ValueChanged<String>? onChanged;

  /// Callback when editing state changes (focus gained/lost).
  final ValueChanged<bool>? onEditingChanged;

  /// Hint text shown when editor is empty.
  final String hintText;

  /// Whether to show the toolbar.
  final bool showToolbar;

  /// Whether the editor can be edited.
  final bool canEdit;

  /// Focus node for the editor.
  final FocusNode? focusNode;

  /// Padding for the editor content.
  final EdgeInsets contentPadding;

  /// Whether to sort checklist items (checked to bottom, unchecked to top).
  final bool sortChecklistItems;

  /// Optional header widget placed above the editor, scrolling together.
  final Widget? header;

  const RichTextEditor({
    super.key,
    this.initialContent,
    this.onChanged,
    this.onEditingChanged,
    this.hintText = 'Start typing...',
    this.showToolbar = true,
    this.canEdit = true,
    this.focusNode,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 16),
    this.sortChecklistItems = true,
    this.header,
  });

  @override
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor>
    with ChecklistReorderMixin {
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  bool _isInternalFocusNode = false;
  bool _isEditing = false;
  EditorFormattingState _formattingState = const EditorFormattingState();

  // ChecklistReorderMixin requirements
  @override
  QuillController get controller => _controller;

  @override
  bool get sortChecklistItems => widget.sortChecklistItems;

  @override
  void onContentChanged() => _notifyChange();

  @override
  void rebuildController(Document newDocument, int cursorPos) {
    _removeListeners();
    _controller.dispose();
    _controller = QuillController(
      document: newDocument,
      selection: TextSelection.collapsed(
        offset: cursorPos.clamp(0, newDocument.length - 1),
      ),
    );
    _addListeners();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialContent);
    _controller.readOnly = !widget.canEdit;
    _scrollController = ScrollController();
    _addListeners();
    initChecklistState();

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canEdit != widget.canEdit) {
      _controller.readOnly = !widget.canEdit;
    }
  }

  @override
  void dispose() {
    _removeListeners();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _scrollController.dispose();
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _addListeners() {
    _controller.addListener(_notifyChange);
    _controller.addListener(_updateFormattingState);
    _controller.addListener(onDocumentChanged);
  }

  void _removeListeners() {
    _controller.removeListener(_notifyChange);
    _controller.removeListener(_updateFormattingState);
    _controller.removeListener(onDocumentChanged);
  }

  void _onFocusChanged() {
    final wasEditing = _isEditing;
    final hasFocus = _focusNode.hasFocus;

    if (!widget.canEdit && hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      setState(() => _isEditing = false);
    } else {
      setState(() => _isEditing = hasFocus);
    }

    if (wasEditing != _isEditing && widget.canEdit) {
      widget.onEditingChanged?.call(_isEditing);
    }
  }

  void _updateFormattingState() {
    if (!mounted) return;
    setState(() {
      _formattingState = EditorFormattingState.fromController(_controller);
    });
  }

  QuillController _createController(String? content) {
    // ignore: experimental_member_use
    final config = QuillControllerConfig(
      // ignore: experimental_member_use
      clipboardConfig: QuillClipboardConfig(
        // ignore: experimental_member_use
        onClipboardPaste: _onClipboardPaste,
      ),
    );

    if (content == null || content.isEmpty) {
      return QuillController.basic(config: config);
    }

    try {
      final json = jsonDecode(content);
      if (json is Map && json['ops'] is List) {
        final document = Document.fromJson(json['ops'] as List);
        return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
          config: config,
        );
      }
    } catch (_) {
      // Invalid JSON -> fall through to empty document
    }

    return QuillController.basic(config: config);
  }

  Future<bool> _onClipboardPaste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = clip?.text?.trim() ?? '';
    if (!isLikelyUrl(raw)) return false;

    final sel = _controller.selection;
    if (!sel.isValid) return false;

    if (sel.isCollapsed) {
      _controller.replaceText(
        sel.start,
        0,
        raw,
        TextSelection.collapsed(offset: sel.start + raw.length),
      );
      _controller.formatText(sel.start, raw.length, LinkAttribute(raw));
    } else {
      _controller.formatText(
        sel.start,
        sel.end - sel.start,
        LinkAttribute(raw),
      );
      _controller.updateSelection(
        TextSelection.collapsed(offset: sel.end),
        ChangeSource.local,
      );
    }
    return true;
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      final ops = _controller.document.toDelta().toJson();
      widget.onChanged!(jsonEncode({'ops': ops}));
    }
  }

  void _openLinkDialog() {
    final selection = _controller.selection;
    final existing = linkAtSelection(_controller);

    final docText = _controller.document.toPlainText();
    final selectedText = (existing == null && !selection.isCollapsed)
        ? docText.substring(selection.start, selection.end)
        : '';
    final selectionIsUrl = existing == null && isLikelyUrl(selectedText);

    LinkEditSheet.show(
      context,
      initialText: existing?.text ?? (selectionIsUrl ? '' : selectedText),
      initialUrl: existing?.url ?? (selectionIsUrl ? selectedText : ''),
      onRemove: existing == null
          ? null
          : () => _removeLinkAt(existing.start, existing.length),
      onSubmit: (text, url) {
        if (existing != null) {
          _replaceLink(existing.start, existing.length, text, url);
        } else if (selection.isCollapsed) {
          final insertAt = selection.start;
          _controller.replaceText(
            insertAt,
            0,
            text,
            TextSelection.collapsed(offset: insertAt + text.length),
          );
          _controller.formatText(insertAt, text.length, LinkAttribute(url));
        } else if (text == selectedText) {
          _controller.formatSelection(LinkAttribute(url));
        } else {
          _replaceLink(
            selection.start,
            selection.end - selection.start,
            text,
            url,
          );
        }
      },
    );
  }

  void _replaceLink(int start, int length, String newText, String newUrl) {
    _controller.replaceText(start, length, '', null);
    _controller.replaceText(
      start,
      0,
      newText,
      TextSelection.collapsed(offset: start + newText.length),
    );
    _controller.formatText(start, newText.length, LinkAttribute(newUrl));
  }

  void _removeLinkAt(int start, int length) {
    _controller.formatText(
      start,
      length,
      Attribute.clone(Attribute.link, null),
    );
  }

  void _handleLaunchUrl(String url) {
    launchExternal(context, url);
  }

  Future<LinkMenuAction> _onLinkLongPress(
    BuildContext ctx,
    String link,
    Node node,
  ) async {
    final range = getLinkRange(node);
    final start = range.start;
    final length = range.end - range.start;
    final text = _controller.document.toPlainText().substring(start, range.end);
    final action = await LinkActionsSheet.show(ctx, text: text, url: link);
    if (action == null || !mounted) return LinkMenuAction.none;
    switch (action) {
      case LinkAction.open:
        _handleLaunchUrl(link);
      case LinkAction.copy:
        await _copyLink(link);
      case LinkAction.edit:
        _editLinkRange(start, length, text, link);
      case LinkAction.remove:
        _removeLinkAt(start, length);
    }
    return LinkMenuAction.none;
  }

  void _editLinkRange(int start, int length, String text, String url) {
    LinkEditSheet.show(
      context,
      initialText: text,
      initialUrl: url,
      onRemove: () => _removeLinkAt(start, length),
      onSubmit: (newText, newUrl) {
        _replaceLink(start, length, newText, newUrl);
      },
    );
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    AppSnackbar.showSuccess(context, message: 'Link copied');
  }

  // Public API
  String getContent() {
    final ops = _controller.document.toDelta().toJson();
    return jsonEncode({'ops': ops});
  }

  String getPlainText() => _controller.document.toPlainText().trim();

  bool get isEmpty => _controller.document.toPlainText().trim().isEmpty;

  bool get isEditing => _isEditing;

  void setContent(String? content) {
    _removeListeners();
    _controller.dispose();
    _controller = _createController(content);
    _addListeners();
    updateChecklistState();
    if (mounted) setState(() {});
  }

  Widget _buildScrollableEditor(BuildContext context) {
    return GestureDetector(
      onTap: widget.canEdit
          ? () {
              if (!_focusNode.hasFocus) _focusNode.requestFocus();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?widget.header,
            QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                placeholder: widget.hintText,
                padding: widget.contentPadding,
                autoFocus: false,
                expands: false,
                scrollable: false,
                showCursor: _isEditing && widget.canEdit,
                enableInteractiveSelection: true,
                customStyles: getEditorStyles(context),
                customStyleBuilder: (attribute) =>
                    getCheckedListStyle(attribute, context),
                onLaunchUrl: _handleLaunchUrl,
                linkActionPickerDelegate: _onLinkLongPress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBubble =
        widget.canEdit && _isEditing && _formattingState.linkUrl != null;

    return Column(
      children: [
        Expanded(child: _buildScrollableEditor(context)),
        if (showBubble)
          _LinkActionBubble(
            url: _formattingState.linkUrl!,
            onOpen: () => _handleLaunchUrl(_formattingState.linkUrl!),
            onCopy: () => _copyLink(_formattingState.linkUrl!),
            onEdit: _openLinkDialog,
            onRemove: () => _removeLinkAt(
              _formattingState.linkStart,
              _formattingState.linkLength,
            ),
          ),
        if (widget.showToolbar && _isEditing && widget.canEdit)
          EditorToolbar(
            controller: _controller,
            state: _formattingState,
            onLinkPressed: _openLinkDialog,
          ),
      ],
    );
  }
}

class _LinkActionBubble extends StatelessWidget {
  final String url;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _LinkActionBubble({
    required this.url,
    required this.onOpen,
    required this.onCopy,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.link, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          _BubbleAction(
            icon: LucideIcons.externalLink,
            tooltip: 'Open',
            onTap: onOpen,
          ),
          _BubbleAction(icon: LucideIcons.copy, tooltip: 'Copy', onTap: onCopy),
          _BubbleAction(
            icon: LucideIcons.pencil,
            tooltip: 'Edit',
            onTap: onEdit,
          ),
          _BubbleAction(
            icon: LucideIcons.unlink,
            tooltip: 'Remove',
            onTap: onRemove,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _BubbleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _BubbleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
