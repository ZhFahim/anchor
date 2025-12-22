import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/tag.dart';
import '../tags_controller.dart';
import 'tag_chip.dart';

class TagSelector extends ConsumerStatefulWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;
  final bool readOnly;

  const TagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.readOnly = false,
  });

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
  void _showTagPickerSheet() {
    if (widget.readOnly) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TagPickerSheet(
        selectedTagIds: widget.selectedTagIds,
        onTagsChanged: widget.onTagsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsControllerProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.tags,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 40,
          child: tagsAsync.when(
            data: (allTags) {
              final selectedTags = allTags
                  .where((t) => widget.selectedTagIds.contains(t.id))
                  .toList();

              // Read-only mode: just show tag chips without actions
              if (widget.readOnly) {
                if (selectedTags.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: selectedTags
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TagChip(tag: tag, selected: false),
                        ),
                      )
                      .toList(),
                );
              }

              // Edit mode: show tags with delete and add button
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...selectedTags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TagChip(
                        tag: tag,
                        selected: true,
                        showDelete: true,
                        onDelete: () {
                          final newIds = List<String>.from(
                            widget.selectedTagIds,
                          )..remove(tag.id);
                          widget.onTagsChanged(newIds);
                        },
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showTagPickerSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add tag',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class TagPickerSheet extends ConsumerStatefulWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;

  const TagPickerSheet({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<TagPickerSheet> {
  late List<String> _selectedIds;
  final _newTagController = TextEditingController();
  bool _isCreatingTag = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
    _newTagController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _newTagController.removeListener(_onTextChanged);
    _newTagController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Clear error when user starts typing
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
    widget.onTagsChanged(_selectedIds);
  }

  Future<void> _createTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreatingTag = true;
      _errorMessage = null;
    });

    try {
      final tag = await ref
          .read(tagsControllerProvider.notifier)
          .createTag(name);
      _newTagController.clear();
      setState(() {
        _selectedIds.add(tag.id);
        _isCreatingTag = false;
        _errorMessage = null;
      });
      widget.onTagsChanged(_selectedIds);
    } catch (e) {
      setState(() {
        _isCreatingTag = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.tags,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Tags',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Organize your note',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),

            // Create new tag input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _newTagController,
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Create new tag...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      prefixIcon: Icon(
                        LucideIcons.plus,
                        size: 18,
                        color: _errorMessage != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      suffixIcon: _isCreatingTag
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _newTagController.text.isNotEmpty
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _errorMessage != null
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _errorMessage != null
                                      ? LucideIcons.x
                                      : LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: _errorMessage != null
                                  ? () {
                                      setState(() => _errorMessage = null);
                                    }
                                  : _createTag,
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      errorText: _errorMessage,
                      errorStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _createTag(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Available Tags',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tags list
            Flexible(
              child: tagsAsync.when(
                data: (tags) {
                  if (tags.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.tags,
                              size: 32,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tags yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create your first tag above',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final isSelected = _selectedIds.contains(tag.id);
                      final tagColor = parseTagColor(
                        tag.color,
                        fallback: theme.colorScheme.primary,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _toggleTag(tag.id),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? tagColor.withValues(alpha: 0.12)
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.03,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? tagColor.withValues(alpha: 0.3)
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.06,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: tagColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.hash,
                                      size: 16,
                                      color: tagColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tag.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? tagColor
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: isSelected
                                        ? Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: tagColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              LucideIcons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
