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

const HIGHLIGHT_COLORS = ['yellow', 'green', 'blue', 'pink', 'purple'];

/** Line starts a markdown reader would take as a block marker. */
const BLOCK_START =
  /^(?:#{1,6}(?:\s|$)|[-+](?:\s|$)|\d{1,9}[.)](?:\s|$)|>|-{2,}\s*$|=+\s*$)/;

type Marks = {
  bold: boolean;
  italic: boolean;
  underline: boolean;
  strike: boolean;
  highlight: string | null;
  link: string | null;
};

/** Unknown colors come out as yellow. */
function highlightOf(value: unknown): string | null {
  if (!value) return null;
  return typeof value === 'string' && HIGHLIGHT_COLORS.includes(value)
    ? value
    : 'yellow';
}

function marksOf(op: QuillOp): Marks {
  const attrs = op.attributes ?? {};
  return {
    bold: attrs.bold === true,
    italic: attrs.italic === true,
    underline: attrs.underline === true,
    strike: attrs.strike === true,
    highlight: highlightOf(attrs.highlight),
    link: typeof attrs.link === 'string' ? attrs.link : null,
  };
}

const marksKey = (marks: Marks) =>
  `${marks.bold}|${marks.italic}|${marks.underline}|${marks.strike}|${marks.highlight ?? ''}|${marks.link ?? ''}`;

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
    // Could form the "==" around a highlight
    if (
      char === '=' &&
      (i === 0 ||
        i === text.length - 1 ||
        text[i - 1] === '=' ||
        text[i + 1] === '=')
    ) {
      out += '\\=';
      continue;
    }
    // Could start an HTML tag, like <u> or <mark>
    if (char === '<' && /[A-Za-z/]/.test(text[i + 1] ?? '')) {
      out += '\\<';
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

/** Markdown delimiters must hug non-whitespace. */
function wrapCore(text: string, wrap: (core: string) => string): string {
  const lead = /^\s*/.exec(text)?.[0] ?? '';
  const rest = text.slice(lead.length);
  const trail = /\s*$/.exec(rest)?.[0] ?? '';
  const core = rest.slice(0, rest.length - trail.length);
  return core ? `${lead}${wrap(core)}${trail}` : text;
}

function applyMarks(text: string, marks: Marks): string {
  return wrapCore(text, (core) => {
    let out = escapeInlineText(core);
    if (marks.italic) out = `*${out}*`;
    if (marks.bold) out = `**${out}**`;
    if (marks.underline) out = `<u>${out}</u>`;
    if (marks.strike) out = `~~${out}~~`;
    if (marks.link) out = `[${out}](${encodeLinkDestination(marks.link)})`;
    return out;
  });
}

function applyHighlight(markdown: string, color: string): string {
  return wrapCore(markdown, (core) =>
    color === 'yellow'
      ? `==${core}==`
      : `<mark data-color="${color}">${core}</mark>`,
  );
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

  let out = '';
  for (let i = 0; i < runs.length;) {
    const { highlight } = runs[i].marks;
    let inner = '';
    for (; i < runs.length && runs[i].marks.highlight === highlight; i++) {
      inner += applyMarks(runs[i].text, runs[i].marks);
    }
    out += highlight ? applyHighlight(inner, highlight) : inner;
  }
  return out;
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
