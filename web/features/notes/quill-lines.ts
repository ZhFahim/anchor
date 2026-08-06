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
