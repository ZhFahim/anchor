import Delta from "quill-delta";

// ============================================================================
// Types
// ============================================================================

export type QuillOp = {
  insert?: unknown;
  delete?: number;
  retain?: number;
  attributes?: Record<string, unknown>;
};

export type QuillDelta = {
  ops: QuillOp[];
};

/**
 * Quill editor instance type.
 * react-quill-new doesn't export proper types, so we define the methods we use.
 */
export type QuillInstance = {
  getContents: () => QuillDelta;
  updateContents: (
    delta: QuillDelta,
    source?: "user" | "api" | "silent",
  ) => void;
  getFormat: (index?: number, length?: number) => Record<string, unknown>;
  format: (
    name: string,
    value: unknown,
    source?: "user" | "api" | "silent",
  ) => void;
  formatText: (
    index: number,
    length: number,
    name: string,
    value: unknown,
    source?: "user" | "api" | "silent",
  ) => void;
  focus: () => void;
  getText: (index?: number, length?: number) => string;
  insertText: (
    index: number,
    text: string,
    source?: "user" | "api" | "silent",
  ) => void;
  deleteText: (
    index: number,
    length: number,
    source?: "user" | "api" | "silent",
  ) => void;
  getSelection: (focus?: boolean) => { index: number; length: number } | null;
  setSelection: (
    index: number,
    length: number,
    source?: "user" | "api" | "silent",
  ) => void;
  getBounds: (
    index: number,
    length?: number,
  ) => {
    top: number;
    left: number;
    width: number;
    height: number;
    bottom: number;
    right: number;
  } | null;
  root: HTMLElement;
  history: {
    undo: () => void;
    redo: () => void;
    cutoff: () => void;
    stack: { undo: unknown[]; redo: unknown[] };
  };
};

// ============================================================================
// Configuration
// ============================================================================

/**
 * Supported Quill formats for the editor.
 */
export const QUILL_FORMATS = [
  "bold",
  "italic",
  "underline",
  "strike",
  "header",
  "list", // ordered, bullet, checked/unchecked
  "blockquote",
  "code-block",
  "link",
] as const;

/**
 * Quill modules configuration.
 */
export const QUILL_MODULES = {
  toolbar: false,
  history: {
    delay: 1000,
    maxStack: 200,
    userOnly: true,
  },
} as const;

/**
 * List format values used by Quill.
 */
export const LIST_FORMATS = {
  ORDERED: "ordered",
  BULLET: "bullet",
  CHECKED: "checked",
  UNCHECKED: "unchecked",
} as const;

// ============================================================================
// Delta Parsing & Serialization
// ============================================================================

function emptyDelta(): QuillDelta {
  return { ops: [{ insert: "\n" }] };
}

export function parseStoredContent(
  content: string | null | undefined,
): QuillDelta {
  if (!content) return emptyDelta();

  try {
    const parsed = JSON.parse(content) as unknown;

    // Canonical Quill storage format: { ops: [...] }
    if (
      parsed &&
      typeof parsed === "object" &&
      parsed !== null &&
      "ops" in parsed &&
      Array.isArray((parsed as { ops: unknown }).ops)
    ) {
      return { ops: (parsed as { ops: QuillOp[] }).ops };
    }
  } catch {
    // invalid JSON -> strict mode: treat as empty
  }

  // Strict mode: only recommended Quill format is accepted.
  return emptyDelta();
}

export function stringifyDelta(delta: unknown): string {
  if (
    delta &&
    typeof delta === "object" &&
    delta !== null &&
    "ops" in delta &&
    Array.isArray((delta as { ops: unknown }).ops)
  ) {
    return JSON.stringify({ ops: (delta as { ops: QuillOp[] }).ops });
  }
  return JSON.stringify(emptyDelta());
}

export function isStoredContentEmpty(
  content: string | null | undefined,
): boolean {
  return deltaToFullPlainText(content).trim() === "";
}

export function deltaToFullPlainText(
  content: string | null | undefined,
): string {
  const delta = parseStoredContent(content);
  return delta.ops
    .map((op) => (typeof op.insert === "string" ? op.insert : ""))
    .join("")
    .replace(/\s+/g, " ")
    .trim();
}

function normalizePreviewTextPreserveNewlines(text: string): string {
  // Keep real newlines, but drop blank/whitespace-only lines (also collapses multiple blank lines).
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);
  return lines.join("\n");
}

export function deltaToPreviewText(
  content: string | null | undefined,
  maxLen = 200,
): string {
  const delta = parseStoredContent(content);
  const raw = delta.ops
    .map((op) => (typeof op.insert === "string" ? op.insert : ""))
    .join("");
  const normalized = normalizePreviewTextPreserveNewlines(raw);
  return normalized.slice(0, maxLen);
}

/**
 * Represents a single line in the editor (content ops + trailing newline op).
 */
type DeltaLine = {
  contentOps: QuillOp[]; // Text/embed ops before the newline
  newlineOp: QuillOp; // The newline op (with attributes like list)
};

/**
 * Check if a line is a checklist item (checked or unchecked).
 */
function isChecklistLine(line: DeltaLine): boolean {
  const list = line.newlineOp.attributes?.list;
  return list === "checked" || list === "unchecked";
}

/**
 * Check if a line is a checked checklist item.
 */
function isCheckedLine(line: DeltaLine): boolean {
  return line.newlineOp.attributes?.list === "checked";
}

/**
 * Parse delta ops into lines. Each line consists of content ops followed by a newline.
 */
function deltaToLines(ops: QuillOp[]): DeltaLine[] {
  const lines: DeltaLine[] = [];
  let currentContentOps: QuillOp[] = [];

  for (const op of ops) {
    if (typeof op.insert === "string" && op.insert.includes("\n")) {
      // Split string by newlines
      const parts = op.insert.split("\n");
      for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        if (part) {
          // Add text content before the newline
          currentContentOps.push({
            insert: part,
            ...(op.attributes ? { attributes: op.attributes } : {}),
          });
        }
        if (i < parts.length - 1) {
          // This is a newline - create a line entry
          lines.push({
            contentOps: currentContentOps,
            newlineOp: {
              insert: "\n",
              ...(op.attributes ? { attributes: op.attributes } : {}),
            },
          });
          currentContentOps = [];
        }
      }
    } else {
      // Non-string insert or string without newline
      currentContentOps.push(op);
    }
  }

  // Handle any remaining content (shouldn't normally happen with well-formed deltas)
  if (currentContentOps.length > 0) {
    lines.push({
      contentOps: currentContentOps,
      newlineOp: { insert: "\n" },
    });
  }

  return lines;
}

/**
 * Plain text of a line (content ops only, no newline).
 */
function getLineText(line: DeltaLine): string {
  return line.contentOps
    .map((op) => (typeof op.insert === "string" ? op.insert : ""))
    .join("");
}

export type PreviewLine = {
  text: string;
  listType: "checked" | "unchecked" | "ordered" | "bullet" | null;
};

/**
 * Parse delta into preview lines with list type for rendering checklists, bullets, and numbers.
 * Returns up to maxLines non-empty lines.
 */
export function deltaToPreviewLines(
  content: string | null | undefined,
  maxLines = 6,
): PreviewLine[] {
  const delta = parseStoredContent(content);
  const lines = deltaToLines(delta.ops);
  return lines
    .map((line) => {
      const text = getLineText(line);
      const list = line.newlineOp.attributes?.list;
      const listType =
        list === "checked" ||
        list === "unchecked" ||
        list === "ordered" ||
        list === "bullet"
          ? (list as PreviewLine["listType"])
          : null;
      return { text, listType };
    })
    .filter((l) => l.text.trim().length > 0)
    .slice(0, maxLines);
}

// ============================================================================
// Checklist Reordering
// ============================================================================

/**
 * Get the character length of a line (content + newline).
 */
function getLineLength(line: DeltaLine): number {
  let len = 0;
  for (const op of line.contentOps) {
    if (typeof op.insert === "string") {
      len += op.insert.length;
    } else if (op.insert !== undefined) {
      len += 1; // Embeds count as 1 character
    }
  }
  return len + 1; // +1 for the newline
}

/**
 * Get the character position where a line starts.
 */
function getLineStartPosition(lines: DeltaLine[], lineIndex: number): number {
  let pos = 0;
  for (let i = 0; i < lineIndex; i++) {
    pos += getLineLength(lines[i]);
  }
  return pos;
}

/**
 * Find the line index that contains the given character position.
 */
function findLineIndexAtPosition(lines: DeltaLine[], position: number): number {
  let pos = 0;
  for (let i = 0; i < lines.length; i++) {
    const lineLen = getLineLength(lines[i]);
    if (position < pos + lineLen) {
      return i;
    }
    pos += lineLen;
  }
  return lines.length - 1;
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

// ============================================================================
// Checklist Drag Reorder
// ============================================================================

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
