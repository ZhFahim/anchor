import { describe, expect, it } from "vitest";
import { deltaToBlocks, foldTickedItems } from "./note-blocks";

const doc = (ops: unknown[]) => JSON.stringify({ ops });

describe("deltaToBlocks", () => {
  it("reads headings, checklists and inline styles", () => {
    const blocks = deltaToBlocks(
      doc([
        { insert: "Plan" },
        { insert: "\n", attributes: { header: 1 } },
        { insert: "Book " },
        { insert: "flights", attributes: { bold: true, highlight: "yellow" } },
        { insert: "\n", attributes: { list: "checked" } },
        { insert: "Pack" },
        { insert: "\n", attributes: { list: "unchecked", indent: 1 } },
      ]),
    );
    expect(blocks.map((b) => b.type)).toEqual(["h1", "check", "check"]);
    expect(blocks[1]).toMatchObject({ done: true, level: 0 });
    expect(blocks[1].runs[1]).toMatchObject({
      text: "flights",
      bold: true,
      highlight: "yellow",
    });
    expect(blocks[2]).toMatchObject({ done: false, level: 1 });
  });

  it("numbers ordered items by level, continuing after a nested run", () => {
    const item = (text: string, indent = 0) => [
      { insert: text },
      {
        insert: "\n",
        attributes: { list: "ordered", ...(indent ? { indent } : {}) },
      },
    ];
    const blocks = deltaToBlocks(
      doc([
        ...item("One"),
        ...item("Sub", 1),
        ...item("Sub two", 1),
        ...item("Two"),
      ]),
    );
    expect(blocks.map((b) => b.marker)).toEqual(["1.", "a.", "b.", "2."]);
  });

  it("joins code lines into one block", () => {
    const blocks = deltaToBlocks(
      doc([
        { insert: "a" },
        { insert: "\n", attributes: { "code-block": "plain" } },
        { insert: "b" },
        { insert: "\n", attributes: { "code-block": "plain" } },
      ]),
    );
    expect(blocks).toHaveLength(1);
    expect(blocks[0].runs.map((r) => r.text).join("")).toBe("a\nb");
  });
});

describe("foldTickedItems", () => {
  const line = (text: string, attributes?: Record<string, unknown>) => [
    { insert: text },
    attributes ? { insert: "\n", attributes } : { insert: "\n" },
  ];
  const open = (text: string, indent = 0) =>
    line(text, { list: "unchecked", ...(indent ? { indent } : {}) });
  const ticked = (text: string, indent = 0) =>
    line(text, { list: "checked", ...(indent ? { indent } : {}) });
  const fold = (...lines: unknown[][]) =>
    foldTickedItems(deltaToBlocks(doc(lines.flat()))).map((row) =>
      row.type === "done"
        ? `${row.isAll ? "all " : ""}${row.count} done`
        : row.runs.map((run) => run.text).join(""),
    );

  it("puts the line after the open items of the same list", () => {
    expect(fold(open("Milk"), ticked("Bread"), open("Eggs"))).toEqual([
      "Milk",
      "Eggs",
      "1 done",
    ]);
  });

  it("keeps a fully ticked list's line after the text above it", () => {
    expect(fold(line("Moved in"), ticked("Bank"), ticked("Post"))).toEqual([
      "Moved in",
      "all 2 done",
    ]);
  });

  it("gives each list its own line", () => {
    expect(
      fold(
        line("Before", { header: 2 }),
        ticked("Flights"),
        open("Maps"),
        line("On the day", { header: 2 }),
        open("Pack"),
        ticked("Charge"),
      ),
    ).toEqual(["Before", "Maps", "1 done", "On the day", "Pack", "1 done"]);
  });

  it("counts ticked nested items with their list", () => {
    expect(fold(open("Pack"), ticked("Socks", 1), ticked("Coat", 1))).toEqual([
      "Pack",
      "2 done",
    ]);
  });

  it("adds no line to a list with nothing ticked", () => {
    expect(fold(open("Milk"), line("Later"))).toEqual(["Milk", "Later"]);
  });
});
