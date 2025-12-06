import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/quill_preview.dart';
import 'package:anchor/core/widgets/app_drawer.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_chip.dart';
import 'package:anchor/features/tags/domain/tag.dart';
import 'notes_controller.dart';

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

  Future<void> _onRefresh() async {
    await ref.read(notesControllerProvider.notifier).sync();
    ref.read(tagsControllerProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesControllerProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedTagId = ref.watch(selectedTagFilterProvider);
    final tagsAsync = ref.watch(tagsControllerProvider);
    final isSyncing = ref.watch(syncingStateProvider);
    final theme = Theme.of(context);

    // Get selected tag
    Tag? selectedTag;
    if (selectedTagId != null && tagsAsync.hasValue) {
      selectedTag = tagsAsync.value
          ?.where((t) => t.id == selectedTagId)
          .firstOrNull;
    }

    return Scaffold(
      drawer: const AppDrawer(),
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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          displacement: 20,
          edgeOffset: 120, // Position below the pinned app bar
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.8,
                ),
                floating: true,
                pinned: true,
                expandedHeight: 80,
                scrolledUnderElevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(LucideIcons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
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
                  // Only show sync indicator when actively syncing
                  if (isSyncing)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(child: _SyncIndicator(theme: theme)),
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchBar(
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
                      // Tag filter indicator
                      if (selectedTag != null) ...[
                        const SizedBox(height: 12),
                        _TagFilterChip(
                          tag: selectedTag,
                          onClear: () {
                            ref
                                .read(selectedTagFilterProvider.notifier)
                                .clear();
                          },
                        ),
                      ],
                    ],
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/note/new'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Note'),
      ),
    );
  }
}

class NoteCard extends ConsumerWidget {
  final Note note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsControllerProvider);

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
                  if (note.tagIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+$remaining',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
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

class _TagFilterChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback onClear;

  const _TagFilterChip({required this.tag, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = parseTagColor(
      tag.color,
      fallback: theme.colorScheme.primary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.filter, size: 14, color: tagColor),
                const SizedBox(width: 6),
                Text(
                  'Filtering by',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.hash, size: 12, color: tagColor),
                      const SizedBox(width: 2),
                      Text(
                        tag.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncIndicator extends StatefulWidget {
  final ThemeData theme;

  const _SyncIndicator({required this.theme});

  @override
  State<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<_SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: Icon(
        LucideIcons.refreshCw,
        size: 20,
        color: widget.theme.colorScheme.onSurface,
      ),
    );
  }
}
