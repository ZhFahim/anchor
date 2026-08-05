import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A line in the document: its offset range and newline (block) attributes.
class ParsedLine {
  final int startOffset;

  /// Length including the trailing newline.
  final int length;
  final Map<String, dynamic>? newlineAttributes;

  ParsedLine({
    required this.startOffset,
    required this.length,
    required this.newlineAttributes,
  });

  String? get listType => newlineAttributes?[Attribute.list.key] as String?;
  bool get isChecklist => listType == 'checked' || listType == 'unchecked';
  bool get isChecked => listType == 'checked';
}

List<ParsedLine> parseDocumentLines(Document document) {
  final lines = <ParsedLine>[];
  var offset = 0;
  var lineStart = 0;

  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is! String) {
      // Embeds occupy one position and never contain a newline.
      offset += 1;
      continue;
    }

    var searchFrom = 0;
    while (true) {
      final newlineIndex = data.indexOf('\n', searchFrom);
      if (newlineIndex == -1) {
        offset += data.length - searchFrom;
        break;
      }
      offset += newlineIndex - searchFrom + 1;
      lines.add(
        ParsedLine(
          startOffset: lineStart,
          length: offset - lineStart,
          newlineAttributes: op.attributes,
        ),
      );
      lineStart = offset;
      searchFrom = newlineIndex + 1;
    }
  }

  return lines;
}

/// Delta that moves the line at [fromIndex] so it ends up at [toIndex].
///
/// Document.compose (and the history inverses of deltas) cannot delete the
/// final newline or insert after it; end-of-document moves retain it and
/// patch its attributes.
Delta buildLineMoveDelta(
  Document document,
  List<ParsedLine> lines,
  int fromIndex,
  int toIndex,
) {
  return _buildLineMoveDelta(
    document.toDelta(),
    document.length,
    lines,
    fromIndex,
    toIndex,
  );
}

Delta _buildLineMoveDelta(
  Delta delta,
  int docLength,
  List<ParsedLine> lines,
  int fromIndex,
  int toIndex,
) {
  assert(fromIndex != toIndex);
  final line = lines[fromIndex];
  final srcStart = line.startOffset;
  final srcLength = line.length;

  final move = Delta();
  if (toIndex > fromIndex) {
    // Move down = pull the lines below it up in front of it.
    final blockLast = lines[toIndex];
    final blockStart = srcStart + srcLength;
    final blockEnd = blockLast.startOffset + blockLast.length;
    if (blockEnd < docLength) {
      move.retain(srcStart);
      delta.slice(blockStart, blockEnd).toList().forEach(move.push);
      move
        ..retain(srcLength)
        ..delete(blockEnd - blockStart);
    } else {
      move
        ..retain(srcStart)
        ..delete(srcLength)
        ..retain(blockEnd - blockStart - 1)
        ..insert('\n', blockLast.newlineAttributes);
      delta.slice(srcStart, srcStart + srcLength - 1).toList().forEach(
        move.push,
      );
      move.retain(
        1,
        _attributeDiff(blockLast.newlineAttributes, line.newlineAttributes),
      );
    }
  } else {
    final insertAt = lines[toIndex].startOffset;
    final srcEnd = srcStart + srcLength;
    if (srcEnd < docLength) {
      move.retain(insertAt);
      delta.slice(srcStart, srcEnd).toList().forEach(move.push);
      move
        ..retain(srcStart - insertAt)
        ..delete(srcLength);
    } else {
      // Moved line is the last line of the document.
      final lineAbove = lines[fromIndex - 1];
      move.retain(insertAt);
      delta.slice(srcStart, srcEnd - 1).toList().forEach(move.push);
      move
        ..insert('\n', line.newlineAttributes)
        ..retain(srcStart - insertAt - 1)
        ..delete(srcLength)
        ..retain(
          1,
          _attributeDiff(line.newlineAttributes, lineAbove.newlineAttributes),
        );
    }
  }
  return move;
}

/// Order of the group's line indices after a toggle: a stable partition —
/// unchecked lines first, checked lines last, each keeping document order,
/// with the toggled line at the end of its own section. Null when the group
/// is already in that order.
List<int>? checklistSortOrder(
  List<ParsedLine> lines,
  int groupStart,
  int groupEnd,
  int toggledIndex,
) {
  final unchecked = <int>[];
  final checked = <int>[];
  for (var i = groupStart; i <= groupEnd; i++) {
    if (i == toggledIndex) continue;
    (lines[i].isChecked ? checked : unchecked).add(i);
  }
  if (lines[toggledIndex].isChecked) {
    checked.add(toggledIndex);
  } else {
    unchecked.add(toggledIndex);
  }

  final order = [...unchecked, ...checked];
  for (var k = 0; k < order.length; k++) {
    if (order[k] != groupStart + k) return order;
  }
  return null;
}

/// Delta that rewrites the group's lines into [order] (indices into
/// [lines]), composed from single-line moves so the final newline is only
/// ever retained. [order] must differ from the current order.
Delta buildGroupReorderDelta(
  Document document,
  List<ParsedLine> lines,
  int groupStart,
  List<int> order,
) {
  var docDelta = document.toDelta();
  final docLength = document.length;
  final model = [...lines];
  // current[k] = original index of the line now at position groupStart + k.
  final current = [for (var i = 0; i < order.length; i++) groupStart + i];
  Delta? total;

  for (var k = 0; k < order.length; k++) {
    final p = current.indexOf(order[k], k);
    if (p == k) continue;

    final move = _buildLineMoveDelta(
      docDelta,
      docLength,
      model,
      groupStart + p,
      groupStart + k,
    );
    docDelta = docDelta.compose(move);
    total = total == null ? move : total.compose(move);

    current
      ..removeAt(p)
      ..insert(k, order[k]);
    final moved = model.removeAt(groupStart + p);
    model.insert(groupStart + k, moved);
    var offset = lines[groupStart].startOffset;
    for (var i = groupStart; i <= groupStart + order.length - 1; i++) {
      model[i] = ParsedLine(
        startOffset: offset,
        length: model[i].length,
        newlineAttributes: model[i].newlineAttributes,
      );
      offset += model[i].length;
    }
  }

  return total!;
}

/// Attribute map that turns [from] into [to] when applied via retain.
Map<String, dynamic>? _attributeDiff(
  Map<String, dynamic>? from,
  Map<String, dynamic>? to,
) {
  final diff = <String, dynamic>{};
  for (final key in {...?from?.keys, ...?to?.keys}) {
    final before = from?[key];
    final after = to?[key];
    if (before != after) diff[key] = after;
  }
  return diff.isEmpty ? null : diff;
}
