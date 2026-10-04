import {
  buildListIndentDelta,
  deltaToLines,
  getLineLength,
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

export type QuillLine = {
  length: () => number;
  formats: () => Record<string, unknown>;
  domNode: HTMLElement;
};

type Range = { index: number; length: number };

export type QuillInstance = {
  getContents: (index?: number, length?: number) => QuillDelta;
  updateContents: (
    delta: QuillDelta,
    source?: "user" | "api" | "silent",
  ) => void;
  setContents: (delta: QuillDelta, source?: "user" | "api" | "silent") => void;
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
  container: HTMLElement;
  getLength: () => number;
  update: (source?: "user" | "api" | "silent") => void;
  getLine: (index: number) => [QuillLine | null, number];
  getIndex: (blot: QuillLine) => number;
  scroll: { find: (node: Node) => QuillLine | null };
  composition: { isComposing: boolean };
  selection: { savedRange: { index: number; length: number } };
  formatLine: (
    index: number,
    length: number,
    name: string,
    value: unknown,
    source?: "user" | "api" | "silent",
  ) => void;
  on: (event: string, handler: (...args: never[]) => void) => void;
  once: (event: string, handler: (...args: never[]) => void) => void;
  off: (event: string, handler: (...args: never[]) => void) => void;
  history: {
    undo: () => void;
    redo: () => void;
    cutoff: () => void;
    stack: { undo: unknown[]; redo: unknown[] };
    ignoreChange?: boolean;
    currentRange?: Range | null;
  };
};

// ============================================================================
// Configuration
// ============================================================================

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
  "highlight",
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

/** getFormat without code block lines, whose text never takes inline formats. */
export function getTextFormat(
  quill: QuillInstance,
  index: number,
  length: number,
): Record<string, unknown> {
  if (!length) return quill.getFormat(index, 0);
  let common: Record<string, unknown> | null = null;
  const end = index + length;
  for (let pos = index; pos < end; ) {
    const [line, offset] = quill.getLine(pos);
    if (!line) break;
    const next = pos - offset + line.length();
    const textEnd = Math.min(end, next - 1);
    if (textEnd > pos && !line.formats()["code-block"]) {
      const part = quill.getFormat(pos, textEnd - pos);
      common = common
        ? Object.fromEntries(
            Object.entries(common).filter(
              ([key, value]) => part[key] !== undefined && part[key] === value,
            ),
          )
        : part;
    }
    pos = next;
  }
  return common ?? quill.getFormat(index, length);
}

export function isInCodeBlock(quill: QuillInstance, range: Range): boolean {
  return !!getTextFormat(quill, range.index, range.length)["code-block"];
}

export function toggleTextFormat(
  quill: QuillInstance,
  range: { index: number; length: number },
  key: string,
) {
  if (isInCodeBlock(quill, range)) return;
  const isOn = !!getTextFormat(quill, range.index, range.length)[key];
  if (range.length)
    quill.formatText(range.index, range.length, key, !isOn, "user");
  else quill.format(key, !isOn, "user");
  quill.root.dispatchEvent(new Event("formatchange", { bubbles: true }));
}

/**
 * Quill keeps a pending format's placeholder when a selection grows from it,
 * and typing then jumps to the line end. Call before the selection grows.
 */
export function dropPendingFormat(quill: QuillInstance) {
  const { selection } = quill as unknown as {
    selection: {
      composing: boolean;
      cursor: { parent: unknown; restore: () => unknown };
    };
  };
  if (selection.composing || !selection.cursor.parent) return;
  const range = quill.getSelection();
  selection.cursor.restore();
  // Quill reads the page again before placing the caret.
  quill.update("silent");
  if (range) quill.setSelection(range.index, range.length, "silent");
}

/** A selection from the start of one line to the start of another. */
export function isWholeLines(
  quill: QuillInstance,
  range: { index: number; length: number },
): boolean {
  if (!range.length) return false;
  const [, startOffset] = quill.getLine(range.index);
  const [endLine, endOffset] = quill.getLine(range.index + range.length);
  return startOffset === 0 && !!endLine && endOffset === 0;
}

/** Deletes whole lines, leaving the line after them as it was. */
export function deleteWholeLines(
  quill: QuillInstance,
  range: { index: number; length: number },
): boolean {
  if (!isWholeLines(quill, range)) return false;
  quill.deleteText(range.index, range.length, "user");
  quill.setSelection(range.index, 0, "silent");
  return true;
}

type PastedDelta = QuillDelta & { insert: (text: string) => PastedDelta };

function endPastedHeaderCell(_node: Node, delta: PastedDelta) {
  const last = delta.ops[delta.ops.length - 1];
  return typeof last?.insert === "string" && last.insert.endsWith("\n")
    ? delta
    : delta.insert("\n");
}

export function capPastedHeading(_node: Node, delta: QuillDelta): QuillDelta {
  for (const op of delta.ops) {
    const level = op.attributes?.header;
    if (typeof level === "number" && level > 3)
      op.attributes = { ...op.attributes, header: 3 };
  }
  return delta;
}

type KeyHandler = (
  this: { quill: QuillInstance },
  range: Range,
  context: { format: Record<string, unknown>; prefix: string },
) => boolean;

const graphemes =
  typeof Intl !== "undefined" && "Segmenter" in Intl
    ? new Intl.Segmenter(undefined, { granularity: "grapheme" })
    : null;

/** Length of the character, as a person sees it, before (-1) or after (1) `index`. */
function clusterLength(
  quill: QuillInstance,
  index: number,
  direction: 1 | -1,
): number {
  const [line, offset] = quill.getLine(index);
  if (!line || !graphemes) return 1;
  const text = quill.getText(index - offset, line.length() - 1);
  for (const { segment, index: at } of graphemes.segment(text)) {
    if (direction < 0 && at + segment.length === offset) return segment.length;
    if (direction > 0 && at === offset) return segment.length;
  }
  return 1;
}

/** The browser's own delete can split an emoji at a format edge. */
function deleteCluster(direction: 1 | -1): KeyHandler {
  return function (range) {
    const length = clusterLength(this.quill, range.index, direction);
    if (length < 2) return true;
    const start = direction < 0 ? range.index - length : range.index;
    this.quill.deleteText(start, length, "user");
    this.quill.setSelection(start, 0, "silent");
    return false;
  };
}

/** Quill's own Delete at a line end lets the next line's format win. */
const joinNextLine: KeyHandler = function (range) {
  const [line, offset] = this.quill.getLine(range.index);
  const [next] = this.quill.getLine(range.index + 1);
  if (!line || !next || line.length() <= 1 || offset < line.length() - 1)
    return true;
  const formats = {
    ...Object.fromEntries(
      Object.keys(next.formats()).map((key) => [key, null]),
    ),
    ...line.formats(),
  };
  this.quill.updateContents(
    {
      ops: [
        { retain: range.index },
        { delete: 1 },
        { retain: next.length() - 1 },
        { retain: 1, attributes: formats },
      ],
    },
    "user",
  );
  return false;
};

const deleteEmptyLine: KeyHandler = function (range) {
  if (range.index < this.quill.getLength() - 1)
    this.quill.deleteText(range.index, 1, "user");
  return false;
};

const splitSelection: KeyHandler = function (range) {
  const [first] = this.quill.getLine(range.index);
  const [last] = this.quill.getLine(range.index + range.length);
  if (!first || first === last) return true;
  this.quill.updateContents(
    {
      ops: [
        { retain: range.index },
        { delete: range.length },
        { insert: "\n", attributes: first.formats() },
      ],
    },
    "user",
  );
  this.quill.setSelection(range.index + 1, 0, "silent");
  return false;
};

const insertTab: KeyHandler = function (range) {
  if (range.length) {
    applyListIndent(this.quill, range, 1);
    return false;
  }
  this.quill.history.cutoff();
  this.quill.insertText(range.index, "\t", "user");
  this.quill.history.cutoff();
  this.quill.setSelection(range.index + 1, 0, "silent");
  return false;
};

const exitCodeBlock: KeyHandler = function (range) {
  const [line, offset] = this.quill.getLine(range.index);
  if (!line) return true;
  const start = range.index - offset;
  const end = start + line.length();
  // getLine past the last line returns the last line again.
  const [next] =
    end < this.quill.getLength() ? this.quill.getLine(end) : [null];
  const [prev] = this.quill.getLine(start - 1);
  if (
    next?.formats()["code-block"] ||
    !prev?.formats()["code-block"] ||
    prev.length() > 1
  )
    return true;
  this.quill.updateContents(
    {
      ops: [
        { retain: start - 1 },
        { retain: 1, attributes: { "code-block": null } },
        { delete: 1 },
      ],
    },
    "user",
  );
  this.quill.setSelection(start - 1, 0, "silent");
  return false;
};

const enterInTickedItem: KeyHandler = function (range) {
  const [line, offset] = this.quill.getLine(range.index);
  if (!line) return true;
  const formats = line.formats();
  const ops =
    offset === 0 && line.length() > 1
      ? [
          { retain: range.index },
          { insert: "\n", attributes: { ...formats, list: "unchecked" } },
        ]
      : [
          { retain: range.index },
          { insert: "\n", attributes: { ...formats, list: "checked" } },
          { retain: line.length() - offset - 1 },
          { retain: 1, attributes: { list: "unchecked" } },
        ];
  this.quill.updateContents({ ops }, "user");
  this.quill.setSelection(range.index + 1, 0, "silent");
  return false;
};

const leaveEmptyListItem: KeyHandler = function (range, context) {
  const indent = Number(context.format.indent ?? 0);
  if (indent)
    this.quill.formatLine(
      range.index,
      range.length,
      "indent",
      indent > 1 ? indent - 1 : false,
      "user",
    );
  else this.quill.formatLine(range.index, range.length, "list", false, "user");
  return false;
};

const unwrapCodeLine: KeyHandler = function (range) {
  const [prev] = this.quill.getLine(range.index - 1);
  if (range.index > 0 && prev?.formats()["code-block"]) return true;
  this.quill.formatLine(range.index, 0, "code-block", false, "user");
  return false;
};

export function lineFormatChange(
  current: Record<string, unknown>,
  next: Record<string, unknown>,
): Record<string, unknown> {
  return {
    ...Object.fromEntries(Object.keys(current).map((key) => [key, null])),
    ...(next.list && current.list && current.indent
      ? { indent: current.indent }
      : {}),
    ...next,
  };
}

const unwrapBlockLine: KeyHandler = function (range, context) {
  const name = context.format.header ? "header" : "blockquote";
  this.quill.formatLine(range.index, 0, name, false, "user");
  return false;
};

const BLOCK_STARTER = /^\s*?(\d+[.)]|[-*+]|\[ ?\]|\[x\]|#{1,3}|>|```)$/;

function starterFormat(mark: string): Record<string, unknown> {
  if (mark === "[x]") return { list: LIST_FORMATS.CHECKED };
  if (mark.startsWith("[")) return { list: LIST_FORMATS.UNCHECKED };
  if (/\d/.test(mark)) return { list: LIST_FORMATS.ORDERED };
  if (mark.startsWith("#")) return { header: mark.length };
  if (mark === ">") return { blockquote: true };
  if (mark === "```") return { "code-block": "plain" };
  return { list: LIST_FORMATS.BULLET };
}

function startBlock(
  quill: QuillInstance,
  start: number,
  length: number,
  mark: string,
) {
  const [line] = quill.getLine(start);
  if (!line) return;
  const formats = lineFormatChange(line.formats(), starterFormat(mark));
  const rest = line.length() - 1 - length;
  quill.history.cutoff();
  quill.updateContents(
    {
      ops: [
        ...(start ? [{ retain: start }] : []),
        { delete: length },
        ...(rest ? [{ retain: rest }] : []),
        { retain: 1, attributes: formats },
      ],
    },
    "user",
  );
  quill.history.cutoff();
  quill.setSelection(start, 0, "silent");
  rememberConversion(quill);
}

const conversions = new WeakMap<
  QuillInstance,
  { index: number; depth: number }
>();

export function rememberConversion(quill: QuillInstance) {
  const selection = quill.getSelection();
  if (!selection) return;
  const conversion = {
    index: selection.index,
    depth: quill.history.stack.undo.length,
  };
  conversions.set(quill, conversion);
  quill.once("editor-change", () => {
    if (conversions.get(quill) === conversion) conversions.delete(quill);
  });
}

export function undoConversion(quill: QuillInstance): boolean {
  const conversion = conversions.get(quill);
  const selection = quill.getSelection();
  if (
    !conversion ||
    !selection ||
    selection.length ||
    selection.index !== conversion.index ||
    quill.history.stack.undo.length !== conversion.depth
  )
    return false;
  conversions.delete(quill);
  quill.history.undo();
  return true;
}

/** Quill's `prefix` is the text before the caret in the same text run only. */
const isLineStart = (quill: QuillInstance, index: number, prefix: string) =>
  quill.getLine(index)[1] === prefix.length;

const startTypedStarter: KeyHandler = function (range, context) {
  const { prefix } = context;
  if (!isLineStart(this.quill, range.index, prefix)) return true;
  this.quill.insertText(range.index, " ", "user");
  startBlock(
    this.quill,
    range.index - prefix.length,
    prefix.length + 1,
    prefix.trim(),
  );
  return false;
};

const startCodeFence: KeyHandler = function (range, context) {
  const { prefix } = context;
  if (!isLineStart(this.quill, range.index, prefix)) return true;
  startBlock(this.quill, range.index - prefix.length, prefix.length, "```");
  return false;
};

const leaveLastCodeLine: KeyHandler = function (range) {
  const [line, offset] = this.quill.getLine(range.index);
  const end = this.quill.getLength();
  if (!line || range.index - offset + line.length() < end) return true;
  this.quill.updateContents(
    {
      ops: [
        { retain: end - 1 },
        { insert: "\n", attributes: line.formats() },
        { retain: 1, attributes: { "code-block": null } },
      ],
    },
    "user",
  );
  this.quill.setSelection(end, 0, "silent");
  return false;
};

/**
 * The bindings named `indent` and `outdent` replace Quill's own, so Tab and
 * Shift+Tab use the clamped indent.
 */
export const QUILL_MODULES = {
  toolbar: false,
  history: {
    delay: 1000,
    maxStack: 200,
    userOnly: true,
  },
  clipboard: {
    matchers: [
      ["h4, h5, h6", capPastedHeading],
      ["th", endPastedHeaderCell],
    ],
  },
  keyboard: {
    bindings: {
      bold: {
        key: "b",
        shortKey: true,
        handler(this: { quill: QuillInstance }, range: Range) {
          toggleTextFormat(this.quill, range, "bold");
          return false;
        },
      },
      italic: {
        key: "i",
        shortKey: true,
        handler(this: { quill: QuillInstance }, range: Range) {
          toggleTextFormat(this.quill, range, "italic");
          return false;
        },
      },
      underline: {
        key: "u",
        shortKey: true,
        handler(this: { quill: QuillInstance }, range: Range) {
          toggleTextFormat(this.quill, range, "underline");
          return false;
        },
      },
      redo: {
        key: ["y", "Y"],
        shortKey: true,
        handler(this: { quill: QuillInstance }) {
          this.quill.history.redo();
          return false;
        },
      },
      deleteLines: {
        key: "Backspace",
        collapsed: false,
        handler(
          this: { quill: QuillInstance },
          range: { index: number; length: number },
        ) {
          return !deleteWholeLines(this.quill, range);
        },
      },
      deleteLinesForward: {
        key: "Delete",
        collapsed: false,
        handler(
          this: { quill: QuillInstance },
          range: { index: number; length: number },
        ) {
          return !deleteWholeLines(this.quill, range);
        },
      },
      "delete character before": {
        key: "Backspace",
        collapsed: true,
        handler: deleteCluster(-1),
      },
      "delete character after": {
        key: "Delete",
        collapsed: true,
        handler: deleteCluster(1),
      },
      // Shift+Enter acts as Enter here too; Quill merges these into its own.
      "header enter": { shiftKey: null },
      "blockquote empty enter": { shiftKey: null },
      "delete empty line": {
        key: "Delete",
        altKey: true,
        collapsed: true,
        empty: true,
        handler: deleteEmptyLine,
      },
      "join next line": {
        key: "Delete",
        collapsed: true,
        handler: joinNextLine,
      },
      "enter selection": {
        key: "Enter",
        shiftKey: null,
        collapsed: false,
        handler: splitSelection,
      },
      tab: { key: "Tab", handler: insertTab },
      "code exit": {
        key: "Enter",
        shiftKey: null,
        collapsed: true,
        format: ["code-block"],
        prefix: /^$/,
        suffix: /^\s*$/,
        handler: exitCodeBlock,
      },
      "code backspace": {
        key: "Backspace",
        collapsed: true,
        format: ["code-block"],
        offset: 0,
        handler: unwrapCodeLine,
      },
      "block backspace": {
        key: "Backspace",
        collapsed: true,
        format: ["header", "blockquote"],
        offset: 0,
        handler: unwrapBlockLine,
      },
      "list autofill": false,
      "block autofill": {
        key: " ",
        shiftKey: null,
        collapsed: true,
        format: { "code-block": false, blockquote: false },
        prefix: BLOCK_STARTER,
        handler: startTypedStarter,
      },
      "code fence enter": {
        key: "Enter",
        shiftKey: null,
        collapsed: true,
        format: { "code-block": false, blockquote: false },
        prefix: /^\s*?```$/,
        suffix: /^$/,
        handler: startCodeFence,
      },
      "code arrow down": {
        key: "ArrowDown",
        collapsed: true,
        format: ["code-block"],
        handler: leaveLastCodeLine,
      },
      "checklist enter": {
        key: "Enter",
        shiftKey: null,
        collapsed: true,
        format: { list: "checked" },
        handler: enterInTickedItem,
      },
      "list empty enter": {
        key: "Enter",
        shiftKey: null,
        collapsed: true,
        format: ["list"],
        empty: true,
        handler: leaveEmptyListItem,
      },
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

export function insertedBeforeCaret(
  quill: QuillInstance,
  change: QuillDelta,
): { from: number; text: string } | null {
  let at = 0;
  let inserted: { from: number; text: string } | null = null;
  for (const op of change.ops) {
    if (typeof op.retain === "number") at += op.retain;
    else if (op.insert !== undefined) {
      if (inserted || typeof op.insert !== "string") return null;
      inserted = { from: at, text: op.insert };
      at += op.insert.length;
    }
  }
  const selection = quill.getSelection();
  if (
    !inserted ||
    !selection ||
    selection.length ||
    selection.index !== inserted.from + inserted.text.length
  )
    return null;
  return inserted;
}

/** Starts a block from a starter typed as text (Android, dictation). */
export function startTypedBlock(quill: QuillInstance, change: QuillDelta) {
  const inserted = insertedBeforeCaret(quill, change);
  if (!inserted?.text.endsWith(" ")) return;
  const caret = inserted.from + inserted.text.length;
  const [line, offset] = quill.getLine(caret);
  const start = caret - offset;
  if (!line || inserted.from < start) return;
  const formats = line.formats();
  if (formats["code-block"] || formats.blockquote) return;
  const match = BLOCK_STARTER.exec(quill.getText(start, offset - 1));
  if (match) startBlock(quill, start, offset, match[1]);
}

/**
 * Makes Undo of the next change put the caret at `index`. Call the returned
 * function after the change.
 */
export function setUndoCaret(quill: QuillInstance, index: number) {
  quill.history.currentRange = { index, length: 0 };
  return () => {
    quill.history.currentRange = quill.getSelection();
  };
}

/** Newline positions of the checklist items `change` ticked. */
export function findTickedLines(
  change: QuillDelta,
  before: QuillDelta,
): number[] {
  if (
    change.ops.some(
      (op) => op.insert !== undefined || op.delete !== undefined,
    ) ||
    !change.ops.some((op) => op.attributes?.list === LIST_FORMATS.CHECKED)
  )
    return [];
  const unchecked = new Set<number>();
  let lineEnd = -1;
  for (const line of deltaToLines(before.ops)) {
    lineEnd += getLineLength(line);
    if (line.newlineOp.attributes?.list === LIST_FORMATS.UNCHECKED)
      unchecked.add(lineEnd);
  }
  const ticked: number[] = [];
  let position = 0;
  for (const op of change.ops) {
    const length = typeof op.retain === "number" ? op.retain : 1;
    if (op.attributes?.list === LIST_FORMATS.CHECKED)
      for (let at = position; at < position + length; at++)
        if (unchecked.has(at)) ticked.push(at);
    position += length;
  }
  return ticked;
}

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
    // Invalid JSON is treated as empty.
  }

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

/** No text, and no list, quote, code block or heading started. */
export function isContentBlank(content: string | null | undefined): boolean {
  return parseStoredContent(content).ops.every(
    (op) =>
      typeof op.insert === "string" &&
      op.insert.trim() === "" &&
      !op.attributes?.list &&
      !op.attributes?.["code-block"] &&
      !op.attributes?.blockquote &&
      !op.attributes?.header,
  );
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
