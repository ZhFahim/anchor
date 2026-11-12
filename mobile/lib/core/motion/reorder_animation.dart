import 'package:flutter/material.dart';

import 'snapshot_scale.dart';
import 'springs.dart';

class ReorderAnimationScope extends InheritedWidget {
  const ReorderAnimationScope({
    super.key,
    required this.generation,
    required this.contentKey,
    required super.child,
  });

  /// Changes when the list's content changes; boxes slide only then.
  final Object generation;

  final GlobalKey contentKey;

  static ReorderAnimationScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReorderAnimationScope>();

  @override
  bool updateShouldNotify(ReorderAnimationScope old) =>
      old.generation != generation;
}

class ReorderPositions {
  final Map<Object, Offset> positions = {};
  Object? generation;
  Object? _page;
  Set<Object> _shown = const {};

  /// Forgets the boxes that left [page] since the last call, so they fade in
  /// when they come back.
  void keepShown(Object page, Set<Object> shown) {
    if (page == _page) {
      _shown.difference(shown).forEach(positions.remove);
    }
    _page = page;
    _shown = shown;
  }
}

class ReorderAnimatedBox extends StatefulWidget {
  const ReorderAnimatedBox({
    super.key,
    required this.id,
    required this.memory,
    required this.child,
  });

  final Object id;
  final ReorderPositions memory;
  final Widget child;

  @override
  State<ReorderAnimatedBox> createState() => _ReorderAnimatedBoxState();
}

class _ReorderAnimatedBoxState extends State<ReorderAnimatedBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: 1,
  );
  Offset _from = Offset.zero;
  bool _isNew = false;
  Object? _seen;

  @override
  void initState() {
    super.initState();
    _isNew =
        widget.memory.positions.isNotEmpty &&
        !widget.memory.positions.containsKey(widget.id);
    if (_isNew) _progress.value = 0;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Offset? _measure(ReorderAnimationScope scope) {
    final box = context.findRenderObject() as RenderBox?;
    final root =
        scope.contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || root == null || !box.attached || !box.hasSize) {
      return null;
    }
    final scroll = Scrollable.maybeOf(context)?.position.pixels ?? 0;
    return box.localToGlobal(Offset.zero, ancestor: root) + Offset(0, scroll);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ReorderAnimationScope._of(context);
    if (scope != null) {
      final generation = scope.generation;
      final isCovered = !TickerMode.valuesOf(context).enabled;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final now = _measure(scope);
        if (now == null) return;
        final previous = widget.memory.positions[widget.id];
        widget.memory.positions[widget.id] = now;
        if (isCovered) {
          _isNew = false;
          _seen = generation;
          _progress.value = 1;
          return;
        }
        if (_isNew) {
          _isNew = false;
          _progress.springTo(1, spring: Spring.snappy);
          setState(() => _from = Offset.zero);
          return;
        }
        if (_seen != generation &&
            previous != null &&
            (previous - now).distance > 1 &&
            !context.isMotionReduced) {
          _from = previous - now;
          _progress.value = 0;
          _progress.springTo(1, spring: Spring.snappy);
          setState(() {});
        }
        _seen = generation;
      });
    }
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final progress = _progress.value;
        if (_from == Offset.zero) {
          if (progress >= 1) return child!;
          return Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: SnapshotScale(scale: 0.96 + 0.04 * progress, child: child!),
          );
        }
        return Transform.translate(
          offset: _from * (1 - progress),
          child: child,
        );
      },
    );
  }
}
