import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:anchor/features/settings/presentation/controllers/editor_preferences_controller.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_selector.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background_picker.dart';
import 'package:anchor/features/notes/presentation/widgets/share_note_sheet.dart';
import '../data/repository/notes_repository.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final Note? note;
  const NoteEditScreen({super.key, this.noteId, this.note});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _editorKey = GlobalKey<RichTextEditorState>();
  bool _isNew = true;
  bool _isDeleted = false;
  bool _isLoaded = false;
  bool _isEditing = false;
  bool _isPinned = false;
  bool _isArchived = false;
  Note? _existingNote;
  String? _initialContent;
  List<String> _selectedTagIds = [];
  String? _selectedBackground;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      // Note passed directly
      _isNew = false;
      _existingNote = widget.note;
      _isPinned = widget.note!.isPinned;
      _isArchived = widget.note!.isArchived;
      _titleController.text = widget.note!.title;
      _initialContent = widget.note!.content;
      _selectedTagIds = List.from(widget.note!.tagIds);
      _selectedBackground = widget.note!.background;
      _isLoaded = true;
      // Trashed notes or viewer notes are read-only
      if (widget.note!.isTrashed || !widget.note!.canEdit) {
        _isEditing = false;
      }
    } else if (widget.noteId != null) {
      // Fallback: fetch from repository if only ID is provided
      _isNew = false;
      _loadNote();
    } else {
      // New notes start in edit mode
      _isEditing = true;
      _isPinned = false;
      _isLoaded = true;
    }

    // Listen to title focus changes
    _titleFocusNode.addListener(_onTitleFocusChanged);
  }

  void _onTitleFocusChanged() {
    _updateEditingState();
  }

  void _onEditorEditingChanged(bool isEditing) {
    _updateEditingState();
  }

  void _updateEditingState() {
    final isReadOnly =
        _existingNote?.isTrashed == true ||
        (_existingNote?.permission == NotePermission.viewer);
    final titleEditing = _titleFocusNode.hasFocus;
    final editorEditing = _editorKey.currentState?.isEditing ?? false;
    final newEditingState = isReadOnly
        ? false
        : (titleEditing || editorEditing);

    if (_isEditing != newEditingState) {
      setState(() {
        _isEditing = newEditingState;
      });
    }
  }

  Future<void> _loadNote() async {
    final note = await ref
        .read(notesRepositoryProvider)
        .getNote(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        _isPinned = note.isPinned;
        _isArchived = note.isArchived;
        _titleController.text = note.title;
        _initialContent = note.content;
        _selectedTagIds = List.from(note.tagIds);
        _selectedBackground = note.background;
        _isLoaded = true;
        // Trashed notes or viewer notes are read-only
        if (note.isTrashed || !note.canEdit) {
          _isEditing = false;
        }
      });
    }
  }

  Future<void> _togglePinned() async {
    // Don't allow pinning if note is trashed
    if (_existingNote?.isTrashed == true) {
      return;
    }
    setState(() {
      _isPinned = !_isPinned;
    });
    await _saveNote();
  }

  Future<void> _toggleArchived() async {
    if (_isNew) return;

    final wasArchived = _isArchived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.archive,
        iconColor: Theme.of(context).colorScheme.primary,
        title: wasArchived ? 'Unarchive Note' : 'Archive Note',
        message: wasArchived
            ? 'This note will be moved back to your notes.'
            : 'This note will be moved to archive.',
        cancelText: 'Cancel',
        confirmText: wasArchived ? 'Unarchive' : 'Archive',
        onConfirm: () {},
      ),
    );

    if (confirm != true || !mounted) return;

    final repository = ref.read(notesRepositoryProvider);
    try {
      if (wasArchived) {
        await repository.unarchiveNote(widget.noteId!);
      } else {
        await repository.archiveNote(widget.noteId!);
      }

      // Reload note to get updated state
      await _loadNote();

      // Show success snackbar
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          message: wasArchived ? 'Note unarchived' : 'Note archived',
        );

        // If archiving, go back after showing snackbar
        if (!wasArchived) {
          // Small delay to ensure snackbar is visible
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            context.pop();
          }
        }
      }
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: wasArchived
              ? 'Failed to unarchive note'
              : 'Failed to archive note',
        );
      }
    }
  }

  void _showColorPicker() {
    // Don't allow changing background if note is trashed
    if (_existingNote?.isTrashed == true) {
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteBackgroundPicker(
        selectedColor: _selectedBackground,
        onColorChanged: (color) {
          setState(() {
            _selectedBackground = color;
          });
          _saveNote();
        },
      ),
    );
  }

  void _showShareSheet() {
    // Only allow sharing for existing, non-trashed notes, and owners only
    if (_isNew ||
        _existingNote?.isTrashed == true ||
        !(_existingNote?.isOwner ?? true)) {
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          ShareNoteSheet(noteId: widget.noteId ?? _existingNote!.id),
    ).then((_) {
      // Reload note to update share count after sheet closes
      if (widget.noteId != null || _existingNote != null) {
        _reloadNoteShareInfo();
      }
    });
  }

  Future<void> _reloadNoteShareInfo() async {
    final noteId = widget.noteId ?? _existingNote?.id;
    if (noteId == null) return;

    final note = await ref.read(notesRepositoryProvider).getNote(noteId);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
      });
    }
  }

  @override
  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    // Don't save if note is trashed or user can't edit
    if (_existingNote?.isTrashed == true || !(_existingNote?.canEdit ?? true)) {
      return;
    }

    final title = _titleController.text.trim();
    final editorState = _editorKey.currentState;
    final content = editorState?.getContent() ?? '';
    final plainText = editorState?.getPlainText() ?? '';

    if (title.isEmpty &&
        plainText.isEmpty &&
        _selectedBackground == null &&
        !_isPinned) {
      return;
    }

    final repository = ref.read(notesRepositoryProvider);

    if (_isNew) {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isNotEmpty ? title : 'Untitled',
        content: content,
        isPinned: _isPinned,
        tagIds: _selectedTagIds,
        background: _selectedBackground,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await repository.createNote(newNote);
      if (mounted) {
        setState(() {
          _isNew = false;
          _existingNote = newNote;
        });
      }
    } else if (_existingNote != null) {
      // Check if anything changed
      final tagsChanged = !_listEquals(_existingNote!.tagIds, _selectedTagIds);
      if (_existingNote!.title == title &&
          _existingNote!.content == content &&
          _existingNote!.isPinned == _isPinned &&
          _existingNote!.background == _selectedBackground &&
          !tagsChanged) {
        return;
      }

      final updatedNote = _existingNote!.copyWith(
        title: title,
        content: content,
        isPinned: _isPinned,
        isArchived: _isArchived,
        tagIds: _selectedTagIds,
        background: _selectedBackground,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await repository.updateNote(updatedNote);
      if (mounted) {
        setState(() {
          _existingNote = updatedNote;
        });
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  Future<void> _deleteNote() async {
    if (_isNew) {
      context.pop();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.trash2,
        iconColor: Theme.of(context).colorScheme.error,
        title: 'Delete Note',
        message:
            'This note will be gone forever. Are you sure you want to let it go?',
        cancelText: 'Keep',
        confirmText: 'Delete',
        confirmColor: Theme.of(context).colorScheme.error,
        onConfirm: () {},
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(notesRepositoryProvider).deleteNote(widget.noteId!);
        _isDeleted = true;

        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Note moved to trash');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Failed to delete note');
        }
      }
    }
  }

  Future<void> _restoreNote() async {
    if (_isNew || _existingNote == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.rotateCcw,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Restore Note',
        message: 'This note will be restored to your notes.',
        cancelText: 'Cancel',
        confirmText: 'Restore',
        onConfirm: () {},
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(notesRepositoryProvider).restoreNote(widget.noteId!);

      // Reload note to get updated state
      await _loadNote();

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Note restored');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to restore note');
      }
    }
  }

  Future<void> _permanentDeleteNote() async {
    if (_isNew || _existingNote == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.trash2,
        iconColor: Theme.of(context).colorScheme.error,
        title: 'Delete Forever',
        message:
            'This action cannot be undone. This note will be permanently deleted and cannot be recovered.',
        cancelText: 'Cancel',
        confirmText: 'Delete Forever',
        confirmColor: Theme.of(context).colorScheme.error,
        onConfirm: () {},
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(notesRepositoryProvider).permanentDelete(widget.noteId!);
        _isDeleted = true;

        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Note permanently deleted');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Failed to delete note');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverUrl = ref.watch(serverUrlProvider);
    final isTrashed = _existingNote?.isTrashed ?? false;
    final isViewer = _existingNote?.permission == NotePermission.viewer;
    final isReadOnly = isTrashed || isViewer;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isDeleted && _isEditing) {
          await _saveNote();
        }
      },
      child: NoteBackground(
        styleId: _selectedBackground,
        borderRadius: BorderRadius.zero,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isTrashed) ...[
                // Restore button for trashed notes
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  onPressed: _isLoaded && !_isNew ? _restoreNote : null,
                  tooltip: 'Restore Note',
                ),
                // Permanent delete button for trashed notes
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: _isLoaded && !_isNew ? _permanentDeleteNote : null,
                  tooltip: 'Delete Forever',
                ),
              ] else ...[
                // Shared by indicator for shared notes
                if (_existingNote?.sharedBy != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SharedByAvatar(
                              sharedBy: _existingNote!.sharedBy!,
                              serverUrl: serverUrl,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Shared by ${_existingNote!.sharedBy!.name}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Background and Pin - shown for non-read-only (owners and editors)
                if (!isReadOnly) ...[
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.pin,
                          color: _isPinned
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        if (_isPinned)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _isLoaded && !isTrashed ? _togglePinned : null,
                    tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.palette),
                    onPressed: !isTrashed ? _showColorPicker : null,
                    tooltip: 'Change Background',
                  ),
                ],
                // Share, Archive, Delete - only for owners
                if (_existingNote?.isOwner ?? true) ...[
                  IconButton(
                    icon: Icon(
                      _isArchived
                          ? LucideIcons.archiveRestore
                          : LucideIcons.archive,
                    ),
                    onPressed: _isLoaded && !_isNew && !isTrashed
                        ? _toggleArchived
                        : null,
                    tooltip: _isArchived ? 'Unarchive Note' : 'Archive Note',
                  ),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(LucideIcons.userPlus),
                        // Badge showing share count
                        if (_existingNote?.hasShares ?? false)
                          Positioned(
                            right: -4,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  '${_existingNote!.shareIds!.length}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _isLoaded && !_isNew && !isTrashed
                        ? _showShareSheet
                        : null,
                    tooltip: 'Share Note',
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2),
                    onPressed: !isTrashed ? _deleteNote : null,
                    tooltip: 'Delete Note',
                  ),
                ],
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: Hero(
            tag: 'note_${widget.noteId ?? 'new'}',
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Read-only banner for trashed or viewer notes
                  if (isReadOnly)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.lock,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isTrashed
                                  ? 'This note is in trash and cannot be edited. Restore it to make changes.'
                                  : 'You have viewer access. Only the owner can edit this note.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: !isReadOnly
                          ? () {
                              if (!_titleFocusNode.hasFocus) {
                                _titleFocusNode.requestFocus();
                              }
                            }
                          : null,
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        readOnly: isReadOnly,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: _isEditing && !isReadOnly ? 'Title' : null,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          filled: false,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        showCursor: _isEditing && !isReadOnly,
                      ),
                    ),
                  ),
                  if ((_isEditing && !isReadOnly) || _selectedTagIds.isNotEmpty)
                    TagSelector(
                      selectedTagIds: _selectedTagIds,
                      readOnly: !_isEditing || isReadOnly,
                      onTagsChanged: (tagIds) {
                        if (!isReadOnly) {
                          setState(() {
                            _selectedTagIds = tagIds;
                          });
                        }
                      },
                    ),
                  Expanded(
                    child: _isLoaded
                        ? RichTextEditor(
                            key: _editorKey,
                            initialContent: _initialContent,
                            hintText: 'Start typing...',
                            showToolbar: _isEditing && !isReadOnly,
                            canEdit: !isReadOnly,
                            onEditingChanged: _onEditorEditingChanged,
                            sortChecklistItems: ref
                                .watch(editorPreferencesControllerProvider)
                                .sortChecklistItems,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar widget to display the profile image of the user who shared the note
class _SharedByAvatar extends StatelessWidget {
  final SharedByUser sharedBy;
  final String? serverUrl;
  final double size;

  const _SharedByAvatar({
    required this.sharedBy,
    this.serverUrl,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileImage = sharedBy.profileImage;

    if (profileImage != null && profileImage.isNotEmpty) {
      String imageUrl = profileImage;
      if (!imageUrl.startsWith('http') && serverUrl != null) {
        imageUrl = '$serverUrl$imageUrl';
      }
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildFallbackAvatar(theme),
          errorWidget: (context, url, error) => _buildFallbackAvatar(theme),
        ),
      );
    }
    return _buildFallbackAvatar(theme);
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          sharedBy.name.isNotEmpty ? sharedBy.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}
