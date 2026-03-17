import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class NoteAttachmentSheet extends StatefulWidget {
  final Future<void> Function(String filePath, String mimeType, String filename)
  onFileSelected;

  const NoteAttachmentSheet({super.key, required this.onFileSelected});

  @override
  State<NoteAttachmentSheet> createState() => _NoteAttachmentSheetState();
}

enum _SheetState { idle, recording, preview }

class _NoteAttachmentSheetState extends State<NoteAttachmentSheet> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  _SheetState _sheetState = _SheetState.idle;

  // Recording state
  Duration _recordingDuration = Duration.zero;
  late DateTime _recordingStart;
  Timer? _recordingTimer;

  // Preview state
  String? _previewPath;
  Duration _previewDuration = Duration.zero;
  Duration _previewPosition = Duration.zero;
  bool _previewPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_sheetState == _SheetState.recording) {
      _recorder.stop();
    }
    _recorder.dispose();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: 'Microphone permission required',
        );
      }
      return;
    }

    // Clean up any previous preview
    await _player.stop();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    if (_previewPath != null) {
      try {
        await File(_previewPath!).delete();
      } catch (_) {}
    }

    final dir = await getTemporaryDirectory();
    final filePath = path.join(
      dir.path,
      'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 192000,
        sampleRate: 44100,
        numChannels: 2,
        echoCancel: true,
        autoGain: true,
        noiseSuppress: true,
      ),
      path: filePath,
    );
    _recordingStart = DateTime.now();
    setState(() {
      _sheetState = _SheetState.recording;
      _recordingDuration = Duration.zero;
      _previewPath = null;
      _previewDuration = Duration.zero;
      _previewPosition = Duration.zero;
      _previewPlaying = false;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sheetState != _SheetState.recording) return;
      setState(() {
        _recordingDuration = DateTime.now().difference(_recordingStart);
      });
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final recordedPath = await _recorder.stop();

    if (recordedPath == null || !mounted) {
      setState(() => _sheetState = _SheetState.idle);
      return;
    }

    // Load into player to get duration and enable preview
    try {
      final duration = await _player.setFilePath(recordedPath);
      _positionSub = _player.positionStream.listen((pos) {
        if (mounted) setState(() => _previewPosition = pos);
      });
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _previewPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _player.stop();
          setState(() {
            _previewPlaying = false;
            _previewPosition = Duration.zero;
          });
        }
      });

      setState(() {
        _sheetState = _SheetState.preview;
        _previewPath = recordedPath;
        _previewDuration = duration ?? Duration.zero;
        _previewPosition = Duration.zero;
        _previewPlaying = false;
      });
    } catch (_) {
      // Fallback: just save directly if player fails
      if (mounted) {
        final filename = path.basename(recordedPath);
        context.pop();
        await widget.onFileSelected(recordedPath, 'audio/mp4', filename);
      }
    }
  }

  Future<void> _togglePreviewPlay() async {
    if (_previewPlaying) {
      await _player.pause();
    } else {
      // After stop() the source is released, so reload before playing
      if (_player.processingState == ProcessingState.idle) {
        await _player.setFilePath(_previewPath!);
      }
      await _player.play();
    }
  }

  Future<void> _saveRecording() async {
    await _player.stop();
    if (!mounted) return;
    final filePath = _previewPath!;
    final filename = path.basename(filePath);
    context.pop();
    await widget.onFileSelected(filePath, 'audio/mp4', filename);
  }

  Future<void> _discardRecording() async {
    await _player.stop();
    if (_previewPath != null) {
      try {
        await File(_previewPath!).delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _sheetState = _SheetState.idle;
        _previewPath = null;
        _previewDuration = Duration.zero;
        _previewPosition = Duration.zero;
        _previewPlaying = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null || !mounted) return;

    context.pop();
    final ext = path.extension(image.path).toLowerCase();
    final mime = ext == '.png'
        ? 'image/png'
        : ext == '.gif'
        ? 'image/gif'
        : 'image/jpeg';
    await widget.onFileSelected(image.path, mime, path.basename(image.path));
  }

  static const _allowedAudioExtensions = ['mp3', 'wav', 'm4a', 'ogg', 'aac'];

  static const _extToMime = {
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.m4a': 'audio/mp4',
    '.ogg': 'audio/ogg',
    '.aac': 'audio/aac',
  };

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedAudioExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    if (file.path == null) return;

    final ext = path.extension(file.path!).toLowerCase();
    final mime = _extToMime[ext];
    if (mime == null) {
      AppSnackbar.showError(
        context,
        message: 'Unsupported audio format. Allowed: mp3, wav, m4a, ogg, aac',
      );
      return;
    }

    context.pop();
    await widget.onFileSelected(file.path!, mime, file.name);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
              : [Colors.white, const Color(0xFFF8F9FC)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.paperclip,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Attachment',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _sheetState == _SheetState.recording
                                ? 'Recording in progress'
                                : _sheetState == _SheetState.preview
                                ? 'Review your recording'
                                : 'Images or audio',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_sheetState == _SheetState.recording)
                _RecordingWidget(
                  duration: _recordingDuration,
                  formatDuration: _formatDuration,
                  onStop: _stopRecording,
                )
              else if (_sheetState == _SheetState.preview)
                _PreviewWidget(
                  duration: _previewDuration,
                  position: _previewPosition,
                  isPlaying: _previewPlaying,
                  formatDuration: _formatDuration,
                  onTogglePlay: _togglePreviewPlay,
                  onRestart: _startRecording,
                  onDiscard: _discardRecording,
                  onSave: _saveRecording,
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionTile(
                      icon: LucideIcons.camera,
                      label: 'Take Photo',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 8),
                    _OptionTile(
                      icon: LucideIcons.image,
                      label: 'Choose Image',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(height: 8),
                    _OptionTile(
                      icon: LucideIcons.mic,
                      label: 'Record Audio',
                      onTap: _startRecording,
                    ),
                    const SizedBox(height: 8),
                    _OptionTile(
                      icon: LucideIcons.music,
                      label: 'Choose Audio File',
                      onTap: _pickAudioFile,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingWidget extends StatelessWidget {
  final Duration duration;
  final String Function(Duration) formatDuration;
  final VoidCallback onStop;

  const _RecordingWidget({
    required this.duration,
    required this.formatDuration,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mic, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            formatDuration(duration),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onStop,
            icon: const Icon(LucideIcons.square, size: 16),
            label: const Text('Stop Recording'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewWidget extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final String Function(Duration) formatDuration;
  final VoidCallback onTogglePlay;
  final VoidCallback onRestart;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const _PreviewWidget({
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.formatDuration,
    required this.onTogglePlay,
    required this.onRestart,
    required this.onDiscard,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/pause button + timer
              Row(
                children: [
                  GestureDetector(
                    onTap: onTogglePlay,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isPlaying ? LucideIcons.pause : LucideIcons.play,
                        size: 26,
                        color: isPlaying
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recording preview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDuration(position)} / ${formatDuration(duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action row
        Row(
          children: [
            // Discard
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text('Discard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Re-record
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Re-record'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Save
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
