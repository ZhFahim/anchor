import 'dart:async';

import 'package:anchor/core/logging/app_logger.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/providers/active_user_id_provider.dart';
import 'package:anchor/core/router/app_routes.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/widgets/note_attachments_gallery.dart';
import 'package:anchor/features/notes/presentation/widgets/note_audio_recorder_sheet.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background_picker.dart';
import 'package:anchor/features/notes/presentation/widgets/note_options_sheet.dart';
import 'package:anchor/features/notes/presentation/widgets/share_note_sheet.dart';
import 'package:anchor/features/settings/presentation/controllers/editor_preferences_controller.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../data/repository/notes_repository.dart';
import 'package:anchor/core/theme/context_extensions.dart';
import 'package:anchor/core/theme/tokens/app_icon_sizes.dart';
import 'package:anchor/core/theme/tokens/app_radius.dart';
import 'package:anchor/core/widgets/app_bottom_sheet.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final Note? note;
  const NoteEditScreen({super.key, this.noteId, this.note});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _editorKey = GlobalKey<RichTextEditorState>();
  bool _isNew = true;
  bool _isDeleted = false;
  bool _isLoaded = false;
  bool _isEditing = false;
  bool _allowPop = false;
  bool _isHandlingPop = false;
  bool _isPinned = false;
  bool _isArchived = false;
  Note? _existingNote;
  String? _initialContent;
  List<String> _selectedTagIds = [];
  String? _selectedBackground;

  bool get _isReadOnly {
    final isActive =
        _existingNote == null || (_existingNote?.isActive ?? false);
    return !isActive || _existingNote?.permission == NotePermission.viewer;
  }

  Timer? _autoSaveTimer;
  StreamSubscription<Note?>? _noteWatch;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String _lastTitleText = '';

  String get _editorContent =>
      _editorKey.currentState?.getContent() ?? _initialContent ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final watchedId = widget.note?.id ?? widget.noteId;
    if (watchedId != null) {
      _watchNote(watchedId);
    }

    if (widget.note != null) {
      _isNew = false;
      _existingNote = widget.note;
      _isPinned = widget.note!.isPinned;
      _isArchived = widget.note!.isArchived;
      _lastTitleText = widget.note!.title;
      _titleController.text = widget.note!.title;
      _initialContent = widget.note!.content;
      _selectedTagIds = List.from(widget.note!.tagIds);
      _selectedBackground = widget.note!.background;
      _isLoaded = true;
      if (!widget.note!.isActive || !widget.note!.canEdit) {
        _isEditing = false;
      }
    } else if (widget.noteId != null) {
      _isNew = false;
      _loadNote();
    } else {
      _isEditing = true;
      _isPinned = false;
      _isLoaded = true;
    }

    _titleFocusNode.addListener(_updateEditingState);
    _titleController.addListener(_onTitleChanged);
  }

  void _updateEditingState() {
    final titleEditing = _titleFocusNode.hasFocus;
    final editorEditing = _editorKey.currentState?.isEditing ?? false;
    final newEditingState = _isReadOnly
        ? false
        : (titleEditing || editorEditing);

    if (_isEditing != newEditingState) {
      setState(() {
        _isEditing = newEditingState;
      });
    }
  }

  void _watchNote(String id) {
    _noteWatch?.cancel();
    _noteWatch = ref
        .read(notesRepositoryProvider)
        .watchNote(id)
        .listen(_onStoredNoteChanged);
  }

  /// The stored note changed under us. It replaces what is on screen unless
  /// there is an unsaved edit, which stays and goes up on the next save.
  void _onStoredNoteChanged(Note? note) {
    if (!mounted) return;

    if (note == null) {
      _handleNoteGone();
      return;
    }

    final adopt = !_hasUnsavedChanges && !_isSaving && !_matchesEditor(note);

    setState(() {
      _existingNote = note;
      _isLoaded = true;
      if (!adopt) return;

      if (_titleController.text != note.title) {
        _lastTitleText = note.title;
        _titleController.text = note.title;
      }
      _initialContent = note.content;
      _isPinned = note.isPinned;
      _isArchived = note.isArchived;
      _selectedTagIds = List.from(note.tagIds);
      _selectedBackground = note.background;
      if (!note.isActive || !note.canEdit) {
        _isEditing = false;
      }
    });
  }

  bool _matchesEditor(Note note) =>
      note.title == _titleController.text.trim() &&
      (note.content ?? '') == _editorContent &&
      note.isPinned == _isPinned &&
      note.isArchived == _isArchived &&
      note.background == _selectedBackground &&
      _listEquals(note.tagIds, _selectedTagIds);

  /// Deleted for good elsewhere, or a share that was revoked.
  void _handleNoteGone() {
    if (_isNew || _isDeleted) return;

    _isDeleted = true;
    _autoSaveTimer?.cancel();
    AppSnackbar.showError(context, message: 'This note is no longer available');
    _popOrExit();
  }

  Future<void> _loadNote() async {
    final note = await ref
        .read(notesRepositoryProvider)
        .getNote(widget.noteId!);
    if (note != null && mounted) {
      _lastTitleText = note.title;
      setState(() {
        _existingNote = note;
        _isPinned = note.isPinned;
        _isArchived = note.isArchived;
        _titleController.text = note.title;
        _initialContent = note.content;
        _selectedTagIds = List.from(note.tagIds);
        _selectedBackground = note.background;
        _isLoaded = true;
        if (!note.isActive || !note.canEdit) {
          _isEditing = false;
        }
      });
    }
  }

  /// The title controller also notifies on selection changes; only text
  /// changes mark the note dirty.
  void _onTitleChanged() {
    if (_titleController.text == _lastTitleText) return;
    _lastTitleText = _titleController.text;
    _onContentChanged();
  }

  void _onContentChanged() {
    _hasUnsavedChanges = true;
    _resetAutoSaveTimer();
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.difference(b).isEmpty;
  }

  void _resetAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges) return;

    await _savePendingChanges();
  }

  Future<void> _savePendingChanges() async {
    // Cleared before saving so edits made during the await stay flagged.
    _hasUnsavedChanges = false;
    _isSaving = true;
    try {
      await _saveNote();
    } finally {
      _isSaving = false;
    }
  }

  /// Leaves the editor: pops when there is a screen beneath, or exits the
  /// app when the editor is the root (opened from the home widget).
  void _popOrExit([Object? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> _saveAndPop([Object? result]) async {
    if (_isHandlingPop) return;

    _isHandlingPop = true;
    _autoSaveTimer?.cancel();

    try {
      // _saveNote skips when no field changed.
      if (!_isDeleted) {
        await _savePendingChanges();
      }
    } finally {
      if (mounted) {
        setState(() {
          _allowPop = true;
        });
        _popOrExit(result);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_hasUnsavedChanges) {
        _autoSave();
      }
    }
  }

  Future<void> _togglePinned() async {
    if (_existingNote?.isActive != true) {
      return;
    }
    setState(() {
      _isPinned = !_isPinned;
    });
    _onContentChanged();
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

      await _loadNote();

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          message: wasArchived ? 'Note unarchived' : 'Note archived',
        );

        if (!wasArchived) {
          // Small delay to ensure snackbar is visible
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _popOrExit();
          }
        }
      }
    } catch (e) {
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
    // New notes have no _existingNote yet but are always editable.
    if (!_isNew && _existingNote?.isActive != true) {
      return;
    }
    AppBottomSheet.show(
      context,
      builder: (context) => NoteBackgroundPicker(
        selectedColor: _selectedBackground,
        onColorChanged: (color) {
          setState(() {
            _selectedBackground = color;
          });
          _onContentChanged();
        },
      ),
    );
  }

  void _showShareSheet() {
    if (_isNew ||
        _existingNote?.isActive != true ||
        !(_existingNote?.isOwner ?? true)) {
      return;
    }
    AppBottomSheet.show(
      context,
      builder: (context) =>
          ShareNoteSheet(noteId: widget.noteId ?? _existingNote!.id),
    ).then((_) {
      if (widget.noteId != null || _existingNote != null) {
        _reloadNoteShareInfo();
      }
    });
  }

  void _showAttachmentSheet() {
    AppBottomSheet.show(
      context,
      builder: (context) => NoteAttachmentSheet(
        onFileSelected: (filePath, mimeType, filename) async {
          try {
            // Attachments are keyed to a persisted note. For a brand-new note
            // the user may start by adding an attachment, so create the note
            // now that there's something to attach to.
            var noteId = widget.noteId ?? _existingNote?.id;
            noteId ??= await _createNote();
            final repo = ref.read(noteAttachmentsRepositoryProvider);
            await repo.addAttachment(noteId, filePath, mimeType, filename);
            if (!context.mounted) return;
            AppSnackbar.showSuccess(context, message: 'Attachment added');
          } catch (_) {
            if (!context.mounted) return;
            AppSnackbar.showError(context, message: 'Failed to add attachment');
          }
        },
      ),
    );
  }

  void _showTagPicker() {
    if (_isReadOnly) return;
    AppBottomSheet.show(
      context,
      builder: (context) => TagPickerSheet(
        selectedTagIds: _selectedTagIds,
        onTagsChanged: (tagIds) {
          setState(() => _selectedTagIds = List.from(tagIds));
          _onContentChanged();
        },
      ),
    );
  }

  void _showOptionsSheet() {
    AppBottomSheet.show(
      context,
      builder: (context) => NoteOptionsSheet(
        isReadOnly: _isReadOnly,
        isNew: _isNew,
        isOwner: _existingNote?.isOwner ?? true,
        isArchived: _isArchived,
        onTagsTap: _showTagPicker,
        onBackgroundTap: _showColorPicker,
        onAttachmentTap: _showAttachmentSheet,
        onArchiveTap: _toggleArchived,
        onDeleteTap: _deleteNote,
        onHistoryTap: !_isNew && !_isReadOnly ? _openHistory : null,
      ),
    );
  }

  /// Sends what is typed so far before showing the versions.
  Future<void> _openHistory() async {
    final noteId = widget.noteId ?? _existingNote?.id;
    if (noteId == null) return;

    _autoSaveTimer?.cancel();
    await _savePendingChanges();
    if (!mounted) return;
    context.push('/note/$noteId/${AppRoutes.noteHistory}');
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    unawaited(_noteWatch?.cancel());
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _titleFocusNode.removeListener(_updateEditingState);
    _titleFocusNode.dispose();
    super.dispose();
  }

  /// Creates and persists a note from the current editor fields, flipping the
  /// screen out of "new" mode. Returns the created note's id.
  Future<String> _createNote() async {
    final title = _titleController.text.trim();
    final content = _editorKey.currentState?.getContent() ?? '';
    final newNote = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      isPinned: _isPinned,
      tagIds: _selectedTagIds,
      background: _selectedBackground,
      isSynced: false,
    );
    AppLogger.instance.info(
      'NoteEdit',
      '_createNote: id=${newNote.id} title.len=${newNote.title.length} '
          'content.len=${content.length} tags=${_selectedTagIds.length}',
    );
    await ref.read(notesRepositoryProvider).createNote(newNote);
    if (mounted) {
      setState(() {
        _isNew = false;
        _existingNote = newNote;
      });
      _watchNote(newNote.id);
    }
    return newNote.id;
  }

  Future<void> _saveNote() async {
    // New notes (_existingNote == null) are always treated as active/editable.
    final isActive =
        _existingNote == null || (_existingNote?.isActive ?? false);
    if (!isActive || !(_existingNote?.canEdit ?? true)) {
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
      AppLogger.instance.debug(
        'NoteEdit',
        '_saveNote: skipping empty note (isNew=$_isNew)',
      );
      return;
    }

    final repository = ref.read(notesRepositoryProvider);

    if (_isNew) {
      await _createNote();
    } else if (_existingNote != null) {
      final tagsChanged = !_listEquals(_existingNote!.tagIds, _selectedTagIds);
      final titleChanged = _existingNote!.title != title;
      final contentChanged = _existingNote!.content != content;
      final pinChanged = _existingNote!.isPinned != _isPinned;
      final bgChanged = _existingNote!.background != _selectedBackground;
      if (!titleChanged &&
          !contentChanged &&
          !pinChanged &&
          !bgChanged &&
          !tagsChanged) {
        AppLogger.instance.debug(
          'NoteEdit',
          '_saveNote: no field changed for id=${_existingNote!.id}, skipping',
        );
        return;
      }

      AppLogger.instance.info(
        'NoteEdit',
        '_saveNote update: id=${_existingNote!.id} '
            'title=$titleChanged content=$contentChanged '
            '(${_existingNote!.content?.length ?? 0}→${content.length}) '
            'pin=$pinChanged bg=$bgChanged tags=$tagsChanged',
      );

      final updatedNote = _existingNote!.copyWith(
        title: title,
        content: content,
        isPinned: _isPinned,
        isArchived: _isArchived,
        tagIds: _selectedTagIds,
        background: _selectedBackground,
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

  bool _listEquals(List<String> a, List<String> b) =>
      _setEquals(a.toSet(), b.toSet());

  Future<void> _deleteNote() async {
    if (_isNew) {
      _popOrExit();
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
          _popOrExit();
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
          _popOrExit();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Failed to delete note');
        }
      }
    }
  }

  Widget _buildSharedByBadge(ThemeData theme, String? serverUrl) {
    final sharedBy = _existingNote!.sharedBy!;
    final dims = context.dims;
    return Padding(
      padding: EdgeInsets.only(right: dims.xs),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dims.xs, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SharedByAvatar(
                sharedBy: sharedBy,
                serverUrl: serverUrl,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Shared by ${sharedBy.name}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton(ThemeData theme) {
    return IconButton(
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
      onPressed: _isLoaded ? _togglePinned : null,
      tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(LucideIcons.userPlus),
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
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
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
      onPressed: _isLoaded && !_isNew ? _showShareSheet : null,
      tooltip: 'Share Note',
    );
  }

  Widget _buildReadOnlyBanner(ThemeData theme, bool isTrashed) {
    final dims = context.dims;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dims.editorPadding.left,
        vertical: dims.sm,
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            LucideIcons.lock,
            size: AppIconSizes.sm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: dims.xs),
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
    );
  }

  Widget _buildEditorHeader(ThemeData theme) {
    final isReadOnly = _isReadOnly;
    final dims = context.dims;
    final showTags = (_isEditing && !isReadOnly) || _selectedTagIds.isNotEmpty;
    final showAttachments =
        !_isNew && (_existingNote != null || widget.noteId != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: dims.editorPadding.left,
            right: dims.editorPadding.right,
            top: dims.xs,
          ),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: isReadOnly ? 'Untitled' : 'Title',
                hintStyle: isReadOnly
                    ? theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )
                    : TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              textCapitalization: TextCapitalization.sentences,
              showCursor: _isEditing && !isReadOnly,
            ),
          ),
        ),
        if (showTags)
          TagSelector(
            selectedTagIds: _selectedTagIds,
            readOnly: !_isEditing || isReadOnly,
            onTagsChanged: (tagIds) {
              if (!isReadOnly) {
                setState(() => _selectedTagIds = tagIds);
                _onContentChanged();
              }
            },
          ),
        if (showAttachments)
          NoteAttachmentsGallery(
            noteId: widget.noteId ?? _existingNote!.id,
            isOwner: _existingNote?.isOwner ?? false,
            canEdit:
                (_existingNote?.canEdit ?? false) &&
                (_existingNote?.isActive ?? false),
            currentUserId: ref.read(activeUserIdProvider),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverUrl = ref.watch(serverUrlProvider);
    final isReadOnly = _isReadOnly;
    final isTrashed = _existingNote?.isTrashed ?? false;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndPop(result);
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
              onPressed: _saveAndPop,
            ),
            actions: [
              if (isTrashed) ...[
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  onPressed: _isLoaded && !_isNew ? _restoreNote : null,
                  tooltip: 'Restore Note',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: _isLoaded && !_isNew ? _permanentDeleteNote : null,
                  tooltip: 'Delete Forever',
                ),
              ] else ...[
                if (_existingNote?.sharedBy != null)
                  _buildSharedByBadge(theme, serverUrl),
                if (!isReadOnly) _buildPinButton(theme),
                if (_existingNote?.isOwner ?? true) _buildShareButton(theme),
                if (!isReadOnly || (_existingNote?.isOwner ?? true))
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical),
                    tooltip: 'More options',
                    onPressed: _showOptionsSheet,
                  ),
              ],
              SizedBox(width: context.dims.xs),
            ],
          ),
          body: Hero(
            tag: 'note_${widget.noteId ?? 'new'}',
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  if (isReadOnly) _buildReadOnlyBanner(theme, isTrashed),
                  Expanded(
                    child: _isLoaded
                        ? RichTextEditor(
                            key: _editorKey,
                            initialContent: _initialContent,
                            hintText: 'Start typing...',
                            showToolbar: !isReadOnly,
                            canEdit: !isReadOnly,
                            onEditingChanged: (_) => _updateEditingState(),
                            onChanged: _onContentChanged,
                            sortChecklistItems: ref
                                .watch(editorPreferencesControllerProvider)
                                .sortChecklistItems,
                            contentPadding: context.dims.editorPadding,
                            header: _buildEditorHeader(theme),
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
