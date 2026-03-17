import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/widgets/image_shimmer.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/domain/note_attachment.dart';
import 'package:anchor/features/notes/presentation/widgets/audio_player_row.dart';

class NoteAttachmentsGallery extends ConsumerStatefulWidget {
  final String noteId;
  final bool isOwner;
  final bool canEdit;
  final String? currentUserId;

  const NoteAttachmentsGallery({
    super.key,
    required this.noteId,
    this.isOwner = false,
    this.canEdit = false,
    this.currentUserId,
  });

  @override
  ConsumerState<NoteAttachmentsGallery> createState() =>
      _NoteAttachmentsGalleryState();
}

class _NoteAttachmentsGalleryState
    extends ConsumerState<NoteAttachmentsGallery> {
  /// Owner can delete any attachment; editors can delete their own uploads.
  /// No modifications when canEdit is false (e.g. trashed notes).
  bool _canDeleteAttachment(NoteAttachment a) {
    if (!widget.canEdit) return false;
    if (widget.isOwner) return true;
    // Pending uploads were created locally by this user
    if (a.isPendingUpload) return true;
    return widget.currentUserId != null &&
        a.uploadedByUserId == widget.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(noteAttachmentsRepositoryProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return StreamBuilder<List<NoteAttachment>>(
      stream: repo.watchAttachments(widget.noteId),
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? [];
        if (attachments.isEmpty) {
          return const SizedBox.shrink();
        }

        final images = attachments.where((a) => a.isImage).toList();
        final audios = attachments.where((a) => a.isAudio).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: GestureDetector(
            onTap: () {}, // Prevent taps in gallery area from focusing editor
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  _ImageGrid(
                    noteId: widget.noteId,
                    attachments: images,
                    canDeleteAttachment: _canDeleteAttachment,
                    repo: repo,
                    isOnline: isOnline,
                  ),
                if (audios.isNotEmpty) ...[
                  if (images.isNotEmpty) const SizedBox(height: 16),
                  ...audios.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AudioPlayerRow(
                        attachment: a,
                        localPath: a.localPath,
                        canDelete: _canDeleteAttachment(a),
                        isOnline: isOnline,
                        onDelete: () =>
                            repo.deleteAttachment(widget.noteId, a.id),
                        onDownload: () => repo.downloadAttachment(
                          widget.noteId,
                          a.id,
                          a.originalFilename,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Adaptive image grid
class _ImageGrid extends StatelessWidget {
  final String noteId;
  final List<NoteAttachment> attachments;
  final bool Function(NoteAttachment) canDeleteAttachment;
  final NoteAttachmentsRepository repo;
  final bool isOnline;

  const _ImageGrid({
    required this.noteId,
    required this.attachments,
    required this.canDeleteAttachment,
    required this.repo,
    required this.isOnline,
  });

  Widget _tile(
    int index, {
    double? aspectRatio,
    double borderRadius = 14,
    bool fillHeight = false,
    String? overlay,
  }) {
    return _ImageTile(
      key: ValueKey(attachments[index].id),
      noteId: noteId,
      attachment: attachments[index],
      canDelete: canDeleteAttachment(attachments[index]),
      canDeleteAttachment: canDeleteAttachment,
      repo: repo,
      isOnline: isOnline,
      allImages: attachments,
      index: index,
      aspectRatio: aspectRatio,
      borderRadius: borderRadius,
      fillHeight: fillHeight,
      overlay: overlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = attachments.length;

    if (count == 1) {
      return _tile(0, aspectRatio: 16 / 10, borderRadius: 16);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _tile(0, aspectRatio: 1)),
          const SizedBox(width: 6),
          Expanded(child: _tile(1, aspectRatio: 1)),
        ],
      );
    }

    if (count == 3) {
      return SizedBox(
        height: 240,
        child: Row(
          children: [
            Expanded(flex: 3, child: _tile(0, fillHeight: true)),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: _tile(1, fillHeight: true)),
                  const SizedBox(height: 6),
                  Expanded(child: _tile(2, fillHeight: true)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Four or more - 2x2 grid with overflow
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(0, fillHeight: true)),
                const SizedBox(height: 6),
                Expanded(child: _tile(2, fillHeight: true)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(1, fillHeight: true)),
                const SizedBox(height: 6),
                Expanded(
                  child: _tile(
                    3,
                    fillHeight: true,
                    overlay: count > 4 ? '+${count - 4}' : null,
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

/// Image tile with loading, error, lightbox
class _ImageTile extends ConsumerStatefulWidget {
  final String noteId;
  final NoteAttachment attachment;
  final bool canDelete;
  final bool Function(NoteAttachment) canDeleteAttachment;
  final NoteAttachmentsRepository repo;
  final bool isOnline;
  final double? aspectRatio;
  final double borderRadius;
  final bool fillHeight;
  final String? overlay;

  final List<NoteAttachment> allImages;
  final int index;

  const _ImageTile({
    super.key,
    required this.noteId,
    required this.attachment,
    required this.canDelete,
    required this.canDeleteAttachment,
    required this.repo,
    required this.isOnline,
    required this.allImages,
    required this.index,
    this.aspectRatio,
    this.borderRadius = 12,
    this.fillHeight = false,
    this.overlay,
  });

  @override
  ConsumerState<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends ConsumerState<_ImageTile> {
  String? _imagePath;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _ImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If localPath appeared (e.g. from a background sync/download), show it
    if (widget.attachment.localPath != null &&
        widget.attachment.localPath != oldWidget.attachment.localPath) {
      setState(() {
        _imagePath = widget.attachment.localPath;
        _loading = false;
        _error = false;
      });
    }
  }

  Future<void> _loadImage() async {
    if (widget.attachment.localPath != null) {
      final file = File(widget.attachment.localPath!);
      if (file.existsSync() && file.lengthSync() > 0) {
        if (mounted) {
          setState(() {
            _imagePath = widget.attachment.localPath;
            _loading = false;
          });
        }
        return;
      }
      // Fall through to download if file is missing or zero-byte
    }
    if (!widget.isOnline) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
      return;
    }
    try {
      final p = await widget.repo.downloadAttachment(
        widget.noteId,
        widget.attachment.id,
        widget.attachment.originalFilename,
      );
      if (mounted) {
        setState(() {
          _imagePath = p;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _openLightbox() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ImageLightboxGallery(
          noteId: widget.noteId,
          attachments: widget.allImages,
          initialIndex: widget.index,
          canDeleteAttachment: widget.canDeleteAttachment,
          repo: widget.repo,
          isOnline: widget.isOnline,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirm = await ConfirmDialog.show(
      context: context,
      icon: LucideIcons.trash2,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Delete attachment?',
      message:
          'This will permanently delete "${widget.attachment.originalFilename}".',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirm == true) {
      widget.repo.deleteAttachment(widget.noteId, widget.attachment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-retry when connection is restored
    ref.listen(connectivityStreamProvider, (previous, next) {
      next.whenData((results) {
        if (isOnlineFromResults(results) && _error && mounted) {
          setState(() {
            _error = false;
            _loading = true;
          });
          _loadImage();
        }
      });
    });

    Widget content;

    if (_loading) {
      content = const ImageShimmer();
    } else if (_error || _imagePath == null) {
      content = Container(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isOnline ? LucideIcons.imageOff : LucideIcons.cloudOff,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Available when online',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      content = Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
        cacheWidth: 800, // Downscale image during decode for fast rendering
        errorBuilder: (_, _, _) {
          // Image file is corrupt — schedule recovery after this build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Delete the corrupt file so the next attempt re-downloads
            try {
              File(_imagePath!).deleteSync();
            } catch (_) {}
            setState(() {
              _imagePath = null;
              _error = true;
              _loading = false;
            });
          });
          return const ImageShimmer();
        },
      );
    }

    Widget tile = Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,

            // Pending upload badge
            if (widget.attachment.isPendingUpload)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.uploadCloud,
                        size: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Overlay for extra count
            if (widget.overlay != null)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    widget.overlay!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Tap to open lightbox
            if (_imagePath != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openLightbox,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),

            // Delete button
            if (widget.canDelete && _imagePath != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _confirmDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.fillHeight) {
      return tile;
    }

    if (widget.aspectRatio != null) {
      return AspectRatio(aspectRatio: widget.aspectRatio!, child: tile);
    }

    return tile;
  }
}

/// Full-screen image lightbox gallery for viewing all images
class _ImageLightboxGallery extends ConsumerStatefulWidget {
  final String noteId;
  final List<NoteAttachment> attachments;
  final int initialIndex;
  final bool Function(NoteAttachment) canDeleteAttachment;
  final NoteAttachmentsRepository repo;
  final bool isOnline;

  const _ImageLightboxGallery({
    required this.noteId,
    required this.attachments,
    required this.initialIndex,
    required this.canDeleteAttachment,
    required this.repo,
    required this.isOnline,
  });

  @override
  ConsumerState<_ImageLightboxGallery> createState() =>
      _ImageLightboxGalleryState();
}

class _ImageLightboxGalleryState extends ConsumerState<_ImageLightboxGallery> {
  late PageController _pageController;
  late int _currentIndex;
  // Keyed by attachmentId (not index) so entries stay correct if the list
  // reorders while the lightbox is open.
  final Map<String, String?> _imagePaths = {};
  final Map<String, bool> _loading = {};
  final Map<String, bool> _errors = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadImage(_currentIndex);
    // Preload next/prev
    if (_currentIndex > 0) _loadImage(_currentIndex - 1);
    if (_currentIndex < widget.attachments.length - 1) {
      _loadImage(_currentIndex + 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImage(int index) async {
    final attachment = widget.attachments[index];
    final id = attachment.id;

    if (_imagePaths.containsKey(id) || _loading[id] == true) return;

    if (mounted) {
      setState(() {
        _loading[id] = true;
      });
    }

    if (attachment.localPath != null) {
      final file = File(attachment.localPath!);
      if (file.existsSync() && file.lengthSync() > 0) {
        if (mounted) {
          setState(() {
            _imagePaths[id] = attachment.localPath;
            _loading[id] = false;
          });
        }
        return;
      }
    }

    final online = ref.read(isOnlineProvider);
    if (!online) {
      if (mounted) {
        setState(() {
          _loading[id] = false;
          _errors[id] = true;
        });
      }
      return;
    }

    try {
      final p = await widget.repo.downloadAttachment(
        widget.noteId,
        attachment.id,
        attachment.originalFilename,
      );
      if (mounted) {
        setState(() {
          _imagePaths[id] = p;
          _loading[id] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading[id] = false;
          _errors[id] = true;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadImage(index);
    if (index > 0) _loadImage(index - 1);
    if (index < widget.attachments.length - 1) _loadImage(index + 1);
  }

  Future<void> _deleteCurrent() async {
    final attachment = widget.attachments[_currentIndex];
    final confirm = await ConfirmDialog.show(
      context: context,
      icon: LucideIcons.trash2,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Delete attachment?',
      message: 'This will permanently delete "${attachment.originalFilename}".',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirm == true && mounted) {
      widget.repo.deleteAttachment(widget.noteId, attachment.id);
      context.pop();
    }
  }

  PhotoViewGalleryPageOptions _buildPageOptions(
    BuildContext context,
    int index,
    bool isOnline,
  ) {
    _loadImage(index);

    final id = widget.attachments[index].id;
    final imagePath = _imagePaths[id];
    final isLoading = _loading[id] ?? true;
    final hasError = _errors[id] ?? false;
    if (hasError || (!isLoading && imagePath == null)) {
      return PhotoViewGalleryPageOptions.customChild(
        child: _buildGalleryState(
          context,
          icon: isOnline ? LucideIcons.imageOff : LucideIcons.cloudOff,
          label: isOnline ? 'Failed to load image' : 'Available when online',
        ),
        childSize: MediaQuery.sizeOf(context),
        disableGestures: true,
      );
    }

    if (imagePath == null) {
      return PhotoViewGalleryPageOptions.customChild(
        child: _buildGalleryLoadingState(context),
        childSize: MediaQuery.sizeOf(context),
        disableGestures: true,
      );
    }

    return PhotoViewGalleryPageOptions(
      imageProvider: ResizeImage(FileImage(File(imagePath)), width: 1600),
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      filterQuality: FilterQuality.medium,
      tightMode: true,
      errorBuilder: (context, error, stackTrace) => _buildGalleryState(
        context,
        icon: LucideIcons.imageOff,
        label: 'Failed to render image',
      ),
    );
  }

  Widget _buildGalleryLoadingState(BuildContext context) {
    return const ImageShimmer(dark: true);
  }

  Widget _buildGalleryState(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentAttachment = widget.attachments[_currentIndex];
    final isOnline = ref.watch(isOnlineProvider);

    // Auto-retry when connection is restored
    ref.listen(connectivityStreamProvider, (previous, next) {
      next.whenData((results) {
        if (!isOnlineFromResults(results) || !mounted) return;
        // Retry all failed loads
        for (var i = 0; i < widget.attachments.length; i++) {
          final id = widget.attachments[i].id;
          if (_errors[id] == true) {
            setState(() {
              _errors.remove(id);
              _loading[id] = true;
            });
            _loadImage(i);
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              scrollPhysics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: widget.attachments.length,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              builder: (context, index) =>
                  _buildPageOptions(context, index, isOnline),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentAttachment.originalFilename,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_currentIndex + 1} of ${widget.attachments.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.canDeleteAttachment(currentAttachment))
                      IconButton(
                        onPressed: _deleteCurrent,
                        icon: Icon(
                          LucideIcons.trash2,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
