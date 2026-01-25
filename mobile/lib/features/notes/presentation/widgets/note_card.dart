import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/core/widgets/quill_preview.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:anchor/features/tags/presentation/widgets/tag_chip.dart';
import 'package:anchor/features/notes/presentation/widgets/note_background.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsControllerProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final theme = Theme.of(context);

    // Resolve card color for the Material/Card background
    // If note.background is null, we use the card theme color or surface
    final cardColor = note.background != null
        ? NoteBackground.resolveColor(context, note.background)
        : theme.cardTheme.color ?? theme.colorScheme.surface;

    return Hero(
      tag: 'note_${note.id}',
      child: Material(
        color: Colors.transparent,
        child: Card(
          color: cardColor,
          clipBehavior: Clip.antiAlias,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap ?? () => context.go('/note/${note.id}', extra: note),
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                NoteBackground(
                  styleId: note.background,
                  borderRadius: BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelectionMode) ...[
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        LucideIcons.check,
                                        size: 16,
                                        color: theme.colorScheme.onPrimary,
                                      )
                                    : null,
                              ),
                            ],
                            Expanded(
                              child: Text(
                                note.title,
                                style: theme.textTheme.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isSelectionMode) ...[
                              if (note.isPinned) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.pin,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ],
                        ),
                        if (note.content != null &&
                            note.content!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          QuillPreview(content: note.content, maxLines: 6),
                        ],
                        if (note.tagIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          tagsAsync.when(
                            data: (allTags) {
                              // Only show tags that belong to the current user (shared notes may have tags from other users)
                              final userNoteTags = allTags
                                  .where((t) => note.tagIds.contains(t.id))
                                  .toList();

                              // Skip if no matching tags for current user
                              if (userNoteTags.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final displayedTags = userNoteTags
                                  .take(3)
                                  .toList();
                              final remaining =
                                  userNoteTags.length - displayedTags.length;

                              return Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  ...displayedTags.map(
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (note.sharedBy != null) ...[
                                  Tooltip(
                                    message: 'Shared by ${note.sharedBy!.name}',
                                    child: _SharedByAvatar(
                                      sharedBy: note.sharedBy!,
                                      serverUrl: serverUrl,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (note.updatedAt != null)
                                  Text(
                                    DateFormat.MMMd().format(note.updatedAt!),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (!note.isSynced)
                              Icon(
                                LucideIcons.cloudOff,
                                size: 16,
                                color: theme.hintColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          sharedBy.name.isNotEmpty ? sharedBy.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}
