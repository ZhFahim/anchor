import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import '../data/repository/notes_repository.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isNew = true;
  bool _isDeleted = false;
  Note? _existingNote;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _isNew = false;
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    final note = await ref
        .read(notesRepositoryProvider)
        .getNote(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content ?? '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isDeleted) {
          await _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
        body: Hero(
          tag: 'note_${widget.noteId ?? 'new'}',
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: false,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 24,
                        ),
                        filled: false,
                      ),
                      maxLines: null,
                      expands: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
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
