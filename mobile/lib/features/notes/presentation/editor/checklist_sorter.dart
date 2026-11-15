import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../domain/note_blocks.dart';
import 'checklist_lines.dart';
import 'document_lines.dart';

class ChecklistSorter {
  ChecklistSorter(
    this._controller, {
    required bool Function() isEnabled,
    Duration Function()? delay,
    void Function(Delta move, TextSelection selection)? compose,
  }) : _isEnabled = isEnabled,
       _delay = delay ?? (() => Duration.zero),
       _compose = compose;

  final QuillController _controller;
  final bool Function() _isEnabled;
  final Duration Function() _delay;
  final void Function(Delta move, TextSelection selection)? _compose;
  final List<_PendingSort> _waiting = [];
  bool _isDisposed = false;

  void handleChange(DocChange change) {
    if (_isDisposed) return;
    for (final pending in _waiting) {
      pending.newline = change.change.transformPosition(pending.newline);
    }
    if (change.source != ChangeSource.local || !_isEnabled()) return;

    final newline = _toggledNewlineOffset(change);
    if (newline == null) return;

    final waiting = _waiting.where((s) => s.newline == newline).firstOrNull;
    if (waiting != null) {
      _cancel(waiting);
      return;
    }
    final history = _controller.document.history;
    final pending = _PendingSort(
      newline,
      lastRecorded: history.lastRecorded,
      steps: history.stack.undo.length,
    );
    _waiting.add(pending);
    final delay = _delay();
    if (delay == Duration.zero) {
      // A microtask runs before the editor's post-frame selection restore.
      scheduleMicrotask(() => _run(pending));
    } else {
      pending.timer = Timer(delay, () => _run(pending));
    }
  }

  void cancelAll() {
    for (final pending in [..._waiting]) {
      _cancel(pending);
    }
  }

  void dispose() {
    _isDisposed = true;
    cancelAll();
  }

  void _cancel(_PendingSort pending) {
    pending.timer?.cancel();
    _waiting.remove(pending);
  }

  void _run(_PendingSort pending) {
    if (_isDisposed || !_waiting.remove(pending) || !_isEnabled()) return;
    final history = _controller.document.history;
    // The move joins the check's Undo step unless something came between.
    final joinUndo =
        history.lastRecorded == pending.lastRecorded &&
        history.stack.undo.length == pending.steps;
    _sortToggledLine(pending.newline, joinUndo: joinUndo);
  }

  /// Sorts after a cascade that [handleChange] cannot read as one toggle.
  ///
  /// The caller composes the cascade first, then calls this with the line the
  /// reader tapped. The move joins the cascade's Undo step.
  void sortAfterToggle(int lineIndex) {
    if (_isDisposed || !_isEnabled()) return;
    final lines = parseDocumentLines(_controller.document);
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    _sortToggledLine(
      lines[lineIndex].startOffset + lines[lineIndex].length - 1,
      joinUndo: true,
    );
  }

  int? _toggledNewlineOffset(DocChange change) {
    var position = 0;
    int? found;
    Object? value;
    for (final op in change.change.toList()) {
      if (!op.isRetain) return null;
      final list = op.attributes?[Attribute.list.key];
      if (isChecklistValue(list)) {
        if (found != null || op.length != 1) return null;
        found = position;
        value = list;
      }
      position += op.length!;
    }
    if (found == null) return null;
    final was = _listValueAt(change.before, found);
    return isChecklistValue(was) && was != value ? found : null;
  }

  static Object? _listValueAt(Delta document, int offset) {
    var position = 0;
    for (final op in document.toList()) {
      position += op.length!;
      if (position > offset) return op.attributes?[Attribute.list.key];
    }
    return null;
  }

  void _sortToggledLine(int newlineOffset, {bool joinUndo = false}) {
    final lines = parseDocumentLines(_controller.document);
    final lineIndex = lineIndexAt(lines, newlineOffset);
    if (lineIndex == -1 || !lines[lineIndex].isChecklist) return;

    final (groupStart, groupEnd) = checklistGroupAround(lines, lineIndex);
    final plan = checklistCheckedSectionPlan(
      lines,
      groupStart,
      groupEnd,
      prefer: lineIndex,
    );
    if (plan == null) return;

    if (joinUndo) {
      _controller.document.history.lastRecorded =
          DateTime.now().millisecondsSinceEpoch;
    }

    final move = buildCheckedSectionDelta(
      _controller.document,
      lines,
      groupStart,
      plan,
    );
    int follow(int offset) {
      final index = lineIndexAt(lines, offset);
      final position = plan.order.indexOf(index);
      if (position == -1 || index == lineIndex) return offset;
      var start = lines[groupStart].startOffset;
      for (final moved in plan.order.take(position)) {
        start += lines[moved].length;
      }
      return start + offset - lines[index].startOffset;
    }

    final selection = _controller.selection;
    final kept = selection.copyWith(
      baseOffset: follow(selection.baseOffset),
      extentOffset: follow(selection.extentOffset),
    );
    final compose = _compose;
    if (compose != null) {
      compose(move, kept);
    } else {
      _controller
        ..compose(move, selection, ChangeSource.local)
        ..updateSelection(kept, ChangeSource.local);
    }
  }
}

class _PendingSort {
  _PendingSort(this.newline, {required this.lastRecorded, required this.steps});

  int newline;
  final int lastRecorded;
  final int steps;
  Timer? timer;
}
