import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_snackbar.dart';
import 'editor/checklist_drag_mixin.dart';
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

  /// Callback when the document changes. Selection-only changes don't fire;
  /// read the content with [RichTextEditorState.getContent].
  final VoidCallback? onChanged;

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
    with ChecklistReorderMixin, ChecklistDragReorderMixin {
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  StreamSubscription<DocChange>? _onChangedSub;
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  final GlobalKey _dragStackKey = GlobalKey();
  bool _isInternalFocusNode = false;
  bool _isEditing = false;
  bool _consumeEditorTapUp = false;

  // ChecklistReorderMixin / ChecklistDragReorderMixin requirements
  @override
  QuillController get controller => _controller;

  @override
  bool get sortChecklistItems => widget.sortChecklistItems;

  @override
  RenderEditor? get renderEditor => _editorKey.currentState?.renderEditor;

  @override
  ScrollController get dragScrollController => _scrollController;

  @override
  RenderBox? get dragOverlayBox =>
      _dragStackKey.currentContext?.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialContent);
    _controller.readOnly = !widget.canEdit;
    _scrollController = ScrollController();
    _onChangedSub = _controller.changes.listen((_) => widget.onChanged?.call());
    attachChecklistSorting();

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
    if (widget.initialContent != oldWidget.initialContent) {
      _syncExternalContent();
    }
  }

  /// Applies externally reloaded content (restore, unarchive, sync) to the
  /// live controller. No-op when the document already matches. Does not fire
  /// [RichTextEditor.onChanged] and touches neither focus nor the keyboard.
  void _syncExternalContent() {
    final incoming = _parseDocument(widget.initialContent);
    if (incoming.toDelta() == _controller.document.toDelta()) return;

    final previousOffset = _controller.selection.extentOffset;
    cancelChecklistDrag();
    // controller.changes is a stream on the document itself; both
    // subscriptions die with the old one.
    detachChecklistSorting();
    _onChangedSub?.cancel();
    _controller
      ..ignoreFocusOnTextChange = true
      ..skipRequestKeyboard = true
      ..document = incoming;
    _controller.updateSelection(
      TextSelection.collapsed(
        offset: previousOffset.clamp(0, _controller.document.length - 1),
      ),
      ChangeSource.silent,
    );
    _onChangedSub = _controller.changes.listen((_) => widget.onChanged?.call());
    attachChecklistSorting();
    // The armed focus guard suppresses the editor's own repaint.
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller
        ..ignoreFocusOnTextChange = false
        ..skipRequestKeyboard = false;
    });
  }

  @override
  void dispose() {
    disposeChecklistDrag();
    detachChecklistSorting();
    _onChangedSub?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _scrollController.dispose();
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
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

  QuillController _createController(String? content) {
    // ignore: experimental_member_use
    final config = QuillControllerConfig(
      // ignore: experimental_member_use
      clipboardConfig: QuillClipboardConfig(
        // ignore: experimental_member_use
        onClipboardPaste: _onClipboardPaste,
      ),
    );

    return QuillController(
      document: _parseDocument(content),
      selection: const TextSelection.collapsed(offset: 0),
      config: config,
    );
  }

  Document _parseDocument(String? content) {
    if (content != null && content.isNotEmpty) {
      try {
        final json = jsonDecode(content);
        if (json is Map && json['ops'] is List) {
          return Document.fromJson(json['ops'] as List);
        }
      } catch (_) {
        // Invalid JSON -> empty document
      }
    }
    return Document();
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

  Widget? _buildLeading(Node node, LeadingConfig config) {
    final isCheck =
        config.attribute == Attribute.checked ||
        config.attribute == Attribute.unchecked;
    if (!isCheck) return null;
    final enabled = config.enabled ?? true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () => _handleCheckboxTap(node.documentOffset, !config.value)
          : null,
      onLongPressStart: enabled
          ? (details) => startChecklistDrag(node.documentOffset, details)
          : null,
      onLongPressMoveUpdate: enabled ? updateChecklistDrag : null,
      onLongPressEnd: enabled ? (_) => endChecklistDrag() : null,
      onLongPressCancel: enabled ? cancelChecklistDrag : null,
      child: AbsorbPointer(
        child: QuillCheckboxPoint(
          size: config.lineSize!,
          value: config.value,
          enabled: enabled,
          uiBuilder: config.uiBuilder,
          onChanged: (_) {},
        ),
      ),
    );
  }

  /// Toggles the checkbox at [offset] without touching selection or focus.
  void _handleCheckboxTap(int offset, bool checked) {
    // Quill's transparent tap recognizer delivers this tap to the editor a
    // second time; [_onEditorTapUp] swallows that duplicate.
    _consumeEditorTapUp = true;
    _controller
      ..ignoreFocusOnTextChange = true
      ..skipRequestKeyboard = true
      ..formatText(
        offset,
        0,
        checked ? Attribute.checked : Attribute.unchecked,
      );
    // While ignoreFocusOnTextChange is armed the editor skips its own repaint.
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumeEditorTapUp = false;
      _controller
        ..ignoreFocusOnTextChange = false
        ..skipRequestKeyboard = false;
    });
  }

  /// Swallows the editor-level duplicate of a checkbox tap, which otherwise
  /// moves the cursor to the tapped word and requests the keyboard.
  bool _onEditorTapUp(
    TapUpDetails details,
    TextPosition Function(Offset offset) getPosition,
  ) {
    if (_consumeEditorTapUp) {
      _consumeEditorTapUp = false;
      return true;
    }
    return false;
  }

  /// Tap on empty space around the content: cursor to the end, keyboard up.
  /// The selection update re-requests the keyboard even when focus is kept.
  void _handleBackgroundTap() {
    _focusNode.requestFocus();
    _controller.updateSelection(
      TextSelection.collapsed(offset: _controller.document.length - 1),
      ChangeSource.local,
    );
  }

  Widget _buildScrollableEditor(BuildContext context) {
    return Stack(
      key: _dragStackKey,
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: widget.canEdit ? _handleBackgroundTap : null,
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
                    // ignore: experimental_member_use
                    customLeadingBlockBuilder: _buildLeading,
                    editorKey: _editorKey,
                    onTapUp: _onEditorTapUp,
                    onLaunchUrl: _handleLaunchUrl,
                    linkActionPickerDelegate: _onLinkLongPress,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDraggingChecklistItem)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<int>(
                valueListenable: dragRepaint,
                builder: (context, _, _) => _buildDragOverlay(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDragOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorTop = dragIndicatorTop;
    final feedback = dragFeedbackPosition;
    final sourceRect = dragSourceRect;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipLeft = (constraints.maxWidth - 272).clamp(
          12.0,
          double.infinity,
        );
        return Stack(
          children: [
            if (sourceRect != null)
              Positioned.fromRect(
                key: const Key('checklist-drag-dim'),
                rect: sourceRect,
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
                ),
              ),
            if (indicatorTop != null)
              AnimatedPositioned(
                key: const Key('checklist-drag-indicator'),
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                left: 20,
                right: 20,
                top: indicatorTop - 4,
                height: 8,
                child: const _DragIndicator(),
              ),
            if (feedback != null)
              Positioned(
                key: const Key('checklist-drag-ghost'),
                left: (feedback.dx + 16).clamp(12.0, maxChipLeft),
                top: (feedback.dy - 52).clamp(4.0, double.infinity),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: _ChecklistDragChip(
                    text: dragFeedbackText,
                    checked: dragFeedbackChecked,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildScrollableEditor(context)),
        // Only the bubble and toolbar rebuild on controller changes.
        if (widget.canEdit)
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildEditingChrome(context),
          ),
      ],
    );
  }

  Widget _buildEditingChrome(BuildContext context) {
    final formatting = EditorFormattingState.fromController(_controller);
    final linkUrl = formatting.linkUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditing && linkUrl != null)
          _LinkActionBubble(
            url: linkUrl,
            onOpen: () => _handleLaunchUrl(linkUrl),
            onCopy: () => _copyLink(linkUrl),
            onEdit: _openLinkDialog,
            onRemove: () =>
                _removeLinkAt(formatting.linkStart, formatting.linkLength),
          ),
        if (widget.showToolbar)
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isEditing
                ? EditorToolbar(
                    controller: _controller,
                    state: formatting,
                    onLinkPressed: _openLinkDialog,
                  )
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }
}

/// Accent line with a dot cap marking the drop gap.
class _DragIndicator extends StatelessWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          Positioned(
            left: 3,
            right: 0,
            top: 3,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0.5,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact floating chip showing the item being dragged.
class _ChecklistDragChip extends StatelessWidget {
  final String text;
  final bool checked;

  const _ChecklistDragChip({required this.text, required this.checked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = checked
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: theme.colorScheme.surfaceContainerLow,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              checked ? LucideIcons.squareCheck : LucideIcons.square,
              size: 16,
              color: checked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text.isEmpty ? ' ' : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: textColor,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  decorationColor: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
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
