import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
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
  Note? _existingNote;
  String? _initialContent;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      // Note passed directly
      _isNew = false;
      _existingNote = widget.note;
      _titleController.text = widget.note!.title;
      _initialContent = widget.note!.content;
      _isLoaded = true;
    } else if (widget.noteId != null) {
      // Fallback: fetch from repository if only ID is provided
      _isNew = false;
      _loadNote();
    } else {
      // New notes start in edit mode
      _isEditing = true;
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
        _titleController.text = note.title;
        _initialContent = note.content;
        _isLoaded = true;
      });
    }
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

    if (title.isEmpty && plainText.isEmpty) return;

    final repository = ref.read(notesRepositoryProvider);

    if (_isNew) {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isNotEmpty ? title : 'Untitled',
        content: content,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await repository.createNote(newNote);
    } else if (_existingNote != null) {
      if (_existingNote!.title == title && _existingNote!.content == content) {
        return;
      }

      final updatedNote = _existingNote!.copyWith(
        title: title,
        content: content,
        isSynced: false,
      );
      await repository.updateNote(updatedNote);
    }
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
        if (didPop && !_isDeleted && _isEditing) {
          await _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.pin),
              onPressed: () {}, // TODO: Implement pin
              tooltip: 'Pin Note',
            ),
            IconButton(
              icon: const Icon(LucideIcons.palette),
              onPressed: () {}, // TODO: Implement color picker
              tooltip: 'Change Color',
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: false,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
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
    );
  }
}
