import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/system_bars.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/page_bar.dart';
import '../../../l10n/l10n.dart';
import '../data/qr/qr_decoder.dart';
import '../domain/magic_link.dart';

/// Scans the magic login QR code that the web shows in Settings, and
/// returns its [MagicLink].
class MagicLoginScanScreen extends StatefulWidget {
  static const routeName = 'magic login scan';

  const MagicLoginScanScreen({super.key});

  static Future<MagicLink?> open(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push<MagicLink>(
        MaterialPageRoute(
          fullscreenDialog: true,
          settings: const RouteSettings(name: routeName),
          builder: (_) => const MagicLoginScanScreen(),
        ),
      );

  @override
  State<MagicLoginScanScreen> createState() => _MagicLoginScanScreenState();
}

class _MagicLoginScanScreenState extends State<MagicLoginScanScreen>
    with WidgetsBindingObserver {
  static const _tag = LogTags.camera;

  /// Frames come faster than they can be read; one at a time, at most this
  /// often.
  static const _readEvery = Duration(milliseconds: 200);

  CameraDescription? _description;
  CameraController? _camera;
  _Problem? _problem;
  bool _isReading = false;
  bool _isDone = false;
  DateTime _lastRead = DateTime(0);

  /// The last QR code read that isn't a magic login.
  String? _otherCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera is the system's; let go of it while away.
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && camera == null) {
      // Also back from the permission prompt.
      _open();
    }
  }

  Future<void> _start() async {
    List<CameraDescription> cameras = const [];
    try {
      cameras = await availableCameras();
    } catch (e) {
      AppLogger.instance.warn(_tag, 'No cameras: $e');
    }
    if (cameras.isEmpty) {
      if (mounted) setState(() => _problem = _Problem.noCamera);
      return;
    }
    _description = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    await _open();
  }

  Future<void> _open() async {
    final description = _description;
    if (description == null || _isDone) return;
    final camera = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await camera.initialize();
      await camera.startImageStream((image) => _read(camera, image));
    } on CameraException catch (e) {
      AppLogger.instance.warn(
        _tag,
        'Couldn’t open the QR scanner: ${e.code} ${e.description}',
      );
      await camera.dispose();
      if (!mounted) return;
      setState(
        () => _problem = e.code.contains('Access')
            ? _Problem.noPermission
            : _Problem.failed,
      );
      return;
    }
    if (!mounted) {
      await camera.dispose();
      return;
    }
    setState(() {
      _camera = camera;
      _problem = null;
    });
  }

  Future<void> _read(CameraController camera, CameraImage image) async {
    final now = DateTime.now();
    if (_isReading || _isDone || now.difference(_lastRead) < _readEvery) {
      return;
    }
    _isReading = true;
    _lastRead = now;
    try {
      // The first plane is the brightness (Y), which is all a QR code needs.
      final plane = image.planes.first;
      final width = image.width;
      final height = image.height;
      final grey = packRows(plane.bytes, width, height, plane.bytesPerRow);
      final text = await Isolate.run(() => decodeQr(grey, width, height));
      if (text == null || !mounted || _isDone) return;
      final link = MagicLink.parse(text);
      if (link == null) {
        if (_otherCode != text) {
          Haptics.warning();
          setState(() => _otherCode = text);
        }
        return;
      }
      _isDone = true;
      Haptics.success();
      if (camera.value.isStreamingImages) {
        unawaited(camera.stopImageStream());
      }
      Navigator.of(context).pop(link);
    } catch (e) {
      AppLogger.instance.warn(_tag, 'Couldn’t read a frame: $e');
    } finally {
      _isReading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const ink = AnchorTokens.colorMediaText;
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          PageBar(
            color: Colors.black,
            systemBars: systemBarsStyle(dark: true),
            leading: BarButton(
              icon: LucideIcons.x,
              label: l10n.commonClose,
              color: ink,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(child: Center(child: _buildPreview())),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              context.density.space16,
              24,
              MediaQuery.paddingOf(context).bottom + context.density.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: context.density.space8,
              children: [
                Text(
                  l10n.magicLoginScanTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.sheetTitle.copyWith(color: ink),
                ),
                Text(
                  _otherCode == null
                      ? l10n.magicLoginScanHint
                      : l10n.magicLoginNotOurs,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary.copyWith(
                    color: AnchorTokens.colorMediaMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final camera = _camera;
    final l10n = context.l10n;
    if (_problem case final problem?) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: context.density.space12,
          children: [
            const Icon(
              LucideIcons.cameraOff,
              color: AnchorTokens.colorMediaMuted,
              size: AnchorTokens.sizeIconLarge,
            ),
            Text(
              switch (problem) {
                _Problem.noCamera => l10n.cameraNone,
                _Problem.noPermission => l10n.magicLoginNoPermission,
                _Problem.failed => l10n.cameraFailed,
              },
              textAlign: TextAlign.center,
              style: AppTypography.secondary.copyWith(
                color: AnchorTokens.colorMediaMuted,
              ),
            ),
          ],
        ),
      );
    }
    if (camera == null || !camera.value.isInitialized) {
      return const CircularProgressIndicator(
        color: AnchorTokens.colorMediaMuted,
      );
    }
    return ClipRRect(
      borderRadius: context.appStyle.corners(AnchorTokens.radiusLg),
      child: CameraPreview(camera),
    );
  }
}

enum _Problem { noCamera, noPermission, failed }
