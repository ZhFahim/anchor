import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

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
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowedAudioExtensions,
    );
    if (file == null || !mounted) return;
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
    final dims = context.dims;

    return AppBottomSheet(
      icon: LucideIcons.paperclip,
      title: 'Add Attachment',
      subtitle: _sheetState == _SheetState.recording
          ? 'Recording in progress'
          : _sheetState == _SheetState.preview
          ? 'Review your recording'
          : 'Images or audio',
      contentPadding: EdgeInsets.fromLTRB(dims.xl, 0, dims.xl, dims.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                SizedBox(height: dims.xs),
                _OptionTile(
                  icon: LucideIcons.image,
                  label: 'Choose Image',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                SizedBox(height: dims.xs),
                _OptionTile(
                  icon: LucideIcons.mic,
                  label: 'Record Audio',
                  onTap: _startRecording,
                ),
                SizedBox(height: dims.xs),
                _OptionTile(
                  icon: LucideIcons.music,
                  label: 'Choose Audio File',
                  onTap: _pickAudioFile,
                ),
              ],
            ),
        ],
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
    final dims = context.dims;
    return Container(
      padding: EdgeInsets.all(dims.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mic, size: 40, color: theme.colorScheme.primary),
          SizedBox(height: dims.xs),
          Text(
            formatDuration(duration),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: dims.sm),
          FilledButton.icon(
            onPressed: onStop,
            icon: const Icon(LucideIcons.square, size: AppIconSizes.sm),
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
    final dims = context.dims;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(dims.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: AppRadius.mdBorder,
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
                        borderRadius: AppRadius.mdBorder,
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
                  SizedBox(width: dims.md),
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
              SizedBox(height: dims.md),
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
        SizedBox(height: dims.sm),
        // Action row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(LucideIcons.trash2, size: AppIconSizes.sm),
                label: const Text('Discard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.symmetric(vertical: dims.sm),
                ),
              ),
            ),
            SizedBox(width: dims.xs),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(LucideIcons.rotateCcw, size: AppIconSizes.sm),
                label: const Text('Re-record'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: dims.sm),
                ),
              ),
            ),
            SizedBox(width: dims.xs),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(LucideIcons.check, size: AppIconSizes.sm),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: dims.sm),
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
    final dims = context.dims;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smBorder,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dims.md, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.smBorder,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            SizedBox(width: dims.md),
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
