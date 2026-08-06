import Delta from "quill-delta";
import { describe, expect, it } from "vitest";
import type { QuillDelta, QuillOp } from "./quill";
import {
  buildChecklistDropDelta,
  checklistLineIndexFromOrdinal,
  createChecklistSortDelta,
  getChecklistDragPlan,
} from "./quill-checklist";

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

/** Push ops through quill-delta so equivalent deltas compare equal. */
function normalized(delta: QuillDelta): QuillOp[] {
  const result = new Delta();
  for (const op of delta.ops) {
    result.push(op as never);
  }
  return result.ops as QuillOp[];
}

/** Apply a move delta and compare the full result against expected lines. */
function expectApplied(
  base: QuillDelta,
  move: QuillDelta | null,
  expected: [string, string | null, number?][],
) {
  expect(move).not.toBeNull();
  const result = new Delta(base.ops as never).compose(
    new Delta((move as QuillDelta).ops as never),
  );
  expect(normalized({ ops: result.ops as QuillOp[] })).toEqual(
    normalized(doc(expected)),
  );
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
      gaps: [{ gap: 1 }, { gap: 2 }, { gap: 3 }],
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
      gaps: [{ gap: 0 }, { gap: 1 }, { gap: 2 }, { gap: 3 }, { gap: 4 }],
    });
    expect(getChecklistDragPlan(sorted, 3)).toMatchObject({
      gaps: [{ gap: 0 }, { gap: 1 }, { gap: 2 }, { gap: 3 }, { gap: 4 }],
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

describe("nested checklists", () => {
  const nested = doc([
    ["a", "unchecked"],
    ["a1", "unchecked", 1],
    ["a2", "unchecked", 1],
    ["b", "unchecked"],
  ]);

  it("the drag plan's block includes the line's indented children", () => {
    expect(getChecklistDragPlan(nested, 0)).toMatchObject({
      lineIndex: 0,
      blockEnd: 2,
    });
    expect(getChecklistDragPlan(nested, 1)).toMatchObject({
      lineIndex: 1,
      blockEnd: 1,
    });
  });

  it("the block never crosses the checklist group boundary", () => {
    const grouped = doc([
      ["a", "unchecked"],
      ["a1", "unchecked", 1],
      ["b", "unchecked"],
      ["note", null, 1],
    ]);
    expect(getChecklistDragPlan(grouped, 0)).toMatchObject({ blockEnd: 1 });
  });

  it("every gap carries the indent range the block may take there", () => {
    expect(getChecklistDragPlan(nested, 3)).toMatchObject({
      gaps: [
        { gap: 0, minIndent: 0, maxIndent: 0 },
        { gap: 1, minIndent: 0, maxIndent: 1 },
        { gap: 2, minIndent: 0, maxIndent: 2 },
        { gap: 3, minIndent: 0, maxIndent: 2 },
        { gap: 4, minIndent: 0, maxIndent: 2 },
      ],
    });
  });

  it("a parent block skips its own inside gaps", () => {
    // The deepest child caps the range at MAX_LIST_INDENT - 1.
    expect(getChecklistDragPlan(nested, 0)).toMatchObject({
      lineIndex: 0,
      blockEnd: 2,
      indent: 0,
      gaps: [
        { gap: 0, minIndent: 0, maxIndent: 0 },
        { gap: 3, minIndent: 0, maxIndent: 0 },
        { gap: 4, minIndent: 0, maxIndent: 1 },
      ],
    });
  });

  it("a child may move between parents or out to the top level", () => {
    expect(getChecklistDragPlan(nested, 1)).toMatchObject({
      indent: 1,
      gaps: [
        { gap: 0, minIndent: 0, maxIndent: 0 },
        { gap: 1, minIndent: 0, maxIndent: 1 },
        { gap: 2, minIndent: 0, maxIndent: 1 },
        { gap: 3, minIndent: 0, maxIndent: 2 },
        { gap: 4, minIndent: 0, maxIndent: 1 },
      ],
    });
  });

  it("returns null when a parent's block fills the whole group", () => {
    const full = doc([
      ["p", "unchecked"],
      ["c1", "unchecked", 1],
      ["c2", "unchecked", 1],
    ]);
    expect(getChecklistDragPlan(full, 0)).toBeNull();
  });

  it("a parent drops with its whole subtree", () => {
    expectApplied(nested, buildChecklistDropDelta(nested, 0, 4), [
      ["b", "unchecked"],
      ["a", "unchecked"],
      ["a1", "unchecked", 1],
      ["a2", "unchecked", 1],
    ]);
  });

  it("gaps inside the dragged block are no-ops", () => {
    for (const gap of [0, 1, 2, 3]) {
      expect(buildChecklistDropDelta(nested, 0, gap)).toBeNull();
    }
  });

  it("a child moves alone within its parent", () => {
    expectApplied(nested, buildChecklistDropDelta(nested, 1, 3), [
      ["a", "unchecked"],
      ["a2", "unchecked", 1],
      ["a1", "unchecked", 1],
      ["b", "unchecked"],
    ]);
  });

  it("a drop can re-indent the block to the gap's level", () => {
    expectApplied(nested, buildChecklistDropDelta(nested, 3, 1, 1), [
      ["a", "unchecked"],
      ["b", "unchecked", 1],
      ["a1", "unchecked", 1],
      ["a2", "unchecked", 1],
    ]);
  });

  it("a shallow drop adopts the children below the gap", () => {
    expectApplied(nested, buildChecklistDropDelta(nested, 3, 1, 0), [
      ["a", "unchecked"],
      ["b", "unchecked"],
      ["a1", "unchecked", 1],
      ["a2", "unchecked", 1],
    ]);
  });

  it("an own-boundary drop with a new indent re-indents in place", () => {
    expectApplied(nested, buildChecklistDropDelta(nested, 3, 4, 1), [
      ["a", "unchecked"],
      ["a1", "unchecked", 1],
      ["a2", "unchecked", 1],
      ["b", "unchecked", 1],
    ]);
    expect(buildChecklistDropDelta(nested, 3, 4, 0)).toBeNull();
  });

  it("children shift with the head and keep their relative depth", () => {
    const deep = doc([
      ["p", "unchecked"],
      ["c1", "unchecked", 1],
      ["g1", "unchecked", 2],
      ["c2", "unchecked", 1],
    ]);
    expectApplied(deep, buildChecklistDropDelta(deep, 1, 0, 0), [
      ["c1", "unchecked"],
      ["g1", "unchecked", 1],
      ["p", "unchecked"],
      ["c2", "unchecked", 1],
    ]);
  });

  it("a mid-level child drops with its own deeper subtree", () => {
    const deep = doc([
      ["p", "unchecked"],
      ["c1", "unchecked", 1],
      ["g1", "unchecked", 2],
      ["c2", "unchecked", 1],
    ]);
    expectApplied(deep, buildChecklistDropDelta(deep, 1, 4), [
      ["p", "unchecked"],
      ["c2", "unchecked", 1],
      ["c1", "unchecked", 1],
      ["g1", "unchecked", 2],
    ]);
  });

  it("checking a parent sinks its whole subtree", () => {
    const toggled = doc([
      ["a", "unchecked"],
      ["b", "checked"],
      ["b1", "unchecked", 1],
      ["c", "unchecked"],
    ]);
    // Toggle position = the newline of "b".
    expectApplied(toggled, createChecklistSortDelta("a\nb".length, toggled), [
      ["a", "unchecked"],
      ["c", "unchecked"],
      ["b", "checked"],
      ["b1", "unchecked", 1],
    ]);
  });

  it("checking a child re-sorts only within its parent", () => {
    const toggled = doc([
      ["p", "unchecked"],
      ["c1", "checked", 1],
      ["c2", "unchecked", 1],
      ["q", "unchecked"],
    ]);
    expectApplied(toggled, createChecklistSortDelta("p\nc1".length, toggled), [
      ["p", "unchecked"],
      ["c2", "unchecked", 1],
      ["c1", "checked", 1],
      ["q", "unchecked"],
    ]);
  });

  it("returns null when the nested group is already ordered", () => {
    const sorted = doc([
      ["p", "unchecked"],
      ["c1", "unchecked", 1],
      ["c2", "checked", 1],
      ["q", "checked"],
    ]);
    expect(createChecklistSortDelta("p\nc1\nc2".length, sorted)).toBeNull();
    expect(createChecklistSortDelta("p\nc1\nc2\nq".length, sorted)).toBeNull();
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
