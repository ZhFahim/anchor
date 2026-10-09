import { describe, expect, it } from "vitest";
import type { QuillOp } from "./quill";
import { diffVersions, diffWords, foldLines } from "./version-diff";

interface Line {
  text: string;
  attributes?: Record<string, unknown>;
}

const doc = (...lines: (string | Line)[]) => {
  const ops: QuillOp[] = [];
  for (const line of lines) {
    const { text, attributes }: Line =
      typeof line === "string" ? { text: line } : line;
    if (text) ops.push({ insert: text });
    ops.push({ insert: "\n", ...(attributes ? { attributes } : {}) });
  }
  return JSON.stringify({ ops });
};

const text = (block: { runs: { text: string }[] }) =>
  block.runs.map((run) => run.text).join("");
const marks = (before: string, after: string) =>
  diffVersions(before, after).lines.map((line) => [
    line.kind,
    text(line.block),
  ]);

describe("diffWords", () => {
  it("keeps what stayed and marks what went and came", () => {
    expect(diffWords("Fado dinner at 8 pm", "Fado dinner at 9 pm")).toEqual([
      { text: "Fado dinner at ", kind: "same" },
      { text: "8", kind: "del" },
      { text: "9", kind: "ins" },
      { text: " pm", kind: "same" },
    ]);
  });

  it("handles a line that was emptied or filled", () => {
    expect(diffWords("", "new")).toEqual([{ text: "new", kind: "ins" }]);
    expect(diffWords("old", "")).toEqual([{ text: "old", kind: "del" }]);
  });
});

describe("diffVersions", () => {
  it("marks nothing when the text is the same", () => {
    const diff = diffVersions(doc("milk", "eggs"), doc("milk", "eggs"));
    expect([diff.added, diff.removed, diff.changed]).toEqual([0, 0, 0]);
  });

  it("shows a small edit as one changed line", () => {
    const diff = diffVersions(
      doc("Check in after 3 pm", "Fado dinner at 8 pm"),
      doc("Check in after 3 pm", "Fado dinner at 9 pm"),
    );
    expect(diff.changed).toBe(1);
    expect(diff.lines[1]).toMatchObject({ kind: "changed" });
  });

  it("keeps lines that have little in common as removed and added", () => {
    expect(
      marks(
        doc("milk", "Buy a new bike helmet"),
        doc("milk", "Call the dentist tomorrow"),
      ),
    ).toEqual([
      ["same", "milk"],
      ["removed", "Buy a new bike helmet"],
      ["added", "Call the dentist tomorrow"],
    ]);
  });

  it("shows ticking an item as a change to that line", () => {
    const diff = diffVersions(
      doc({ text: "Book the flights", attributes: { list: "unchecked" } }),
      doc({ text: "Book the flights", attributes: { list: "checked" } }),
    );
    expect(diff.lines).toHaveLength(1);
    expect(diff.lines[0]).toMatchObject({
      kind: "changed",
      words: [{ text: "Book the flights", kind: "same" }],
    });
  });

  it("marks lines the next version added and removed", () => {
    expect(marks(doc("a", "b"), doc("a", "c", "b"))).toEqual([
      ["same", "a"],
      ["added", "c"],
      ["same", "b"],
    ]);
    expect(marks(doc("a", "b", "c"), doc("a", "c"))).toEqual([
      ["same", "a"],
      ["removed", "b"],
      ["same", "c"],
    ]);
  });

  it("leaves out empty lines", () => {
    expect(marks(doc("a", "", "b"), doc("a", "b"))).toEqual([
      ["same", "a"],
      ["same", "b"],
    ]);
  });
});

describe("foldLines", () => {
  const lines = (...kinds: string[]) =>
    kinds.map((kind) => ({
      kind: kind as "same",
      block: { type: "p" as const, level: 0, runs: [] },
    }));

  it("keeps two lines around a change and folds three or more", () => {
    const sample = lines(
      "same",
      "same",
      "same",
      "same",
      "same",
      "added",
      "same",
      "same",
      "same",
      "same",
      "same",
      "same",
    );
    expect(foldLines(sample)).toEqual([
      { fold: true, from: 0, to: 3 },
      3,
      4,
      5,
      6,
      7,
      { fold: true, from: 8, to: 12 },
    ]);
  });

  it("doesn't fold two lines", () => {
    const sample = lines("same", "same", "same", "same", "added");
    expect(foldLines(sample)).toEqual([0, 1, 2, 3, 4]);
  });

  it("opens a fold that was opened", () => {
    const sample = lines("same", "same", "same", "same", "same", "added");
    expect(foldLines(sample, new Set([0, 1, 2]))).toEqual([0, 1, 2, 3, 4, 5]);
  });
});
