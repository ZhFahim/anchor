import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:anchor/features/notes/presentation/widgets/note_card.dart';
import 'notes_controller.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  void _showUnarchiveDialog(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.archiveRestore,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Unarchive Note',
        message: 'This note will be moved back to your notes.',
        cancelText: 'Cancel',
        confirmText: 'Unarchive',
        onConfirm: () async {
          try {
            await ref
                .read(archiveControllerProvider.notifier)
                .unarchiveNote(note.id);
            if (context.mounted) {
              AppSnackbar.showSuccess(context, message: 'Note unarchived');
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackbar.showError(
                context,
                message: 'Failed to unarchive note',
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(archiveControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Archive',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: archiveAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.archive, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'Archive is empty',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NoteCard(
                    note: note,
                    datePrefix: 'Archived',
                    onTap: () => context.push('/note/${note.id}', extra: note),
                    trailingActions: [
                      IconButton(
                        icon: const Icon(LucideIcons.archiveRestore),
                        onPressed: () =>
                            _showUnarchiveDialog(context, ref, note),
                        tooltip: 'Unarchive',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
