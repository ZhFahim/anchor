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

/// Lines of a checklist group in the checked section's order, with the absolute
/// indent each line takes. [order] holds original line indices; [indents]
/// follows it. An unchecked line keeps its own indent. A checked block starts
/// the checked section at absolute indent 0, and its descendants follow one
/// level below their own parent.
class CheckedSectionPlan {
  final List<int> order;
  final List<int> indents;

  const CheckedSectionPlan({required this.order, required this.indents});
}

class _ChecklistBlock {
  final int start;
  final int end;
  final List<_ChecklistBlock> children = [];

  _ChecklistBlock(this.start, this.end);
}

/// Splits [start..end] into sibling blocks, each with its own descendants.
/// A block is a head line and the deeper-indented lines after it; the next
/// line at the head's indent or shallower ends the block.
List<_ChecklistBlock> _checklistBlocks(
  List<ParsedLine> lines,
  int start,
  int end,
) {
  final heads = <int>[];
  for (var i = start; i <= end; i++) {
    if (i == start || lines[i].indent <= lines[heads.last].indent) {
      heads.add(i);
    }
  }

  final blocks = <_ChecklistBlock>[];
  for (var h = 0; h < heads.length; h++) {
    final head = heads[h];
    final blockEnd = h + 1 < heads.length ? heads[h + 1] - 1 : end;
    blocks.add(_checklistSubtree(lines, head, blockEnd));
  }
  return blocks;
}

/// Block [start..end] with its descendants nested by indent.
_ChecklistBlock _checklistSubtree(List<ParsedLine> lines, int start, int end) {
  final root = _ChecklistBlock(start, end);
  final children = _checklistBlocks(lines, start + 1, end);
  root.children.addAll(children);
  return root;
}

/// One checked section at the bottom of the group, after every unchecked
/// line. Null when the group is already in that order.
///
/// [prefer] is the line the reader just toggled. Its block goes last in the
/// section its container lands in: the container is its parent block when it
/// has one, otherwise its own checked or unchecked section. Pass null for the
/// plain order, which keeps every section in document order.
CheckedSectionPlan? checklistCheckedSectionPlan(
  List<ParsedLine> lines,
  int groupStart,
  int groupEnd, {
  int? prefer,
}) {
  final open = <int>[];
  final openIndents = <int>[];
  final done = <int>[];
  final doneIndents = <int>[];
  final blocks = _checklistBlocks(lines, groupStart, groupEnd);
  final late = prefer == null ? null : _blockStartingAt(blocks, prefer);
  // A checked block with an unchecked descendant is frozen as a whole. It does
  // not move, and neither does a child toggled inside it, however deep.
  final parentFrozen = late != null && _hasFrozenAncestor(lines, blocks, late);
  final lateMoves =
      late != null &&
      !parentFrozen &&
      (!lines[late.start].isChecked || _blockFullyChecked(lines, late));
  final effectiveLate = lateMoves ? late : null;
  final frozen = late != null && !lateMoves ? late : null;
  _planSiblings(
    lines,
    blocks,
    open,
    openIndents,
    done,
    doneIndents,
    late: effectiveLate,
    frozen: frozen,
  );
  // The toggled block was skipped everywhere above, so it is appended once,
  // here. A checked block with only checked descendants leaves its parent and
  // starts at the absolute root. An unchecked block keeps its own indent.
  if (lateMoves) {
    final toDone = _blockFullyChecked(lines, late);
    _appendWholeBlock(
      late,
      toDone ? 0 : lines[late.start].indent,
      toDone ? done : open,
      toDone ? doneIndents : openIndents,
      late: null,
    );
  }
  final order = [...open, ...done];
  final indents = [...openIndents, ...doneIndents];
  if (order.length != groupEnd - groupStart + 1) return null;

  for (var k = 0; k < order.length; k++) {
    final line = lines[groupStart + k];
    if (order[k] != groupStart + k || indents[k] != line.indent) {
      return CheckedSectionPlan(order: order, indents: indents);
    }
  }
  return null;
}

/// One level of blocks, in document order. An unchecked block emits its head
/// at its own absolute indent, then its children in place. A checked block
/// goes to the group's one checked section.
void _planSiblings(
  List<ParsedLine> lines,
  List<_ChecklistBlock> blocks,
  List<int> open,
  List<int> openIndents,
  List<int> done,
  List<int> doneIndents, {
  required _ChecklistBlock? late,
  _ChecklistBlock? frozen,
}) {
  for (final block in blocks) {
    // The toggled block waits for the caller to append it last.
    if (block == late) continue;
    _appendBlock(
      lines,
      block,
      open,
      openIndents,
      done,
      doneIndents,
      late,
      frozen,
    );
  }
}

void _appendBlock(
  List<ParsedLine> lines,
  _ChecklistBlock block,
  List<int> open,
  List<int> openIndents,
  List<int> done,
  List<int> doneIndents,
  _ChecklistBlock? late,
  _ChecklistBlock? frozen,
) {
  if (block == frozen) {
    // A frozen block keeps its whole subtree where it is.
    _appendWholeBlock(
      block,
      lines[block.start].indent,
      open,
      openIndents,
      late: null,
    );
    return;
  }
  if (lines[block.start].isChecked && _blockFullyChecked(lines, block)) {
    // A checked block leaves its parent and starts the checked section at
    // the absolute root indent. A parent with an unchecked descendant stays
    // in the open list, and its checked children may still leave it.
    _appendWholeBlock(block, 0, done, doneIndents, late: late);
    return;
  }
  _appendLine(block.start, lines[block.start].indent, open, openIndents);
  _appendChildren(
    lines,
    block,
    open,
    openIndents,
    done,
    doneIndents,
    late,
    frozen,
  );
}

void _appendChildren(
  List<ParsedLine> lines,
  _ChecklistBlock block,
  List<int> open,
  List<int> openIndents,
  List<int> done,
  List<int> doneIndents,
  _ChecklistBlock? late,
  _ChecklistBlock? frozen,
) {
  for (final child in block.children) {
    // The toggled block waits its turn in _planSiblings.
    if (child == late) continue;
    _appendBlock(
      lines,
      child,
      open,
      openIndents,
      done,
      doneIndents,
      late,
      frozen,
    );
  }
}

/// The innermost block that starts at line [index].
_ChecklistBlock? _blockStartingAt(List<_ChecklistBlock> blocks, int index) {
  for (final block in blocks) {
    if (block.start == index) return block;
    final inner = _blockStartingAt(block.children, index);
    if (inner != null) return inner;
  }
  return null;
}

/// The block whose children hold [target], or null when it is top level.
_ChecklistBlock? _blockParent(
  List<_ChecklistBlock> blocks,
  _ChecklistBlock target,
) {
  for (final block in blocks) {
    if (block.children.contains(target)) return block;
    final inner = _blockParent(block.children, target);
    if (inner != null) return inner;
  }
  return null;
}

/// True when any ancestor of [target] is checked but not fully checked. Such
/// an ancestor is frozen, so its descendants must stay in place too.
bool _hasFrozenAncestor(
  List<ParsedLine> lines,
  List<_ChecklistBlock> blocks,
  _ChecklistBlock target,
) {
  var parent = _blockParent(blocks, target);
  while (parent != null) {
    if (lines[parent.start].isChecked && !_blockFullyChecked(lines, parent)) {
      return true;
    }
    parent = _blockParent(blocks, parent);
  }
  return false;
}

/// True when every line in the block is checked. A block with any unchecked
/// descendant stays in the open list.
bool _blockFullyChecked(List<ParsedLine> lines, _ChecklistBlock block) {
  for (var i = block.start; i <= block.end; i++) {
    if (!lines[i].isChecked) return false;
  }
  return true;
}

/// A checked block moves whole. [headIndent] is absolute: the head takes it,
/// and each descendant is one level below its own parent.
void _appendWholeBlock(
  _ChecklistBlock block,
  int headIndent,
  List<int> order,
  List<int> indents, {
  _ChecklistBlock? late,
}) {
  _appendLine(block.start, headIndent, order, indents);
  for (final child in block.children) {
    // The toggled block is appended last by the caller, so it is never
    // emitted here. Without this the same line lands in [order] twice.
    if (child == late) continue;
    _appendWholeBlock(child, headIndent + 1, order, indents, late: late);
  }
}

void _appendLine(int index, int indent, List<int> order, List<int> indents) {
  order.add(index);
  indents.add(indent);
}

/// [order] holds indices into [lines]. It may be the identity order when only
/// the indents change; that case makes an empty delta.
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

  // An order that only re-indents makes no move of its own.
  return total ?? Delta();
}

/// Writes [lines] newline indent attributes to their absolute [indents],
/// keeping every other attribute of each newline.
Delta buildIndentsDelta(
  List<ParsedLine> lines,
  int groupStart,
  List<int> indents,
) {
  final delta = Delta();
  var cursor = 0;
  for (var k = 0; k < indents.length; k++) {
    final line = lines[groupStart + k];
    if (indents[k] == line.indent) continue;
    final newlineOffset = line.startOffset + line.length - 1;
    if (newlineOffset > cursor) delta.retain(newlineOffset - cursor);
    delta.retain(1, indentAttributes(indents[k]));
    cursor = newlineOffset + 1;
  }
  return delta;
}

/// Moves the group at [groupStart] into the checked section [plan] describes,
/// in one delta: the reorder, then the indent each line takes in the new
/// order.
Delta buildCheckedSectionDelta(
  Document document,
  List<ParsedLine> lines,
  int groupStart,
  CheckedSectionPlan plan,
) {
  final move = buildGroupReorderDelta(document, lines, groupStart, plan.order);
  // A plan that only re-indents makes no move of its own, and Document.compose
  // rejects an empty delta.
  if (move.isEmpty) {
    return buildIndentsDelta(lines, groupStart, plan.indents);
  }
  final moved = Document.fromDelta(document.toDelta())
    ..compose(move, ChangeSource.local);
  final reindent = buildIndentsDelta(
    parseDocumentLines(moved),
    groupStart,
    plan.indents,
  );
  return reindent.isEmpty ? move : move.compose(reindent);
}

/// Toggles [index] and every checklist line in its block.
Delta buildChecklistToggleDelta(
  List<ParsedLine> lines,
  int index,
  bool checked,
) {
  final end = checklistBlockEnd(lines, index, lines.length - 1);
  final value = checked ? Attribute.checked.value : Attribute.unchecked.value;
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
