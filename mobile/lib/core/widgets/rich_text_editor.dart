import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A reusable rich text editor widget powered by flutter_quill.
///
/// Content is stored and loaded as JSON Delta format.
class RichTextEditor extends StatefulWidget {
  /// Initial content in JSON Delta format, or plain text if not valid JSON.
  final String? initialContent;

  /// Callback when content changes. Returns JSON Delta string.
  final ValueChanged<String>? onChanged;

  /// Callback when editing state changes (focus gained/lost).
  final ValueChanged<bool>? onEditingChanged;

  /// Hint text shown when editor is empty.
  final String hintText;

  /// Whether to show the toolbar.
  final bool showToolbar;

  /// Whether the editor can be edited (tap-to-edit enabled).
  /// If false, the editor will remain in view-only mode.
  final bool canEdit;

  /// Focus node for the editor.
  final FocusNode? focusNode;

  /// Padding for the editor content.
  final EdgeInsets contentPadding;

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
  });

  @override
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor> {
  late QuillController _controller;
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  bool _isEditing = false;

  // Track formatting state for dynamic toolbar
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;
  bool _isList = false;
  bool _isNumberedList = false;
  bool _isChecklist = false;
  bool _isQuote = false;
  bool _isCode = false;
  int _headerLevel = 0;
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialContent);
    _controller.readOnly = !widget.canEdit;
    _controller.addListener(_onTextChanged);
    _controller.addListener(_updateFormattingState);

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }

    // Listen to focus changes to track editing state
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final wasEditing = _isEditing;
    final hasFocus = _focusNode.hasFocus;

    // If in read-only mode and focus is gained, hide keyboard immediately
    if (!widget.canEdit && hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      // Don't set editing state for read-only mode
      setState(() {
        _isEditing = false;
      });
    } else {
      setState(() {
        _isEditing = hasFocus;
      });
    }

    // Notify parent of editing state change (only for editable mode)
    if (wasEditing != _isEditing &&
        widget.canEdit &&
        widget.onEditingChanged != null) {
      widget.onEditingChanged!(_isEditing);
    }
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update read-only state if canEdit changed
    if (oldWidget.canEdit != widget.canEdit) {
      _controller.readOnly = !widget.canEdit;
    }
  }

  void _updateFormattingState() {
    if (!mounted) return;
    final style = _controller.getSelectionStyle();
    setState(() {
      _isBold = style.attributes.containsKey(Attribute.bold.key);
      _isItalic = style.attributes.containsKey(Attribute.italic.key);
      _isUnderline = style.attributes.containsKey(Attribute.underline.key);
      _isStrikethrough = style.attributes.containsKey(
        Attribute.strikeThrough.key,
      );
      _isList =
          style.attributes.containsKey(Attribute.list.key) &&
          style.attributes[Attribute.list.key]?.value == 'bullet';
      _isNumberedList =
          style.attributes.containsKey(Attribute.list.key) &&
          style.attributes[Attribute.list.key]?.value == 'ordered';
      final listValue = style.attributes[Attribute.list.key]?.value;
      _isChecklist =
          style.attributes.containsKey(Attribute.list.key) &&
          (listValue == 'checked' || listValue == 'unchecked');
      _isQuote = style.attributes.containsKey(Attribute.blockQuote.key);
      _isCode = style.attributes.containsKey(Attribute.codeBlock.key);

      final header = style.attributes[Attribute.header.key];
      _headerLevel = header?.value is int ? header!.value as int : 0;

      // Update undo/redo availability
      _canUndo = _controller.hasUndo;
      _canRedo = _controller.hasRedo;
    });
  }

  QuillController _createController(String? content) {
    if (content == null || content.isEmpty) {
      return QuillController.basic();
    }

    try {
      final json = jsonDecode(content);
      // Canonical Quill storage format: { "ops": [...] }
      if (json is Map && json['ops'] is List) {
        final document = Document.fromJson(json['ops'] as List);
        return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {
      // Invalid JSON -> strict mode: fall through to empty document
    }

    // Strict mode: only recommended Quill format is accepted.
    return QuillController.basic();
  }

  void _onTextChanged() {
    if (widget.onChanged != null) {
      final ops = _controller.document.toDelta().toJson();
      widget.onChanged!(jsonEncode({'ops': ops}));
    }
  }

  /// Gets the current content as JSON Delta string.
  String getContent() {
    final ops = _controller.document.toDelta().toJson();
    return jsonEncode({'ops': ops});
  }

  /// Gets the current content as plain text.
  String getPlainText() {
    return _controller.document.toPlainText().trim();
  }

  /// Checks if the editor content is empty.
  bool get isEmpty {
    final text = _controller.document.toPlainText().trim();
    return text.isEmpty;
  }

  /// Whether the editor is currently being edited (has focus).
  bool get isEditing => _isEditing;

  /// Sets new content from JSON Delta string.
  void setContent(String? content) {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _controller = _createController(content);
    _controller.addListener(_onTextChanged);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.removeListener(_updateFormattingState);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                customStyles: _getCustomStyles(context),
              ),
            ),
          ),
        ),
        if (widget.showToolbar && _isEditing && widget.canEdit)
          _buildCustomToolbar(theme),
      ],
    );
  }

  Widget _buildCustomToolbar(ThemeData theme) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding + 4 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Undo/Redo group
            _buildToolbarGroup([
              _ToolbarButton(
                icon: LucideIcons.undo2,
                isActive: false,
                isEnabled: _canUndo,
                onTap: () {
                  _controller.undo();
                  HapticFeedback.lightImpact();
                },
                tooltip: 'Undo',
              ),
              _ToolbarButton(
                icon: LucideIcons.redo2,
                isActive: false,
                isEnabled: _canRedo,
                onTap: () {
                  _controller.redo();
                  HapticFeedback.lightImpact();
                },
                tooltip: 'Redo',
              ),
            ], theme),

            _buildDivider(theme),

            // Text style group
            _buildToolbarGroup([
              _ToolbarButton(
                icon: LucideIcons.bold,
                isActive: _isBold,
                onTap: () => _toggleFormat(Attribute.bold),
                tooltip: 'Bold',
              ),
              _ToolbarButton(
                icon: LucideIcons.italic,
                isActive: _isItalic,
                onTap: () => _toggleFormat(Attribute.italic),
                tooltip: 'Italic',
              ),
              _ToolbarButton(
                icon: LucideIcons.underline,
                isActive: _isUnderline,
                onTap: () => _toggleFormat(Attribute.underline),
                tooltip: 'Underline',
              ),
              _ToolbarButton(
                icon: LucideIcons.strikethrough,
                isActive: _isStrikethrough,
                onTap: () => _toggleFormat(Attribute.strikeThrough),
                tooltip: 'Strikethrough',
              ),
            ], theme),

            _buildDivider(theme),

            // Headers group
            _buildToolbarGroup([
              _ToolbarButton(
                icon: LucideIcons.heading1,
                isActive: _headerLevel == 1,
                onTap: () => _toggleHeader(1),
                tooltip: 'Heading 1',
              ),
              _ToolbarButton(
                icon: LucideIcons.heading2,
                isActive: _headerLevel == 2,
                onTap: () => _toggleHeader(2),
                tooltip: 'Heading 2',
              ),
              _ToolbarButton(
                icon: LucideIcons.heading3,
                isActive: _headerLevel == 3,
                onTap: () => _toggleHeader(3),
                tooltip: 'Heading 3',
              ),
            ], theme),

            _buildDivider(theme),

            // List group
            _buildToolbarGroup([
              _ToolbarButton(
                icon: LucideIcons.listChecks,
                isActive: _isChecklist,
                onTap: () => _toggleList(Attribute.unchecked),
                tooltip: 'Checklist',
              ),
              _ToolbarButton(
                icon: LucideIcons.listOrdered,
                isActive: _isNumberedList,
                onTap: () => _toggleList(Attribute.ol),
                tooltip: 'Numbered List',
              ),
              _ToolbarButton(
                icon: LucideIcons.list,
                isActive: _isList,
                onTap: () => _toggleList(Attribute.ul),
                tooltip: 'Bullet List',
              ),
            ], theme),

            _buildDivider(theme),

            // Block group
            _buildToolbarGroup([
              _ToolbarButton(
                icon: LucideIcons.quote,
                isActive: _isQuote,
                onTap: () => _toggleBlock(Attribute.blockQuote),
                tooltip: 'Quote',
              ),
              _ToolbarButton(
                icon: LucideIcons.code,
                isActive: _isCode,
                onTap: () => _toggleBlock(Attribute.codeBlock),
                tooltip: 'Code Block',
              ),
              _ToolbarButton(
                icon: LucideIcons.link,
                isActive: false,
                onTap: _insertLink,
                tooltip: 'Link',
              ),
            ], theme),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarGroup(List<_ToolbarButton> buttons, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons
            .map((btn) => _buildToolbarButton(btn, theme))
            .toList(),
      ),
    );
  }

  Widget _buildToolbarButton(_ToolbarButton button, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.tertiary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.7 : 0.6,
    );
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);

    // Check if this is an enabled/disabled button (undo/redo style)
    final hasEnabledState = button.isEnabled != null;
    final isEnabled = button.isEnabled ?? true;

    return Tooltip(
      message: button.tooltip,
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                button.onTap();
                HapticFeedback.selectionClick();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            // No highlight for undo/redo, only for formatting buttons
            color: hasEnabledState
                ? Colors.transparent
                : (button.isActive
                      ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                button.icon,
                key: ValueKey('${button.isActive}_$isEnabled'),
                size: 20,
                // Undo/redo: just fade when disabled, normal when enabled
                // Formatting: highlight color when active
                color: hasEnabledState
                    ? (isEnabled ? inactiveColor : disabledColor)
                    : (button.isActive ? activeColor : inactiveColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.outline.withValues(alpha: 0),
              theme.colorScheme.outline.withValues(alpha: 0.2),
              theme.colorScheme.outline.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFormat(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    _controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleHeader(int level) {
    final style = _controller.getSelectionStyle();
    final currentHeader = style.attributes[Attribute.header.key];
    final currentLevel = currentHeader?.value is int
        ? currentHeader!.value as int
        : 0;

    if (currentLevel == level) {
      _controller.formatSelection(Attribute.clone(Attribute.header, null));
    } else {
      final headerAttr = switch (level) {
        1 => Attribute.h1,
        2 => Attribute.h2,
        3 => Attribute.h3,
        _ => Attribute.header,
      };
      _controller.formatSelection(headerAttr);
    }
  }

  void _toggleList(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    final currentValue = currentList?.value;

    // For checklist, check both 'checked' and 'unchecked' values
    final isChecklist = attribute == Attribute.unchecked;
    final isCurrentlyChecklist =
        currentValue == 'checked' || currentValue == 'unchecked';

    if (isChecklist && isCurrentlyChecklist) {
      // Toggle off checklist
      _controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else if (currentValue == attribute.value) {
      // Toggle off same list type
      _controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      _controller.formatSelection(attribute);
    }
  }

  void _toggleBlock(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    _controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _insertLink() {
    final selection = _controller.selection;
    final text = _controller.document.toPlainText();
    final selectedText = selection.isCollapsed
        ? ''
        : text.substring(selection.start, selection.end);

    showDialog(
      context: context,
      builder: (ctx) => _LinkDialog(
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

  DefaultStyles _getCustomStyles(BuildContext context) {
    final theme = Theme.of(context);

    // Use DM Sans for body text (matching app theme)
    final baseStyle = GoogleFonts.dmSans(
      color: theme.colorScheme.onSurface,
      fontSize: 18,
      height: 1.6,
    );

    // Use Playfair Display for headers (matching app theme)
    final headerStyle = GoogleFonts.playfairDisplay(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        headerStyle.copyWith(fontSize: 28, height: 1.3),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        headerStyle.copyWith(fontSize: 24, height: 1.3),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(12, 6),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        headerStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: const TextStyle(fontWeight: FontWeight.bold),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: theme.colorScheme.tertiary,
        decoration: TextDecoration.underline,
      ),
      placeHolder: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      lists: DefaultListBlockStyle(
        baseStyle.copyWith(height: 1.2),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 12),
        const VerticalSpacing(8, 0),
        null,
        null,
        indentWidthBuilder: (block, context, count, widthBuilder) {
          final attrs = block.style.attributes;
          final listAttr = attrs[Attribute.list.key];
          final isOrdered = listAttr?.value == 'ordered';
          final isBullet = listAttr?.value == 'bullet';

          if (attrs.containsKey(Attribute.blockQuote.key)) {
            return HorizontalSpacing(16, 0);
          }

          if (isOrdered) {
            final base = widthBuilder(16, count);
            return HorizontalSpacing(base, 0);
          }
          if (isBullet) {
            return HorizontalSpacing(24, 0);
          }
          return HorizontalSpacing(36, 0);
        },
      ),
      quote: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
        const HorizontalSpacing(16, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: theme.colorScheme.onSurface,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Internal button model for the custom toolbar
class _ToolbarButton {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  /// For undo/redo: simple enabled/disabled without highlight
  final bool? isEnabled;

  const _ToolbarButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
    this.isEnabled,
  });
}

/// Dialog for inserting/editing links
class _LinkDialog extends StatefulWidget {
  final String initialText;
  final void Function(String text, String url) onSubmit;

  const _LinkDialog({required this.initialText, required this.onSubmit});

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(LucideIcons.link, color: theme.colorScheme.tertiary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Insert Link',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Text',
              labelStyle: GoogleFonts.dmSans(),
              hintText: 'Link text',
              prefixIcon: const Icon(LucideIcons.type, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: GoogleFonts.dmSans(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: GoogleFonts.dmSans(),
              hintText: 'https://...',
              prefixIcon: const Icon(LucideIcons.globe, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: GoogleFonts.dmSans(),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final text = _textController.text.trim();
            final url = _urlController.text.trim();
            if (text.isNotEmpty && url.isNotEmpty) {
              widget.onSubmit(text, url);
              Navigator.pop(context);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Insert',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
