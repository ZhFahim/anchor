import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/quill_preview.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_chip.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
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
                return _ArchiveNoteCard(
                  note: note,
                  onUnarchive: () => _showUnarchiveDialog(context, ref, note),
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

class _ArchiveNoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onUnarchive;

  const _ArchiveNoteCard({required this.note, required this.onUnarchive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagsControllerProvider);

    // Resolve card color for the Material/Card background
    final cardColor = note.background != null
        ? NoteBackground.resolveColor(context, note.background)
        : theme.cardTheme.color ?? theme.colorScheme.surface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/note/${note.id}', extra: note),
        child: NoteBackground(
          styleId: note.background,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned) ...[
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.pin,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                if (note.content != null && note.content!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  QuillPreview(content: note.content, maxLines: 3),
                ],
                if (note.tagIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  tagsAsync.when(
                    data: (allTags) {
                      final noteTags = allTags
                          .where((t) => note.tagIds.contains(t.id))
                          .take(3)
                          .toList();
                      final remaining = note.tagIds.length - noteTags.length;

                      return Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...noteTags.map(
                            (tag) => TagChip(tag: tag, selected: false),
                          ),
                          if (remaining > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+$remaining',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (note.updatedAt != null)
                      Text(
                        'Archived ${DateFormat.MMMd().format(note.updatedAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.archiveRestore),
                      onPressed: onUnarchive,
                      tooltip: 'Unarchive',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
