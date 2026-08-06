import { describe, expect, it } from "vitest";
import { deltaToPreviewLines, orderedPreviewMarker } from "./quill";

function content(ops: unknown[]): string {
  return JSON.stringify({ ops });
}

describe("deltaToPreviewLines", () => {
  it("carries list type and indent per line", () => {
    const stored = content([
      { insert: "title\na" },
      { insert: "\n", attributes: { list: "unchecked" } },
      { insert: "a1" },
      { insert: "\n", attributes: { list: "checked", indent: 1 } },
      { insert: "g1" },
      { insert: "\n", attributes: { list: "bullet", indent: 2 } },
      { insert: "note\n" },
    ]);
    expect(deltaToPreviewLines(stored)).toEqual([
      { text: "title", listType: null, indent: 0 },
      { text: "a", listType: "unchecked", indent: 0 },
      { text: "a1", listType: "checked", indent: 1 },
      { text: "g1", listType: "bullet", indent: 2 },
      { text: "note", listType: null, indent: 0 },
    ]);
  });

  it("drops blank lines and respects maxLines", () => {
    const stored = content([{ insert: "a\n\nb\nc\n" }]);
    expect(deltaToPreviewLines(stored, 2)).toEqual([
      { text: "a", listType: null, indent: 0 },
      { text: "b", listType: null, indent: 0 },
    ]);
  });
});

describe("orderedPreviewMarker", () => {
  it("cycles number styles by depth like the editor", () => {
    expect(orderedPreviewMarker(2, 0)).toBe("2.");
    expect(orderedPreviewMarker(2, 1)).toBe("b.");
    expect(orderedPreviewMarker(4, 2)).toBe("iv.");
    expect(orderedPreviewMarker(3, 3)).toBe("3.");
  });
});
