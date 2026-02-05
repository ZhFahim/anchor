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
  updateContents: (delta: QuillDelta, source?: "user" | "api" | "silent") => void;
  getFormat: () => Record<string, unknown>;
  format: (name: string, value: unknown, source?: "user" | "api" | "silent") => void;
  formatText: (index: number, length: number, name: string, value: unknown, source?: "user" | "api" | "silent") => void;
  getText: (index?: number, length?: number) => string;
  insertText: (index: number, text: string, source?: "user" | "api" | "silent") => void;
  getSelection: (focus?: boolean) => { index: number; length: number } | null;
  setSelection: (index: number, length: number, source?: "user" | "api" | "silent") => void;
  history: {
    undo: () => void;
    redo: () => void;
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

export function isStoredContentEmpty(content: string | null | undefined): boolean {
  return deltaToFullPlainText(content).trim() === "";
}

export function deltaToFullPlainText(content: string | null | undefined): string {
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
 * Create a delta for `updateContents` that moves a toggled checklist item
 * to its correct position. This preserves undo history as a single operation.
 * 
 * @param togglePosition - Position where the checkbox was toggled (from change delta)
 * @param currentDelta - Current document content
 * @returns A delta to pass to updateContents, or null if no move needed
 */
export function createChecklistMoveDelta(
  togglePosition: number,
  currentDelta: QuillDelta,
): QuillDelta | null {
  const lines = deltaToLines(currentDelta.ops);
  const lineIndex = findLineIndexAtPosition(lines, togglePosition);

  if (lineIndex < 0 || lineIndex >= lines.length) return null;

  const toggledLine = lines[lineIndex];
  if (!isChecklistLine(toggledLine)) return null;

  // Find the checklist group boundaries
  let groupStart = lineIndex;
  while (groupStart > 0 && isChecklistLine(lines[groupStart - 1])) {
    groupStart--;
  }

  let groupEnd = lineIndex;
  while (groupEnd < lines.length - 1 && isChecklistLine(lines[groupEnd + 1])) {
    groupEnd++;
  }

  const isChecked = isCheckedLine(toggledLine);
  const lineStart = getLineStartPosition(lines, lineIndex);
  const lineLength = getLineLength(toggledLine);
  const lineOps: QuillOp[] = [...toggledLine.contentOps, toggledLine.newlineOp];

  let targetIndex: number;

  if (isChecked) {
    // Checked: move to end of checklist group
    if (lineIndex === groupEnd) return null; // Already at end
    targetIndex = groupEnd;
  } else {
    // Unchecked: move to start of checked items
    let firstCheckedIndex = -1;
    for (let i = groupStart; i <= groupEnd; i++) {
      if (isCheckedLine(lines[i])) {
        firstCheckedIndex = i;
        break;
      }
    }
    if (firstCheckedIndex === -1 || lineIndex < firstCheckedIndex) {
      return null; // No checked items or already before them
    }
    targetIndex = firstCheckedIndex;
  }

  // Build the move delta
  const ops: QuillOp[] = [];

  if (lineIndex < targetIndex) {
    // Moving down: delete source, then insert at target (adjusted)
    const targetStart = getLineStartPosition(lines, targetIndex) + getLineLength(lines[targetIndex]);

    // Retain to source start
    if (lineStart > 0) {
      ops.push({ retain: lineStart });
    }
    // Delete the line
    ops.push({ delete: lineLength });
    // Retain to target position (adjusted for deletion)
    const retainToTarget = targetStart - lineLength - lineStart;
    if (retainToTarget > 0) {
      ops.push({ retain: retainToTarget });
    }
    // Insert the line
    ops.push(...lineOps);
  } else {
    // Moving up: insert at target, then delete source (adjusted)
    const targetStart = getLineStartPosition(lines, targetIndex);

    // Retain to target position
    if (targetStart > 0) {
      ops.push({ retain: targetStart });
    }
    // Insert the line
    ops.push(...lineOps);
    // Retain to source position (adjusted for insertion)
    const retainToSource = lineStart - targetStart;
    if (retainToSource > 0) {
      ops.push({ retain: retainToSource });
    }
    // Delete the original line
    ops.push({ delete: lineLength });
  }

  return { ops };
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
