import {
  buildListIndentDelta,
  deltaToLines,
  getLineText,
  indentOf,
} from "./quill-lines";

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
  "indent",
  "blockquote",
  "code-block",
  "link",
] as const;

/**
 * Applies a clamped list indent change at [range]; no-op when not allowed.
 */
export function applyListIndent(
  quill: QuillInstance,
  range: { index: number; length: number },
  direction: 1 | -1,
): void {
  const delta = buildListIndentDelta(
    quill.getContents(),
    range.index,
    range.length,
    direction,
  );
  if (delta) quill.updateContents(delta as QuillDelta, "user");
}

/**
 * Quill modules configuration. The named `indent`/`outdent` bindings replace
 * Quill's defaults so Tab and Shift+Tab go through the clamped indent path.
 */
export const QUILL_MODULES = {
  toolbar: false,
  history: {
    delay: 1000,
    maxStack: 200,
    userOnly: true,
  },
  keyboard: {
    bindings: {
      indent: {
        key: "Tab",
        format: ["list"],
        handler(
          this: { quill: QuillInstance },
          range: { index: number; length: number },
        ) {
          applyListIndent(this.quill, range, 1);
          return false;
        },
      },
      outdent: {
        key: "Tab",
        shiftKey: true,
        format: ["list"],
        handler(
          this: { quill: QuillInstance },
          range: { index: number; length: number },
        ) {
          applyListIndent(this.quill, range, -1);
          return false;
        },
      },
    },
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

export type PreviewLine = {
  text: string;
  listType: "checked" | "unchecked" | "ordered" | "bullet" | null;
  /** Nesting level (0 = top level). */
  indent: number;
};

/**
 * Marker for an ordered item, cycling number styles by depth like the
 * editor: 1. at the top level, then a., then i.
 */
export function orderedPreviewMarker(count: number, indent: number): string {
  switch (indent % 3) {
    case 1:
      return `${String.fromCharCode(97 + ((count - 1) % 26))}.`;
    case 2:
      return `${toRoman(count)}.`;
    default:
      return `${count}.`;
  }
}

const ROMAN_PAIRS: [number, string][] = [
  [1000, "m"],
  [900, "cm"],
  [500, "d"],
  [400, "cd"],
  [100, "c"],
  [90, "xc"],
  [50, "l"],
  [40, "xl"],
  [10, "x"],
  [9, "ix"],
  [5, "v"],
  [4, "iv"],
  [1, "i"],
];

function toRoman(count: number): string {
  let value = count;
  let result = "";
  for (const [threshold, numeral] of ROMAN_PAIRS) {
    while (value >= threshold) {
      result += numeral;
      value -= threshold;
    }
  }
  return result;
}

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
      return { text, listType, indent: indentOf(line) };
    })
    .filter((l) => l.text.trim().length > 0)
    .slice(0, maxLines);
}
