import { deltaToLines, getLineText } from "./quill-lines";

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
