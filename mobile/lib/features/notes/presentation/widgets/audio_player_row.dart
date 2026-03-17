import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:anchor/core/widgets/confirm_dialog.dart';
import 'package:anchor/features/notes/domain/note_attachment.dart';

class AudioPlayerRow extends StatefulWidget {
  final NoteAttachment attachment;
  final String? localPath;
  final bool canDelete;
  final bool isOnline;
  final VoidCallback? onDelete;
  final Future<String> Function()? onDownload;

  const AudioPlayerRow({
    super.key,
    required this.attachment,
    this.localPath,
    this.canDelete = false,
    this.isOnline = true,
    this.onDelete,
    this.onDownload,
  });

  @override
  State<AudioPlayerRow> createState() => _AudioPlayerRowState();
}

class _AudioPlayerRowState extends State<AudioPlayerRow> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<PlayerException> _errorSub;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isCompleted = false;
  String? _loadedPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    // Track both playing state and processingState per the just_audio state model
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final completed = state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = state.playing && !completed;
        _isCompleted = completed;
      });
    });

    _positionSub = _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (mounted && duration != null) setState(() => _duration = duration);
    });

    // Listen to playback errors per the just_audio docs
    _errorSub = _player.errorStream.listen((e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Playback error: ${e.message}');
      }
    });
  }

  @override
  void didUpdateWidget(AudioPlayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If localPath became available (e.g. after sync), reset the loaded path
    // so the next play picks up the new file instead of trying to re-download.
    if (oldWidget.localPath != widget.localPath && widget.localPath != null) {
      _loadedPath = null;
    }
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _errorSub.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    // If playback completed, seek back to the start and replay
    if (_isCompleted) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    final filePath = widget.localPath ?? _loadedPath;

    if (filePath != null && File(filePath).existsSync()) {
      // Use AudioSource.uri with a file URI as per the just_audio docs
      if (_loadedPath != filePath) {
        await _player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
        _loadedPath = filePath;
      }
      await _player.play();
    } else if (widget.onDownload != null) {
      if (!widget.isOnline) {
        AppSnackbar.showInfo(context, message: 'Available when online');
        return;
      }
      setState(() => _isLoading = true);
      try {
        final downloadedPath = await widget.onDownload!();
        _loadedPath = downloadedPath;
        await _player.setAudioSource(AudioSource.uri(Uri.file(downloadedPath)));
        await _player.play();
      } on PlayerException catch (e) {
        if (mounted) {
          AppSnackbar.showError(
            context,
            message: 'Could not play audio: ${e.message}',
          );
        }
      } catch (_) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Failed to load audio');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirm = await ConfirmDialog.show(
      context: context,
      icon: LucideIcons.trash2,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Delete audio?',
      message:
          'This will permanently delete "${widget.attachment.originalFilename}".',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirm == true) {
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.attachment.originalFilename;
    final truncated = name.length > 30 ? '${name.substring(0, 27)}...' : name;

    return GestureDetector(
      onTap: _isLoading ? null : _togglePlay, // Tap the card to play/pause
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon, filename, play button, delete
            Row(
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlay,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isLoading
                        ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _isPlaying
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? LucideIcons.pause
                                : _isCompleted
                                ? LucideIcons.rotateCcw
                                : LucideIcons.play,
                            size: 24,
                            color: _isPlaying
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Filename and waveform icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              truncated,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.attachment.isPendingUpload)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.upload,
                                    size: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pending',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCompleted
                            ? 'Tap to replay'
                            : _duration.inMilliseconds > 0
                            ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                            : 'Tap to play',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (widget.canDelete) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    tooltip: 'Delete audio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(shape: const CircleBorder()),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
