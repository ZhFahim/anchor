import Delta from "quill-delta";
import { describe, expect, it } from "vitest";
import type { QuillDelta, QuillOp } from "../../quill";
import { planChecklistSort } from "./checklist-sort";

type Line = [text: string, list: string | null, indent?: number];

const doc = (lines: Line[]): QuillDelta => {
  const ops: QuillOp[] = [];
  for (const [text, list, indent] of lines) {
    if (text) ops.push({ insert: text });
    const attributes = {
      ...(list ? { list } : {}),
      ...(indent ? { indent } : {}),
    };
    ops.push(
      Object.keys(attributes).length
        ? { insert: "\n", attributes }
        : { insert: "\n" },
    );
  }
  return { ops };
};

const normalized = (ops: QuillOp[]) =>
  new Delta().compose(new Delta(ops as never)).ops;
const sorted = (before: QuillDelta, delta: QuillDelta) =>
  normalized(
    new Delta(before.ops as never).compose(new Delta(delta.ops as never))
      .ops as QuillOp[],
  );

describe("planChecklistSort", () => {
  it("moves a ticked item below the open ones", () => {
    const before = doc([
      ["Groceries", null],
      ["Milk", "checked"],
      ["Eggs", "unchecked"],
      ["Bread", "unchecked"],
    ]);
    const plan = planChecklistSort(before, [1]);
    expect(plan?.origins).toEqual([0, 2, 3, 1]);
    const after = doc([
      ["Groceries", null],
      ["Eggs", "unchecked"],
      ["Bread", "unchecked"],
      ["Milk", "checked"],
    ]);
    expect(sorted(before, plan?.delta ?? { ops: [] })).toEqual(
      normalized(after.ops),
    );
  });

  it("moves an unticked item up to the end of the open ones", () => {
    const before = doc([
      ["Eggs", "unchecked"],
      ["Milk", "checked"],
      ["Bread", "unchecked"],
      ["Tea", "checked"],
    ]);
    expect(planChecklistSort(before, [2])?.origins).toEqual([0, 2, 1, 3]);
  });

  it("keeps the order items were ticked in", () => {
    const before = doc([
      ["A", "checked"],
      ["B", "checked"],
      ["C", "unchecked"],
    ]);
    expect(planChecklistSort(before, [1, 0])?.origins).toEqual([2, 1, 0]);
    expect(planChecklistSort(before, [0, 1])?.origins).toEqual([2, 0, 1]);
  });

  it("follows the ticked one of two same items", () => {
    const before = doc([
      ["Milk", "checked"],
      ["Tea", "unchecked"],
      ["Milk", "checked"],
    ]);
    expect(planChecklistSort(before, [0])?.origins).toEqual([1, 2, 0]);
  });

  it("takes sub-items along", () => {
    const before = doc([
      ["Trip", "checked"],
      ["Tickets", "unchecked", 1],
      ["Bags", "unchecked"],
    ]);
    expect(planChecklistSort(before, [0])?.origins).toEqual([2, 0, 1]);
  });

  it("gives nothing when the order already fits", () => {
    const before = doc([
      ["Eggs", "unchecked"],
      ["Milk", "checked"],
    ]);
    expect(planChecklistSort(before, [1])).toBeNull();
  });
});
