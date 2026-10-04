import { orderedPreviewMarker, parseStoredContent } from "./quill";
import { deltaToLines, indentOf } from "./quill-lines";

export interface InlineRun {
  text: string;
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strike?: boolean;
  code?: boolean;
  link?: string;
  /** A highlight name: yellow, green, blue, pink or purple. */
  highlight?: string;
}

type BlockType =
  | "p"
  | "h1"
  | "h2"
  | "h3"
  | "check"
  | "bullet"
  | "ordered"
  | "quote"
  | "code";

export interface NoteBlock {
  type: BlockType;
  level: number;
  runs: InlineRun[];
  done?: boolean;
  /** An ordered item's marker: “1.”, “a.”, “i.”. */
  marker?: string;
}

const HEADERS: Record<number, BlockType> = { 1: "h1", 2: "h2", 3: "h3" };

function runsOf(
  ops: { insert?: unknown; attributes?: Record<string, unknown> }[],
): InlineRun[] {
  const runs: InlineRun[] = [];
  for (const op of ops) {
    if (typeof op.insert !== "string" || !op.insert) continue;
    const attrs = op.attributes ?? {};
    runs.push({
      text: op.insert,
      bold: attrs.bold === true || undefined,
      italic: attrs.italic === true || undefined,
      underline: attrs.underline === true || undefined,
      strike: attrs.strike === true || undefined,
      code: attrs.code === true || undefined,
      link: typeof attrs.link === "string" ? attrs.link : undefined,
      highlight:
        typeof attrs.highlight === "string" ? attrs.highlight : undefined,
    });
  }
  return runs;
}

/** One block per line, except code lines join into one. */
export function deltaToBlocks(content: string | null | undefined): NoteBlock[] {
  const lines = deltaToLines(parseStoredContent(content).ops);
  const blocks: NoteBlock[] = [];
  const counters = new Map<number, number>();
  for (const line of lines) {
    const attrs = line.newlineOp.attributes ?? {};
    const level = indentOf(line);
    const runs = runsOf(line.contentOps);
    let type: BlockType = "p";
    if (attrs["code-block"]) type = "code";
    else if (typeof attrs.header === "number" && HEADERS[attrs.header])
      type = HEADERS[attrs.header];
    else if (attrs.blockquote) type = "quote";
    else if (attrs.list === "checked" || attrs.list === "unchecked")
      type = "check";
    else if (attrs.list === "bullet") type = "bullet";
    else if (attrs.list === "ordered") type = "ordered";

    if (type === "code") {
      const last = blocks[blocks.length - 1];
      const text = runs.map((run) => run.text).join("");
      if (last?.type === "code") last.runs.push({ text: `\n${text}` });
      else blocks.push({ type, level: 0, runs: [{ text }] });
      counters.clear();
      continue;
    }
    if (type === "ordered") {
      for (const depth of [...counters.keys()])
        if (depth > level) counters.delete(depth);
      const count = (counters.get(level) ?? 0) + 1;
      counters.set(level, count);
      blocks.push({
        type,
        level,
        runs,
        marker: orderedPreviewMarker(count, level),
      });
      continue;
    }
    if (type !== "check" && type !== "bullet") counters.clear();
    blocks.push({
      type,
      level,
      runs,
      done: type === "check" ? attrs.list === "checked" : undefined,
    });
  }
  return blocks;
}

export interface DoneRow {
  type: "done";
  count: number;
  isAll: boolean;
}

export function foldTickedItems(blocks: NoteBlock[]): (NoteBlock | DoneRow)[] {
  const rows: (NoteBlock | DoneRow)[] = [];
  let ticked = 0;
  let open = 0;
  const endList = () => {
    if (ticked) rows.push({ type: "done", count: ticked, isAll: open === 0 });
    ticked = 0;
    open = 0;
  };
  for (const block of blocks) {
    if (block.type !== "check") endList();
    else if (block.done) {
      ticked++;
      continue;
    } else open++;
    rows.push(block);
  }
  endList();
  return rows;
}
