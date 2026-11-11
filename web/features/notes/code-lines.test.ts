import { describe, expect, it } from "vitest";
import { codeIndentColumns, splitCodeLines } from "./code-lines";

describe("codeIndentColumns", () => {
  it("counts leading spaces", () => {
    expect(codeIndentColumns("    return x;")).toBe(4);
    expect(codeIndentColumns("return x;")).toBe(0);
    expect(codeIndentColumns("")).toBe(0);
  });

  it("moves a tab to the next tab stop", () => {
    expect(codeIndentColumns("\tbuild")).toBe(4);
    expect(codeIndentColumns("\t\tbuild")).toBe(8);
    expect(codeIndentColumns("  \tbuild")).toBe(4);
    expect(codeIndentColumns("    \tbuild")).toBe(8);
  });

  it("stops at the first other character", () => {
    expect(codeIndentColumns("  a  b")).toBe(2);
    expect(codeIndentColumns("   ")).toBe(3);
  });
});

describe("splitCodeLines", () => {
  it("splits plain text into lines", () => {
    expect(splitCodeLines([{ text: "a\n  b\n\nc" }])).toEqual([
      [{ text: "a" }],
      [{ text: "  b" }],
      [],
      [{ text: "c" }],
    ]);
  });

  it("keeps each part's kind across a line break", () => {
    const lines = splitCodeLines([
      { kind: "same", text: "url: " },
      { kind: "del", text: "old\n  next" },
      { kind: "ins", text: "new" },
      { kind: "same", text: "\n}" },
    ]);
    expect(lines).toEqual([
      [
        { kind: "same", text: "url: " },
        { kind: "del", text: "old" },
      ],
      [
        { kind: "del", text: "  next" },
        { kind: "ins", text: "new" },
      ],
      [{ kind: "same", text: "}" }],
    ]);
  });

  it("gives one empty line for no text", () => {
    expect(splitCodeLines([])).toEqual([[]]);
    expect(splitCodeLines([{ text: "" }])).toEqual([[]]);
  });
});
