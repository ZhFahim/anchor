import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Parsed line from delta operations for checklist reordering
class ParsedLine {
  final List<Operation> contentOps;
  final Operation newlineOp;
  final int startOffset;
  final int length;

  ParsedLine({
    required this.contentOps,
    required this.newlineOp,
    required this.startOffset,
    required this.length,
  });

  String? get listType {
    final attrs = newlineOp.attributes;
    if (attrs == null) return null;
    return attrs['list'] as String?;
  }

  bool get isChecklist => listType == 'checked' || listType == 'unchecked';
  bool get isChecked => listType == 'checked';
}

/// Mixin that adds checklist reordering functionality to a rich text editor.
/// Automatically moves checked items to bottom and unchecked items to top.
mixin ChecklistReorderMixin<T extends StatefulWidget> on State<T> {
  /// Override to provide the QuillController
  QuillController get controller;

  /// Override to check if sorting is enabled
  bool get sortChecklistItems;

  /// Override to notify when content changes
  void onContentChanged();

  /// Override to rebuild the controller with new document
  void rebuildController(Document newDocument, int cursorPos);

  // Internal state
  Map<int, String> _previousChecklistState = {};
  int? _previousLineCount;
  bool _isReordering = false;

  /// Initialize checklist state tracking
  void initChecklistState() {
    final lines = _parseDocumentLines();
    _previousChecklistState = _buildChecklistState();
    _previousLineCount = lines.length;
  }

  /// Call this when the document changes
  void onDocumentChanged() {
    if (!sortChecklistItems || _isReordering || !mounted) return;

    final lines = _parseDocumentLines();
    final currentState = <int, String>{};

    // Build current checklist state
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isChecklist) {
        currentState[i] = line.listType!;
      }
    }

    // If line count changed (user added/deleted a line), only sync state.
    // Comparing by index would wrongly treat shifted lines as toggles.
    if (_previousLineCount != null && lines.length != _previousLineCount!) {
      _previousChecklistState = currentState;
      _previousLineCount = lines.length;
      return;
    }

    // Find if any item changed from unchecked to checked or vice versa
    int? toggledLineIndex;
    bool? isNowChecked;

    for (final entry in currentState.entries) {
      final lineIndex = entry.key;
      final currentValue = entry.value;
      final previousValue = _previousChecklistState[lineIndex];

      if (previousValue != null && previousValue != currentValue) {
        toggledLineIndex = lineIndex;
        isNowChecked = currentValue == 'checked';
        break;
      }
    }

    // Update previous state
    _previousChecklistState = currentState;
    _previousLineCount = lines.length;

    // If a checkbox was toggled, schedule reorder
    if (toggledLineIndex != null && isNowChecked != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && !_isReordering) {
          _reorderChecklistItem(toggledLineIndex!, isNowChecked!);
        }
      });
    }
  }

  /// Update checklist state after content changes
  void updateChecklistState() {
    _previousChecklistState = _buildChecklistState();
    _previousLineCount = _parseDocumentLines().length;
  }

  /// Parse document into lines with their operations and positions
  List<ParsedLine> _parseDocumentLines() {
    final lines = <ParsedLine>[];
    final delta = controller.document.toDelta();
    final ops = delta.toList();

    var currentContentOps = <Operation>[];
    var currentOffset = 0;
    var lineStartOffset = 0;

    for (final op in ops) {
      if (op.data is! String) {
        currentContentOps.add(op);
        currentOffset += 1;
        continue;
      }

      final text = op.data as String;
      final parts = text.split('\n');

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (part.isNotEmpty) {
          currentContentOps.add(Operation.insert(part, op.attributes));
          currentOffset += part.length;
        }

        if (i < parts.length - 1) {
          final newlineOp = Operation.insert('\n', op.attributes);
          final lineLength = currentOffset - lineStartOffset + 1;

          lines.add(
            ParsedLine(
              contentOps: List.from(currentContentOps),
              newlineOp: newlineOp,
              startOffset: lineStartOffset,
              length: lineLength,
            ),
          );

          currentOffset += 1;
          lineStartOffset = currentOffset;
          currentContentOps = [];
        }
      }
    }

    return lines;
  }

  Map<int, String> _buildChecklistState() {
    final lines = _parseDocumentLines();
    final state = <int, String>{};
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isChecklist) {
        state[i] = line.listType!;
      }
    }
    return state;
  }

  void _reorderChecklistItem(int lineIndex, bool isNowChecked) {
    if (_isReordering) return;

    final lines = _parseDocumentLines();
    if (lineIndex >= lines.length) return;

    final toggledLine = lines[lineIndex];
    if (!toggledLine.isChecklist) return;

    // Find checklist group boundaries
    int groupStart = lineIndex;
    int groupEnd = lineIndex;

    while (groupStart > 0 && lines[groupStart - 1].isChecklist) {
      groupStart--;
    }
    while (groupEnd < lines.length - 1 && lines[groupEnd + 1].isChecklist) {
      groupEnd++;
    }

    // Calculate target position
    int targetLineIndex;
    if (isNowChecked) {
      if (lineIndex == groupEnd) return;
      targetLineIndex = groupEnd;
    } else {
      int firstCheckedIndex = -1;
      for (int i = groupStart; i <= groupEnd; i++) {
        if (lines[i].isChecked) {
          firstCheckedIndex = i;
          break;
        }
      }
      if (firstCheckedIndex == -1 || lineIndex < firstCheckedIndex) return;
      targetLineIndex = firstCheckedIndex;
    }

    _isReordering = true;

    try {
      _moveLineInDocument(lines, lineIndex, targetLineIndex);
      _previousChecklistState = _buildChecklistState();
      _previousLineCount = _parseDocumentLines().length;
    } finally {
      _isReordering = false;
    }
  }

  void _moveLineInDocument(
    List<ParsedLine> lines,
    int sourceIndex,
    int targetIndex,
  ) {
    final reorderedLines = List<ParsedLine>.from(lines);
    final movedLine = reorderedLines.removeAt(sourceIndex);
    final insertAt = sourceIndex < targetIndex ? targetIndex : targetIndex;
    reorderedLines.insert(insertAt, movedLine);

    // Convert lines back to ops
    final newOps = <Map<String, dynamic>>[];
    for (final line in reorderedLines) {
      for (final contentOp in line.contentOps) {
        final opMap = <String, dynamic>{'insert': contentOp.data};
        if (contentOp.attributes != null && contentOp.attributes!.isNotEmpty) {
          opMap['attributes'] = Map<String, dynamic>.from(
            contentOp.attributes!,
          );
        }
        newOps.add(opMap);
      }
      final newlineMap = <String, dynamic>{'insert': '\n'};
      if (line.newlineOp.attributes != null &&
          line.newlineOp.attributes!.isNotEmpty) {
        newlineMap['attributes'] = Map<String, dynamic>.from(
          line.newlineOp.attributes!,
        );
      }
      newOps.add(newlineMap);
    }

    final newDocument = Document.fromJson(newOps);

    int cursorPos = 0;
    for (int i = 0; i < insertAt && i < reorderedLines.length; i++) {
      cursorPos += reorderedLines[i].length;
    }

    rebuildController(newDocument, cursorPos);
    onContentChanged();
  }
}
