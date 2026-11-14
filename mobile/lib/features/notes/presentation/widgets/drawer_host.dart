import 'package:flutter/material.dart';

import '../../../../core/motion/springs.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/page_settled.dart';
import '../../../../l10n/l10n.dart';
import 'app_drawer.dart';

/// Open and close it through its state, found with a [GlobalKey].
class DrawerHost extends StatefulWidget {
  const DrawerHost({
    super.key,
    required this.drawerBuilder,
    required this.child,
    this.canSwipeOpen = true,
  });

  final Widget Function(VoidCallback close) drawerBuilder;

  final bool canSwipeOpen;

  final Widget child;

  @override
  State<DrawerHost> createState() => DrawerHostState();
}

class DrawerHostState extends State<DrawerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawer = AnimationController(vsync: this)
    ..addListener(() => _isCovered.value = _drawer.value > 0);

  final ValueNotifier<bool> _isCovered = ValueNotifier(false);

  bool _isClosing = false;

  final SnapshotController _still = SnapshotController();

  Animation<double>? _pageOver;

  bool get isOpen => _drawer.value > 0.5;

  /// True while any of the drawer shows, opening or closing.
  bool get isCovered => _isCovered.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pageOver = ModalRoute.of(context)?.secondaryAnimation;
    if (pageOver == _pageOver) return;
    _pageOver?.removeStatusListener(_pageOverChanged);
    _pageOver = pageOver?..addStatusListener(_pageOverChanged);
  }

  @override
  void dispose() {
    _pageOver?.removeStatusListener(_pageOverChanged);
    _drawer.dispose();
    _isCovered.dispose();
    _still.dispose();
    super.dispose();
  }

  void _pageOverChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        if (_drawer.value > 0) _still.allowSnapshotting = true;
      case AnimationStatus.completed:
        _isClosing = false;
        _drawer.value = 0;
        _still.allowSnapshotting = false;
      case AnimationStatus.dismissed:
        _still.allowSnapshotting = false;
      case AnimationStatus.reverse:
        break;
    }
  }

  void open([double velocity = 0]) {
    FocusScope.of(context).unfocus();
    _isClosing = false;
    _drawer.springTo(1, velocity: velocity);
  }

  void close([double velocity = 0]) {
    _isClosing = true;
    _drawer.springTo(0, spring: Spring.snappy, velocity: velocity);
  }

  void _dragUpdate(DragUpdateDetails details) {
    _isClosing = false;
    _drawer.value = (_drawer.value + details.delta.dx / AppDrawer.width).clamp(
      0.0,
      1.0,
    );
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    velocity > 300 || (_drawer.value > 0.5 && velocity > -300)
        ? open(velocity / AppDrawer.width)
        : close(velocity / AppDrawer.width);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final width = MediaQuery.sizeOf(context).width;
    final drawer = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width * 0.84),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: context.l10n.commonMenu,
        child: widget.drawerBuilder(close),
      ),
    );
    final host = AnimatedBuilder(
      animation: _drawer,
      builder: (context, child) {
        final progress = _drawer.value;
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(28 * progress, 0),
              child: ExcludeSemantics(excluding: progress > 0, child: child),
            ),
            if (progress == 0 && widget.canSwipeOpen && context.isCupertino)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 22, // off-scale: the edge a swipe starts from
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: _dragUpdate,
                  onHorizontalDragEnd: _dragEnd,
                ),
              ),
            if (progress > 0) ...[
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _isClosing,
                  child: GestureDetector(
                    onTap: close,
                    onHorizontalDragUpdate: _dragUpdate,
                    onHorizontalDragEnd: _dragEnd,
                    child: ColoredBox(
                      color: colors.appOverlay.withValues(
                        alpha: colors.appOverlay.a * progress.clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: FractionalTranslation(
                  translation: Offset((progress - 1) * 1.04, 0),
                  child: GestureDetector(
                    onHorizontalDragUpdate: _dragUpdate,
                    onHorizontalDragEnd: _dragEnd,
                    child: drawer,
                  ),
                ),
              ),
            ],
          ],
        );
      },
      child: PageCoverScope(notifier: _isCovered, child: widget.child),
    );
    // Back closes the drawer instead of leaving the page.
    return ValueListenableBuilder<bool>(
      valueListenable: _isCovered,
      builder: (context, isCovered, child) => PopScope(
        canPop: !isCovered,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: child!,
      ),
      child: SnapshotWidget(
        controller: _still,
        mode: SnapshotMode.permissive,
        child: host,
      ),
    );
  }
}
