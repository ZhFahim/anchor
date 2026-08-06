import Delta from "quill-delta";
import { LIST_FORMATS, type QuillDelta, type QuillOp } from "./quill";
import {
  blockEndIndex,
  type DeltaLine,
  deltaToLines,
  findLineIndexAtPosition,
  getLineLength,
  getLineStartPosition,
  getLineText,
  indentOf,
  isCheckedLine,
  isChecklistLine,
  MAX_LIST_INDENT,
} from "./quill-lines";

// ============================================================================
// Change Detection
// ============================================================================

/**
 * Check if a change delta indicates a checkbox was clicked to toggle its state.
 *
 * When clicking a checkbox, Quill produces a very specific delta pattern:
 * { ops: [{ retain: N }, { retain: 1, attributes: { list: "checked" | "unchecked" } }] }
 */
export function didChangeChecklistItemState(changeDelta: unknown): boolean {
  if (!changeDelta || typeof changeDelta !== "object") return false;

  const delta = changeDelta as { ops?: unknown[] };
  if (!Array.isArray(delta.ops) || delta.ops.length === 0) return false;

  // Check that there are no inserts or deletes (pure format change)
  const hasInsertOrDelete = delta.ops.some((op) => {
    if (!op || typeof op !== "object") return false;
    const operation = op as { insert?: unknown; delete?: number };
    return operation.insert !== undefined || operation.delete !== undefined;
  });

  if (hasInsertOrDelete) return false;

  // Find operations that change list format to checked/unchecked
  const listFormatChanges = delta.ops.filter((op) => {
    if (!op || typeof op !== "object") return false;

    const operation = op as {
      retain?: number;
      attributes?: { list?: string };
    };

    // Must be a retain operation with list attribute
    if (operation.retain === undefined) return false;
    if (!operation.attributes) return false;

    const list = operation.attributes.list;
    return list === LIST_FORMATS.CHECKED || list === LIST_FORMATS.UNCHECKED;
  });

  // A checkbox toggle should have exactly one list format change
  // and it should retain exactly 1 character (the newline)
  if (listFormatChanges.length !== 1) return false;

  const formatChange = listFormatChanges[0] as { retain?: number };
  return formatChange.retain === 1;
}

/**
 * Extract the position from a change delta where a checkbox was toggled.
 * Returns the character position of the toggled line's newline, or -1 if not found.
 */
export function getToggledLinePosition(changeDelta: QuillDelta): number {
  let position = 0;
  for (const op of changeDelta.ops) {
    if (op.retain !== undefined && !op.attributes) {
      position += op.retain;
    } else if (op.retain === 1 && op.attributes) {
      const list = op.attributes.list;
      if (list === LIST_FORMATS.CHECKED || list === LIST_FORMATS.UNCHECKED) {
        return position;
      }
    }
  }
  return -1;
}

// ============================================================================
// Checklist Sorting
// ============================================================================

/**
 * Order of the group's line indices after a toggle: at each nesting level a
 * stable partition of sibling blocks (a line plus its indented children) —
 * unchecked blocks first, checked blocks last, each keeping document order,
 * with the toggled block at the end of its own section — applied recursively
 * within each block. Null when the group is already in that order.
 */
function checklistSortOrder(
  lines: DeltaLine[],
  groupStart: number,
  groupEnd: number,
  toggledIndex: number,
): number[] | null {
  const order: number[] = [];
  orderSiblingBlocks(lines, groupStart, groupEnd, toggledIndex, order);
  return order.some((lineIndex, k) => lineIndex !== groupStart + k)
    ? order
    : null;
}

function orderSiblingBlocks(
  lines: DeltaLine[],
  start: number,
  end: number,
  toggledIndex: number,
  out: number[],
): void {
  type Block = [number, number];
  const unchecked: Block[] = [];
  const checked: Block[] = [];
  let toggled: Block | null = null;

  for (let i = start; i <= end; ) {
    const blockEnd = blockEndIndex(lines, i, end);
    const block: Block = [i, blockEnd];
    if (i === toggledIndex) {
      toggled = block;
    } else {
      (isCheckedLine(lines[i]) ? checked : unchecked).push(block);
    }
    i = blockEnd + 1;
  }
  if (toggled) {
    (isCheckedLine(lines[toggled[0]]) ? checked : unchecked).push(toggled);
  }

  for (const [blockStart, blockEnd] of [...unchecked, ...checked]) {
    out.push(blockStart);
    if (blockEnd > blockStart) {
      orderSiblingBlocks(lines, blockStart + 1, blockEnd, toggledIndex, out);
    }
  }
}

/**
 * Create a delta for `updateContents` that re-sorts the toggled item's
 * checklist group: unchecked on top, checked at the bottom. A minimal diff
 * of the group slice, so cursor positions survive.
 *
 * @param togglePosition - Position where the checkbox was toggled (from change delta)
 * @param currentDelta - Current document content
 * @returns A delta to pass to updateContents, or null if no move needed
 */
export function createChecklistSortDelta(
  togglePosition: number,
  currentDelta: QuillDelta,
): QuillDelta | null {
  const lines = deltaToLines(currentDelta.ops);
  const lineIndex = findLineIndexAtPosition(lines, togglePosition);

  if (lineIndex < 0 || lineIndex >= lines.length) return null;
  if (!isChecklistLine(lines[lineIndex])) return null;

  let groupStart = lineIndex;
  while (groupStart > 0 && isChecklistLine(lines[groupStart - 1])) {
    groupStart--;
  }
  let groupEnd = lineIndex;
  while (groupEnd < lines.length - 1 && isChecklistLine(lines[groupEnd + 1])) {
    groupEnd++;
  }

  const order = checklistSortOrder(lines, groupStart, groupEnd, lineIndex);
  if (!order) return null;

  const groupOffset = getLineStartPosition(lines, groupStart);
  let groupLength = 0;
  for (let i = groupStart; i <= groupEnd; i++) {
    groupLength += getLineLength(lines[i]);
  }

  const oldSlice = new Delta(currentDelta.ops as never).slice(
    groupOffset,
    groupOffset + groupLength,
  );
  const newSlice = new Delta();
  for (const idx of order) {
    for (const op of lines[idx].contentOps) newSlice.push(op as never);
    newSlice.push(lines[idx].newlineOp as never);
  }

  const diff = oldSlice.diff(newSlice);
  if (diff.ops.length === 0) return null;

  const result = new Delta().retain(groupOffset);
  for (const op of diff.ops) result.push(op);
  return { ops: result.ops as QuillOp[] };
}

// ============================================================================
// Checklist Drag Reorder
// ============================================================================

/** The line's newline op with its indent shifted by [indentDelta]. */
function shiftedNewlineOp(line: DeltaLine, indentDelta: number): QuillOp {
  if (indentDelta === 0) return line.newlineOp;
  const { indent: _, ...rest } = line.newlineOp.attributes ?? {};
  const indent = indentOf(line) + indentDelta;
  const attributes = { ...rest, ...(indent > 0 ? { indent } : {}) };
  return Object.keys(attributes).length
    ? { insert: "\n", attributes }
    : { insert: "\n" };
}

/**
 * Delta that moves the contiguous lines [fromStart..fromEnd] into [gap]
 * (the position before line [gap], which must lie outside the span),
 * shifting each moved line's indent by [indentDelta].
 */
function buildSpanMoveDelta(
  lines: DeltaLine[],
  fromStart: number,
  fromEnd: number,
  gap: number,
  indentDelta: number,
): QuillDelta {
  const spanStart = getLineStartPosition(lines, fromStart);
  let spanLength = 0;
  const spanOps: QuillOp[] = [];
  for (let i = fromStart; i <= fromEnd; i++) {
    spanLength += getLineLength(lines[i]);
    spanOps.push(
      ...lines[i].contentOps,
      shiftedNewlineOp(lines[i], indentDelta),
    );
  }
  const ops: QuillOp[] = [];

  if (gap > fromEnd + 1) {
    // Moving down: delete the span, then reinsert it before line [gap].
    const insertPos = getLineStartPosition(lines, gap);
    if (spanStart > 0) {
      ops.push({ retain: spanStart });
    }
    ops.push({ delete: spanLength });
    const retainBetween = insertPos - spanStart - spanLength;
    if (retainBetween > 0) {
      ops.push({ retain: retainBetween });
    }
    ops.push(...spanOps);
  } else {
    // Moving up: insert before line [gap], then delete the source span.
    const targetPos = getLineStartPosition(lines, gap);
    if (targetPos > 0) {
      ops.push({ retain: targetPos });
    }
    ops.push(...spanOps);
    const retainToSource = spanStart - targetPos;
    if (retainToSource > 0) {
      ops.push({ retain: retainToSource });
    }
    ops.push({ delete: spanLength });
  }

  return { ops };
}

export type ChecklistDropGap = {
  /** Insertion point: the block drops before line [gap]. */
  gap: number;
  /** Lowest indent the block's head line may take at this gap. */
  minIndent: number;
  /** Highest indent the block's head line may take at this gap. */
  maxIndent: number;
};

export type ChecklistDragPlan = {
  lineIndex: number;
  /** Last line of the dragged block (the line plus its indented children). */
  blockEnd: number;
  /** Nesting level of the dragged line at drag start. */
  indent: number;
  groupStart: number;
  groupEnd: number;
  /**
   * Valid insertion gaps, sorted by gap, each with the indent range the
   * dropped block may take there. Includes the block's own boundaries
   * (a no-op unless the indent changes). In flat groups this is every gap
   * in the group.
   */
  gaps: ChecklistDropGap[];
  /** Ordinal of the group's first line among all checklist lines. */
  groupOrdinal: number;
  text: string;
  checked: boolean;
};

/**
 * Gaps where the block [blockStart..blockEnd] can drop, with the indent
 * range its head line may take at each: at most one level below the line
 * above the gap, deep enough that the line below the gap keeps a parent,
 * and capped so the block's deepest child stays within MAX_LIST_INDENT.
 */
function checklistDropGaps(
  lines: DeltaLine[],
  groupStart: number,
  groupEnd: number,
  blockStart: number,
  blockEnd: number,
): ChecklistDropGap[] {
  const head = indentOf(lines[blockStart]);
  let relMax = 0;
  for (let i = blockStart; i <= blockEnd; i++) {
    relMax = Math.max(relMax, indentOf(lines[i]) - head);
  }
  const relLast = indentOf(lines[blockEnd]) - head;

  const gaps: ChecklistDropGap[] = [];
  for (let g = groupStart; g <= groupEnd + 1; g++) {
    if (g > blockStart && g <= blockEnd) continue;
    // Both own boundaries are the same position once the block is taken out.
    const own = g >= blockStart && g <= blockEnd + 1;
    const aboveIndex = own ? blockStart - 1 : g - 1;
    const belowIndex = own ? blockEnd + 1 : g;
    const above = aboveIndex >= groupStart ? indentOf(lines[aboveIndex]) : null;
    const below = belowIndex <= groupEnd ? indentOf(lines[belowIndex]) : null;
    const maxIndent = Math.min(
      above === null ? 0 : above + 1,
      MAX_LIST_INDENT - relMax,
    );
    const minIndent = below === null ? 0 : Math.max(0, below - 1 - relLast);
    if (minIndent > maxIndent) continue;
    gaps.push({ gap: g, minIndent, maxIndent });
  }
  return gaps;
}

/**
 * Everything needed to drag the checklist line at [lineIndex]: its group
 * bounds, the allowed insertion gaps, and its content for the drag ghost.
 * Null when the line is not a checklist item or has nowhere to go.
 */
export function getChecklistDragPlan(
  currentDelta: QuillDelta,
  lineIndex: number,
): ChecklistDragPlan | null {
  const lines = deltaToLines(currentDelta.ops);
  if (lineIndex < 0 || lineIndex >= lines.length) return null;
  const line = lines[lineIndex];
  if (!isChecklistLine(line)) return null;

  let groupStart = lineIndex;
  while (groupStart > 0 && isChecklistLine(lines[groupStart - 1])) {
    groupStart--;
  }
  let groupEnd = lineIndex;
  while (groupEnd < lines.length - 1 && isChecklistLine(lines[groupEnd + 1])) {
    groupEnd++;
  }

  const blockEnd = blockEndIndex(lines, lineIndex, groupEnd);
  const gaps = checklistDropGaps(
    lines,
    groupStart,
    groupEnd,
    lineIndex,
    blockEnd,
  );
  // Without a real move or a possible indent change there is nothing to do.
  if (
    gaps.every(
      (g) =>
        g.gap >= lineIndex &&
        g.gap <= blockEnd + 1 &&
        g.minIndent === g.maxIndent,
    )
  ) {
    return null;
  }

  let groupOrdinal = 0;
  for (let i = 0; i < groupStart; i++) {
    if (isChecklistLine(lines[i])) groupOrdinal++;
  }

  return {
    lineIndex,
    blockEnd,
    indent: indentOf(line),
    groupStart,
    groupEnd,
    gaps,
    groupOrdinal,
    text: getLineText(line),
    checked: isCheckedLine(line),
  };
}

/**
 * Map the ordinal of a checklist item (its position among all checklist
 * lines, e.g. a DOM query result index) to its document line index.
 */
export function checklistLineIndexFromOrdinal(
  currentDelta: QuillDelta,
  ordinal: number,
): number {
  const lines = deltaToLines(currentDelta.ops);
  let seen = 0;
  for (let i = 0; i < lines.length; i++) {
    if (isChecklistLine(lines[i])) {
      if (seen === ordinal) return i;
      seen++;
    }
  }
  return -1;
}

/**
 * Delta for `updateContents` that drops the dragged line — together with its
 * indented children, all shifted to put the head at [targetIndent] — into
 * [gap]. A gap at the block's own boundaries re-indents in place. Null when
 * the drop changes nothing or the gap falls inside the dragged block.
 */
export function buildChecklistDropDelta(
  currentDelta: QuillDelta,
  lineIndex: number,
  gap: number,
  targetIndent?: number,
): QuillDelta | null {
  const lines = deltaToLines(currentDelta.ops);
  if (lineIndex < 0 || lineIndex >= lines.length) return null;
  if (gap < 0 || gap > lines.length) return null;

  let blockEnd = lineIndex;
  if (isChecklistLine(lines[lineIndex])) {
    let groupEnd = lineIndex;
    while (
      groupEnd < lines.length - 1 &&
      isChecklistLine(lines[groupEnd + 1])
    ) {
      groupEnd++;
    }
    blockEnd = blockEndIndex(lines, lineIndex, groupEnd);
  }

  const indentDelta =
    (targetIndent ?? indentOf(lines[lineIndex])) - indentOf(lines[lineIndex]);
  if (gap >= lineIndex && gap <= blockEnd + 1) {
    if (indentDelta === 0) return null;
    const ops: QuillOp[] = [];
    let cursor = 0;
    for (let i = lineIndex; i <= blockEnd; i++) {
      const newlineOffset =
        getLineStartPosition(lines, i) + getLineLength(lines[i]) - 1;
      if (newlineOffset > cursor) {
        ops.push({ retain: newlineOffset - cursor });
      }
      const indent = indentOf(lines[i]) + indentDelta;
      ops.push({
        retain: 1,
        attributes: { indent: indent > 0 ? indent : null },
      });
      cursor = newlineOffset + 1;
    }
    return { ops };
  }
  return buildSpanMoveDelta(lines, lineIndex, blockEnd, gap, indentDelta);
}
