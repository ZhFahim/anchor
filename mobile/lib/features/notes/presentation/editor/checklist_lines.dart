import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../domain/note_blocks.dart';
import 'document_lines.dart';

/// First and last line of the checklist run holding line [index].
(int, int) checklistGroupAround(List<ParsedLine> lines, int index) {
  var start = index;
  var end = index;
  while (start > 0 && lines[start - 1].isChecklist) {
    start--;
  }
  while (end < lines.length - 1 && lines[end + 1].isChecklist) {
    end++;
  }
  return (start, end);
}

/// Last line of [index]'s block: it and the deeper-indented lines after it.
int checklistBlockEnd(List<ParsedLine> lines, int index, int rangeEnd) {
  final base = lines[index].indent;
  var end = index;
  while (end < rangeEnd && lines[end + 1].indent > base) {
    end++;
  }
  return end;
}

class ChecklistGap {
  /// The block drops before line [gap].
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

/// Gaps where block [blockStart..blockEnd] can drop, including its own
/// boundaries, with the indent range its head line may take at each.
List<ChecklistGap> checklistDropGaps(
  List<ParsedLine> lines,
  int groupStart,
  int groupEnd,
  int blockStart,
  int blockEnd,
) {
  final head = lines[blockStart].indent;
  var maxRelativeIndent = 0;
  for (var i = blockStart; i <= blockEnd; i++) {
    if (lines[i].indent - head > maxRelativeIndent) {
      maxRelativeIndent = lines[i].indent - head;
    }
  }
  final lastRelativeIndent = lines[blockEnd].indent - head;

  final gaps = <ChecklistGap>[];
  for (var g = groupStart; g <= groupEnd + 1; g++) {
    if (g > blockStart && g <= blockEnd) continue;
    // Both own boundaries are the same position once the block is taken out.
    final own = g >= blockStart && g <= blockEnd + 1;
    final aboveIndex = own ? blockStart - 1 : g - 1;
    final belowIndex = own ? blockEnd + 1 : g;
    final above = aboveIndex >= groupStart ? lines[aboveIndex].indent : null;
    final below = belowIndex <= groupEnd ? lines[belowIndex].indent : null;
    var maxIndent = maxListIndent - maxRelativeIndent;
    final aboveCap = above == null ? 0 : above + 1;
    if (aboveCap < maxIndent) maxIndent = aboveCap;
    var minIndent = below == null ? 0 : below - 1 - lastRelativeIndent;
    if (minIndent < 0) minIndent = 0;
    if (minIndent > maxIndent) continue;
    gaps.add(ChecklistGap(g, minIndent, maxIndent));
  }
  return gaps;
}

/// Moves the line at [fromIndex] so it ends up at [toIndex].
@visibleForTesting
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
    delta.retain(1, indentAttributes(lines[i].indent + indentDelta));
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

/// Moves lines [fromStart..fromEnd] to before line [gap], which must lie
/// outside the span, shifting their indent by [indentDelta].
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

  // The re-indent is retain-only: line offsets stay valid for the move.
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

/// Document.compose can't delete the final newline or insert after it.
Delta _buildSpanMoveDelta(
  Delta delta,
  int docLength,
  List<ParsedLine> lines,
  int fromStart,
  int fromEnd,
  int gap,
) {
  assert(gap < fromStart || gap > fromEnd + 1);
  final sourceStart = lines[fromStart].startOffset;
  final sourceEnd = lines[fromEnd].startOffset + lines[fromEnd].length;
  final sourceLength = sourceEnd - sourceStart;

  final move = Delta();
  if (gap > fromEnd + 1) {
    // Move down = pull the lines below the span up in front of it.
    final belowLast = lines[gap - 1];
    final belowStart = sourceEnd;
    final belowEnd = belowLast.startOffset + belowLast.length;
    if (belowEnd < docLength) {
      move.retain(sourceStart);
      delta.slice(belowStart, belowEnd).toList().forEach(move.push);
      move
        ..retain(sourceLength)
        ..delete(belowEnd - belowStart);
    } else {
      move
        ..retain(sourceStart)
        ..delete(sourceLength)
        ..retain(belowEnd - belowStart - 1)
        ..insert('\n', belowLast.newlineAttributes);
      delta.slice(sourceStart, sourceEnd - 1).toList().forEach(move.push);
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
    if (sourceEnd < docLength) {
      move.retain(insertAt);
      delta.slice(sourceStart, sourceEnd).toList().forEach(move.push);
      move
        ..retain(sourceStart - insertAt)
        ..delete(sourceLength);
    } else {
      final lineAbove = lines[fromStart - 1];
      move.retain(insertAt);
      delta.slice(sourceStart, sourceEnd - 1).toList().forEach(move.push);
      move
        ..insert('\n', lines[fromEnd].newlineAttributes)
        ..retain(sourceStart - insertAt - 1)
        ..delete(sourceLength)
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

/// Unchecked blocks before checked at each level, in document order, with
/// the toggled block last in its section. Null when already in order.
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

/// [order] holds indices into [lines] and must differ from the current order.
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
    final position = current.indexOf(order[k], k);
    if (position == k) continue;

    final move = _buildLineMoveDelta(
      docDelta,
      docLength,
      model,
      groupStart + position,
      groupStart + k,
    );
    docDelta = docDelta.compose(move);
    total = total == null ? move : total.compose(move);

    current
      ..removeAt(position)
      ..insert(k, order[k]);
    final moved = model.removeAt(groupStart + position);
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

/// Toggles [index] and every checklist line in its block.
Delta buildChecklistToggleDelta(
  List<ParsedLine> lines,
  int index,
  bool checked,
) {
  final end = checklistBlockEnd(lines, index, lines.length - 1);
  final value = checked
      ? Attribute.checked.value
      : Attribute.unchecked.value;
  final delta = Delta();
  var cursor = 0;
  for (var i = index; i <= end; i++) {
    final line = lines[i];
    if (!line.isChecklist) continue;
    final newlineOffset = line.startOffset + line.length - 1;
    if (newlineOffset > cursor) delta.retain(newlineOffset - cursor);
    delta.retain(1, {Attribute.list.key: value});
    cursor = newlineOffset + 1;
  }
  return delta;
}

Delta? buildUncheckAllDelta(List<ParsedLine> lines) {
  final delta = Delta();
  var cursor = 0;
  for (final line in lines) {
    if (!line.isChecked) continue;
    final newlineOffset = line.startOffset + line.length - 1;
    if (newlineOffset > cursor) delta.retain(newlineOffset - cursor);
    delta.retain(1, {Attribute.list.key: Attribute.unchecked.value});
    cursor = newlineOffset + 1;
  }
  return cursor > 0 ? delta : null;
}

/// An open item under a deleted one moves up a level for each deleted item
/// above it. A note of only checked items keeps one empty item.
Delta? buildDeleteCheckedDelta(List<ParsedLine> lines) {
  if (!lines.any((line) => line.isChecked)) return null;
  final indents = _indentsWithoutChecked(lines);
  var tail = lines.length;
  while (tail > 0 && lines[tail - 1].isChecked) {
    tail--;
  }

  final delta = Delta();
  var cursor = 0;
  void retainTo(int offset) {
    if (offset > cursor) delta.retain(offset - cursor);
    cursor = offset;
  }

  final endsChecked = tail < lines.length;
  for (var i = 0; i < tail; i++) {
    final line = lines[i];
    if (line.isChecked) {
      retainTo(line.startOffset);
      delta.delete(line.length);
      cursor += line.length;
    } else if (indents[i] != line.indent && !(endsChecked && i == tail - 1)) {
      retainTo(line.startOffset + line.length - 1);
      delta.retain(1, indentAttributes(indents[i]));
      cursor++;
    }
  }
  if (!endsChecked) return delta;

  // Document.compose can't delete the final newline.
  final last = lines.last;
  final finalNewline = last.startOffset + last.length - 1;
  final kept = tail > 0 ? lines[tail - 1] : null;
  final keptNewline = kept == null ? 0 : kept.startOffset + kept.length - 1;
  retainTo(keptNewline);
  delta
    ..delete(finalNewline - keptNewline)
    ..retain(
      1,
      _attributeDiff(
        last.newlineAttributes,
        kept == null
            ? {Attribute.list.key: Attribute.unchecked.value}
            : _withIndent(kept.newlineAttributes, indents[tail - 1]),
      ),
    );
  return delta;
}

List<int> _indentsWithoutChecked(List<ParsedLine> lines) {
  final indents = <int>[];
  final above = <ParsedLine>[];
  for (final line in lines) {
    if (line.listType == null) {
      above.clear();
      indents.add(line.indent);
      continue;
    }
    while (above.isNotEmpty && above.last.indent >= line.indent) {
      above.removeLast();
    }
    indents.add(line.indent - above.where((item) => item.isChecked).length);
    above.add(line);
  }
  return indents;
}

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
