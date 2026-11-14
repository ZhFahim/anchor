import 'package:flutter/widgets.dart';

/// Like [Transform.scale], but draws [child] as a picture taken when the
/// scaling starts. Use it only for what doesn't change while it scales.
class SnapshotScale extends StatefulWidget {
  const SnapshotScale({
    super.key,
    required this.scale,
    this.alignment = Alignment.center,
    required this.child,
  });

  final double scale;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  State<SnapshotScale> createState() => _SnapshotScaleState();
}

class _SnapshotScaleState extends State<SnapshotScale> {
  late final SnapshotController _snapshot = SnapshotController(
    allowSnapshotting: widget.scale != 1,
  );

  @override
  void didUpdateWidget(SnapshotScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    _snapshot.allowSnapshotting = widget.scale != 1;
  }

  @override
  void dispose() {
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: widget.scale,
    alignment: widget.alignment,
    child: SnapshotWidget(
      controller: _snapshot,
      mode: SnapshotMode.permissive,
      child: widget.child,
    ),
  );
}
