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

  /// Horizontal finger travel per nesting level, matching the editor's
  /// indent width.
  static const double _indentStep = 24;

  List<ParsedLine>? _dragLines;
  int? _dragLineIndex;
  int _dragBlockEnd = 0;
  List<ChecklistGap> _validGaps = const [];
  int? _hoverGap;
  int? _hoverIndent;
  double _dragStartX = 0;
  Offset? _dragGlobalPosition;
  String _dragText = '';
  bool _dragChecked = false;
  Timer? _autoScrollTimer;
  double _scrollDelta = 0;

  bool get isDraggingChecklistItem => _dragLineIndex != null;

  String get dragFeedbackText => _dragText;

  bool get dragFeedbackChecked => _dragChecked;

  /// Indented children travelling with the dragged line.
  int get dragFeedbackChildCount {
    final index = _dragLineIndex;
    return index == null ? 0 : _dragBlockEnd - index;
  }

  /// flutter_quill right-aligns the 18px checkbox glyph in the leading slot
  /// with a half-size end inset, so the glyph column starts 27px left of the
  /// line's text.
  static const double _checkboxColumnInset = 27;

  /// Left of the insertion indicator in overlay coordinates: the checkbox
  /// column of the nesting level the drop would give the dragged line.
  double get dragIndicatorLeft {
    final lines = _dragLines;
    final index = _dragLineIndex;
    final editor = renderEditor;
    final box = dragOverlayBox;
    if (lines == null || index == null || editor == null || box == null) {
      return 0;
    }
    final caret = editor.getLocalRectForCaret(
      TextPosition(offset: lines[index].startOffset),
    );
    final left = box
        .globalToLocal(editor.localToGlobal(Offset(caret.left, 0)))
        .dx;
    final head = lines[index].indent;
    final shift = _indentStep * ((_hoverIndent ?? head) - head);
    return left - _checkboxColumnInset + shift;
  }

  /// Finger position in overlay coordinates, or null when not dragging.
  Offset? get dragFeedbackPosition {
    final global = _dragGlobalPosition;
    final box = dragOverlayBox;
    if (global == null || box == null || !isDraggingChecklistItem) return null;
    return box.globalToLocal(global);
  }

  /// Rect of the block being dragged (line + its indented children), in
  /// overlay coordinates.
  Rect? get dragSourceRect {
    final lines = _dragLines;
    final index = _dragLineIndex;
    final editor = renderEditor;
    final box = dragOverlayBox;
    if (lines == null || index == null || editor == null || box == null) {
      return null;
    }
    final top = _lineRect(editor, lines[index]);
    final bottom = _lineRect(editor, lines[_dragBlockEnd]);
    final rect = Rect.fromLTRB(top.left, top.top, top.right, bottom.bottom);
    return box.globalToLocal(editor.localToGlobal(rect.topLeft)) & rect.size;
  }

  /// Top of the insertion indicator in overlay coordinates. Null while the
  /// drop would change nothing.
  double? get dragIndicatorTop {
    final gap = _hoverGap;
    final lines = _dragLines;
    final index = _dragLineIndex;
    final editor = renderEditor;
    final box = dragOverlayBox;
    if (gap == null || lines == null || index == null) return null;
    if (editor == null || box == null) return null;
    if (gap >= index &&
        gap <= _dragBlockEnd + 1 &&
        _hoverIndent == lines[index].indent) {
      return null;
    }

    final y = _gapY(editor, lines, gap);
    return box.globalToLocal(editor.localToGlobal(Offset(0, y))).dy;
  }

  /// Y of the gap, centered in the visual seam between the two lines.
  double _gapY(RenderEditor editor, List<ParsedLine> lines, int gap) {
    if (gap >= lines.length) return _lineRect(editor, lines.last).bottom;
    final top = _lineRect(editor, lines[gap]).top;
    if (gap == 0) return top;
    return (_lineRect(editor, lines[gap - 1]).bottom + top) / 2;
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

    final blockEnd = checklistBlockEnd(lines, index, groupEnd);
    final gaps = checklistDropGaps(
      lines,
      groupStart,
      groupEnd,
      index,
      blockEnd,
    );
    // Without a real move or a possible indent change there is nothing to do.
    final pointless = gaps.every(
      (g) =>
          g.gap >= index && g.gap <= blockEnd + 1 && g.minIndent == g.maxIndent,
    );
    if (pointless) return;

    final line = lines[index];
    final text = controller.document.toPlainText().substring(
      line.startOffset,
      line.startOffset + line.length - 1,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _dragLines = lines;
      _dragLineIndex = index;
      _dragBlockEnd = blockEnd;
      _validGaps = gaps;
      _hoverGap = null;
      _hoverIndent = null;
      _dragStartX = details.globalPosition.dx;
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
    final blockEnd = _dragBlockEnd;
    final gap = _hoverGap;
    final indent = _hoverIndent;
    final snapshot = _dragLines;
    _stopAutoScroll();

    if (index == null || gap == null || indent == null || snapshot == null) {
      _resetDrag();
      return;
    }
    final ownBoundary = gap >= index && gap <= blockEnd + 1;
    final indentDelta = indent - snapshot[index].indent;
    if (ownBoundary && indentDelta == 0) {
      _resetDrag();
      return;
    }

    // The document may have been swapped mid-drag (external sync); only
    // compose against a layout that still matches the drag snapshot.
    final lines = parseDocumentLines(controller.document);
    var matches = lines.length == snapshot.length && gap <= lines.length;
    for (var i = index; matches && i <= blockEnd; i++) {
      matches = _sameLine(lines[i], snapshot[i]);
    }
    if (matches && gap < lines.length) {
      matches = _sameLine(lines[gap], snapshot[gap]);
    }
    if (!matches) {
      _resetDrag();
      return;
    }

    final move = ownBoundary
        ? buildBlockReindentDelta(lines, index, blockEnd, indentDelta)
        : buildBlockMoveDelta(
            controller.document,
            lines,
            index,
            blockEnd,
            gap,
            indentDelta: indentDelta,
          );
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

    // Snap to the nearest structurally valid gap.
    final localY = editor.globalToLocal(globalPosition).dy;
    var entry = _validGaps.first;
    var bestDistance = double.infinity;
    for (final g in _validGaps) {
      final distance = (localY - _gapY(editor, lines, g.gap)).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        entry = g;
      }
    }
    // Horizontal travel from the grab point picks the indent at this gap.
    final head = lines[_dragLineIndex!].indent;
    var indent =
        head + ((globalPosition.dx - _dragStartX) / _indentStep).round();
    if (indent < entry.minIndent) indent = entry.minIndent;
    if (indent > entry.maxIndent) indent = entry.maxIndent;

    if (entry.gap != _hoverGap || indent != _hoverIndent) {
      if (_hoverGap != null) HapticFeedback.selectionClick();
      _hoverGap = entry.gap;
      _hoverIndent = indent;
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
      _dragBlockEnd = 0;
      _validGaps = const [];
      _hoverGap = null;
      _hoverIndent = null;
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
      a.listType == b.listType &&
      a.indent == b.indent;
}
