import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';

import '../motion/haptics.dart';
import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'bottom_bar_frame.dart';
import 'pressable.dart';

enum SnackbarKind { done, success, error, info }

abstract final class AppSnackbar {
  static _SnackbarController? _current;

  /// [onClosed] gets whether the action button was pressed.
  static void show(
    BuildContext context,
    String message, {
    SnackbarKind kind = SnackbarKind.done,
    String? actionLabel,
    VoidCallback? onAction,
    ValueChanged<bool>? onClosed,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    if (kind == SnackbarKind.success) Haptics.success();
    if (kind == SnackbarKind.error) Haptics.warning();
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
    final data = _SnackData(
      message: message,
      kind: kind,
      actionLabel: actionLabel,
      onAction: onAction,
      onClosed: onClosed,
      page: ModalRoute.of(context),
      navigator: Navigator.maybeOf(context),
    );
    final current = _current;
    if (current != null && current.isShowing) {
      current.replace(data);
      return;
    }
    _current = _SnackbarController(overlay, data);
  }
}

class _SnackData {
  _SnackData({
    required this.message,
    required this.kind,
    this.actionLabel,
    this.onAction,
    this.onClosed,
    this.page,
    this.navigator,
  });

  final String message;
  final SnackbarKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<bool>? onClosed;

  final Route<Object?>? page;
  final NavigatorState? navigator;
  bool isActionPressed = false;

  Duration get displayDuration => kind == SnackbarKind.error
      ? const Duration(seconds: 10)
      : const Duration(seconds: 6);
}

class _SnackbarController {
  _SnackbarController(OverlayState overlay, _SnackData data) {
    _data = ValueNotifier(data);
    _entry = OverlayEntry(
      builder: (_) => _SnackbarView(controller: this, data: _data),
    );
    overlay.insert(_entry);
  }

  late final ValueNotifier<_SnackData> _data;
  late final OverlayEntry _entry;
  bool isShowing = true;
  _SnackbarViewState? view;

  void replace(_SnackData data) {
    final old = _data.value;
    old.onClosed?.call(old.isActionPressed);
    _data.value = data;
    view?.restart();
  }

  void removed() {
    isShowing = false;
    final data = _data.value;
    data.onClosed?.call(data.isActionPressed);
    _entry.remove();
    if (AppSnackbar._current == this) AppSnackbar._current = null;
  }
}

class _SnackbarView extends StatefulWidget {
  const _SnackbarView({required this.controller, required this.data});

  final _SnackbarController controller;
  final ValueNotifier<_SnackData> data;

  @override
  State<_SnackbarView> createState() => _SnackbarViewState();
}

class _SnackbarViewState extends State<_SnackbarView>
    with TickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    value: 0,
  );
  // Flutter cuts a normal controller to 1/20 of its time with animations off.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  double _drag = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.view = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _show.springTo(1);
    });
    _startClock();
    _clock.addStatusListener((status) {
      if (status == AnimationStatus.completed) leave();
    });
  }

  void _startClock() {
    final data = widget.data.value;
    _clock.stop();
    _clock.value = 0;
    _clock.duration = data.displayDuration;
    final isReaderOn =
        SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;
    if (data.actionLabel != null && isReaderOn) return;
    _clock.forward();
  }

  void restart() {
    if (!mounted) return;
    _leaving = false;
    _drag = 0;
    if (_show.value < 1) _show.springTo(1);
    _startClock();
    setState(() {});
  }

  void leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    _clock.stop();
    if (context.isMotionReduced) {
      widget.controller.removed();
      return;
    }
    _show
        .animateTo(
          0,
          duration: AnchorTokens.motionDurationExit,
          curve: AnchorTokens.motionEaseExit,
        )
        .whenComplete(() {
          if (mounted && _leaving) widget.controller.removed();
        });
  }

  @override
  void dispose() {
    if (AppSnackbar._current == widget.controller) AppSnackbar._current = null;
    _show.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ListenableBuilder(
      listenable: Listenable.merge([BottomBarFrame.changes, widget.data]),
      builder: (context, _) {
        final data = widget.data.value;
        final bottomBarInset = BottomBarFrame.insetOn(
          data.page,
          data.navigator,
        );
        final density = context.density;
        final bottom = keyboard > 0
            ? math.max(keyboard, bottomBarInset) + density.space8
            : math.max(context.safeBottom, bottomBarInset) + density.space12;
        return AnimatedPositioned(
          duration: context.motion(Spring.keyboard.duration),
          curve: Spring.keyboard.curve,
          left: 16,
          right: 16,
          bottom: bottom,
          child: AnimatedBuilder(
            animation: _show,
            builder: (context, child) {
              final shown = _show.value;
              return Opacity(
                opacity: shown.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - shown) * 90 + _drag),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onVerticalDragStart: (_) => _clock.stop(),
              onVerticalDragUpdate: (details) => setState(
                () => _drag = (_drag + details.delta.dy).clamp(0, 200),
              ),
              onVerticalDragEnd: (details) {
                if (_drag > 24 || (details.primaryVelocity ?? 0) > 400) {
                  leave();
                } else {
                  setState(() => _drag = 0);
                  _clock.forward();
                }
              },
              child: ValueListenableBuilder<_SnackData>(
                valueListenable: widget.data,
                builder: (context, data, _) => _SnackbarBody(
                  data: data,
                  clock: _clock,
                  onAction: () {
                    data.isActionPressed = true;
                    leave();
                    data.onAction?.call();
                  },
                  onDismiss: leave,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SnackbarBody extends StatelessWidget {
  const _SnackbarBody({
    required this.data,
    required this.clock,
    required this.onAction,
    required this.onDismiss,
  });

  final _SnackData data;
  final Animation<double> clock;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final accent = data.kind == SnackbarKind.error
        ? colors.appInverseDanger
        : colors.appInverseLink;
    final iconColor = switch (data.kind) {
      SnackbarKind.done || SnackbarKind.success => colors.appInverseLink,
      SnackbarKind.error => colors.appInverseDanger,
      SnackbarKind.info => colors.appOnInverse,
    };
    final icon = switch (data.kind) {
      SnackbarKind.done || SnackbarKind.success => LucideIcons500.check,
      SnackbarKind.error => LucideIcons.circleAlert,
      SnackbarKind.info => LucideIcons.info,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      onDismiss: onDismiss,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(minHeight: context.density.control),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.appInverse,
            borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
            boxShadow: colors.shadowBar,
          ),
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  context.density.space8,
                  data.actionLabel == null ? 16 : 8,
                  context.density.space8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(
                          alpha: data.kind == SnackbarKind.info ? 0.12 : 0.17,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: AnchorTokens.sizeIconSmall,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: context.motion(
                          AnchorTokens.motionDurationFade,
                        ),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          data.message,
                          key: ValueKey(data.message),
                          style: AppTypography.secondary.copyWith(
                            color: colors.appOnInverse,
                          ),
                        ),
                      ),
                    ),
                    if (data.actionLabel != null) ...[
                      const SizedBox(width: 12),
                      _ActionButton(
                        label: data.actionLabel!,
                        color: accent,
                        onPressed: onAction,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2,
                child: AnimatedBuilder(
                  animation: clock,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1 - clock.value,
                    child: ColoredBox(color: accent.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      style: PressStyle.inverse,
      onTap: onPressed,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AnchorTokens.sizeControlSmall,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: AppTypography.secondary.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
