import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Formatting state for the editor toolbar
class EditorFormattingState {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isBulletList;
  final bool isNumberedList;
  final bool isChecklist;
  final bool isQuote;
  final bool isCode;
  final int headerLevel;
  final bool canUndo;
  final bool canRedo;

  const EditorFormattingState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isBulletList = false,
    this.isNumberedList = false,
    this.isChecklist = false,
    this.isQuote = false,
    this.isCode = false,
    this.headerLevel = 0,
    this.canUndo = false,
    this.canRedo = false,
  });

  /// Create formatting state from QuillController
  factory EditorFormattingState.fromController(QuillController controller) {
    final style = controller.getSelectionStyle();
    final listValue = style.attributes[Attribute.list.key]?.value;
    final header = style.attributes[Attribute.header.key];

    return EditorFormattingState(
      isBold: style.attributes.containsKey(Attribute.bold.key),
      isItalic: style.attributes.containsKey(Attribute.italic.key),
      isUnderline: style.attributes.containsKey(Attribute.underline.key),
      isStrikethrough: style.attributes.containsKey(
        Attribute.strikeThrough.key,
      ),
      isBulletList: listValue == 'bullet',
      isNumberedList: listValue == 'ordered',
      isChecklist: listValue == 'checked' || listValue == 'unchecked',
      isQuote: style.attributes.containsKey(Attribute.blockQuote.key),
      isCode: style.attributes.containsKey(Attribute.codeBlock.key),
      headerLevel: header?.value is int ? header!.value as int : 0,
      canUndo: controller.hasUndo,
      canRedo: controller.hasRedo,
    );
  }
}

/// Custom toolbar for the rich text editor
class EditorToolbar extends StatelessWidget {
  final QuillController controller;
  final EditorFormattingState state;
  final VoidCallback? onLinkPressed;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.state,
    this.onLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            // Undo/Redo
            _ToolbarGroup(
              buttons: [
                _ToolbarButtonData(
                  icon: LucideIcons.undo2,
                  isEnabled: state.canUndo,
                  onTap: () {
                    controller.undo();
                    HapticFeedback.lightImpact();
                  },
                  tooltip: 'Undo',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.redo2,
                  isEnabled: state.canRedo,
                  onTap: () {
                    controller.redo();
                    HapticFeedback.lightImpact();
                  },
                  tooltip: 'Redo',
                ),
              ],
            ),
            _buildDivider(theme),

            // Text styles
            _ToolbarGroup(
              buttons: [
                _ToolbarButtonData(
                  icon: LucideIcons.bold,
                  isActive: state.isBold,
                  onTap: () => _toggleFormat(Attribute.bold),
                  tooltip: 'Bold',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.italic,
                  isActive: state.isItalic,
                  onTap: () => _toggleFormat(Attribute.italic),
                  tooltip: 'Italic',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.underline,
                  isActive: state.isUnderline,
                  onTap: () => _toggleFormat(Attribute.underline),
                  tooltip: 'Underline',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.strikethrough,
                  isActive: state.isStrikethrough,
                  onTap: () => _toggleFormat(Attribute.strikeThrough),
                  tooltip: 'Strikethrough',
                ),
              ],
            ),
            _buildDivider(theme),

            // Headers
            _ToolbarGroup(
              buttons: [
                _ToolbarButtonData(
                  icon: LucideIcons.heading1,
                  isActive: state.headerLevel == 1,
                  onTap: () => _toggleHeader(1),
                  tooltip: 'Heading 1',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.heading2,
                  isActive: state.headerLevel == 2,
                  onTap: () => _toggleHeader(2),
                  tooltip: 'Heading 2',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.heading3,
                  isActive: state.headerLevel == 3,
                  onTap: () => _toggleHeader(3),
                  tooltip: 'Heading 3',
                ),
              ],
            ),
            _buildDivider(theme),

            // Lists
            _ToolbarGroup(
              buttons: [
                _ToolbarButtonData(
                  icon: LucideIcons.listChecks,
                  isActive: state.isChecklist,
                  onTap: () => _toggleList(Attribute.unchecked),
                  tooltip: 'Checklist',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.listOrdered,
                  isActive: state.isNumberedList,
                  onTap: () => _toggleList(Attribute.ol),
                  tooltip: 'Numbered List',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.list,
                  isActive: state.isBulletList,
                  onTap: () => _toggleList(Attribute.ul),
                  tooltip: 'Bullet List',
                ),
              ],
            ),
            _buildDivider(theme),

            // Blocks
            _ToolbarGroup(
              buttons: [
                _ToolbarButtonData(
                  icon: LucideIcons.quote,
                  isActive: state.isQuote,
                  onTap: () => _toggleBlock(Attribute.blockQuote),
                  tooltip: 'Quote',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.code,
                  isActive: state.isCode,
                  onTap: () => _toggleBlock(Attribute.codeBlock),
                  tooltip: 'Code Block',
                ),
                _ToolbarButtonData(
                  icon: LucideIcons.link,
                  onTap: onLinkPressed ?? () {},
                  tooltip: 'Link',
                ),
              ],
            ),
          ],
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
    final style = controller.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleHeader(int level) {
    final style = controller.getSelectionStyle();
    final currentHeader = style.attributes[Attribute.header.key];
    final currentLevel = currentHeader?.value is int
        ? currentHeader!.value as int
        : 0;

    if (currentLevel == level) {
      controller.formatSelection(Attribute.clone(Attribute.header, null));
    } else {
      final headerAttr = switch (level) {
        1 => Attribute.h1,
        2 => Attribute.h2,
        3 => Attribute.h3,
        _ => Attribute.header,
      };
      controller.formatSelection(headerAttr);
    }
  }

  void _toggleList(Attribute attribute) {
    final style = controller.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    final currentValue = currentList?.value;

    final isChecklist = attribute == Attribute.unchecked;
    final isCurrentlyChecklist =
        currentValue == 'checked' || currentValue == 'unchecked';

    if (isChecklist && isCurrentlyChecklist) {
      controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else if (currentValue == attribute.value) {
      controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      controller.formatSelection(attribute);
    }
  }

  void _toggleBlock(Attribute attribute) {
    final style = controller.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }
}

// Private helper classes
class _ToolbarButtonData {
  final IconData icon;
  final bool isActive;
  final bool? isEnabled;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolbarButtonData({
    required this.icon,
    this.isActive = false,
    this.isEnabled,
    required this.onTap,
    required this.tooltip,
  });
}

class _ToolbarGroup extends StatelessWidget {
  final List<_ToolbarButtonData> buttons;

  const _ToolbarGroup({required this.buttons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        children: buttons.map((btn) => _ToolbarButton(data: btn)).toList(),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final _ToolbarButtonData data;

  const _ToolbarButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.tertiary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.7 : 0.6,
    );
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);

    final hasEnabledState = data.isEnabled != null;
    final isEnabled = data.isEnabled ?? true;

    return Tooltip(
      message: data.tooltip,
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                data.onTap();
                HapticFeedback.selectionClick();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasEnabledState
                ? Colors.transparent
                : (data.isActive
                      ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              data.icon,
              size: 20,
              color: hasEnabledState
                  ? (isEnabled ? inactiveColor : disabledColor)
                  : (data.isActive ? activeColor : inactiveColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for inserting links
class LinkInsertDialog extends StatefulWidget {
  final String initialText;
  final void Function(String text, String url) onSubmit;

  const LinkInsertDialog({
    super.key,
    required this.initialText,
    required this.onSubmit,
  });

  @override
  State<LinkInsertDialog> createState() => _LinkInsertDialogState();
}

class _LinkInsertDialogState extends State<LinkInsertDialog> {
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
