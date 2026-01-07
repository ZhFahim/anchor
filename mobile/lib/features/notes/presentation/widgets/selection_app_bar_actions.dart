import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/quill_preview.dart'
    show extractPlainTextFromQuillContent;
import '../notes_controller.dart';

class SelectionAppBarActions extends ConsumerWidget {
  final Set<String> selectedNoteIds;
  final VoidCallback onExitSelectionMode;

  const SelectionAppBarActions({
    super.key,
    required this.selectedNoteIds,
    required this.onExitSelectionMode,
  });

  Future<void> _handleArchive(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.archive,
        iconColor: theme.colorScheme.primary,
        title: 'Archive Notes',
        message: 'Archive ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}?',
        cancelText: 'Cancel',
        confirmText: 'Archive',
        onConfirm: () {},
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(notesControllerProvider.notifier).bulkArchiveNotes(ids);
        onExitSelectionMode();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${ids.length} ${ids.length == 1 ? 'note' : 'notes'} archived',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to archive notes'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.trash2,
        iconColor: theme.colorScheme.error,
        title: 'Delete Notes',
        message:
            'Delete ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}? This action cannot be undone.',
        cancelText: 'Cancel',
        confirmText: 'Delete',
        onConfirm: () {},
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(notesControllerProvider.notifier).bulkDeleteNotes(ids);
        onExitSelectionMode();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${ids.length} ${ids.length == 1 ? 'note' : 'notes'} deleted',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete notes'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesControllerProvider);
    final query = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);

    final filteredNotes = notes.maybeWhen(
      data: (notesList) {
        return notesList.where((note) {
          if (query.isEmpty) return true;
          final q = query.toLowerCase();
          final contentText = extractPlainTextFromQuillContent(
            note.content,
          ).toLowerCase();
          return note.title.toLowerCase().contains(q) ||
              contentText.contains(q);
        }).toList();
      },
      orElse: () => <Note>[],
    );

    final allSelected =
        filteredNotes.isNotEmpty &&
        selectedNoteIds.length == filteredNotes.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archive button
        if (selectedNoteIds.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.archive),
            onPressed: () =>
                _handleArchive(context, ref, selectedNoteIds.toList()),
            tooltip: 'Archive',
          ),
        // Delete button
        if (selectedNoteIds.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () =>
                _handleDelete(context, ref, selectedNoteIds.toList()),
            tooltip: 'Delete',
            color: theme.colorScheme.error,
          ),
        // Select all button
        IconButton(
          icon: Icon(
            allSelected ? LucideIcons.checkSquare : LucideIcons.square,
          ),
          onPressed: () {
            if (allSelected) {
              ref.read(selectedNoteIdsProvider.notifier).clear();
            } else {
              ref
                  .read(selectedNoteIdsProvider.notifier)
                  .selectAll(filteredNotes.map((n) => n.id).toList());
            }
          },
          tooltip: allSelected ? 'Deselect all' : 'Select all',
        ),
      ],
    );
  }
}
