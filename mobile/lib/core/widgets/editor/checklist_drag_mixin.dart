import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'checklist_lines.dart';

/// Manual drag-to-reorder for checklist items: long-press on the checkbox
/// slot lifts the line, dragging moves it within its checklist group, and
/// dropping composes a single move onto the live document (one undo entry,
/// cursor and scroll untouched).
mixin ChecklistDragReorderMixin<T extends StatefulWidget> on State<T> {
  /// Override to provide the QuillController.
  QuillController get controller;

  /// The editor's render object; null before the first layout.
  RenderEditor? get renderEditor;

  /// The scroll view hosting the editor, for edge auto-scroll while dragging.
  ScrollController get dragScrollController;

  /// Render box of the overlay the indicator and feedback row are drawn in.
  RenderBox? get dragOverlayBox;

  /// Bumped on every pointer move; repaints the overlay without rebuilding
  /// the editor subtree.
  final ValueNotifier<int> dragRepaint = ValueNotifier<int>(0);

  static const double _edgeExtent = 56;
  static const double _maxScrollSpeed = 14;

  List<ParsedLine>? _dragLines;
  int? _dragLineIndex;
  int _minGap = 0;
  int _maxGap = 0;
  int? _hoverGap;
  Offset? _dragGlobalPosition;
  String _dragText = '';
  bool _dragChecked = false;
  Timer? _autoScrollTimer;
  double _scrollDelta = 0;

  bool get isDraggingChecklistItem => _dragLineIndex != null;

  String get dragFeedbackText => _dragText;

  bool get dragFeedbackChecked => _dragChecked;

  /// Finger position in overlay coordinates, or null when not dragging.
  Offset? get dragFeedbackPosition {
    final global = _dragGlobalPosition;
    final box = dragOverlayBox;
    if (global == null || box == null || !isDraggingChecklistItem) return null;
    return box.globalToLocal(global);
  }

  /// Rect of the line being dragged, in overlay coordinates.
  Rect? get dragSourceRect {
    final lines = _dragLines;
    final index = _dragLineIndex;
    final editor = renderEditor;
    final box = dragOverlayBox;
    if (lines == null || index == null || editor == null || box == null) {
      return null;
    }
    final rect = _lineRect(editor, lines[index]);
    return box.globalToLocal(editor.localToGlobal(rect.topLeft)) & rect.size;
  }

  /// Top of the insertion indicator in overlay coordinates. Null while the
  /// drop would put the item back where it started.
  double? get dragIndicatorTop {
    final gap = _hoverGap;
    final lines = _dragLines;
    final index = _dragLineIndex;
    final editor = renderEditor;
    final box = dragOverlayBox;
    if (gap == null || lines == null || index == null) return null;
    if (editor == null || box == null) return null;
    if (gap == index || gap == index + 1) return null;

    final y = gap < lines.length
        ? _lineRect(editor, lines[gap]).top
        : _lineRect(editor, lines.last).bottom;
    return box.globalToLocal(editor.localToGlobal(Offset(0, y))).dy;
  }

  void startChecklistDrag(int documentOffset, LongPressStartDetails details) {
    final editor = renderEditor;
    if (editor == null || isDraggingChecklistItem) return;

    final lines = parseDocumentLines(controller.document);
    final index = _lineIndexAtOffset(lines, documentOffset);
    if (index == -1 || !lines[index].isChecklist) return;

    var groupStart = index;
    var groupEnd = index;
    while (groupStart > 0 && lines[groupStart - 1].isChecklist) {
      groupStart--;
    }
    while (groupEnd < lines.length - 1 && lines[groupEnd + 1].isChecklist) {
      groupEnd++;
    }

    // Valid insertion gaps: gap g drops the item before line g.
    final minGap = groupStart;
    final maxGap = groupEnd + 1;
    if (maxGap - minGap <= 1) return;

    final line = lines[index];
    final text = controller.document.toPlainText().substring(
      line.startOffset,
      line.startOffset + line.length - 1,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _dragLines = lines;
      _dragLineIndex = index;
      _minGap = minGap;
      _maxGap = maxGap;
      _hoverGap = null;
      _dragText = text;
      _dragChecked = line.isChecked;
      _dragGlobalPosition = details.globalPosition;
    });
    _updateHover(details.globalPosition);
  }

  void updateChecklistDrag(LongPressMoveUpdateDetails details) {
    if (!isDraggingChecklistItem) return;
    _updateHover(details.globalPosition);
  }

  void endChecklistDrag() {
    if (!isDraggingChecklistItem) return;
    final index = _dragLineIndex;
    final gap = _hoverGap;
    final snapshot = _dragLines;
    _stopAutoScroll();

    if (index == null || gap == null || snapshot == null) {
      _resetDrag();
      return;
    }
    final target = gap <= index ? gap : gap - 1;
    if (target == index) {
      _resetDrag();
      return;
    }

    // The document may have been swapped mid-drag (external sync); only
    // compose against a layout that still matches the drag snapshot.
    final lines = parseDocumentLines(controller.document);
    if (index >= lines.length ||
        target >= lines.length ||
        !_sameLine(lines[index], snapshot[index]) ||
        !_sameLine(lines[target], snapshot[target])) {
      _resetDrag();
      return;
    }

    final move = buildLineMoveDelta(controller.document, lines, index, target);
    _composeGuarded(move);
    HapticFeedback.lightImpact();
    _resetDrag();
  }

  void cancelChecklistDrag() {
    if (!isDraggingChecklistItem) return;
    _stopAutoScroll();
    _resetDrag();
  }

  /// Call from the host's dispose.
  void disposeChecklistDrag() {
    _stopAutoScroll();
    dragRepaint.dispose();
  }

  void _updateHover(Offset globalPosition) {
    final editor = renderEditor;
    final lines = _dragLines;
    if (editor == null || lines == null || !isDraggingChecklistItem) return;

    final position = editor.getPositionForOffset(globalPosition);
    var hoverLine = _lineIndexAtOffset(lines, position.offset);
    if (hoverLine == -1) hoverLine = lines.length - 1;

    final rect = _lineRect(editor, lines[hoverLine]);
    final localY = editor.globalToLocal(globalPosition).dy;
    final gap = (localY < rect.center.dy ? hoverLine : hoverLine + 1).clamp(
      _minGap,
      _maxGap,
    );
    if (gap != _hoverGap) {
      if (_hoverGap != null) HapticFeedback.selectionClick();
      _hoverGap = gap;
    }
    _dragGlobalPosition = globalPosition;
    dragRepaint.value++;
    _maybeAutoScroll(globalPosition);
  }

  void _maybeAutoScroll(Offset globalPosition) {
    final box = dragOverlayBox;
    if (box == null || !dragScrollController.hasClients) {
      _stopAutoScroll();
      return;
    }
    final local = box.globalToLocal(globalPosition);
    final height = box.size.height;
    double delta = 0;
    if (local.dy < _edgeExtent) {
      delta = -_maxScrollSpeed * (1 - local.dy / _edgeExtent).clamp(0.0, 1.0);
    } else if (local.dy > height - _edgeExtent) {
      delta =
          _maxScrollSpeed *
          (1 - (height - local.dy) / _edgeExtent).clamp(0.0, 1.0);
    }
    if (delta == 0) {
      _stopAutoScroll();
      return;
    }
    _scrollDelta = delta;
    _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!dragScrollController.hasClients) return;
      final position = dragScrollController.position;
      final next = (position.pixels + _scrollDelta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next == position.pixels) return;
      position.jumpTo(next);
      final global = _dragGlobalPosition;
      if (global != null) _updateHover(global);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _resetDrag() {
    if (!mounted) {
      _dragLineIndex = null;
      _dragLines = null;
      return;
    }
    setState(() {
      _dragLines = null;
      _dragLineIndex = null;
      _hoverGap = null;
      _dragGlobalPosition = null;
      _dragText = '';
    });
  }

  void _composeGuarded(Delta move) {
    controller
      ..ignoreFocusOnTextChange = true
      ..skipRequestKeyboard = true
      ..compose(move, controller.selection, ChangeSource.local);
    // While ignoreFocusOnTextChange is armed the editor skips its own repaint.
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller
        ..ignoreFocusOnTextChange = false
        ..skipRequestKeyboard = false;
    });
  }

  Rect _lineRect(RenderEditor editor, ParsedLine line) {
    final top = editor.getLocalRectForCaret(
      TextPosition(offset: line.startOffset),
    );
    final bottom = editor.getLocalRectForCaret(
      TextPosition(offset: line.startOffset + line.length - 1),
    );
    return Rect.fromLTRB(0, top.top, editor.size.width, bottom.bottom);
  }

  int _lineIndexAtOffset(List<ParsedLine> lines, int offset) {
    for (var i = 0; i < lines.length; i++) {
      if (offset >= lines[i].startOffset &&
          offset < lines[i].startOffset + lines[i].length) {
        return i;
      }
    }
    return -1;
  }

  bool _sameLine(ParsedLine a, ParsedLine b) =>
      a.startOffset == b.startOffset &&
      a.length == b.length &&
      a.listType == b.listType;
}
