import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/core/widgets/image_shimmer.dart';
import 'package:anchor/core/widgets/quill_preview.dart';
import 'package:anchor/core/network/connectivity_provider.dart';
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
  final String? datePrefix;
  final List<Widget>? trailingActions;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.datePrefix,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsControllerProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final theme = Theme.of(context);
    final hasImages = note.imagePreviewData.isNotEmpty;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImages)
                  Stack(
                    children: [
                      _NoteImagePreviews(previews: note.imagePreviewData),
                      if (isSelectionMode || note.isPinned)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: isSelectionMode
                              ? _SelectionBadge(isSelected: isSelected)
                              : _PinBadge(),
                        ),
                    ],
                  ),
                NoteBackground(
                  styleId: note.background,
                  borderRadius: BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelectionMode && !hasImages) ...[
                              _SelectionBadge(isSelected: isSelected),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                note.title,
                                style: theme.textTheme.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isSelectionMode &&
                                !hasImages &&
                                note.isPinned) ...[
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.pin,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (note.content != null &&
                            note.content!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          QuillPreview(content: note.content, maxLines: 6),
                        ],
                        if (note.tagIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          tagsAsync.when(
                            data: (allTags) {
                              final userNoteTags = allTags
                                  .where((t) => note.tagIds.contains(t.id))
                                  .toList();
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
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
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
                        const SizedBox(height: 14),
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
                                    datePrefix != null
                                        ? '$datePrefix ${DateFormat.MMMd().format(note.updatedAt!)}'
                                        : DateFormat.MMMd().format(
                                            note.updatedAt!,
                                          ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (trailingActions != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: trailingActions!,
                              ),
                            if (trailingActions == null && !note.isSynced)
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

class _SelectionBadge extends StatelessWidget {
  final bool isSelected;
  const _SelectionBadge({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.primary : Colors.black26,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(
              LucideIcons.check,
              size: 14,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(LucideIcons.pin, size: 13, color: Colors.white),
    );
  }
}

/// Full-bleed image block at the top of a note card.
class _NoteImagePreviews extends StatelessWidget {
  final List<NoteImagePreview> previews;

  const _NoteImagePreviews({required this.previews});

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) return const SizedBox.shrink();

    final count = previews.length;

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _Thumb(
          key: ValueKey(previews[0].attachmentId),
          preview: previews[0],
        ),
      );
    }

    if (count == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(
          children: [
            Expanded(
              child: _Thumb(
                key: ValueKey(previews[0].attachmentId),
                preview: previews[0],
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: _Thumb(
                key: ValueKey(previews[1].attachmentId),
                preview: previews[1],
              ),
            ),
          ],
        ),
      );
    }

    if (count == 3) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _Thumb(
                key: ValueKey(previews[0].attachmentId),
                preview: previews[0],
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Thumb(
                      key: ValueKey(previews[1].attachmentId),
                      preview: previews[1],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: _Thumb(
                      key: ValueKey(previews[2].attachmentId),
                      preview: previews[2],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4-up grid
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Thumb(
                    key: ValueKey(previews[0].attachmentId),
                    preview: previews[0],
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _Thumb(
                    key: ValueKey(previews[1].attachmentId),
                    preview: previews[1],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Thumb(
                    key: ValueKey(previews[2].attachmentId),
                    preview: previews[2],
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _Thumb(
                    key: ValueKey(previews[3].attachmentId),
                    preview: previews[3],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single thumbnail tile that downloads the image on demand if not cached locally.
class _Thumb extends ConsumerStatefulWidget {
  final NoteImagePreview preview;

  const _Thumb({super.key, required this.preview});

  @override
  ConsumerState<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends ConsumerState<_Thumb> {
  String? _resolvedPath;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _Thumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the local path appeared (e.g. after sync downloaded the file), use it
    if (widget.preview.localPath != null &&
        widget.preview.localPath != oldWidget.preview.localPath) {
      setState(() {
        _resolvedPath = widget.preview.localPath;
        _error = false;
      });
    }
  }

  Future<void> _resolveImage() async {
    final localPath = widget.preview.localPath;
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        if (mounted) setState(() => _resolvedPath = localPath);
        return;
      }
    }

    // Download from server
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final repo = ref.read(noteAttachmentsRepositoryProvider);
      final path = await repo.downloadAttachment(
        widget.preview.noteId,
        widget.preview.attachmentId,
        widget.preview.filename,
      );
      if (mounted) setState(() => _resolvedPath = path);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((results) {
          if (isOnlineFromResults(results) && _error && mounted) {
            _resolveImage();
          }
        });
      },
    );

    if (_resolvedPath != null && File(_resolvedPath!).existsSync()) {
      return Image.file(
        File(_resolvedPath!),
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (_, _, _) => _placeholder(theme),
      );
    }

    if (_loading) {
      return const ImageShimmer();
    }

    if (_error) {
      return _placeholder(theme);
    }

    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
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
