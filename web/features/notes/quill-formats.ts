import { HIGHLIGHTS } from "@/lib/design/tokens";
import { LINK_PROTOCOLS } from "./link-utils";
import { deleteWholeLines, isWholeLines, type QuillInstance } from "./quill";
import { MAX_LIST_INDENT } from "./quill-lines";

type QuillStatic = {
  import: (path: string) => unknown;
  register: (
    target: unknown,
    moduleOrOverwrite?: unknown,
    overwrite?: boolean,
  ) => void;
};

type Range = { index: number; length: number };
type Formats = Record<string, unknown>;

let registered = false;

const isHighlight = (value: unknown): value is (typeof HIGHLIGHTS)[number] =>
  (HIGHLIGHTS as readonly unknown[]).includes(value);

/** Highlights are <mark class="hl" data-hl="<name>">, read by lib/highlight-paint.ts. */
export function registerNoteFormats(Quill: QuillStatic) {
  if (registered) return;
  registered = true;
  const Inline = Quill.import("blots/inline") as {
    new (...args: never[]): object;
    create(value: unknown): HTMLElement;
  };
  class Highlight extends Inline {
    static blotName = "highlight";
    static tagName = "MARK";
    static className = "hl";
    static create(value: unknown) {
      // biome-ignore lint/complexity/noThisInStatic: Parchment's create reads this.tagName
      const node = super.create(value);
      node.setAttribute("data-hl", isHighlight(value) ? value : "yellow");
      return node;
    }
    static formats(node: HTMLElement) {
      const name = node.getAttribute("data-hl");
      return isHighlight(name) ? name : undefined;
    }
  }
  Quill.register(Highlight, true);

  const Delta = Quill.import("delta") as DeltaStatic;
  const Clipboard = Quill.import("modules/clipboard") as {
    new (
      ...args: never[]
    ): {
      quill: ClipboardQuill;
      onCaptureCopy(e: ClipboardEvent, isCut?: boolean): void;
      onCopy(range: Range, isCut?: boolean): { html: string; text: string };
      normalizeHTML(doc: Document): void;
      convertHTML(html: string): DeltaInstance;
    };
  };
  class NoteClipboard extends Clipboard {
    onCaptureCopy(e: ClipboardEvent, isCut = false) {
      const quill = this.quill as unknown as QuillInstance;
      const range = quill.getSelection();
      if (range && !range.length) return;
      if (
        !isCut ||
        e.defaultPrevented ||
        !range ||
        !isWholeLines(quill, range)
      ) {
        super.onCaptureCopy(e, isCut);
        return;
      }
      e.preventDefault();
      const { html, text } = this.onCopy(range, true);
      e.clipboardData?.setData("text/plain", text);
      e.clipboardData?.setData("text/html", html);
      deleteWholeLines(quill, range);
    }

    onCopy(range: Range, isCut = false) {
      const { html, text } = super.onCopy(range, isCut);
      // Quill writes every space as &nbsp;, which other apps won't wrap at.
      const spaced = html.replace(/(?<=[^\s>;])&nbsp;(?=[^\s<&])/g, " ");
      return { html: `${COPY_MARK}${spaced}`, text };
    }

    normalizeHTML(doc: Document) {
      super.normalizeHTML(doc);
      keepPreformattedSpaces(doc);
    }

    onPaste(range: Range, data: { text?: string; html?: string }) {
      const quill = this.quill;
      const text = data.text?.replace(/\r\n?/g, "\n");
      const { html } = data;
      const formats = quill.getFormat(range.index);
      const line = pick(formats, (key) => LINE_FORMATS.includes(key));
      const [caretLine, offset] = quill.getLine(range.index);
      const hasTextBefore = offset > 0;
      const isLineEmpty = (caretLine?.length() ?? 1) <= 1;
      const before = formats.link;
      const after = quill.getFormat(range.index + range.length, 1).link;
      // Quill gives pasted text the link at the caret; keep it only inside a link.
      const keepsLink = !!before && before === after;
      const inline = pick(
        formats,
        (key) => !LINE_FORMATS.includes(key) && (keepsLink || key !== "link"),
      );

      const [endLine, endOffset] = quill.getLine(range.index + range.length);
      const rest = (endLine?.length() ?? 1) - 1 - endOffset;
      let pasted: DeltaInstance;
      let lastLine: Formats = {};
      if (formats["code-block"]) {
        pasted = new Delta().insert(text || plainText(html ?? ""), {
          "code-block": formats["code-block"],
        });
      } else if (html) {
        pasted = this.convertHTML(html);
        const last = pasted.ops[pasted.ops.length - 1];
        const lastFormats = cleanLine(last?.attributes ?? {});
        // Only Anchor's own copies say whether their last line was whole.
        const isAnchorCopy = html.includes("data-anchor-copy");
        const isPartial = isAnchorCopy && !!text && !text.endsWith("\n");
        const dropsBreak = isAnchorCopy
          ? isPartial || rest === 0
          : rest === 0 || !Object.keys(lastFormats).length;
        if (
          typeof last?.insert === "string" &&
          last.insert.endsWith("\n") &&
          dropsBreak
        ) {
          pasted = pasted.compose(
            new Delta().retain(pasted.length() - 1).delete(1),
          );
          if (isPartial || rest === 0) lastLine = lastFormats;
        }
        pasted = formatLines(pasted, { line, hasTextBefore, inline: {} });
      } else {
        pasted = formatLines(new Delta().insert(text ?? ""), {
          line,
          hasTextBefore,
          inline,
          next: nextLineOf(line),
        });
      }

      const hasBreak = pasted.ops.some(
        (op) => typeof op.insert === "string" && op.insert.includes("\n"),
      );
      let tail: Formats =
        endLine && endLine !== caretLine && endOffset > 0
          ? { ...clearing(endLine.formats()), ...line }
          : {};
      if (!formats["code-block"] && !(offset === 0 && rest > 0)) {
        if (Object.keys(lastLine).length && (hasBreak || isLineEmpty))
          tail = { ...tail, ...clearing(line), ...lastLine };
        else if (hasBreak) tail = { ...tail, ...nextLineChange(line) };
      }
      const change = new Delta()
        .retain(range.index)
        .delete(range.length)
        .concat(pasted);
      if (Object.keys(tail).length) change.retain(rest).retain(1, tail);
      const end = range.index + pasted.length();
      quill.history.cutoff();
      quill.updateContents(change, "user");
      quill.history.cutoff();
      quill.setSelection(end, 0, "silent");
      quill.scrollSelectionIntoView();
    }
  }

  function formatLines(
    pasted: DeltaInstance,
    options: {
      line: Formats;
      hasTextBefore: boolean;
      inline: Formats;
      next?: Formats;
    },
  ): DeltaInstance {
    const { line, hasTextBefore, inline, next = {} } = options;
    const out = new Delta();
    let isFirst = true;
    for (const op of pasted.ops) {
      if (typeof op.insert !== "string") {
        out.insert(op.insert, op.attributes);
        continue;
      }
      const own = op.attributes ?? {};
      const ownLine = cleanLine(own);
      const hasOwnLine = Object.keys(ownLine).length > 0;
      const textFormats = { ...inline, ...cleanInline(own) };
      op.insert.split("\n").forEach((part, i) => {
        if (i > 0) {
          const lineFormats = isFirst
            ? hasOwnLine && !(hasTextBefore && Object.keys(line).length)
              ? ownLine
              : line
            : hasOwnLine
              ? ownLine
              : next;
          out.insert("\n", lineFormats);
          isFirst = false;
        }
        if (part) out.insert(part, textFormats);
      });
    }
    return out;
  }

  Quill.register("modules/clipboard", NoteClipboard, true);

  const Input = Quill.import("modules/input") as {
    new (
      ...args: never[]
    ): {
      quill: QuillInstance;
      deleteRange(range: Range): void;
    };
  };
  class NoteInput extends Input {
    replaceText(range: Range, text = "") {
      if (!range.length) return false;
      const quill = this.quill;
      const formats = text ? typedFormats(quill, range) : {};
      this.deleteRange(range);
      if (text)
        quill.updateContents(
          new Delta().retain(range.index).insert(text, formats),
          "user",
        );
      quill.setSelection(range.index + text.length, 0, "silent");
      return true;
    }

    handleCompositionStart() {
      const quill = this.quill;
      const range = quill.getSelection();
      if (!range?.length) return;
      const formats = pick(
        typedFormats(quill, range),
        (key) => !LINE_FORMATS.includes(key),
      );
      this.replaceText(range);
      for (const [name, value] of Object.entries(formats))
        quill.format(name, value, "silent");
    }
  }
  Quill.register("modules/input", NoteInput, true);

  const History = Quill.import("modules/history") as {
    new (
      ...args: never[]
    ): {
      stack: { undo: unknown[] };
      cutoff(): void;
      record(change: unknown, old: unknown): void;
    };
  };
  class NoteHistory extends History {
    record(change: unknown, old: unknown) {
      const count = this.stack.undo.length;
      super.record(change, old);
      // Quill drops a step that cancels out but keeps its start time.
      if (this.stack.undo.length < count) this.cutoff();
    }
  }
  Quill.register("modules/history", NoteHistory, true);

  const Link = Quill.import("formats/link") as {
    PROTOCOL_WHITELIST: string[];
  };
  Link.PROTOCOL_WHITELIST = LINK_PROTOCOLS;
}

function typedFormats(quill: QuillInstance, range: Range): Formats {
  const formats = quill.getFormat(range.index, 1);
  const after = quill.getFormat(range.index + range.length, 1).link;
  if (formats.link && formats.link !== after) delete formats.link;
  return formats;
}

type Op = { insert?: unknown; attributes?: Formats };
type DeltaInstance = {
  ops: Op[];
  length(): number;
  insert(insert: unknown, attributes?: Formats): DeltaInstance;
  retain(length: number, attributes?: Formats): DeltaInstance;
  delete(length: number): DeltaInstance;
  compose(other: DeltaInstance): DeltaInstance;
  concat(other: DeltaInstance): DeltaInstance;
};
type DeltaStatic = new () => DeltaInstance;
type ClipboardQuill = {
  getFormat: (index: number, length?: number) => Formats;
  getLine: (
    index: number,
  ) => [{ length: () => number; formats: () => Formats } | null, number];
  getSelection: () => Range | null;
  updateContents: (delta: DeltaInstance, source: "user") => void;
  setSelection: (index: number, length: number, source: "silent") => void;
  scrollSelectionIntoView: () => void;
  history: { cutoff: () => void };
};

const LINE_FORMATS = ["header", "list", "blockquote", "indent", "code-block"];

const COPY_MARK = '<span data-anchor-copy=""></span>';

/** Formats that switch each of `formats` off. */
const clearing = (formats: Formats): Formats =>
  Object.fromEntries(Object.keys(formats).map((key) => [key, null]));

const pick = (formats: Formats, keep: (key: string) => boolean): Formats =>
  Object.fromEntries(Object.entries(formats).filter(([key]) => keep(key)));

function nextLineOf(line: Formats): Formats {
  if (line.list)
    return {
      list: line.list === "checked" ? "unchecked" : line.list,
      ...(line.indent ? { indent: line.indent } : {}),
    };
  return line.blockquote ? { blockquote: true } : {};
}

function nextLineChange(line: Formats): Formats | null {
  if (line.header) return { header: false };
  if (line.list === "checked") return { list: "unchecked" };
  return null;
}

function cleanLine(formats: Formats): Formats {
  const line = pick(formats, (key) => LINE_FORMATS.includes(key));
  if (typeof line.indent === "number") {
    if (!line.list) delete line.indent;
    else line.indent = Math.min(line.indent, MAX_LIST_INDENT);
  }
  return line;
}

function cleanInline(formats: Formats): Formats {
  const inline = pick(formats, (key) => !LINE_FORMATS.includes(key));
  if (inline.link) delete inline.underline;
  return inline;
}

function plainText(html: string): string {
  return (
    new DOMParser().parseFromString(html, "text/html").body.textContent ?? ""
  );
}

/** Quill keeps spaces only inside <pre>; this keeps them in `white-space: pre` text too. */
function keepPreformattedSpaces(doc: Document) {
  for (const element of doc.body.querySelectorAll<HTMLElement>("[style]")) {
    if (!/^(pre|pre-wrap|break-spaces)$/.test(element.style.whiteSpace))
      continue;
    if (element.closest("pre")) continue;
    const walker = doc.createTreeWalker(element, NodeFilter.SHOW_TEXT);
    const nodes: Text[] = [];
    while (walker.nextNode()) nodes.push(walker.currentNode as Text);
    for (const node of nodes) {
      const lines = node.data
        .replace(/\t/g, "  ")
        .replace(/ /g, "\u00a0")
        .split("\n");
      if (lines.length === 1) {
        node.data = lines[0];
        continue;
      }
      const parts = lines.flatMap((text, i) =>
        i
          ? [doc.createElement("br"), doc.createTextNode(text)]
          : [doc.createTextNode(text)],
      );
      node.replaceWith(...parts);
    }
  }
}
