import Delta from "quill-delta";
import { describe, expect, it } from "vitest";
import type { QuillDelta, QuillOp } from "./quill";
import {
  buildChecklistDropDelta,
  checklistLineIndexFromOrdinal,
  createChecklistSortDelta,
  getChecklistDragPlan,
} from "./quill-checklist";

function doc(lines: [string, string | null][]): QuillDelta {
  const ops: QuillOp[] = [];
  for (const [text, list] of lines) {
    if (text) ops.push({ insert: text });
    ops.push({
      insert: "\n",
      ...(list ? { attributes: { list } } : {}),
    });
  }
  return { ops };
}

/** Apply a move delta and read back the resulting lines. */
function applied(
  base: QuillDelta,
  move: QuillDelta | null,
): [string, string | null][] {
  expect(move).not.toBeNull();
  const result = new Delta(base.ops as never).compose(
    new Delta((move as QuillDelta).ops as never),
  );
  const lines: [string, string | null][] = [];
  let current = "";
  for (const op of result.ops) {
    if (typeof op.insert !== "string") {
      current += "⌘"; // embed marker
      continue;
    }
    const parts = op.insert.split("\n");
    for (let i = 0; i < parts.length; i++) {
      current += parts[i];
      if (i < parts.length - 1) {
        const list = (op.attributes as { list?: string } | undefined)?.list;
        lines.push([current, list ?? null]);
        current = "";
      }
    }
  }
  expect(current).toBe(""); // document still ends with a newline
  return lines;
}

const abcd = doc([
  ["a", "unchecked"],
  ["b", "unchecked"],
  ["c", "unchecked"],
  ["d", "unchecked"],
]);

describe("buildChecklistDropDelta", () => {
  it("moves a line down (gap after a later line)", () => {
    expect(applied(abcd, buildChecklistDropDelta(abcd, 0, 3))).toEqual([
      ["b", "unchecked"],
      ["c", "unchecked"],
      ["a", "unchecked"],
      ["d", "unchecked"],
    ]);
  });

  it("moves a line up (gap before an earlier line)", () => {
    expect(applied(abcd, buildChecklistDropDelta(abcd, 3, 1))).toEqual([
      ["a", "unchecked"],
      ["d", "unchecked"],
      ["b", "unchecked"],
      ["c", "unchecked"],
    ]);
  });

  it("moves the first line to the very end of the document", () => {
    expect(applied(abcd, buildChecklistDropDelta(abcd, 0, 4))).toEqual([
      ["b", "unchecked"],
      ["c", "unchecked"],
      ["d", "unchecked"],
      ["a", "unchecked"],
    ]);
  });

  it("moves the last line of the document to the top", () => {
    expect(applied(abcd, buildChecklistDropDelta(abcd, 3, 0))).toEqual([
      ["d", "unchecked"],
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["c", "unchecked"],
    ]);
  });

  it("returns null for a no-op gap (own position or just after)", () => {
    expect(buildChecklistDropDelta(abcd, 1, 1)).toBeNull();
    expect(buildChecklistDropDelta(abcd, 1, 2)).toBeNull();
  });

  it("lines keep their own attributes across a move", () => {
    const mixed = doc([
      ["a", "unchecked"],
      ["b", "checked"],
      ["c", "unchecked"],
    ]);
    expect(applied(mixed, buildChecklistDropDelta(mixed, 0, 3))).toEqual([
      ["b", "checked"],
      ["c", "unchecked"],
      ["a", "unchecked"],
    ]);
  });

  it("inline formatting travels with the moved line", () => {
    const withBold: QuillDelta = {
      ops: [
        { insert: "plain " },
        { insert: "bold", attributes: { bold: true } },
        { insert: "\n", attributes: { list: "unchecked" } },
        { insert: "b" },
        { insert: "\n", attributes: { list: "unchecked" } },
      ],
    };
    const move = buildChecklistDropDelta(withBold, 0, 2);
    const result = new Delta(withBold.ops as never).compose(
      new Delta((move as QuillDelta).ops as never),
    );
    expect(result.ops).toEqual([
      { insert: "b" },
      { insert: "\n", attributes: { list: "unchecked" } },
      { insert: "plain " },
      { insert: "bold", attributes: { bold: true } },
      { insert: "\n", attributes: { list: "unchecked" } },
    ]);
  });

  it("a paragraph outside the group is untouched", () => {
    const withNote = doc([
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["note", null],
    ]);
    expect(applied(withNote, buildChecklistDropDelta(withNote, 0, 2))).toEqual([
      ["b", "unchecked"],
      ["a", "unchecked"],
      ["note", null],
    ]);
  });
});

describe("getChecklistDragPlan", () => {
  it("bounds gaps to the checklist group", () => {
    const mixed = doc([
      ["intro", null],
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["outro", null],
    ]);
    const plan = getChecklistDragPlan(mixed, 1);
    expect(plan).toMatchObject({
      lineIndex: 1,
      groupStart: 1,
      groupEnd: 2,
      minGap: 1,
      maxGap: 3,
      groupOrdinal: 0,
      text: "a",
      checked: false,
    });
  });

  it("items move freely across the checked boundary", () => {
    const sorted = doc([
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["c", "checked"],
      ["d", "checked"],
    ]);
    expect(getChecklistDragPlan(sorted, 0)).toMatchObject({
      minGap: 0,
      maxGap: 4,
    });
    expect(getChecklistDragPlan(sorted, 3)).toMatchObject({
      minGap: 0,
      maxGap: 4,
      checked: true,
    });
  });

  it("returns null when the item is alone in its group", () => {
    const lone = doc([
      ["intro", null],
      ["a", "unchecked"],
      ["outro", null],
    ]);
    expect(getChecklistDragPlan(lone, 1)).toBeNull();
  });

  it("returns null for non-checklist lines", () => {
    const mixed = doc([
      ["intro", null],
      ["a", "unchecked"],
      ["b", "unchecked"],
    ]);
    expect(getChecklistDragPlan(mixed, 0)).toBeNull();
  });

  it("ordinal accounts for earlier checklist groups", () => {
    const twoGroups = doc([
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["gap", null],
      ["c", "unchecked"],
      ["d", "unchecked"],
    ]);
    const plan = getChecklistDragPlan(twoGroups, 3);
    expect(plan).toMatchObject({
      groupStart: 3,
      groupEnd: 4,
      groupOrdinal: 2,
    });
  });
});

describe("checklistLineIndexFromOrdinal", () => {
  it("maps DOM item order back to document line indices", () => {
    const twoGroups = doc([
      ["intro", null],
      ["a", "unchecked"],
      ["gap", null],
      ["b", "checked"],
    ]);
    expect(checklistLineIndexFromOrdinal(twoGroups, 0)).toBe(1);
    expect(checklistLineIndexFromOrdinal(twoGroups, 1)).toBe(3);
    expect(checklistLineIndexFromOrdinal(twoGroups, 2)).toBe(-1);
  });
});

describe("createChecklistSortDelta", () => {
  it("moves a checked item below the unchecked items", () => {
    const toggled = doc([
      ["a", "checked"],
      ["b", "unchecked"],
      ["c", "unchecked"],
    ]);
    // Toggle position = the newline of line 0 ("a\n" -> offset 1)
    expect(applied(toggled, createChecklistSortDelta(1, toggled))).toEqual([
      ["b", "unchecked"],
      ["c", "unchecked"],
      ["a", "checked"],
    ]);
  });

  it("moves an unchecked item above the checked items", () => {
    const toggled = doc([
      ["a", "checked"],
      ["b", "unchecked"],
    ]);
    expect(applied(toggled, createChecklistSortDelta(3, toggled))).toEqual([
      ["b", "unchecked"],
      ["a", "checked"],
    ]);
  });

  it("heals a mixed group: one toggle re-sorts everything, stably", () => {
    // "leggy" (line 4) was just checked in a group that was never sorted.
    const mixed = doc([
      ["observing", "unchecked"],
      ["jsjshs", "checked"],
      ["test", "checked"],
      ["pretty", "unchecked"],
      ["leggy", "checked"],
      ["patio", "unchecked"],
    ]);
    // Toggle position = the newline of "leggy" line.
    const togglePosition = "observing\njsjshs\ntest\npretty\nleggy".length;
    expect(
      applied(mixed, createChecklistSortDelta(togglePosition, mixed)),
    ).toEqual([
      ["observing", "unchecked"],
      ["pretty", "unchecked"],
      ["patio", "unchecked"],
      ["jsjshs", "checked"],
      ["test", "checked"],
      ["leggy", "checked"],
    ]);
  });

  it("returns null when the group is already sorted", () => {
    const sorted = doc([
      ["a", "unchecked"],
      ["b", "checked"],
    ]);
    expect(createChecklistSortDelta(1, sorted)).toBeNull();
    expect(createChecklistSortDelta(3, sorted)).toBeNull();
  });

  it("never touches content before the group (cursor safety)", () => {
    const withIntro = doc([
      ["intro paragraph", null],
      ["a", "checked"],
      ["b", "unchecked"],
    ]);
    const sortDelta = createChecklistSortDelta(
      "intro paragraph\na".length,
      withIntro,
    );
    expect(sortDelta).not.toBeNull();
    // First op must retain past the intro untouched.
    const first = (sortDelta as QuillDelta).ops[0];
    expect(first.retain).toBeGreaterThanOrEqual("intro paragraph\n".length);
  });
});
