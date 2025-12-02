import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/core/widgets/quill_preview.dart';
import 'notes_controller.dart';
import '../../auth/presentation/auth_controller.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync controller with provider state if it exists
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.logOut,
        title: 'Log Out',
        message:
            'Are you sure you want to log out? Your unsynced notes will stay safe on this device.',
        cancelText: 'Stay',
        confirmText: 'Log Out',
        onConfirm: () async {
          await ref.read(authControllerProvider.notifier).logout();
          // Navigation is handled by the router redirect logic
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesControllerProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
              floating: true,
              pinned: true,
              expandedHeight: 80,
              scrolledUnderElevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Anchor',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw),
                  onPressed: () {
                    ref.read(notesControllerProvider.notifier).sync();
                  },
                  tooltip: 'Sync Notes',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => context.push('/trash'),
                  tooltip: 'Trash',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.logOut),
                  onPressed: () => _showLogoutDialog(context),
                  tooltip: 'Log Out',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  controller: _searchController,
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                  hintText: 'Search your thoughts...',
                  leading: const Icon(LucideIcons.search),
                  trailing: [
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                      ),
                  ],
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).set(value);
                  },
                ),
              ),
            ),
            notesAsync.when(
              data: (notes) {
                final filteredNotes = notes.where((note) {
                  if (searchQuery.isEmpty) return true;
                  final q = searchQuery.toLowerCase();
                  return note.title.toLowerCase().contains(q) ||
                      (note.content?.toLowerCase().contains(q) ?? false);
                }).toList();

                if (filteredNotes.isEmpty) {
                  if (searchQuery.isNotEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.search,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No matching notes found'),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('Capture your ideas here'),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(note: filteredNotes[index]);
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/note/new'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Note'),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'note_${note.id}',
      child: Material(
        color: Colors.transparent,
        child: Card(
          color: note.color != null
              ? Color(int.parse(note.color!))
              : Theme.of(context).cardTheme.color,
          child: InkWell(
            onTap: () => context.go('/note/${note.id}', extra: note),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.content != null && note.content!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    QuillPreview(content: note.content, maxLines: 6),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (note.updatedAt != null)
                        Text(
                          DateFormat.MMMd().format(note.updatedAt!),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      if (!note.isSynced)
                        Icon(
                          LucideIcons.cloudOff,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                    ],
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
