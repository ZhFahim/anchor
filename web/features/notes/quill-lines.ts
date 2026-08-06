import type { QuillOp } from "./quill";

/**
 * Represents a single line in the editor (content ops + trailing newline op).
 */
export type DeltaLine = {
  contentOps: QuillOp[]; // Text/embed ops before the newline
  newlineOp: QuillOp; // The newline op (with attributes like list)
};

/**
 * Parse delta ops into lines. Each line consists of content ops followed by a newline.
 */
export function deltaToLines(ops: QuillOp[]): DeltaLine[] {
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
export function getLineText(line: DeltaLine): string {
  return line.contentOps
    .map((op) => (typeof op.insert === "string" ? op.insert : ""))
    .join("");
}

/**
 * Check if a line is a checklist item (checked or unchecked).
 */
export function isChecklistLine(line: DeltaLine): boolean {
  const list = line.newlineOp.attributes?.list;
  return list === "checked" || list === "unchecked";
}

/**
 * Check if a line is a checked checklist item.
 */
export function isCheckedLine(line: DeltaLine): boolean {
  return line.newlineOp.attributes?.list === "checked";
}

/**
 * Nesting level of a line (0 = top level).
 */
export function indentOf(line: DeltaLine): number {
  const value = line.newlineOp.attributes?.indent;
  return typeof value === "number" ? value : 0;
}

/**
 * Last line of the block headed by [index]: the line plus the contiguous
 * run of following lines (up to [rangeEnd]) with deeper indent.
 */
export function blockEndIndex(
  lines: DeltaLine[],
  index: number,
  rangeEnd: number,
): number {
  const base = indentOf(lines[index]);
  let end = index;
  while (end < rangeEnd && indentOf(lines[end + 1]) > base) {
    end++;
  }
  return end;
}

/**
 * Get the character length of a line (content + newline).
 */
export function getLineLength(line: DeltaLine): number {
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
export function getLineStartPosition(
  lines: DeltaLine[],
  lineIndex: number,
): number {
  let pos = 0;
  for (let i = 0; i < lineIndex; i++) {
    pos += getLineLength(lines[i]);
  }
  return pos;
}

/**
 * Find the line index that contains the given character position.
 */
export function findLineIndexAtPosition(
  lines: DeltaLine[],
  position: number,
): number {
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

export const MAX_LIST_INDENT = 3;

/**
 * Delta that indents (direction 1) or outdents (direction -1) the list lines
 * intersecting the selection [index, index+length]. Indenting is clamped to
 * MAX_LIST_INDENT and to one level deeper than the line above, which must be
 * a list line itself. Null when nothing changes.
 */
export function buildListIndentDelta(
  currentDelta: { ops: QuillOp[] },
  index: number,
  length: number,
  direction: 1 | -1,
): { ops: QuillOp[] } | null {
  const lines = deltaToLines(currentDelta.ops);
  const selEnd = length > 0 ? index + length : index + 1;
  const effective: number[] = [];
  const ops: QuillOp[] = [];
  let cursor = 0;
  let position = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineLength = getLineLength(line);
    const newlineOffset = position + lineLength - 1;
    const inRange = position < selEnd && index <= newlineOffset;
    const isList = line.newlineOp.attributes?.list !== undefined;
    let newIndent = indentOf(line);

    if (inRange && isList) {
      if (direction === 1) {
        const prevIsList =
          i > 0 && lines[i - 1].newlineOp.attributes?.list !== undefined;
        let cap = prevIsList ? effective[i - 1] + 1 : 0;
        if (cap > MAX_LIST_INDENT) cap = MAX_LIST_INDENT;
        const proposed = newIndent + 1;
        if (proposed <= cap) newIndent = proposed;
      } else if (newIndent > 0) {
        newIndent -= 1;
      }
    }
    effective.push(newIndent);

    if (newIndent !== indentOf(line)) {
      if (newlineOffset > cursor) {
        ops.push({ retain: newlineOffset - cursor });
      }
      ops.push({
        retain: 1,
        attributes: { indent: newIndent === 0 ? null : newIndent },
      });
      cursor = newlineOffset + 1;
    }
    position += lineLength;
  }

  return cursor > 0 ? { ops } : null;
}
