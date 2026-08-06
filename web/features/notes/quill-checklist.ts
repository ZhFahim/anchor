import Delta from "quill-delta";
import { LIST_FORMATS, type QuillDelta, type QuillOp } from "./quill";
import {
  type DeltaLine,
  deltaToLines,
  findLineIndexAtPosition,
  getLineLength,
  getLineStartPosition,
  getLineText,
  isCheckedLine,
  isChecklistLine,
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
 * Order of the group's line indices after a toggle: a stable partition —
 * unchecked lines first, checked lines last, each keeping document order,
 * with the toggled line at the end of its own section. Null when the group
 * is already in that order.
 */
function checklistSortOrder(
  lines: DeltaLine[],
  groupStart: number,
  groupEnd: number,
  toggledIndex: number,
): number[] | null {
  const unchecked: number[] = [];
  const checked: number[] = [];
  for (let i = groupStart; i <= groupEnd; i++) {
    if (i === toggledIndex) continue;
    (isCheckedLine(lines[i]) ? checked : unchecked).push(i);
  }
  if (isCheckedLine(lines[toggledIndex])) {
    checked.push(toggledIndex);
  } else {
    unchecked.push(toggledIndex);
  }

  const order = [...unchecked, ...checked];
  return order.some((lineIndex, k) => lineIndex !== groupStart + k)
    ? order
    : null;
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

/**
 * Delta that moves the line at fromIndex so it ends up at index toIndex.
 */
function buildLineMoveDelta(
  lines: DeltaLine[],
  fromIndex: number,
  toIndex: number,
): QuillDelta {
  const line = lines[fromIndex];
  const lineStart = getLineStartPosition(lines, fromIndex);
  const lineLength = getLineLength(line);
  const lineOps: QuillOp[] = [...line.contentOps, line.newlineOp];
  const ops: QuillOp[] = [];

  if (fromIndex < toIndex) {
    // Moving down: delete source, then insert after the target line
    const targetStart =
      getLineStartPosition(lines, toIndex) + getLineLength(lines[toIndex]);

    if (lineStart > 0) {
      ops.push({ retain: lineStart });
    }
    ops.push({ delete: lineLength });
    const retainToTarget = targetStart - lineLength - lineStart;
    if (retainToTarget > 0) {
      ops.push({ retain: retainToTarget });
    }
    ops.push(...lineOps);
  } else {
    // Moving up: insert at target, then delete source (adjusted)
    const targetStart = getLineStartPosition(lines, toIndex);

    if (targetStart > 0) {
      ops.push({ retain: targetStart });
    }
    ops.push(...lineOps);
    const retainToSource = lineStart - targetStart;
    if (retainToSource > 0) {
      ops.push({ retain: retainToSource });
    }
    ops.push({ delete: lineLength });
  }

  return { ops };
}

export type ChecklistDragPlan = {
  lineIndex: number;
  groupStart: number;
  groupEnd: number;
  /** Insertion gaps: gap g drops the line before line g. Inclusive bounds. */
  minGap: number;
  maxGap: number;
  /** Ordinal of the group's first line among all checklist lines. */
  groupOrdinal: number;
  text: string;
  checked: boolean;
};

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

  const minGap = groupStart;
  const maxGap = groupEnd + 1;
  if (maxGap - minGap <= 1) return null;

  let groupOrdinal = 0;
  for (let i = 0; i < groupStart; i++) {
    if (isChecklistLine(lines[i])) groupOrdinal++;
  }

  return {
    lineIndex,
    groupStart,
    groupEnd,
    minGap,
    maxGap,
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
 * Delta for `updateContents` that drops the dragged line into [gap].
 * Null when the drop is a no-op.
 */
export function buildChecklistDropDelta(
  currentDelta: QuillDelta,
  lineIndex: number,
  gap: number,
): QuillDelta | null {
  const targetIndex = gap <= lineIndex ? gap : gap - 1;
  if (targetIndex === lineIndex) return null;
  const lines = deltaToLines(currentDelta.ops);
  if (lineIndex < 0 || lineIndex >= lines.length) return null;
  if (targetIndex < 0 || targetIndex >= lines.length) return null;
  return buildLineMoveDelta(lines, lineIndex, targetIndex);
}
