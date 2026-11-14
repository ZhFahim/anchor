import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../motion/animated_resize.dart';
import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'app_buttons.dart';
import 'balanced_text.dart';
import 'button_row.dart';
import 'grouped_list.dart';

enum SheetDetent { fit, medium, large }

Future<T?> showAnchorSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetDetent detent = SheetDetent.fit,
  bool canGrow = false,
  String? semanticLabel,
  VoidCallback? onGone,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    _AnchorSheetRoute<T>(
      builder: builder,
      detent: detent,
      canGrow: canGrow,
      semanticLabel: semanticLabel,
      onGone: onGone,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}

class _AnchorSheetRoute<T> extends PopupRoute<T> {
  _AnchorSheetRoute({
    required this.builder,
    required this.detent,
    required this.canGrow,
    required this.capturedThemes,
    this.semanticLabel,
    this.onGone,
  });

  final WidgetBuilder builder;
  final SheetDetent detent;
  final bool canGrow;
  final CapturedThemes capturedThemes;
  final String? semanticLabel;

  /// Called once the closing sheet has left the screen.
  final VoidCallback? onGone;
  bool _isGone = false;

  /// In sheet heights per second.
  double _releaseVelocity = 0;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Spring.smooth.duration;

  @override
  Duration get reverseTransitionDuration => Spring.snappy.duration;

  @override
  TickerFuture didPush() {
    super.didPush();
    return controller!.springTo(1);
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    controller!
      ..addListener(_checkGone)
      ..springBackTo(
        -0.02,
        spring: Spring.snappy,
        velocity: -_releaseVelocity.abs(),
      );
    _releaseVelocity = 0;
    _checkGone();
    return popped;
  }

  void _checkGone() {
    if (_isGone || controller!.value > 0) return;
    _isGone = true;
    controller!.removeListener(_checkGone);
    onGone?.call();
  }

  @override
  void dispose() {
    if (!_isGone) {
      _isGone = true;
      onGone?.call();
    }
    super.dispose();
  }

  AnimationController get sheetController => controller!;

  void closeWithVelocity(double velocity) {
    _releaseVelocity = velocity;
    navigator?.pop();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return capturedThemes.wrap(_SheetFrame(route: this, animation: animation));
  }
}

class _SheetFrame extends StatefulWidget {
  const _SheetFrame({required this.route, required this.animation});

  final _AnchorSheetRoute<dynamic> route;
  final Animation<double> animation;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  final GlobalKey _sheetKey = GlobalKey();
  late SheetDetent _detent = widget.route.detent;

  /// How far a drag has pulled the sheet up past its rest, in pixels.
  double _overscroll = 0;
  bool _dragging = false;

  AnimationController get _controller => widget.route.sheetController;

  double get _height {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.hasSize == true ? box!.size.height : 400;
  }

  void _dragStart() {
    _dragging = true;
    _controller.stop();
  }

  void _dragUpdate(double dy) {
    final height = _height;
    if (_controller.value >= 1 && (dy < 0 || _overscroll > 0)) {
      _overscroll = math.max(0, _overscroll - dy);
      setState(() {});
      return;
    }
    _controller.value = (_controller.value - dy / height).clamp(0.0, 1.0);
  }

  void _dragEnd(double velocity) {
    _dragging = false;
    final height = _height;
    final velocityFraction = velocity / height;
    if (_overscroll > 0) {
      setState(() => _overscroll = 0);
    }
    final pulled = 1 - _controller.value;
    if (velocity > 900 || pulled > 0.4) {
      widget.route.closeWithVelocity(velocityFraction);
      return;
    }
    if (widget.route.canGrow) {
      if (velocity < -500 && _detent == SheetDetent.medium) {
        setState(() => _detent = SheetDetent.large);
      } else if (velocity > 400 && _detent == SheetDetent.large) {
        setState(() => _detent = SheetDetent.medium);
      }
    }
    _controller.springTo(1, velocity: -velocityFraction);
  }

  void grow() {
    if (widget.route.canGrow && _detent != SheetDetent.large) {
      setState(() => _detent = SheetDetent.large);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0) {
      if (!_dragging) _dragStart();
      _dragUpdate(-notification.overscroll);
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _dragging &&
        _controller.value < 1 &&
        (notification.scrollDelta ?? 0) > 0) {
      _dragUpdate(-(notification.scrollDelta ?? 0));
      if (notification.metrics.pixels > 0) {
        Scrollable.maybeOf(
          notification.context!,
        )?.position.correctBy(-notification.metrics.pixels);
      }
    } else if (notification is ScrollEndNotification && _dragging) {
      _dragEnd(notification.dragDetails?.primaryVelocity ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final cupertino = context.isCupertino;
    final screen = MediaQuery.sizeOf(context).height;
    final max =
        screen -
        MediaQuery.paddingOf(context).top -
        (cupertino ? 6 : 4) -
        keyboard;
    final isFloating =
        cupertino && _detent != SheetDetent.large && keyboard == 0;
    final gap = isFloating ? 8.0 : 0.0;
    final height = switch (_detent) {
      SheetDetent.fit => null,
      SheetDetent.medium => math.min(max, (screen * 0.56).roundToDouble()),
      SheetDetent.large => max,
    };
    final radius = isFloating
        ? const BorderRadius.all(
            Radius.circular(40), // off-scale: the screen's corner less 8
          )
        : const BorderRadius.vertical(
            top: Radius.circular(AnchorTokens.radiusSheet),
          );

    final sheet = Container(
      key: _sheetKey,
      constraints: BoxConstraints(maxHeight: max),
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.appSurface,
        borderRadius: radius,
        boxShadow: colors.shadowDialog,
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: isFloating || keyboard > 0,
        child: SheetSurface(
          child: _SheetScope(
            grow: grow,
            isFloating: isFloating,
            // Text fields need a Material ancestor.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Handle(
                    onStart: _dragStart,
                    onUpdate: _dragUpdate,
                    onEnd: _dragEnd,
                  ),
                  Flexible(
                    fit: height == null ? FlexFit.loose : FlexFit.tight,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: _BodyDrag(
                        onStart: _dragStart,
                        onUpdate: _dragUpdate,
                        onEnd: _dragEnd,
                        child: widget.route.builder(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.route.semanticLabel,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          final progress = widget.animation.value.clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: colors.appOverlay.withValues(
                      alpha: colors.appOverlay.a * progress,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: gap,
                right: gap,
                bottom: keyboard + gap,
                child: FractionalTranslation(
                  translation: Offset(0, (1 - progress) * 1.06),
                  child: Transform.translate(
                    offset: Offset(0, -math.pow(_overscroll, 0.7).toDouble()),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: AnimatedResize(
          duration: Spring.smooth.duration,
          curve: Spring.smooth.curve,
          alignment: Alignment.bottomCenter,
          child: sheet,
        ),
      ),
    );
  }
}

class _SheetScope extends InheritedWidget {
  const _SheetScope({
    required this.grow,
    required this.isFloating,
    required super.child,
  });

  final VoidCallback grow;
  final bool isFloating;

  @override
  bool updateShouldNotify(_SheetScope old) => old.isFloating != isFloating;
}

void expandSheet(BuildContext context) =>
    context.getInheritedWidgetOfExactType<_SheetScope>()?.grow();

class _Handle extends StatelessWidget {
  const _Handle({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final ValueChanged<double> onEnd;

  @override
  Widget build(BuildContext context) {
    final cupertino = context.isCupertino;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => onStart(),
      onVerticalDragUpdate: (d) => onUpdate(d.delta.dy),
      onVerticalDragEnd: (d) => onEnd(d.velocity.pixelsPerSecond.dy),
      child: SizedBox(
        height: cupertino ? 20 : 26, // off-scale: each platform's handle
        child: Center(
          child: Container(
            width: cupertino ? 36 : 32, // off-scale: as above
            height: cupertino ? 5 : 4, // off-scale: as above
            decoration: BoxDecoration(
              color: context.anchor.appMuted.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyDrag extends StatelessWidget {
  const _BodyDrag({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });

  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final ValueChanged<double> onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.deferToChild,
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
              (recognizer) {
                recognizer
                  ..onStart = ((_) => onStart())
                  ..onUpdate = ((d) => onUpdate(d.delta.dy))
                  ..onEnd = ((d) => onEnd(d.velocity.pixelsPerSecond.dy));
              },
            ),
      },
      child: child,
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.titleChild,
    this.subtitle,
    this.showDone = false,
  });

  final String title;

  /// Drawn in place of [title].
  final Widget? titleChild;
  final String? subtitle;

  final bool showDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final titleStyle = AppTypography.sheetTitle.copyWith(color: colors.appText);
    final done = showDone
        ? AppButton(
            label: context.l10n.commonDone,
            kind: AppButtonKind.secondary,
            isExpanded: false,
            size: AppButtonSize.small,
            hitPadding: const EdgeInsets.symmetric(
              vertical:
                  (AnchorTokens.sizeTargetTouch -
                      AnchorTokens.sizeControlSmall) /
                  2,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        context.density.space16 - (subtitle == null ? 0 : 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AnchorTokens.sizeControlMedium,
            child: NavigationToolbar(
              middleSpacing: 12,
              middle: MediaQuery.withClampedTextScaling(
                maxScaleFactor:
                    AnchorTokens.sizeControlMedium /
                    (titleStyle.fontSize! * titleStyle.height!),
                child: Semantics(
                  header: true,
                  child: DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                    child: titleChild ?? Text(title),
                  ),
                ),
              ),
              trailing: done,
            ),
          ),
          if (subtitle != null)
            Transform.translate(
              offset: const Offset(0, -8),
              child: Center(
                child: BalancedText(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary.copyWith(
                    color: colors.appMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SheetFooter extends StatelessWidget {
  const SheetFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SheetScope>();
    final isFloating = scope?.isFloating ?? false;
    final density = context.density;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        density.space8 + density.space8,
        16,
        isFloating ? density.space16 : context.safeBottom + 8,
      ),
      child: ButtonRow(
        spacing: 12,
        stackSpacing: density.space12,
        children: children,
      ),
    );
  }
}

class SheetBottomSpace extends StatelessWidget {
  const SheetBottomSpace({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SheetScope>();
    final isFloating = scope?.isFloating ?? false;
    final density = context.density;
    return SizedBox(
      height: isFloating
          ? density.space16
          : math.max(context.safeBottom + 8, density.space16),
    );
  }
}
