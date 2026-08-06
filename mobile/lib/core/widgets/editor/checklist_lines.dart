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

  /// Nesting level (0 = top level).
  int get indent => (newlineAttributes?[Attribute.indent.key] as int?) ?? 0;
}

/// Last line of the block headed by [index]: the line plus the contiguous
/// run of following lines (up to [rangeEnd]) with deeper indent.
int checklistBlockEnd(List<ParsedLine> lines, int index, int rangeEnd) {
  final base = lines[index].indent;
  var end = index;
  while (end < rangeEnd && lines[end + 1].indent > base) {
    end++;
  }
  return end;
}

/// A valid insertion gap and the indent range the dropped block's head line
/// may take there.
class ChecklistGap {
  /// Insertion point: the block drops before line [gap].
  final int gap;
  final int minIndent;
  final int maxIndent;

  const ChecklistGap(this.gap, this.minIndent, this.maxIndent);

  @override
  bool operator ==(Object other) =>
      other is ChecklistGap &&
      other.gap == gap &&
      other.minIndent == minIndent &&
      other.maxIndent == maxIndent;

  @override
  int get hashCode => Object.hash(gap, minIndent, maxIndent);

  @override
  String toString() => 'ChecklistGap($gap, $minIndent..$maxIndent)';
}

/// Gaps where the block [blockStart..blockEnd] can drop, with the indent
/// range its head line may take at each: at most one level below the line
/// above the gap, deep enough that the line below the gap keeps a parent,
/// and capped so the block's deepest child stays within [maxListIndent].
/// Includes the block's own boundaries (a no-op unless the indent changes).
/// In flat groups this is every gap in the group.
List<ChecklistGap> checklistDropGaps(
  List<ParsedLine> lines,
  int groupStart,
  int groupEnd,
  int blockStart,
  int blockEnd,
) {
  final head = lines[blockStart].indent;
  var relMax = 0;
  for (var i = blockStart; i <= blockEnd; i++) {
    if (lines[i].indent - head > relMax) relMax = lines[i].indent - head;
  }
  final relLast = lines[blockEnd].indent - head;

  final gaps = <ChecklistGap>[];
  for (var g = groupStart; g <= groupEnd + 1; g++) {
    if (g > blockStart && g <= blockEnd) continue;
    // Both own boundaries are the same position once the block is taken out.
    final own = g >= blockStart && g <= blockEnd + 1;
    final aboveIndex = own ? blockStart - 1 : g - 1;
    final belowIndex = own ? blockEnd + 1 : g;
    final above = aboveIndex >= groupStart ? lines[aboveIndex].indent : null;
    final below = belowIndex <= groupEnd ? lines[belowIndex].indent : null;
    var maxIndent = maxListIndent - relMax;
    final aboveCap = above == null ? 0 : above + 1;
    if (aboveCap < maxIndent) maxIndent = aboveCap;
    var minIndent = below == null ? 0 : below - 1 - relLast;
    if (minIndent < 0) minIndent = 0;
    if (minIndent > maxIndent) continue;
    gaps.add(ChecklistGap(g, minIndent, maxIndent));
  }
  return gaps;
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
  return _buildSpanMoveDelta(
    delta,
    docLength,
    lines,
    fromIndex,
    fromIndex,
    toIndex > fromIndex ? toIndex + 1 : toIndex,
  );
}

/// Retain-only delta that shifts the indent of lines [fromStart..fromEnd]
/// by [indentDelta].
Delta buildBlockReindentDelta(
  List<ParsedLine> lines,
  int fromStart,
  int fromEnd,
  int indentDelta,
) {
  final delta = Delta();
  var cursor = 0;
  for (var i = fromStart; i <= fromEnd; i++) {
    final newlineOffset = lines[i].startOffset + lines[i].length - 1;
    if (newlineOffset > cursor) delta.retain(newlineOffset - cursor);
    final indent = lines[i].indent + indentDelta;
    delta.retain(1, {'indent': indent == 0 ? null : indent});
    cursor = newlineOffset + 1;
  }
  return delta;
}

Map<String, dynamic>? _withIndent(
  Map<String, dynamic>? attributes,
  int indent,
) {
  final next = {...?attributes}..remove(Attribute.indent.key);
  if (indent > 0) next[Attribute.indent.key] = indent;
  return next.isEmpty ? null : next;
}

/// Delta that moves the contiguous lines [fromStart..fromEnd] into [gap]
/// (the position before line [gap], which must lie outside the span),
/// shifting each moved line's indent by [indentDelta].
///
/// Document.compose (and the history inverses of deltas) cannot delete the
/// final newline or insert after it; end-of-document moves retain it and
/// patch its attributes.
Delta buildBlockMoveDelta(
  Document document,
  List<ParsedLine> lines,
  int fromStart,
  int fromEnd,
  int gap, {
  int indentDelta = 0,
}) {
  if (indentDelta == 0) {
    return _buildSpanMoveDelta(
      document.toDelta(),
      document.length,
      lines,
      fromStart,
      fromEnd,
      gap,
    );
  }

  // The re-indent is retain-only, so the line offsets stay valid for the move.
  final reindent = buildBlockReindentDelta(
    lines,
    fromStart,
    fromEnd,
    indentDelta,
  );
  final patched = [...lines];
  for (var i = fromStart; i <= fromEnd; i++) {
    patched[i] = ParsedLine(
      startOffset: lines[i].startOffset,
      length: lines[i].length,
      newlineAttributes: _withIndent(
        lines[i].newlineAttributes,
        lines[i].indent + indentDelta,
      ),
    );
  }
  final move = _buildSpanMoveDelta(
    document.toDelta().compose(reindent),
    document.length,
    patched,
    fromStart,
    fromEnd,
    gap,
  );
  return reindent.compose(move);
}

Delta _buildSpanMoveDelta(
  Delta delta,
  int docLength,
  List<ParsedLine> lines,
  int fromStart,
  int fromEnd,
  int gap,
) {
  assert(gap < fromStart || gap > fromEnd + 1);
  final srcStart = lines[fromStart].startOffset;
  final srcEnd = lines[fromEnd].startOffset + lines[fromEnd].length;
  final srcLength = srcEnd - srcStart;

  final move = Delta();
  if (gap > fromEnd + 1) {
    // Move down = pull the lines below the span up in front of it.
    final belowLast = lines[gap - 1];
    final belowStart = srcEnd;
    final belowEnd = belowLast.startOffset + belowLast.length;
    if (belowEnd < docLength) {
      move.retain(srcStart);
      delta.slice(belowStart, belowEnd).toList().forEach(move.push);
      move
        ..retain(srcLength)
        ..delete(belowEnd - belowStart);
    } else {
      move
        ..retain(srcStart)
        ..delete(srcLength)
        ..retain(belowEnd - belowStart - 1)
        ..insert('\n', belowLast.newlineAttributes);
      delta.slice(srcStart, srcEnd - 1).toList().forEach(move.push);
      move.retain(
        1,
        _attributeDiff(
          belowLast.newlineAttributes,
          lines[fromEnd].newlineAttributes,
        ),
      );
    }
  } else {
    final insertAt = lines[gap].startOffset;
    if (srcEnd < docLength) {
      move.retain(insertAt);
      delta.slice(srcStart, srcEnd).toList().forEach(move.push);
      move
        ..retain(srcStart - insertAt)
        ..delete(srcLength);
    } else {
      // The span ends the document.
      final lineAbove = lines[fromStart - 1];
      move.retain(insertAt);
      delta.slice(srcStart, srcEnd - 1).toList().forEach(move.push);
      move
        ..insert('\n', lines[fromEnd].newlineAttributes)
        ..retain(srcStart - insertAt - 1)
        ..delete(srcLength)
        ..retain(
          1,
          _attributeDiff(
            lines[fromEnd].newlineAttributes,
            lineAbove.newlineAttributes,
          ),
        );
    }
  }
  return move;
}

/// Order of the group's line indices after a toggle: at each nesting level a
/// stable partition of sibling blocks (a line plus its indented children) —
/// unchecked blocks first, checked blocks last, each keeping document order,
/// with the toggled block at the end of its own section — applied recursively
/// within each block. Null when the group is already in that order.
List<int>? checklistSortOrder(
  List<ParsedLine> lines,
  int groupStart,
  int groupEnd,
  int toggledIndex,
) {
  final order = <int>[];
  _orderSiblingBlocks(lines, groupStart, groupEnd, toggledIndex, order);
  for (var k = 0; k < order.length; k++) {
    if (order[k] != groupStart + k) return order;
  }
  return null;
}

void _orderSiblingBlocks(
  List<ParsedLine> lines,
  int start,
  int end,
  int toggledIndex,
  List<int> out,
) {
  final unchecked = <(int, int)>[];
  final checked = <(int, int)>[];
  (int, int)? toggled;

  var i = start;
  while (i <= end) {
    final blockEnd = checklistBlockEnd(lines, i, end);
    final block = (i, blockEnd);
    if (i == toggledIndex) {
      toggled = block;
    } else {
      (lines[i].isChecked ? checked : unchecked).add(block);
    }
    i = blockEnd + 1;
  }
  if (toggled != null) {
    (lines[toggled.$1].isChecked ? checked : unchecked).add(toggled);
  }

  for (final (blockStart, blockEnd) in [...unchecked, ...checked]) {
    out.add(blockStart);
    if (blockEnd > blockStart) {
      _orderSiblingBlocks(lines, blockStart + 1, blockEnd, toggledIndex, out);
    }
  }
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

const int maxListIndent = 3;

/// Delta that indents ([increase]) or outdents the list lines intersecting
/// the selection [start]..[end]. Indenting is clamped to [maxListIndent] and
/// to one level deeper than the line above, which must be a list line
/// itself. Null when nothing changes.
Delta? buildListIndentDelta(
  List<ParsedLine> lines,
  int start,
  int end, {
  required bool increase,
}) {
  final selEnd = end > start ? end : start + 1;
  final effective = <int>[];
  final delta = Delta();
  var cursor = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final newlineOffset = line.startOffset + line.length - 1;
    final inRange = line.startOffset < selEnd && start <= newlineOffset;
    var newIndent = line.indent;

    if (inRange && line.listType != null) {
      if (increase) {
        final prevIsList = i > 0 && lines[i - 1].listType != null;
        var cap = prevIsList ? effective[i - 1] + 1 : 0;
        if (cap > maxListIndent) cap = maxListIndent;
        final proposed = newIndent + 1;
        if (proposed <= cap) newIndent = proposed;
      } else if (newIndent > 0) {
        newIndent -= 1;
      }
    }
    effective.add(newIndent);

    if (newIndent != line.indent) {
      if (newlineOffset > cursor) {
        delta.retain(newlineOffset - cursor);
      }
      delta.retain(1, {'indent': newIndent == 0 ? null : newIndent});
      cursor = newlineOffset + 1;
    }
  }

  return cursor > 0 ? delta : null;
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
