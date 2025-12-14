import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_selector.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background_picker.dart';
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
  final _editorKey = GlobalKey<RichTextEditorState>();
  bool _isNew = true;
  bool _isDeleted = false;
  bool _isLoaded = false;
  bool _isEditing = false;
  bool _isPinned = false;
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
      _titleController.text = widget.note!.title;
      _initialContent = widget.note!.content;
      _selectedTagIds = List.from(widget.note!.tagIds);
      _selectedBackground = widget.note!.background;
      _isLoaded = true;
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
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _loadNote() async {
    final note = await ref
        .read(notesRepositoryProvider)
        .getNote(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        _isPinned = note.isPinned;
        _titleController.text = note.title;
        _initialContent = note.content;
        _selectedTagIds = List.from(note.tagIds);
        _selectedBackground = note.background;
        _isLoaded = true;
      });
    }
  }

  Future<void> _togglePinned() async {
    setState(() {
      _isPinned = !_isPinned;
    });
    await _saveNote();
  }

  void _showColorPicker() {
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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
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
      await ref.read(notesRepositoryProvider).deleteNote(widget.noteId!);
      _isDeleted = true;

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isDeleted) {
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
                onPressed: _isLoaded ? _togglePinned : null,
                tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
              ),
              IconButton(
                icon: const Icon(LucideIcons.palette),
                onPressed: _showColorPicker,
                tooltip: 'Change Background',
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: _deleteNote,
                tooltip: 'Delete Note',
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: !_isEditing
              ? FloatingActionButton(
                  onPressed: _startEditing,
                  tooltip: 'Edit Note',
                  child: const Icon(LucideIcons.pencil),
                )
              : null,
          body: Hero(
            tag: 'note_${widget.noteId ?? 'new'}',
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _titleController,
                      readOnly: !_isEditing,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: _isEditing ? 'Title' : null,
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
                    ),
                  ),
                  if (_isEditing || _selectedTagIds.isNotEmpty)
                    TagSelector(
                      selectedTagIds: _selectedTagIds,
                      readOnly: !_isEditing,
                      onTagsChanged: (tagIds) {
                        setState(() {
                          _selectedTagIds = tagIds;
                        });
                      },
                    ),
                  Expanded(
                    child: _isLoaded
                        ? RichTextEditor(
                            key: _editorKey,
                            initialContent: _initialContent,
                            hintText: 'Start typing...',
                            showToolbar: _isEditing,
                            readOnly: !_isEditing,
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
