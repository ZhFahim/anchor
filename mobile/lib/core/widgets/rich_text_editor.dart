import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'editor/checklist_reorder_mixin.dart';
import 'editor/editor_toolbar.dart';
import 'editor/editor_styles.dart';

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
  });

  @override
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor>
    with ChecklistReorderMixin {
  late QuillController _controller;
  late FocusNode _focusNode;
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
    if (content == null || content.isEmpty) {
      return QuillController.basic();
    }

    try {
      final json = jsonDecode(content);
      if (json is Map && json['ops'] is List) {
        final document = Document.fromJson(json['ops'] as List);
        return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {
      // Invalid JSON -> fall through to empty document
    }

    return QuillController.basic();
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      final ops = _controller.document.toDelta().toJson();
      widget.onChanged!(jsonEncode({'ops': ops}));
    }
  }

  void _insertLink() {
    final selection = _controller.selection;
    final text = _controller.document.toPlainText();
    final selectedText = selection.isCollapsed
        ? ''
        : text.substring(selection.start, selection.end);

    showDialog(
      context: context,
      builder: (ctx) => LinkInsertDialog(
        initialText: selectedText,
        onSubmit: (text, url) {
          if (selection.isCollapsed) {
            _controller.replaceText(
              selection.start,
              0,
              text,
              TextSelection.collapsed(offset: selection.start + text.length),
            );
            _controller.formatText(
              selection.start,
              text.length,
              LinkAttribute(url),
            );
          } else {
            _controller.formatSelection(LinkAttribute(url));
          }
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.canEdit
                ? () {
                    if (!_focusNode.hasFocus) {
                      _focusNode.requestFocus();
                    }
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              config: QuillEditorConfig(
                placeholder: widget.hintText,
                padding: widget.contentPadding,
                autoFocus: false,
                expands: true,
                scrollable: true,
                showCursor: _isEditing && widget.canEdit,
                enableInteractiveSelection: true,
                customStyles: getEditorStyles(context),
                customStyleBuilder: (attribute) =>
                    getCheckedListStyle(attribute, context),
              ),
            ),
          ),
        ),
        if (widget.showToolbar && _isEditing && widget.canEdit)
          EditorToolbar(
            controller: _controller,
            state: _formattingState,
            onLinkPressed: _insertLink,
          ),
      ],
    );
  }
}
