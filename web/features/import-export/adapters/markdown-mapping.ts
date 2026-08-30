import type { QuillDelta, QuillOp } from "@/features/notes/quill";
import { MAX_LIST_INDENT } from "@/features/notes/quill-lines";

/**
 * Markdown to Quill Delta. Anything outside the editor's formats (tables,
 * images, html) is kept as plain text.
 */

const TAB_WIDTH = 4;

type Marks = {
  bold?: true;
  italic?: true;
  underline?: true;
  strike?: true;
  link?: string;
};

type ParsedLine = {
  ops: QuillOp[];
  attrs: Record<string, unknown>;
};

const ALPHANUMERIC = /[\p{L}\p{N}]/u;

const ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
};

// ============================================================================
// Inline
// ============================================================================

function attributesOf(marks: Marks): Record<string, unknown> | null {
  const attrs: Record<string, unknown> = {};
  if (marks.bold) attrs.bold = true;
  if (marks.italic) attrs.italic = true;
  if (marks.underline) attrs.underline = true;
  if (marks.strike) attrs.strike = true;
  if (marks.link) attrs.link = marks.link;
  return Object.keys(attrs).length ? attrs : null;
}

function sameAttributes(
  a: Record<string, unknown> | undefined,
  b: Record<string, unknown> | null,
): boolean {
  const left = a ?? {};
  const right = b ?? {};
  const keys = Object.keys(left);
  if (keys.length !== Object.keys(right).length) return false;
  return keys.every((key) => left[key] === right[key]);
}

function pushText(ops: QuillOp[], text: string, marks: Marks): void {
  if (!text) return;
  const attributes = attributesOf(marks);
  const last = ops[ops.length - 1];
  if (
    last &&
    typeof last.insert === "string" &&
    sameAttributes(last.attributes, attributes)
  ) {
    last.insert += text;
    return;
  }
  ops.push(attributes ? { insert: text, attributes } : { insert: text });
}

function decodeEntity(body: string): string {
  if (body.startsWith("#")) {
    const code =
      body.startsWith("#x") || body.startsWith("#X")
        ? Number.parseInt(body.slice(2), 16)
        : Number.parseInt(body.slice(1), 10);
    return Number.isFinite(code) && code > 0 ? String.fromCodePoint(code) : "";
  }
  return ENTITIES[body] ?? `&${body};`;
}

type LinkMatch = { label: string; dest: string; end: number };

/** Matches `[label](dest "title")` starting at the opening bracket. */
function matchLink(text: string, start: number): LinkMatch | null {
  if (text[start] !== "[") return null;

  let depth = 0;
  let i = start;
  for (; i < text.length; i++) {
    const char = text[i];
    if (char === "\\") {
      i++;
      continue;
    }
    if (char === "[") depth++;
    else if (char === "]") {
      depth--;
      if (depth === 0) break;
    }
  }
  if (depth !== 0 || text[i + 1] !== "(") return null;

  const label = text.slice(start + 1, i);
  let j = i + 2;
  let parens = 1;
  for (; j < text.length; j++) {
    const char = text[j];
    if (char === "\\") {
      j++;
      continue;
    }
    if (char === "(") parens++;
    else if (char === ")") {
      parens--;
      if (parens === 0) break;
    }
  }
  if (parens !== 0) return null;

  let dest = text.slice(i + 2, j).trim();
  dest = dest.replace(/\s+["'(].*$/, "").trim();
  if (dest.startsWith("<") && dest.endsWith(">")) dest = dest.slice(1, -1);
  dest = dest.replace(/\\(.)/g, "$1");

  return { label, dest, end: j + 1 };
}

type Emphasis = { inner: string; length: number; marks: Marks };

/** Matches an emphasis run at [start]; null when the delimiter never closes. */
function matchEmphasis(text: string, start: number): Emphasis | null {
  const char = text[start];
  const rest = text.slice(start);

  if (char === "~") {
    const match = /^~~(?!\s)([\s\S]+?)(?<!\s)~~/.exec(rest);
    return match
      ? { inner: match[1], length: match[0].length, marks: { strike: true } }
      : null;
  }

  // Underscores are literal inside words, so "snake_case" stays as typed
  if (char === "_") {
    const before = text[start - 1] ?? "";
    if (ALPHANUMERIC.test(before)) return null;
  }

  const delimiter = char === "*" ? "\\*" : "_";
  const patterns: { re: RegExp; marks: Marks }[] = [
    {
      re: new RegExp(
        `^${delimiter}{3}(?!\\s)([\\s\\S]+?)(?<!\\s)${delimiter}{3}`,
      ),
      marks: { bold: true, italic: true },
    },
    {
      re: new RegExp(
        `^${delimiter}{2}(?!\\s)([\\s\\S]+?)(?<!\\s)${delimiter}{2}`,
      ),
      marks: { bold: true },
    },
    {
      re: new RegExp(
        `^${delimiter}(?!\\s)((?:${delimiter}{2}[\\s\\S]*?${delimiter}{2}|[^${delimiter}])+?)(?<!\\s)${delimiter}`,
      ),
      marks: { italic: true },
    },
  ];

  for (const [index, { re, marks }] of patterns.entries()) {
    const match = re.exec(rest);
    if (!match) continue;

    let inner = match[1];
    let length = match[0].length;

    // In "**bold *and italic***" the extra closing delimiter is the nested run's
    if (index === 1) {
      let extra = 0;
      while (text[start + length + extra] === char) extra++;
      if (extra) {
        inner += char.repeat(extra);
        length += extra;
      }
    }

    if (char === "_" && ALPHANUMERIC.test(text[start + length] ?? "")) continue;
    return { inner, length, marks };
  }
  return null;
}

function scanInline(text: string, marks: Marks, ops: QuillOp[]): void {
  let buffer = "";
  const flush = () => {
    pushText(ops, buffer, marks);
    buffer = "";
  };

  let i = 0;
  while (i < text.length) {
    const char = text[i];
    const rest = text.slice(i);

    if (char === "\\" && /^[!-/:-@[-`{-~]/.test(text[i + 1] ?? "")) {
      buffer += text[i + 1];
      i += 2;
      continue;
    }

    if (char === "`") {
      const run = /^`+/.exec(rest)?.[0] ?? "`";
      const close = text.indexOf(run, i + run.length);
      if (close !== -1) {
        // The editor has no inline code format, so keep the text itself
        let inner = text.slice(i + run.length, close);
        if (inner.startsWith(" ") && inner.endsWith(" ") && inner.trim()) {
          inner = inner.slice(1, -1);
        }
        buffer += inner;
        i = close + run.length;
        continue;
      }
    }

    if (/^<u>/i.test(rest)) {
      const close = rest.toLowerCase().indexOf("</u>", 3);
      if (close !== -1) {
        flush();
        scanInline(rest.slice(3, close), { ...marks, underline: true }, ops);
        i += close + 4;
        continue;
      }
    }

    const autolink = /^<((?:https?|mailto):[^>\s]+)>/.exec(rest);
    if (autolink) {
      flush();
      pushText(ops, autolink[1], { ...marks, link: autolink[1] });
      i += autolink[0].length;
      continue;
    }

    const wikilink = /^!?\[\[([^\]]+)\]\]/.exec(rest);
    if (wikilink) {
      const [page, alias] = wikilink[1].split("|");
      buffer += (alias ?? page).trim();
      i += wikilink[0].length;
      continue;
    }

    if (char === "!" && text[i + 1] === "[") {
      const link = matchLink(text, i + 1);
      if (link) {
        if (/^https?:/i.test(link.dest)) {
          flush();
          pushText(ops, link.label || link.dest, {
            ...marks,
            link: link.dest,
          });
        } else {
          // An image the importer could not resolve stays visible as text
          buffer += text.slice(i, link.end);
        }
        i = link.end;
        continue;
      }
    }

    if (char === "[") {
      const link = matchLink(text, i);
      if (link?.dest) {
        flush();
        scanInline(link.label, { ...marks, link: link.dest }, ops);
        i = link.end;
        continue;
      }
    }

    if (char === "*" || char === "_" || char === "~") {
      const emphasis = matchEmphasis(text, i);
      if (emphasis) {
        flush();
        scanInline(emphasis.inner, { ...marks, ...emphasis.marks }, ops);
        i += emphasis.length;
        continue;
      }
    }

    if (!marks.link) {
      const bare = /^https?:\/\/[^\s<]+/.exec(rest);
      if (bare) {
        let url = bare[0].replace(/[.,;:!?]+$/, "");
        if (url.endsWith(")") && !url.includes("(")) url = url.slice(0, -1);
        flush();
        pushText(ops, url, { ...marks, link: url });
        i += url.length;
        continue;
      }
    }

    if (char === "&") {
      const entity = /^&(#\d{1,7}|#[xX][0-9a-fA-F]{1,6}|[a-zA-Z]{2,31});/.exec(
        rest,
      );
      if (entity) {
        buffer += decodeEntity(entity[1]);
        i += entity[0].length;
        continue;
      }
    }

    buffer += char;
    i++;
  }

  flush();
}

/** Ops for one line of markdown, with only the formats the editor supports. */
export function parseInline(text: string): QuillOp[] {
  const ops: QuillOp[] = [];
  scanInline(text, {}, ops);
  return ops;
}

// ============================================================================
// Blocks
// ============================================================================

const FENCE = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const ATX_HEADING = /^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*#*[ \t]*$/;
const SETEXT_H1 = /^ {0,3}=+[ \t]*$/;
const SETEXT_H2 = /^ {0,3}-+[ \t]*$/;
const THEMATIC_BREAK =
  /^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$/;
const BLOCKQUOTE = /^ {0,3}(?:>[ \t]?)+/;
const LIST_ITEM = /^([ \t]*)([-*+]|\d{1,9}[.)])([ \t]+|$)([\s\S]*)$/;
const TASK_MARKER = /^\[([ xX])\](?:[ \t]+|$)([\s\S]*)$/;
const MAX_HEADER = 3;

/** Removes [columns] worth of leading whitespace, keeping any remainder. */
function stripColumns(text: string, columns: number): string {
  let removed = 0;
  let i = 0;
  while (i < text.length && removed < columns) {
    removed += text[i] === "\t" ? TAB_WIDTH - (removed % TAB_WIDTH) : 1;
    i++;
  }
  return " ".repeat(Math.max(0, removed - columns)) + text.slice(i);
}

function expandTabs(text: string): number {
  let width = 0;
  for (const char of text) {
    width = char === "\t" ? width + TAB_WIDTH - (width % TAB_WIDTH) : width + 1;
  }
  return width;
}

function appendOps(target: QuillOp[], ops: QuillOp[]): void {
  for (const op of ops) {
    const last = target[target.length - 1];
    if (
      last &&
      typeof last.insert === "string" &&
      typeof op.insert === "string" &&
      sameAttributes(last.attributes, op.attributes ?? null)
    ) {
      last.insert += op.insert;
    } else {
      target.push(op);
    }
  }
}

type ListLevel = { indentCol: number; contentCol: number };

/**
 * Nesting level for a list item, clamped to what Quill accepts: at most one
 * deeper than the line above, and never past MAX_LIST_INDENT.
 */
function listLevel(
  stack: ListLevel[],
  width: number,
  previous: ParsedLine | undefined,
): number {
  while (stack.length && width < stack[stack.length - 1].indentCol) {
    stack.pop();
  }
  let level = stack.length;
  if (stack.length && width < stack[stack.length - 1].indentCol + 2) {
    level = stack.length - 1;
  }
  const previousIndent =
    previous && previous.attrs.list !== undefined
      ? ((previous.attrs.indent as number | undefined) ?? 0)
      : -1;
  return Math.max(0, Math.min(level, previousIndent + 1, MAX_LIST_INDENT));
}

function listTypeOf(marker: string, task: string | null): string {
  if (task !== null) return task === " " ? "unchecked" : "checked";
  return /^\d/.test(marker) ? "ordered" : "bullet";
}

/** Parses a markdown body into canonical Quill Delta content. */
export function markdownToDelta(text: string): QuillDelta {
  const source = text.replace(/^﻿/, "");
  const rawLines = source.split(/\r\n|\r|\n/);
  if (rawLines.length && rawLines[rawLines.length - 1] === "") rawLines.pop();

  const out: ParsedLine[] = [];
  const stack: ListLevel[] = [];
  let fence: { char: string; length: number; indent: number } | null = null;
  let pendingBlank = false;
  let lastWasParagraph = false;

  const flushBlank = () => {
    if (pendingBlank) {
      out.push({ ops: [], attrs: {} });
      pendingBlank = false;
    }
  };

  for (const raw of rawLines) {
    if (fence) {
      const closing = FENCE.exec(raw);
      if (
        closing &&
        closing[1][0] === fence.char &&
        closing[1].length >= fence.length &&
        !closing[2].trim()
      ) {
        fence = null;
        continue;
      }
      out.push({
        ops: [{ insert: raw.slice(fence.indent) }],
        attrs: { "code-block": true },
      });
      continue;
    }

    const opening = FENCE.exec(raw);
    if (opening && !(opening[1][0] === "`" && opening[2].includes("`"))) {
      flushBlank();
      fence = {
        char: opening[1][0],
        length: opening[1].length,
        indent: raw.length - raw.trimStart().length,
      };
      stack.length = 0;
      lastWasParagraph = false;
      continue;
    }

    if (!raw.trim()) {
      if (stack.length) {
        pendingBlank = true;
      } else {
        out.push({ ops: [], attrs: {} });
      }
      lastWasParagraph = false;
      continue;
    }

    const leading = /^[ \t]*/.exec(raw)?.[0] ?? "";
    const width = expandTabs(leading);

    if (!stack.length && !lastWasParagraph && width >= 4) {
      flushBlank();
      out.push({
        ops: [{ insert: stripColumns(raw, 4) }],
        attrs: { "code-block": true },
      });
      continue;
    }

    if (
      stack.length &&
      width >= stack[stack.length - 1].contentCol &&
      !LIST_ITEM.test(raw)
    ) {
      // Quill list items are single lines, so a wrapped line joins the item
      pendingBlank = false;
      appendOps(out[out.length - 1].ops, parseInline(` ${raw.trim()}`));
      continue;
    }

    const quote = BLOCKQUOTE.exec(raw);
    if (quote) {
      flushBlank();
      stack.length = 0;
      out.push({
        ops: parseInline(raw.slice(quote[0].length)),
        attrs: { blockquote: true },
      });
      lastWasParagraph = false;
      continue;
    }

    const heading = ATX_HEADING.exec(raw);
    if (heading) {
      flushBlank();
      stack.length = 0;
      out.push({
        ops: parseInline(heading[2] ?? ""),
        attrs: { header: Math.min(heading[1].length, MAX_HEADER) },
      });
      lastWasParagraph = false;
      continue;
    }

    const previous = out[out.length - 1];
    if (
      lastWasParagraph &&
      previous &&
      (SETEXT_H1.test(raw) || SETEXT_H2.test(raw))
    ) {
      previous.attrs = { header: SETEXT_H1.test(raw) ? 1 : 2 };
      lastWasParagraph = false;
      continue;
    }

    if (THEMATIC_BREAK.test(raw)) {
      flushBlank();
      stack.length = 0;
      lastWasParagraph = false;
      continue;
    }

    const item = LIST_ITEM.exec(raw);
    if (item) {
      const [, , marker, spacing, remainder] = item;
      const task = TASK_MARKER.exec(remainder);
      const content = task ? task[2] : remainder;
      const level = listLevel(stack, width, out[out.length - 1]);
      if (pendingBlank) {
        if (level === 0) out.push({ ops: [], attrs: {} });
        pendingBlank = false;
      }

      const markerWidth =
        marker.length +
        (spacing.length > 4 || !spacing.length ? 1 : spacing.length);
      stack.length = level;
      stack.push({ indentCol: width, contentCol: width + markerWidth });

      out.push({
        ops: parseInline(content),
        attrs: {
          list: listTypeOf(marker, task ? task[1] : null),
          ...(level ? { indent: level } : {}),
        },
      });
      lastWasParagraph = false;
      continue;
    }

    flushBlank();
    stack.length = 0;
    out.push({ ops: parseInline(raw.trim()), attrs: {} });
    lastWasParagraph = true;
  }

  flushBlank();

  const ops: QuillOp[] = [];
  for (const line of out) {
    ops.push(...line.ops);
    ops.push(
      Object.keys(line.attrs).length
        ? { insert: "\n", attributes: line.attrs }
        : { insert: "\n" },
    );
  }
  if (!ops.length) ops.push({ insert: "\n" });
  return { ops };
}

// ============================================================================
// Titles and attachment references
// ============================================================================

/** Comparable form of a title, ignoring case, spacing and punctuation. */
export function normalizeTitle(value: string): string {
  return value
    .normalize("NFKC")
    .replace(/\s*\(\d+\)$/, "")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "");
}

/** Drops a leading `# Title` when it only repeats the filename. */
export function stripTitleHeading(text: string, stem: string): string {
  const lines = text.split(/\r\n|\r|\n/);
  const first = lines.findIndex((line) => line.trim());
  if (first === -1) return text;

  const heading = /^ {0,3}#[ \t]+(.*?)[ \t]*#*[ \t]*$/.exec(lines[first]);
  if (!heading || normalizeTitle(heading[1]) !== normalizeTitle(stem)) {
    return text;
  }

  let rest = lines.slice(first + 1);
  if (rest.length && !rest[0].trim()) rest = rest.slice(1);
  return rest.join("\n");
}

export type AttachmentRef = {
  /** Exact source text, so the adapter can remove it once resolved */
  raw: string;
  target: string;
  label: string;
  kind: "image" | "link";
  line: number;
};

const IMAGE_REF = /!\[([^\]]*)\]\(([^)]*)\)/g;
const LINK_REF = /(^|[^!])\[([^\]]*)\]\(([^)]*)\)/g;
const EMBED_REF = /!?\[\[([^\]]+)\]\]/g;

function cleanTarget(target: string): string {
  let value = target.trim().replace(/\s+["'(].*$/, "");
  if (value.startsWith("<") && value.endsWith(">")) value = value.slice(1, -1);
  value = value.replace(/[?#].*$/, "");
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

const isLocalTarget = (target: string) =>
  Boolean(target) &&
  !/^[a-z][a-z0-9+.-]*:/i.test(target) &&
  !target.startsWith("#");

/** Local file references outside code fences, in source order per line. */
export function findAttachmentRefs(text: string): AttachmentRef[] {
  const refs: AttachmentRef[] = [];
  const lines = text.split(/\r\n|\r|\n/);
  let fence: { char: string; length: number } | null = null;

  lines.forEach((line, index) => {
    const fenceMatch = FENCE.exec(line);
    if (fenceMatch) {
      if (fence && fenceMatch[1][0] === fence.char) fence = null;
      else if (!fence)
        fence = { char: fenceMatch[1][0], length: fenceMatch[1].length };
      return;
    }
    if (fence) return;

    for (const match of line.matchAll(IMAGE_REF)) {
      const target = cleanTarget(match[2]);
      if (isLocalTarget(target)) {
        refs.push({
          raw: match[0],
          target,
          label: match[1],
          kind: "image",
          line: index,
        });
      }
    }
    for (const match of line.matchAll(LINK_REF)) {
      const target = cleanTarget(match[3]);
      if (isLocalTarget(target)) {
        refs.push({
          raw: match[0].slice(match[1].length),
          target,
          label: match[2],
          kind: "link",
          line: index,
        });
      }
    }
    for (const match of line.matchAll(EMBED_REF)) {
      const target = cleanTarget(match[1].split("|")[0]);
      if (isLocalTarget(target)) {
        refs.push({
          raw: match[0],
          target,
          label: match[1],
          kind: match[0].startsWith("!") ? "image" : "link",
          line: index,
        });
      }
    }
  });

  return refs;
}
