import { deltaToBlocks, type NoteBlock } from "./note-blocks";

export interface WordPart {
  text: string;
  kind: "same" | "del" | "ins";
}

export type VersionLine =
  | { kind: "same" | "removed" | "added"; block: NoteBlock }
  | { kind: "changed"; block: NoteBlock; words: WordPart[] };

export interface VersionDiff {
  lines: VersionLine[];
  added: number;
  removed: number;
  changed: number;
}

/** Lines `from` up to, not including, `to`. */
export interface Fold {
  fold: true;
  from: number;
  to: number;
}

const MAX_CELLS = 1_000_000;
/** How alike two lines must be to count as one line that changed. */
const ALIKE = 0.4;

const textOf = (block: NoteBlock) => block.runs.map((run) => run.text).join("");
const keyOf = (block: NoteBlock) =>
  [block.type, block.level, block.done ? 1 : 0, textOf(block)].join("\u0000");
const hasText = (block: NoteBlock) => textOf(block).trim().length > 0;

/** Longest common subsequence table, filled from the end. */
function lcs<T>(a: T[], b: T[], same: (x: T, y: T) => boolean) {
  const width = b.length + 1;
  const table = new Uint32Array((a.length + 1) * width);
  for (let i = a.length - 1; i >= 0; i--)
    for (let j = b.length - 1; j >= 0; j--)
      table[i * width + j] = same(a[i], b[j])
        ? table[(i + 1) * width + j + 1] + 1
        : Math.max(table[(i + 1) * width + j], table[i * width + j + 1]);
  return (i: number, j: number) => table[i * width + j];
}

export function diffWords(before: string, after: string): WordPart[] {
  const oldWords = before.split(/(\s+)/).filter(Boolean);
  const newWords = after.split(/(\s+)/).filter(Boolean);
  const parts: WordPart[] = [];
  const push = (text: string, kind: WordPart["kind"]) => {
    const last = parts[parts.length - 1];
    if (last?.kind === kind) last.text += text;
    else parts.push({ text, kind });
  };
  if ((oldWords.length + 1) * (newWords.length + 1) > MAX_CELLS) {
    push(before, "del");
    push(after, "ins");
    return parts;
  }
  const common = lcs(oldWords, newWords, (x, y) => x === y);
  let i = 0;
  let j = 0;
  while (i < oldWords.length && j < newWords.length) {
    if (oldWords[i] === newWords[j]) {
      push(oldWords[i++], "same");
      j++;
    } else if (common(i + 1, j) >= common(i, j + 1)) push(oldWords[i++], "del");
    else push(newWords[j++], "ins");
  }
  while (i < oldWords.length) push(oldWords[i++], "del");
  while (j < newWords.length) push(newWords[j++], "ins");
  return parts;
}

/** Share of words the two lines have in common, 0 to 1. */
function alike(a: string, b: string) {
  const wordsA = a.toLowerCase().split(/\s+/).filter(Boolean);
  const wordsB = b.toLowerCase().split(/\s+/).filter(Boolean);
  if (!wordsA.length || !wordsB.length) return 0;
  const common = lcs(wordsA, wordsB, (x, y) => x === y)(0, 0);
  return (2 * common) / (wordsA.length + wordsB.length);
}

export function diffVersions(
  before: string | null | undefined,
  after: string | null | undefined,
): VersionDiff {
  const oldBlocks = deltaToBlocks(before).filter(hasText);
  const newBlocks = deltaToBlocks(after).filter(hasText);
  const oldKeys = oldBlocks.map(keyOf);
  const newKeys = newBlocks.map(keyOf);

  const raw: { kind: "same" | "removed" | "added"; block: NoteBlock }[] = [];
  if ((oldBlocks.length + 1) * (newBlocks.length + 1) > MAX_CELLS) {
    for (const block of oldBlocks) raw.push({ kind: "removed", block });
    for (const block of newBlocks) raw.push({ kind: "added", block });
  } else {
    const common = lcs(oldKeys, newKeys, (x, y) => x === y);
    let i = 0;
    let j = 0;
    while (i < oldBlocks.length && j < newBlocks.length) {
      if (oldKeys[i] === newKeys[j]) {
        raw.push({ kind: "same", block: oldBlocks[i++] });
        j++;
      } else if (common(i + 1, j) >= common(i, j + 1))
        raw.push({ kind: "removed", block: oldBlocks[i++] });
      else raw.push({ kind: "added", block: newBlocks[j++] });
    }
    while (i < oldBlocks.length)
      raw.push({ kind: "removed", block: oldBlocks[i++] });
    while (j < newBlocks.length)
      raw.push({ kind: "added", block: newBlocks[j++] });
  }

  const lines: VersionLine[] = [];
  for (let start = 0; start < raw.length; ) {
    if (raw[start].kind === "same") {
      lines.push(raw[start++]);
      continue;
    }
    let end = start;
    while (end < raw.length && raw[end].kind !== "same") end++;
    const run = raw.slice(start, end);
    const added = run.filter((line) => line.kind === "added");
    const used = new Set<number>();
    const out: (VersionLine | null)[] = run.map((line) => {
      if (line.kind !== "removed") return line;
      const match = added.findIndex(
        (candidate, index) =>
          !used.has(index) &&
          (textOf(candidate.block) === textOf(line.block) ||
            alike(textOf(line.block), textOf(candidate.block)) >= ALIKE),
      );
      if (match < 0) return line;
      used.add(match);
      return {
        kind: "changed",
        block: line.block,
        words: diffWords(textOf(line.block), textOf(added[match].block)),
      };
    });
    run.forEach((line, index) => {
      if (line.kind === "added" && used.has(added.indexOf(line)))
        out[index] = null;
    });
    for (const line of out) if (line) lines.push(line);
    start = end;
  }

  return {
    lines,
    added: lines.filter((line) => line.kind === "added").length,
    removed: lines.filter((line) => line.kind === "removed").length,
    changed: lines.filter((line) => line.kind === "changed").length,
  };
}

/** `open` holds the indexes of lines opened. */
export function foldLines(
  lines: VersionLine[],
  open: ReadonlySet<number> = new Set(),
): (number | Fold)[] {
  const keep = lines.map(
    (_, k) =>
      open.has(k) ||
      [k - 2, k - 1, k, k + 1, k + 2].some(
        (j) => lines[j] && lines[j].kind !== "same",
      ),
  );
  const out: (number | Fold)[] = [];
  for (let k = 0; k < lines.length; ) {
    if (!keep[k]) {
      let end = k;
      while (end < lines.length && !keep[end]) end++;
      if (end - k > 2) {
        out.push({ fold: true, from: k, to: end });
        k = end;
        continue;
      }
    }
    out.push(k++);
  }
  return out;
}
