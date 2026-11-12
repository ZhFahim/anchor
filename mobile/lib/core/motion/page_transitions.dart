import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'springs.dart';

class AnchorPageTransitionsBuilder extends PageTransitionsBuilder {
  const AnchorPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      isSystemMotionReduced ? Duration.zero : Spring.smooth.duration;

  @override
  Duration get reverseTransitionDuration =>
      isSystemMotionReduced ? Duration.zero : Spring.smooth.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return _AndroidPageTransition(
        route: route,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    }
    return const CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

enum _BackPhase { idle, gesture, cancel, commit }

class _AndroidPageTransition extends StatefulWidget {
  const _AndroidPageTransition({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_AndroidPageTransition> createState() => _AndroidPageTransitionState();
}

class _AndroidPageTransitionState extends State<_AndroidPageTransition>
    with WidgetsBindingObserver {
  _BackPhase _phase = _BackPhase.idle;

  double _side = 1;
  double _progress = 0;
  double _dy = 0;
  double _startY = 0;
  double _cancelFrom = 1;
  final _Slide _slide = _Slide();
  final _Slide _covered = _Slide();

  final SnapshotController _still = SnapshotController();

  bool get _enabled => widget.route.isCurrent && widget.route.popGestureEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _still.dispose();
    super.dispose();
  }

  void _enter(_BackPhase phase) {
    _phase = phase;
    _still.allowSnapshotting = phase != _BackPhase.idle;
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_enabled) return false;
    _side = backEvent.swipeEdge == SwipeEdge.right ? -1 : 1;
    _startY = backEvent.touchOffset?.dy ?? 0;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    setState(() {
      _enter(_BackPhase.gesture);
      _progress = backEvent.progress;
      _dy = 0;
    });
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_phase != _BackPhase.gesture) return;
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
    setState(() {
      _progress = backEvent.progress;
      _dy = (backEvent.touchOffset?.dy ?? _startY) - _startY;
    });
  }

  @override
  void handleCancelBackGesture() {
    if (_phase != _BackPhase.gesture) return;
    _cancelFrom = widget.animation.value;
    setState(() => _enter(_BackPhase.cancel));
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    if (_phase != _BackPhase.gesture) return;
    setState(() => _enter(_BackPhase.commit));
    widget.route.handleCommitBackGesture();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.animation,
        widget.secondaryAnimation,
        widget.route.navigator?.userGestureInProgressNotifier,
      ]),
      child: SnapshotWidget(
        controller: _still,
        mode: SnapshotMode.permissive,
        child: widget.child,
      ),
      builder: (context, child) {
        final covered = _covered.of(widget.secondaryAnimation);
        Widget page;
        if (_phase == _BackPhase.gesture && widget.route.popGestureInProgress) {
          page = _shrunk(child!, size, _eased(_progress), 0, 1);
        } else if (_phase == _BackPhase.cancel &&
            !widget.animation.isCompleted) {
          final back = _cancelFrom >= 1
              ? 1.0
              : (widget.animation.value - _cancelFrom) / (1 - _cancelFrom);
          final left = 1 - Spring.smooth.curve.transform(back.clamp(0.0, 1.0));
          page = _shrunk(child!, size, _eased(_progress) * left, 0, 1, left);
        } else if (_phase == _BackPhase.commit &&
            !widget.animation.isCompleted) {
          // Letting go restarts the closing animation from the end.
          final left = Spring.smooth.curve.transform(
            1 - widget.animation.value,
          );
          page = _shrunk(
            child!,
            size,
            _eased(_progress),
            left * size.width * 0.9,
            (1 - left * 1.6).clamp(0.0, 1.0),
          );
        } else {
          if (_phase != _BackPhase.idle && widget.animation.isCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _enter(_BackPhase.idle));
            });
          }
          final progress = _slide.of(widget.animation);
          page = FractionalTranslation(
            translation: Offset(1 - progress, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: progress < 1
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.14 * math.min(1, progress * 1.4),
                          ),
                          blurRadius: 40,
                          offset: const Offset(-16, 0),
                        ),
                      ]
                    : const [],
              ),
              child: child,
            ),
          );
        }
        if (covered <= 0) return page;
        if (!widget.route.popGestureInProgress) {
          page = FractionalTranslation(
            translation: Offset(-covered / 3, 0),
            child: page,
          );
        }
        return Stack(
          fit: StackFit.passthrough,
          children: [
            page,
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.1 * covered),
              ),
            ),
          ],
        );
      },
    );
  }

  double _eased(double progress) =>
      Curves.easeOut.transform(progress.clamp(0.0, 1.0));

  Widget _shrunk(
    Widget child,
    Size size,
    double shrink,
    double slide,
    double opacity, [
    double drag = 1,
  ]) {
    final radius = 34.0 * shrink;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(_side * 8 * shrink + slide, _dy * 0.08 * drag),
        child: Transform.scale(
          scale: 1 - 0.1 * shrink,
          alignment: _side < 0 ? Alignment.centerRight : Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Slide {
  double _shown = 0;
  ({double value, double shown})? _closing;

  double of(Animation<double> animation) {
    final curve = Spring.smooth.curve;
    if (animation.status != AnimationStatus.reverse) {
      _closing = null;
      return _shown = curve.transform(animation.value);
    }
    final closing = _closing ??= (value: animation.value, shown: _shown);
    if (closing.value == 0) return _shown = 0;
    final elapsed = (closing.value - animation.value) / closing.value;
    return _shown =
        closing.shown * (1 - curve.transform(elapsed.clamp(0.0, 1.0)));
  }
}
