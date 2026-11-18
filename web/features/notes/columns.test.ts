import { describe, expect, it } from "vitest";
import { draggedNoteIds, noteHref, parseDropTarget } from "./columns";

describe("draggedNoteIds", () => {
  const shown = ["a", "b", "c", "d"];

  it("carries every picked note, in list order, when a picked note is dragged", () => {
    expect(draggedNoteIds("c", new Set(["d", "a", "c"]), shown)).toEqual([
      "a",
      "c",
      "d",
    ]);
  });

  it("carries only the dragged note when it is not picked", () => {
    expect(draggedNoteIds("b", new Set(["a", "c"]), shown)).toEqual(["b"]);
  });

  it("carries only the dragged note when nothing is picked", () => {
    expect(draggedNoteIds("b", new Set(), shown)).toEqual(["b"]);
  });

  it("leaves out picked notes that are no longer in the list", () => {
    expect(draggedNoteIds("a", new Set(["a", "gone"]), shown)).toEqual(["a"]);
  });
});

describe("parseDropTarget", () => {
  it("reads a tag, the archive and the trash", () => {
    expect(parseDropTarget("tag:t1")).toEqual({ kind: "tag", tagId: "t1" });
    expect(parseDropTarget("archive")).toEqual({ kind: "archive" });
    expect(parseDropTarget("trash")).toEqual({ kind: "trash" });
  });

  it("ignores anything else", () => {
    expect(parseDropTarget(null)).toBeNull();
    expect(parseDropTarget("")).toBeNull();
    expect(parseDropTarget("tag:")).toBeNull();
    expect(parseDropTarget("notes")).toBeNull();
  });
});

describe("noteHref", () => {
  it("keeps the tag the list shows", () => {
    expect(noteHref("n1", "t 1")).toBe("/notes/n1?tagId=t%201");
  });

  it("is the plain note address without a tag", () => {
    expect(noteHref("n1", null)).toBe("/notes/n1");
  });
});
