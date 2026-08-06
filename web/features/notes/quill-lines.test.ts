import Delta from "quill-delta";
import { describe, expect, it } from "vitest";
import type { QuillDelta, QuillOp } from "./quill";
import { buildListIndentDelta, MAX_LIST_INDENT } from "./quill-lines";

function doc(lines: [string, string | null, number?][]): QuillDelta {
  const ops: QuillOp[] = [];
  for (const [text, list, indent] of lines) {
    if (text) ops.push({ insert: text });
    const attributes = {
      ...(list ? { list } : {}),
      ...(indent ? { indent } : {}),
    };
    ops.push({
      insert: "\n",
      ...(Object.keys(attributes).length ? { attributes } : {}),
    });
  }
  return { ops };
}

/** Apply an indent delta and read back [text, list, indent] per line. */
function applied(
  base: QuillDelta,
  change: { ops: QuillOp[] } | null,
): [string, string | null, number][] {
  expect(change).not.toBeNull();
  const result = new Delta(base.ops as never).compose(
    new Delta((change as QuillDelta).ops as never),
  );
  const lines: [string, string | null, number][] = [];
  let current = "";
  for (const op of result.ops) {
    if (typeof op.insert !== "string") continue;
    const parts = op.insert.split("\n");
    for (let i = 0; i < parts.length; i++) {
      current += parts[i];
      if (i < parts.length - 1) {
        const attrs = op.attributes as
          | { list?: string; indent?: number }
          | undefined;
        lines.push([current, attrs?.list ?? null, attrs?.indent ?? 0]);
        current = "";
      }
    }
  }
  return lines;
}

const flat = doc([
  ["a", "unchecked"],
  ["b", "unchecked"],
  ["c", "unchecked"],
]);

describe("buildListIndentDelta", () => {
  it("indents a list line one level under its predecessor", () => {
    expect(
      applied(flat, buildListIndentDelta(flat, "a\nb".length, 0, 1)),
    ).toEqual([
      ["a", "unchecked", 0],
      ["b", "unchecked", 1],
      ["c", "unchecked", 0],
    ]);
  });

  it("cannot indent deeper than one level below the line above", () => {
    const oneDeep = doc([
      ["a", "unchecked"],
      ["b", "unchecked", 1],
    ]);
    expect(buildListIndentDelta(oneDeep, "a\nb".length, 0, 1)).toBeNull();
  });

  it("the first list line cannot indent", () => {
    expect(buildListIndentDelta(flat, 0, 0, 1)).toBeNull();
    const afterParagraph = doc([
      ["intro", null],
      ["a", "unchecked"],
    ]);
    expect(
      buildListIndentDelta(afterParagraph, "intro\na".length, 0, 1),
    ).toBeNull();
  });

  it("caps at MAX_LIST_INDENT", () => {
    const chain = doc([
      ["a", "unchecked"],
      ["b", "unchecked", 1],
      ["c", "unchecked", 2],
      ["d", "unchecked", MAX_LIST_INDENT],
    ]);
    expect(buildListIndentDelta(chain, "a\nb\nc\nd".length, 0, 1)).toBeNull();
  });

  it("outdenting level 1 removes the indent attribute entirely", () => {
    const oneDeep = doc([
      ["a", "unchecked"],
      ["b", "unchecked", 1],
    ]);
    const change = buildListIndentDelta(oneDeep, "a\nb".length, 0, -1);
    expect(applied(oneDeep, change)).toEqual([
      ["a", "unchecked", 0],
      ["b", "unchecked", 0],
    ]);
    const result = new Delta(oneDeep.ops as never).compose(
      new Delta((change as QuillDelta).ops as never),
    );
    for (const op of result.ops) {
      expect(op.attributes ?? {}).not.toHaveProperty("indent");
    }
  });

  it("outdenting a top-level line is a no-op", () => {
    expect(buildListIndentDelta(flat, 0, 0, -1)).toBeNull();
  });

  it("a multi-line selection indents each list line with chained clamping", () => {
    // Selecting b and c: b nests under a, and c may then nest under b.
    const change = buildListIndentDelta(flat, "a\n".length, "b\nc".length, 1);
    expect(applied(flat, change)).toEqual([
      ["a", "unchecked", 0],
      ["b", "unchecked", 1],
      ["c", "unchecked", 1],
    ]);
  });

  it("paragraph lines inside the selection are untouched", () => {
    const mixed = doc([
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["note", null],
    ]);
    const change = buildListIndentDelta(mixed, 0, "a\nb\nnote".length, 1);
    expect(applied(mixed, change)).toEqual([
      ["a", "unchecked", 0],
      ["b", "unchecked", 1],
      ["note", null, 0],
    ]);
  });

  it("returns null for non-list lines", () => {
    const paragraphs = doc([
      ["one", null],
      ["two", null],
    ]);
    expect(buildListIndentDelta(paragraphs, "one\nt".length, 0, 1)).toBeNull();
  });
});
