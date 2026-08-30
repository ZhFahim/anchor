import {
  DeltaLine,
  QuillOp,
  deltaToLines,
  getLineText,
  indentOf,
} from './delta-lines';

/** One nesting level of a list, wide enough to nest under "- " and "1. ". */
const INDENT_UNIT = '    ';
const MAX_HEADER = 3;

const ALPHANUMERIC = /[\p{L}\p{N}]/u;

/** Line starts a markdown reader would take as a block marker. */
const BLOCK_START =
  /^(?:#{1,6}(?:\s|$)|[-+](?:\s|$)|\d{1,9}[.)](?:\s|$)|>|-{2,}\s*$|=+\s*$)/;

type Marks = {
  bold: boolean;
  italic: boolean;
  underline: boolean;
  strike: boolean;
  link: string | null;
};

function marksOf(op: QuillOp): Marks {
  const attrs = op.attributes ?? {};
  return {
    bold: attrs.bold === true,
    italic: attrs.italic === true,
    underline: attrs.underline === true,
    strike: attrs.strike === true,
    link: typeof attrs.link === 'string' ? attrs.link : null,
  };
}

const marksKey = (marks: Marks) =>
  `${marks.bold}|${marks.italic}|${marks.underline}|${marks.strike}|${marks.link ?? ''}`;

/** Escapes characters a markdown reader would treat as formatting. */
export function escapeInlineText(text: string): string {
  let out = '';
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (char === '\\' || char === '*' || char === '`') {
      out += `\\${char}`;
      continue;
    }
    if (char === '~' && text[i + 1] === '~') {
      out += '\\~\\~';
      i++;
      continue;
    }
    if (char === '_') {
      // Intraword underscores are literal in CommonMark
      const intraword =
        ALPHANUMERIC.test(text[i - 1] ?? '') &&
        ALPHANUMERIC.test(text[i + 1] ?? '');
      out += intraword ? '_' : '\\_';
      continue;
    }
    out += char;
  }
  return out;
}

/** Escapes a leading block marker so the line stays plain text on re-import. */
export function escapeLineStart(line: string): string {
  return BLOCK_START.test(line) ? `\\${line}` : line;
}

function applyMarks(text: string, marks: Marks): string {
  // Delimiters must hug non-whitespace, so edge spaces move outside
  const lead = /^\s*/.exec(text)?.[0] ?? '';
  const rest = text.slice(lead.length);
  const trail = /\s*$/.exec(rest)?.[0] ?? '';
  const core = rest.slice(0, rest.length - trail.length);
  if (!core) return escapeInlineText(text);

  let out = escapeInlineText(core);
  if (marks.italic) out = `*${out}*`;
  if (marks.bold) out = `**${out}**`;
  if (marks.underline) out = `<u>${out}</u>`;
  if (marks.strike) out = `~~${out}~~`;
  if (marks.link) out = `[${out}](${encodeLinkDestination(marks.link)})`;
  return `${lead}${out}${trail}`;
}

/** Angle-bracket form for destinations a bare (…) can't hold. */
function encodeLinkDestination(url: string): string {
  return /[\s()]/.test(url) ? `<${url.replace(/[<>]/g, '')}>` : url;
}

/** Renders the text ops of a single line, merging runs that share formatting. */
export function renderInline(ops: QuillOp[]): string {
  const runs: { text: string; marks: Marks }[] = [];
  for (const op of ops) {
    if (typeof op.insert !== 'string' || !op.insert) continue;
    const marks = marksOf(op);
    const last = runs[runs.length - 1];
    if (last && marksKey(last.marks) === marksKey(marks)) {
      last.text += op.insert;
    } else {
      runs.push({ text: op.insert, marks });
    }
  }
  return runs.map((run) => applyMarks(run.text, run.marks)).join('');
}

function longestBacktickRun(lines: string[]): number {
  let longest = 0;
  for (const line of lines) {
    for (const match of line.matchAll(/`+/g)) {
      longest = Math.max(longest, match[0].length);
    }
  }
  return longest;
}

function listPrefix(
  list: unknown,
  indent: number,
  orderedCount: number,
): string | null {
  const pad = INDENT_UNIT.repeat(indent);
  switch (list) {
    case 'bullet':
      return `${pad}- `;
    case 'ordered':
      return `${pad}${orderedCount}. `;
    case 'checked':
      return `${pad}- [x] `;
    case 'unchecked':
      return `${pad}- [ ] `;
    default:
      return null;
  }
}

function blockPrefix(line: DeltaLine, counters: Map<number, number>): string {
  const attrs = line.newlineOp.attributes ?? {};
  const list = attrs.list;

  if (list === undefined) {
    counters.clear();
  } else {
    // A shallower item ends the deeper runs
    for (const level of [...counters.keys()]) {
      if (level > indentOf(line)) counters.delete(level);
    }
  }

  const header = Number(attrs.header);
  if (Number.isFinite(header) && header >= 1) {
    return `${'#'.repeat(Math.min(header, MAX_HEADER))} `;
  }

  if (list !== undefined) {
    const indent = Math.max(0, indentOf(line));
    let count = 0;
    if (list === 'ordered') {
      count = (counters.get(indent) ?? 0) + 1;
      counters.set(indent, count);
    }
    const prefix = listPrefix(list, indent, count);
    if (prefix !== null) return prefix;
  }

  if (attrs.blockquote) return '> ';
  return '';
}

/** Renders a note's Delta ops as a markdown body (empty string when blank). */
export function deltaToMarkdown(ops: QuillOp[]): string {
  const lines = deltaToLines(ops);
  const out: string[] = [];
  const counters = new Map<number, number>();

  let i = 0;
  while (i < lines.length) {
    const isCode = (line: DeltaLine) =>
      Boolean((line.newlineOp.attributes ?? {})['code-block']);

    if (isCode(lines[i])) {
      const block: string[] = [];
      while (i < lines.length && isCode(lines[i])) {
        block.push(getLineText(lines[i]));
        i++;
      }
      const fence = '`'.repeat(Math.max(3, longestBacktickRun(block) + 1));
      out.push(fence, ...block, fence);
      counters.clear();
      continue;
    }

    const prefix = blockPrefix(lines[i], counters);
    const text = escapeLineStart(renderInline(lines[i].contentOps));
    out.push(`${prefix}${text}`.trimEnd());
    i++;
  }

  const body = out.join('\n').replace(/\s+$/, '');
  return body ? `${body}\n` : '';
}
