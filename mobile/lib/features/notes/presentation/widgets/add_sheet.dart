import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/motion/animated_resize.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/springs.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/anchor_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/play_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';
import '../../data/image_compressor.dart';
import '../../data/photo_files.dart';
import '../../domain/note_attachment.dart';
import '../../domain/note_dates.dart';
import 'audio_playback.dart';

typedef AddedFile = ({String path, String mime, String name});

Future<AddedFile?> showAddSheet(BuildContext context) {
  return showAnchorSheet<AddedFile>(
    context,
    semanticLabel: context.l10n.addToNote,
    builder: (_) => const _AddSheet(),
  );
}

enum _Stage { pick, recording, review }

const _audioTypes = {
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.m4a': 'audio/mp4',
  '.ogg': 'audio/ogg',
  '.aac': 'audio/aac',
};

const _waveformBarCount = 36;

const _recordingLimit = maxAttachmentBytes - 2 * 1024 * 1024;

class _AddSheet extends ConsumerStatefulWidget {
  const _AddSheet();

  @override
  _AddSheetState createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  _Stage _stage = _Stage.pick;
  StreamSubscription<Amplitude>? _levels;
  StreamSubscription<Duration>? _position;
  StreamSubscription<bool>? _playing;
  Timer? _clock;
  DateTime _startedAt = DateTime.now();
  Duration _length = Duration.zero;
  Duration _played = Duration.zero;
  bool _isPlaying = false;
  bool _isStoppedAtLimit = false;
  String? _file;

  /// Levels from 0 to 1, newest last.
  final List<double> _amplitudes = [];

  @override
  void dispose() {
    _clock?.cancel();
    _levels?.cancel();
    _position?.cancel();
    _playing?.cancel();
    final unattached = _file;
    final stopped = _stage == _Stage.recording
        ? _recorder.stop()
        : Future<void>.value();
    if (unattached != null) {
      stopped.whenComplete(() => File(unattached).delete()).ignore();
    }
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickPicture(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image == null || !mounted) return;
    final photo = await PhotoFiles.uploadable(image.path);
    if (!mounted) return;
    if (photo == null) {
      AppSnackbar.show(
        context,
        context.l10n.addPhotoUnsupported,
        kind: SnackbarKind.error,
      );
      return;
    }

    // Compress before returning. Fallback to original on failure.
    String finalPath = photo.path;
    String finalMime = photo.mime;
    try {
      final result = await ref.read(imageCompressorProvider).compress(
        SourceImage(path: photo.path, mime: photo.mime),
      );
      finalPath = result.path;
      finalMime = result.mime;
    } catch (_) {
      // Keep original if compression fails
    }

    if (!mounted) return;
    Navigator.of(context).pop<AddedFile>((
      path: finalPath,
      mime: finalMime,
      name: path.basename(finalPath),
    ));
  }

  Future<void> _pickAudio() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [for (final e in _audioTypes.keys) e.substring(1)],
    );
    if (file?.path == null || !mounted) return;
    final mime = _audioTypes[path.extension(file!.path!).toLowerCase()];
    if (mime == null) {
      AppSnackbar.show(
        context,
        context.l10n.addAudioFormats,
        kind: SnackbarKind.error,
      );
      return;
    }
    Navigator.of(
      context,
    ).pop<AddedFile>((path: file.path!, mime: mime, name: file.name));
  }

  Future<void> _record() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.addMicDenied,
          kind: SnackbarKind.error,
        );
      }
      return;
    }
    await _discardRecording();
    _isStoppedAtLimit = false;
    final dir = await getTemporaryDirectory();
    final file = path.join(
      dir.path,
      '$recordingFilePrefix${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        numChannels: 1,
        echoCancel: true,
        autoGain: true,
        noiseSuppress: true,
      ),
      path: file,
    );
    if (!mounted) return;
    Haptics.medium();
    _amplitudes.clear();
    _startedAt = DateTime.now();
    _levels = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((amplitude) {
          // -50 dB and under reads as silence; 0 dB fills the bar.
          final level = ((amplitude.current + 50) / 50).clamp(0.0, 1.0);
          if (mounted) {
            setState(() => _amplitudes.add(0.12 + 0.88 * math.pow(level, 1.4)));
          }
        });
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() => _length = DateTime.now().difference(_startedAt));
      }
      if (!_isStoppedAtLimit && File(file).statSync().size >= _recordingLimit) {
        _isStoppedAtLimit = true;
        unawaited(_stop());
      }
    });
    setState(() {
      _stage = _Stage.recording;
      _file = file;
      _length = Duration.zero;
    });
  }

  Future<void> _stop() async {
    _clock?.cancel();
    await _levels?.cancel();
    final file = await _recorder.stop();
    if (!mounted) return;
    if (file == null) {
      setState(() => _stage = _Stage.pick);
      return;
    }
    Haptics.light();
    try {
      final length = await _player.setFilePath(file);
      _position = _player.positionStream.listen((position) {
        if (mounted) setState(() => _played = position);
      });
      _playing = _player.isPlayingStream.listen((isPlaying) {
        if (mounted) setState(() => _isPlaying = isPlaying);
      });
      setState(() {
        _stage = _Stage.review;
        _file = file;
        _length = length ?? _length;
        _played = Duration.zero;
      });
    } catch (_) {
      _attachRecording();
    }
  }

  Future<void> _discardRecording() async {
    await _player.stop();
    await _position?.cancel();
    await _playing?.cancel();
    final file = _file;
    _file = null;
    if (file != null) {
      try {
        await File(file).delete();
      } catch (_) {}
    }
  }

  void _attachRecording() {
    final file = _file;
    if (file == null) return;
    _file = null;
    unawaited(_player.stop());
    Navigator.of(context).pop<AddedFile>((
      path: file,
      mime: 'audio/mp4',
      name: path.basename(file),
    ));
  }

  Future<void> _discard() async {
    await _discardRecording();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _cancelRecording() async {
    _clock?.cancel();
    await _levels?.cancel();
    await _recorder.stop();
    await _discardRecording();
    if (mounted) Navigator.of(context).pop();
  }

  List<double> _shownBars() {
    if (_amplitudes.isEmpty) return List.filled(_waveformBarCount, 0.12);
    if (_stage == _Stage.recording) {
      final tail = _amplitudes.length > _waveformBarCount
          ? _amplitudes.sublist(_amplitudes.length - _waveformBarCount)
          : _amplitudes;
      return [...List.filled(_waveformBarCount - tail.length, 0.12), ...tail];
    }
    return [
      for (var i = 0; i < _waveformBarCount; i++)
        _amplitudes
            .sublist(
              (i * _amplitudes.length / _waveformBarCount).floor(),
              math.max(
                (i * _amplitudes.length / _waveformBarCount).floor() + 1,
                ((i + 1) * _amplitudes.length / _waveformBarCount).floor(),
              ),
            )
            .reduce(math.max),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final seconds = math.max(1, _length.inSeconds);
    final l10n = context.l10n;
    final (title, subtitle) = switch (_stage) {
      _Stage.pick => (l10n.addToNote, null),
      _Stage.recording => (l10n.recordingTitle, l10n.recordingHelp),
      _Stage.review => (
        l10n.recordingReviewTitle,
        _isStoppedAtLimit
            ? l10n.recordingStoppedAtLimit
            : l10n.recordingReviewHelp(seconds),
      ),
    };
    return PopScope(
      canPop: _stage != _Stage.recording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelRecording();
      },
      child: AnimatedResize(
        duration: Spring.smooth.duration,
        curve: Spring.smooth.curve,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: title, subtitle: subtitle),
            if (_stage == _Stage.pick) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  spacing: 12,
                  children: [
                    _OptionRow(
                      first: _Option(
                        icon: LucideIcons.camera,
                        label: l10n.addTakePhoto,
                        onTap: () => _pickPicture(ImageSource.camera),
                      ),
                      second: _Option(
                        icon: LucideIcons.images,
                        label: l10n.addChoosePhoto,
                        onTap: () => _pickPicture(ImageSource.gallery),
                      ),
                    ),
                    _OptionRow(
                      first: _Option(
                        icon: LucideIcons.mic,
                        label: l10n.addRecordAudio,
                        onTap: _record,
                      ),
                      second: _Option(
                        icon: LucideIcons.fileAudio,
                        label: l10n.addAudioFile,
                        onTap: _pickAudio,
                      ),
                    ),
                  ],
                ),
              ),
              const SheetBottomSpace(),
            ] else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16, context.density.space8, 16, 0),
                child: Column(
                  spacing: context.density.space16,
                  children: [
                    _Waveform(
                      bars: _shownBars(),
                      isRecording: _stage == _Stage.recording,
                      progress:
                          _stage == _Stage.review && _length.inMilliseconds > 0
                          ? _played.inMilliseconds / _length.inMilliseconds
                          : null,
                    ),
                    if (_stage == _Stage.recording)
                      Semantics(
                        liveRegion: false,
                        label: l10n.recordingElapsed(durationLabel(_length)),
                        child: ExcludeSemantics(
                          child: Text(
                            durationLabel(_length),
                            style: AppTypography.sheetTitle.tabular
                                .withSize(AppTypography.largeTitle.fontSize!)
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.anchor.appText,
                                ),
                          ),
                        ),
                      )
                    else
                      _PlayRow(
                        playing: _isPlaying,
                        text:
                            '${durationLabel(_played)} / ${durationLabel(_length)}',
                        onTap: () async {
                          Haptics.selection();
                          if (_isPlaying) {
                            await _player.pause();
                          } else {
                            await _player.play();
                          }
                        },
                      ),
                  ],
                ),
              ),
              if (_stage == _Stage.recording)
                SheetFooter(
                  children: [
                    AppButton(
                      label: l10n.commonCancel,
                      kind: AppButtonKind.secondary,
                      onPressed: _cancelRecording,
                    ),
                    AppButton(
                      label: l10n.recordingStop,
                      icon: LucideIcons.square,
                      kind: AppButtonKind.danger,
                      onPressed: _stop,
                    ),
                  ],
                )
              else
                SheetFooter(
                  children: [
                    AppButton(
                      label: l10n.recordingDiscard,
                      kind: AppButtonKind.dangerText,
                      onPressed: _discard,
                    ),
                    AppButton(
                      label: l10n.recordingAgain,
                      icon: LucideIcons.rotateCcw,
                      kind: AppButtonKind.secondary,
                      onPressed: _record,
                    ),
                    AppButton(
                      label: l10n.commonSave,
                      onPressed: () {
                        Haptics.success();
                        _attachRecording();
                      },
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Expanded(child: first),
        Expanded(child: second),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final density = context.density;
    return Pressable(
      style: PressStyle.button,
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: density.control * 2),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: density.space16,
        ),
        decoration: BoxDecoration(
          color: GroupedList.fillOf(context),
          borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: density.space12,
          children: [
            Container(
              width: 40, // off-scale: the option's round icon
              height: 40, // off-scale: as above
              decoration: BoxDecoration(
                color: colors.accentStrong.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AnchorTokens.sizeIconMedium,
                color: colors.accentStrong,
              ),
            ),
            Text(
              label,
              style: AppTypography.row.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.appText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.bars,
    required this.isRecording,
    this.progress,
  });

  final List<double> bars;
  final bool isRecording;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final idleBarColor = colors.appMuted.withValues(alpha: 0.45);
    return ExcludeSemantics(
      child: SizedBox(
        height: 64, // off-scale: the waveform, a drawing
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3, // off-scale: as above
          children: [
            for (var i = 0; i < bars.length; i++)
              AnimatedContainer(
                duration: context.motion(AnchorTokens.motionDurationPress),
                curve: AnchorTokens.motionEaseStandard,
                width: 4,
                height: 64 * bars[i], // off-scale: as above
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
                  color: isRecording
                      ? (bars[i] > 0.13 ? colors.statusDanger : idleBarColor)
                      : progress != null && i / bars.length < progress!
                      ? colors.accentStrong
                      : idleBarColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayRow extends StatelessWidget {
  const _PlayRow({
    required this.playing,
    required this.text,
    required this.onTap,
  });

  final bool playing;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        PlayButton(
          isPlaying: playing,
          size: PlayButtonSize.large,
          onPressed: onTap,
        ),
        Text(
          text,
          style: AppTypography.secondary.tabular.copyWith(
            color: colors.appMuted,
          ),
        ),
      ],
    );
  }
}