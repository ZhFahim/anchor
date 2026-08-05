import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'checklist_lines.dart';

/// Keeps checklists sorted: unchecked items on top, checked items at the
/// bottom of their group. Toggles are detected on the document change stream
/// and the item is moved by composing a delta onto the live document.
mixin ChecklistReorderMixin<T extends StatefulWidget> on State<T> {
  /// Override to provide the QuillController
  QuillController get controller;

  /// Override to check if sorting is enabled
  bool get sortChecklistItems;

  StreamSubscription<DocChange>? _changesSub;
  bool _isSorting = false;

  /// Start watching [controller] for checkbox toggles. Call again after the
  /// controller instance changes.
  void attachChecklistSorting() {
    _changesSub?.cancel();
    _changesSub = controller.changes.listen(_onDocChange);
  }

  void detachChecklistSorting() {
    _changesSub?.cancel();
    _changesSub = null;
  }

  void _onDocChange(DocChange change) {
    if (!sortChecklistItems || _isSorting || !mounted) return;
    if (change.source != ChangeSource.local) return;

    final offset = _toggledNewlineOffset(change.change);
    if (offset == null) return;

    // A microtask runs before the editor's post-frame selection restore.
    scheduleMicrotask(() {
      if (!mounted || _isSorting) return;
      _sortToggledLine(offset);
    });
  }

  /// Returns the offset of the single newline whose `list` attribute was set
  /// to checked/unchecked by [delta], or null for any other kind of change.
  int? _toggledNewlineOffset(Delta delta) {
    var position = 0;
    int? found;
    for (final op in delta.toList()) {
      if (!op.isRetain) return null;
      final list = op.attributes?[Attribute.list.key];
      if (list == 'checked' || list == 'unchecked') {
        if (found != null || op.length != 1) return null;
        found = position;
      }
      position += op.length!;
    }
    return found;
  }

  void _sortToggledLine(int newlineOffset) {
    final lines = parseDocumentLines(controller.document);

    var lineIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (newlineOffset >= line.startOffset &&
          newlineOffset < line.startOffset + line.length) {
        lineIndex = i;
        break;
      }
    }
    if (lineIndex == -1) return;

    final line = lines[lineIndex];
    if (!line.isChecklist) return;

    var groupStart = lineIndex;
    var groupEnd = lineIndex;
    while (groupStart > 0 && lines[groupStart - 1].isChecklist) {
      groupStart--;
    }
    while (groupEnd < lines.length - 1 && lines[groupEnd + 1].isChecklist) {
      groupEnd++;
    }

    final order = checklistSortOrder(lines, groupStart, groupEnd, lineIndex);
    if (order == null) return;

    final move = buildGroupReorderDelta(
      controller.document,
      lines,
      groupStart,
      order,
    );

    _isSorting = true;
    try {
      controller.compose(move, controller.selection, ChangeSource.local);
    } finally {
      _isSorting = false;
    }
  }
}
