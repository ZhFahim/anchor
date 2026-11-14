import 'dart:math' as math;
import 'dart:ui' as ui show Image;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show PaintingContextCallback, ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import 'widgets/card_registry.dart';
import 'widgets/note_surface.dart';
import 'widgets/notes_bottom_bar.dart';

class NoteMorphPage extends Page<void> {
  const NoteMorphPage({
    super.key,
    required this.child,
    this.noteId,
    this.backgroundId,
  });

  final Widget child;
  final String? noteId;
  final String? backgroundId;

  @override
  Route<void> createRoute(BuildContext context) => NoteMorphRoute(
    settings: this,
    noteId: noteId,
    backgroundId: backgroundId,
    builder: (_) => child,
  );
}

class NoteMorphRoute extends PageRoute<void> {
  NoteMorphRoute({
    required RouteSettings settings,
    required this.builder,
    String? noteId,
    this.backgroundId,
  }) : noteId = ValueNotifier(noteId),
       super(settings: settings);

  final WidgetBuilder builder;

  /// Null for a new note until it holds something.
  final ValueNotifier<String?> noteId;

  String? backgroundId;

  Rect? _origin;
  bool _isOriginRound = false;
  bool _isOriginCard = false;
  bool _isCloseTargetSet = false;

  bool _wasNew = false;

  /// Set by the note: whether a new note is still blank.
  bool Function()? isBlank;

  double _closeFrom = 1;

  Rect? _closingRect;

  bool _isDisposed = false;

  static NoteMorphRoute? of(BuildContext context) {
    final route = ModalRoute.of(context);
    return route is NoteMorphRoute ? route : null;
  }

  /// Retakes the flying note's picture after this frame.
  static void refreshOf(BuildContext context) {
    final route = of(context);
    if (route == null || route.animation?.status == AnimationStatus.completed) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => route._refresh?.call(),
    );
  }

  VoidCallback? _refresh;

  void _aimAt(Rect? origin, {bool isCard = true}) {
    _origin = origin;
    _isOriginRound = isCard && noteId.value == null;
    _isOriginCard = isCard;
  }

  double get _originRadius =>
      _isOriginRound ? _origin!.shortestSide / 2 : AnchorTokens.radiusCard;

  bool get _isBlankNew =>
      _wasNew && noteId.value == null && (isBlank?.call() ?? true);

  Rect? _target() {
    final id = noteId.value;
    if (id != null) return CardRegistry.rectOf(id);
    return _isBlankNew ? CardRegistry.newNoteRect() : null;
  }

  bool _isOnScreen(Rect? rect, Size screen) =>
      rect != null &&
      rect.bottom > _onScreenMargin &&
      rect.top < screen.height - _onScreenMargin;

  void _followCard(Size screen, double progress, Rect? closingRect) {
    final target = _target();
    if (_isCloseTargetSet) {
      if (_isOriginCard && _origin != null && target != null) _aimAt(target);
      return;
    }
    _isCloseTargetSet = true;
    _closeFrom = progress;
    if (_isOnScreen(target, screen)) {
      _aimAt(target);
    } else if (closingRect != null) {
      _aimAt(
        Rect.fromLTWH(
          closingRect.left + closingRect.width * 0.1,
          closingRect.top + _onScreenMargin,
          closingRect.width * 0.8,
          closingRect.height * 0.8,
        ),
        isCard: false,
      );
    } else {
      _aimAt(null);
    }
  }

  static const double _onScreenMargin = 40;

  static const Duration _cardWait = Duration(milliseconds: 300);

  static const double _touchableAt = 0.9;

  void _finishOpening() {
    final controller = this.controller!;
    if (controller.status != AnimationStatus.forward) return;
    controller.animateTo(
      1,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _closeOnceCardIsIn() {
    final waited = Stopwatch()..start();
    void check(Duration _) {
      if (_isDisposed) return;
      if (_target() == null && waited.elapsed < _cardWait) {
        SchedulerBinding.instance
          ..addPostFrameCallback(check)
          ..scheduleFrame();
        return;
      }
      controller!.springBackTo(0);
    }

    controller!.stop();
    SchedulerBinding.instance
      ..addPostFrameCallback(check)
      ..scheduleFrame();
  }

  String? _hiddenCardId;

  void _setCardHidden(bool isHidden) {
    final shown = _hiddenCardId;
    final id = isHidden ? noteId.value : null;
    if (id == shown) return;
    _hiddenCardId = id;
    if (shown != null) CardRegistry.show(shown);
    if (id != null) CardRegistry.hide(id);
  }

  void _setRouteBelowVisible(bool isVisible) {
    if (overlayEntries.isEmpty || !isCurrent) return;
    overlayEntries.first.opaque = !isVisible;
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Spring.smooth.duration;

  @override
  Duration get reverseTransitionDuration => Spring.smooth.duration;

  @override
  void install() {
    super.install();
    controller!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _setCardHidden(false);
    });
  }

  @override
  TickerFuture didPush() {
    _wasNew = noteId.value == null;
    _aimAt(_target());
    // Hide the card only once the note is drawn over it.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isActive) _setCardHidden(true);
    });
    super.didPush();
    return controller!.springTo(1);
  }

  @override
  bool didPop(void result) {
    _isCloseTargetSet = false;
    _closeFrom = 1;
    _setCardHidden(true);
    if (isSystemMotionReduced) {
      // go_router calls didPop before the navigator marks the route as
      // popping, so the route is closed first or it is never removed.
      controller!.value = 0;
      return super.didPop(result);
    }
    final popped = super.didPop(result);
    if (_target() == null &&
        _closingRect == null &&
        (_wasNew || noteId.value != null)) {
      _closeOnceCardIsIn();
    } else {
      controller!.springBackTo(0);
    }
    return popped;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _setCardHidden(false);
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _NoteMorph(route: this, animation: animation, child: child);
  }
}

class _NoteMorph extends StatefulWidget {
  const _NoteMorph({
    required this.route,
    required this.animation,
    required this.child,
  });

  final NoteMorphRoute route;
  final Animation<double> animation;
  final Widget child;

  @override
  State<_NoteMorph> createState() => _NoteMorphState();
}

class _NoteMorphState extends State<_NoteMorph>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// How far a gesture has pulled the note, 0 to 1.
  double _pull = 0;
  Offset _shift = Offset.zero;
  bool _pulling = false;
  bool _overscrolling = false;
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  );

  final SnapshotController _snapshot = SnapshotController(
    allowSnapshotting: true,
  );
  final _FadingSnapshot _fade = _FadingSnapshot();
  final SnapshotController _contentSnapshot = SnapshotController(
    allowSnapshotting: true,
  );
  final _FadingSnapshot _contentFade = _FadingSnapshot();

  static const double _shadowPadding = 4;

  static Rect _withShadowPadding(Rect rect, Size card) {
    final x = _shadowPadding * rect.width / card.width;
    final y = _shadowPadding * rect.height / card.height;
    return Rect.fromLTRB(
      rect.left - x,
      rect.top - y,
      rect.right + x,
      rect.bottom + y,
    );
  }

  NoteMorphRoute get _route => widget.route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _route._refresh = _snapshot.clear;
    _settle.addListener(
      () => setState(() => _pull = _settle.value.clamp(0.0, 1.0)),
    );
  }

  @override
  void didChangeMetrics() {
    if (widget.animation.status == AnimationStatus.forward) _snapshot.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_route._refresh == _snapshot.clear) _route._refresh = null;
    _settle.dispose();
    _snapshot.dispose();
    _fade.dispose();
    _contentSnapshot.dispose();
    _contentFade.dispose();
    super.dispose();
  }

  Size get _size => MediaQuery.sizeOf(context);

  Rect _draggedRect() {
    final size = _size;
    final scale = 1 - 0.16 * _pull;
    return Rect.fromCenter(
      center: size.center(Offset.zero) + _shift,
      width: size.width * scale,
      height: size.height * scale,
    );
  }

  void _updateDrag(double pull, Offset shift) {
    if (!_pulling) {
      Haptics.selection();
      _route
        .._setCardHidden(true)
        .._setRouteBelowVisible(true);
    }
    _settle.stop();
    setState(() {
      _pulling = true;
      _pull = pull.clamp(0.0, 1.0);
      _shift = shift;
    });
  }

  Future<void> _release({required bool close, double velocity = 0}) async {
    if (close) {
      _route._closingRect = _draggedRect();
      final popped = await Navigator.of(context).maybePop();
      if (popped) return;
      _route._closingRect = null;
    }
    _settle.value = _pull;
    final shift = _shift;
    void follow() => _shift = Offset.lerp(Offset.zero, shift, _pull)!;
    _settle.addListener(follow);
    await _settle.springTo(0, spring: Spring.snappy, velocity: velocity);
    _settle.removeListener(follow);
    if (mounted) {
      setState(() {
        _pulling = false;
        _pull = 0;
        _shift = Offset.zero;
      });
      _route._setRouteBelowVisible(false);
    }
  }

  bool get _isTop =>
      _route.isCurrent && _route.animation!.status == AnimationStatus.completed;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (!_isTop || backEvent.isButtonEvent) return false;
    _updateDrag(0, Offset.zero);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    final side = backEvent.swipeEdge == SwipeEdge.left ? 1.0 : -1.0;
    _updateDrag(backEvent.progress, Offset(side * 24 * backEvent.progress, 0));
  }

  @override
  void handleCommitBackGesture() => _release(close: true);

  @override
  void handleCancelBackGesture() => _release(close: false);

  /// Defers [change] past layout, where setState isn't allowed.
  void _afterLayout(VoidCallback change) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) change();
      });
    } else {
      change();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        !_isTop) {
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final overscroll = -notification.metrics.pixels;
      // Letting go starts the bounce back, which ends at the top: decide now.
      if (_overscrolling &&
          notification.dragDetails == null &&
          _pull * 420 > 110) {
        _overscrolling = false;
        _afterLayout(() => _release(close: true));
      } else if (overscroll > 0 &&
          (notification.dragDetails != null || _overscrolling)) {
        _overscrolling = true;
        _afterLayout(
          () => _updateDrag(overscroll / 420, Offset(0, overscroll * 0.35)),
        );
      } else if (_overscrolling && overscroll <= 0) {
        _overscrolling = false;
        _afterLayout(() => _release(close: false));
      }
    } else if (notification is ScrollEndNotification && _overscrolling) {
      _overscrolling = false;
      _afterLayout(() => _release(close: _pull * 420 > 110));
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        _overscrolling &&
        _pull * 420 > 110) {
      _overscrolling = false;
      _afterLayout(() => _release(close: true));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final full = Offset.zero & size;
    final reduce = context.isMotionReduced;
    final isCupertino = context.isCupertino;
    final page = Listener(
      onPointerDown: (_) => _route._finishOpening(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    );

    final morph = AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final animationValue = widget.animation.value;
        final opening =
            widget.animation.status == AnimationStatus.forward ||
            widget.animation.status == AnimationStatus.completed;
        final closingRect =
            _route._closingRect ?? (_pulling ? _draggedRect() : null);
        if (!opening && animationValue < 1) {
          _route._followCard(size, animationValue, closingRect);
        }

        if (animationValue >= 1 && closingRect == null) return page;

        final progress = opening
            ? animationValue.clamp(0.0, 1.0)
            : (animationValue / _route._closeFrom).clamp(0.0, 1.0);
        final origin = _route._origin;
        if (origin == null || reduce) {
          final curve = Curves.easeOut.transform(progress);
          return Opacity(
            opacity: curve,
            child: Transform.scale(scale: 0.94 + 0.06 * curve, child: page),
          );
        }

        final to = closingRect ?? full;
        final rect = Rect.lerp(origin, to, progress)!;
        final radius = lerpDouble(
          _route._originRadius,
          closingRect != null ? 28 : 0,
          progress,
        )!;
        final scale = rect.width / size.width;
        final shown = ((progress - 0.25) / 0.55).clamp(0.0, 1.0);
        final contentOpacity = (1 - progress / 0.4).clamp(0.0, 1.0);
        final cardContent = contentOpacity > 0 && _route._isOriginCard
            ? CardRegistry.contentOf(_route.noteId.value)
            : null;
        final appearance = NoteAppearance.of(context, _route.backgroundId);
        final isRound = _route._isOriginRound;
        final buttonLook = isRound
            ? Curves.easeOut.transform((1 - progress / 0.3).clamp(0.0, 1.0))
            : 0.0;
        final pencil = isRound ? (1 - progress / 0.2).clamp(0.0, 1.0) : 0.0;
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12 * progress),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(
                ignoring: animationValue < NoteMorphRoute._touchableAt,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              shown < 1 || rect.height > size.height * scale + 1
                              ? Color.lerp(
                                  appearance.colors.bg,
                                  context.anchor.appInverse,
                                  buttonLook,
                                )
                              : null,
                        ),
                        child: SizedBox.expand(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: size.width,
                            maxWidth: size.width,
                            minHeight: size.height,
                            maxHeight: size.height,
                            child: Transform.scale(
                              scale: math.max(scale, 0.01),
                              alignment: Alignment.topLeft,
                              child: SnapshotWidget(
                                controller: _snapshot,
                                mode: SnapshotMode.permissive,
                                painter: _fade
                                  ..opacity = Curves.easeOut.transform(shown),
                                child: page,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (pencil > 0)
                        Center(
                          child: Opacity(
                            opacity: pencil,
                            child: const NewNoteIcon(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (cardContent != null)
              Positioned.fromRect(
                rect: _withShadowPadding(rect, origin.size),
                child: IgnorePointer(
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: origin.width + 2 * _shadowPadding,
                      height: origin.height + 2 * _shadowPadding,
                      child: SnapshotWidget(
                        controller: _contentSnapshot,
                        mode: SnapshotMode.permissive,
                        autoresize: true,
                        painter: _contentFade..opacity = contentOpacity,
                        child: Padding(
                          padding: const EdgeInsets.all(_shadowPadding),
                          child: Material(
                            type: MaterialType.transparency,
                            child: cardContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (!isCupertino) return morph;

    return Stack(
      children: [
        Positioned.fill(child: morph),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 22, // off-scale: the edge a swipe starts from
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              if (!_isTop) return;
              _updateDrag(
                details.globalPosition.dx / size.width,
                Offset(details.globalPosition.dx * 0.5, 0),
              );
            },
            onHorizontalDragEnd: (details) {
              if (!_pulling) return;
              final velocity = details.velocity.pixelsPerSecond.dx;
              _release(
                close: velocity > 400 || _pull > 0.33,
                velocity: -velocity / size.width,
              );
            },
            onHorizontalDragCancel: () {
              if (_pulling) _release(close: false);
            },
          ),
        ),
      ],
    );
  }
}

class _FadingSnapshot extends SnapshotPainter {
  double _opacity = 1;

  set opacity(double value) {
    if (value == _opacity) return;
    _opacity = value;
    notifyListeners();
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    if (_opacity <= 0) return;
    context.canvas.drawImageRect(
      image,
      Offset.zero & sourceSize,
      offset & size,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, _opacity)
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    if (_opacity <= 0) return;
    if (_opacity >= 1) {
      painter(context, offset);
    } else {
      context.pushOpacity(offset, (_opacity * 255).round(), painter);
    }
  }

  @override
  bool shouldRepaint(_FadingSnapshot oldPainter) => true;
}
