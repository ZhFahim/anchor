import { describe, expect, it } from "vitest";
import { roundTripCases } from "./fixtures/markdown-roundtrip";
import {
  findAttachmentRefs,
  markdownToDelta,
  normalizeTitle,
  parseInline,
  stripTitleHeading,
} from "./markdown-mapping";

const lines = (...values: string[]) => values.join("\n");

describe("parseInline", () => {
  it("reads the basic marks", () => {
    expect(parseInline("**bold**")).toEqual([
      { insert: "bold", attributes: { bold: true } },
    ]);
    expect(parseInline("__bold__")).toEqual([
      { insert: "bold", attributes: { bold: true } },
    ]);
    expect(parseInline("*italic*")).toEqual([
      { insert: "italic", attributes: { italic: true } },
    ]);
    expect(parseInline("~~gone~~")).toEqual([
      { insert: "gone", attributes: { strike: true } },
    ]);
    expect(parseInline("<u>under</u>")).toEqual([
      { insert: "under", attributes: { underline: true } },
    ]);
  });

  it("nests marks", () => {
    expect(parseInline("**bold *and italic***")).toEqual([
      { insert: "bold ", attributes: { bold: true } },
      { insert: "and italic", attributes: { bold: true, italic: true } },
    ]);
    expect(parseInline("*a **b** c*")).toEqual([
      { insert: "a ", attributes: { italic: true } },
      { insert: "b", attributes: { bold: true, italic: true } },
      { insert: " c", attributes: { italic: true } },
    ]);
  });

  it("leaves intraword underscores and unmatched delimiters alone", () => {
    expect(parseInline("snake_case_name")).toEqual([
      { insert: "snake_case_name" },
    ]);
    expect(parseInline("2 * 3 * 4")).toEqual([{ insert: "2 * 3 * 4" }]);
  });

  it("reads links, autolinks and bare urls", () => {
    expect(parseInline("[site](https://example.com)")).toEqual([
      { insert: "site", attributes: { link: "https://example.com" } },
    ]);
    expect(parseInline('[site](https://example.com "Title")')).toEqual([
      { insert: "site", attributes: { link: "https://example.com" } },
    ]);
    expect(parseInline("[site](<https://example.com/a b>)")).toEqual([
      { insert: "site", attributes: { link: "https://example.com/a b" } },
    ]);
    expect(parseInline("<https://example.com>")).toEqual([
      {
        insert: "https://example.com",
        attributes: { link: "https://example.com" },
      },
    ]);
    expect(parseInline("see https://example.com/x, ok")).toEqual([
      { insert: "see " },
      {
        insert: "https://example.com/x",
        attributes: { link: "https://example.com/x" },
      },
      { insert: ", ok" },
    ]);
  });

  it("formats link text", () => {
    expect(parseInline("[**bold**](https://example.com)")).toEqual([
      {
        insert: "bold",
        attributes: { bold: true, link: "https://example.com" },
      },
    ]);
  });

  it("keeps inline code as plain text", () => {
    expect(parseInline("run `npm test` now")).toEqual([
      { insert: "run npm test now" },
    ]);
    expect(parseInline("`a * b`")).toEqual([{ insert: "a * b" }]);
  });

  it("unescapes backslash escapes and entities", () => {
    expect(parseInline("2 \\* 3")).toEqual([{ insert: "2 * 3" }]);
    expect(parseInline("a &amp; b &lt;c&gt;")).toEqual([
      { insert: "a & b <c>" },
    ]);
  });

  it("reduces wikilinks to their text", () => {
    expect(parseInline("see [[Ideas|my ideas]]")).toEqual([
      { insert: "see my ideas" },
    ]);
    expect(parseInline("see [[Ideas]]")).toEqual([{ insert: "see Ideas" }]);
  });

  it("links remote images and keeps local ones literal", () => {
    expect(parseInline("![alt](https://example.com/a.png)")).toEqual([
      { insert: "alt", attributes: { link: "https://example.com/a.png" } },
    ]);
    expect(parseInline("![alt](local.png)")).toEqual([
      { insert: "![alt](local.png)" },
    ]);
  });
});

describe("markdownToDelta blocks", () => {
  it("returns an empty document for empty input", () => {
    expect(markdownToDelta("")).toEqual({ ops: [{ insert: "\n" }] });
  });

  it("clamps headings and reads both setext forms", () => {
    expect(markdownToDelta("###### deep").ops[1]).toEqual({
      insert: "\n",
      attributes: { header: 3 },
    });
    expect(markdownToDelta("## closed ##").ops).toEqual([
      { insert: "closed" },
      { insert: "\n", attributes: { header: 2 } },
    ]);
    expect(markdownToDelta(lines("Title", "===")).ops[1]).toEqual({
      insert: "\n",
      attributes: { header: 1 },
    });
    expect(markdownToDelta(lines("Title", "---")).ops[1]).toEqual({
      insert: "\n",
      attributes: { header: 2 },
    });
  });

  it("nests lists by indentation, with tabs counting as four columns", () => {
    const indents = (markdown: string) =>
      markdownToDelta(markdown)
        .ops.filter((op) => op.insert === "\n")
        .map((op) => op.attributes?.indent ?? 0);

    expect(indents(lines("- a", "  - b", "    - c"))).toEqual([0, 1, 2]);
    expect(indents(lines("- a", "\t- b"))).toEqual([0, 1]);
    expect(indents(lines("- a", "        - b"))).toEqual([0, 1]);
    expect(
      indents(lines("- a", "    - b", "        - c", "    - d", "- e")),
    ).toEqual([0, 1, 2, 1, 0]);
  });

  it("clamps nesting deeper than the editor allows", () => {
    const indents = markdownToDelta(
      lines(
        "- a",
        "    - b",
        "        - c",
        "            - d",
        "                - e",
      ),
    )
      .ops.filter((op) => op.insert === "\n")
      .map((op) => op.attributes?.indent ?? 0);
    expect(indents).toEqual([0, 1, 2, 3, 3]);
  });

  it("reads every list marker and task box", () => {
    const listTypes = (markdown: string) =>
      markdownToDelta(markdown)
        .ops.filter((op) => op.insert === "\n")
        .map((op) => op.attributes?.list);

    expect(listTypes(lines("- a", "* b", "+ c"))).toEqual([
      "bullet",
      "bullet",
      "bullet",
    ]);
    expect(listTypes(lines("1. a", "2) b"))).toEqual(["ordered", "ordered"]);
    expect(listTypes(lines("- [ ] a", "- [x] b", "* [X] c"))).toEqual([
      "unchecked",
      "checked",
      "checked",
    ]);
  });

  it("drops blank lines inside a nested list but keeps them between top-level items", () => {
    const nested = markdownToDelta(lines("- a", "", "    - b"));
    expect(nested.ops).toEqual([
      { insert: "a" },
      { insert: "\n", attributes: { list: "bullet" } },
      { insert: "b" },
      { insert: "\n", attributes: { list: "bullet", indent: 1 } },
    ]);

    const flat = markdownToDelta(lines("- a", "", "- b"));
    expect(flat.ops[2]).toEqual({ insert: "\n" });
  });

  it("joins a wrapped list item onto the item it continues", () => {
    expect(markdownToDelta(lines("- first line", "  continued")).ops).toEqual([
      { insert: "first line continued" },
      { insert: "\n", attributes: { list: "bullet" } },
    ]);
  });

  it("flattens nested blockquotes", () => {
    expect(markdownToDelta("> > deep").ops).toEqual([
      { insert: "deep" },
      { insert: "\n", attributes: { blockquote: true } },
    ]);
  });

  it("reads fenced code, keeping the text raw", () => {
    expect(
      markdownToDelta(lines("```js", "const a = *b*;", "```")).ops,
    ).toEqual([
      { insert: "const a = *b*;" },
      { insert: "\n", attributes: { "code-block": true } },
    ]);
    expect(markdownToDelta(lines("~~~", "text", "~~~")).ops[1]).toEqual({
      insert: "\n",
      attributes: { "code-block": true },
    });
  });

  it("treats an unclosed fence as code to the end", () => {
    expect(markdownToDelta(lines("```", "a", "b")).ops).toEqual([
      { insert: "a" },
      { insert: "\n", attributes: { "code-block": true } },
      { insert: "b" },
      { insert: "\n", attributes: { "code-block": true } },
    ]);
  });

  it("reads indented code outside lists only", () => {
    expect(markdownToDelta(lines("", "    indented")).ops[2]).toEqual({
      insert: "\n",
      attributes: { "code-block": true },
    });
    expect(markdownToDelta(lines("- a", "    continued")).ops).toEqual([
      { insert: "a continued" },
      { insert: "\n", attributes: { list: "bullet" } },
    ]);
  });

  it("drops thematic breaks", () => {
    expect(markdownToDelta(lines("a", "", "***", "", "b")).ops).toEqual([
      { insert: "a" },
      { insert: "\n" },
      { insert: "\n" },
      { insert: "\n" },
      { insert: "b" },
      { insert: "\n" },
    ]);
  });

  it("keeps tables and html as plain text", () => {
    const delta = markdownToDelta(
      lines("| a | b |", "| --- | --- |", "<div>x</div>"),
    );
    expect(delta.ops[0]).toEqual({ insert: "| a | b |" });
    expect(delta.ops[4]).toEqual({ insert: "<div>x</div>" });
  });

  it("handles CRLF, a BOM and a missing trailing newline", () => {
    expect(markdownToDelta("﻿a\r\nb").ops).toEqual([
      { insert: "a" },
      { insert: "\n" },
      { insert: "b" },
      { insert: "\n" },
    ]);
    expect(markdownToDelta("a\n").ops).toEqual([
      { insert: "a" },
      { insert: "\n" },
    ]);
  });

  it.each(roundTripCases)("parses the $name fixture", ({ markdown, ops }) => {
    expect(markdownToDelta(markdown)).toEqual({ ops });
  });
});

describe("stripTitleHeading", () => {
  it("drops a heading that repeats the filename", () => {
    expect(
      stripTitleHeading("# Meeting notes\n\nAgenda", "Meeting notes"),
    ).toBe("Agenda");
    expect(stripTitleHeading("# Meeting: Q3\n\nAgenda", "Meeting- Q3")).toBe(
      "Agenda",
    );
    expect(stripTitleHeading("# Groceries\nmilk", "Groceries (2)")).toBe(
      "milk",
    );
  });

  it("keeps a heading that says something else", () => {
    expect(stripTitleHeading("# Agenda\n\nBody", "Meeting notes")).toBe(
      "# Agenda\n\nBody",
    );
    expect(stripTitleHeading("## Notes\n\nBody", "Notes")).toBe(
      "## Notes\n\nBody",
    );
  });

  it("leaves blank input alone", () => {
    expect(stripTitleHeading("   ", "x")).toBe("   ");
  });
});

describe("normalizeTitle", () => {
  it("ignores case, spacing, punctuation and dedupe suffixes", () => {
    expect(normalizeTitle("Meeting: Q3 planning")).toBe(
      normalizeTitle("meeting- q3   planning"),
    );
    expect(normalizeTitle("Groceries (2)")).toBe(normalizeTitle("Groceries"));
  });
});

describe("findAttachmentRefs", () => {
  it("finds local images, links and embeds", () => {
    const refs = findAttachmentRefs(
      lines(
        "![shot](assets/shot%20one.png)",
        "[memo](../audio/memo.m4a)",
        "![[diagram.png]]",
        "[external](https://example.com/a.png)",
        "![remote](https://example.com/b.png)",
      ),
    );

    expect(refs.map((ref) => ref.target)).toEqual([
      "assets/shot one.png",
      "../audio/memo.m4a",
      "diagram.png",
    ]);
    expect(refs[0].kind).toBe("image");
    expect(refs[1].kind).toBe("link");
    expect(refs[0].raw).toBe("![shot](assets/shot%20one.png)");
  });

  it("ignores references inside code fences", () => {
    const refs = findAttachmentRefs(
      lines("```", "![shot](a.png)", "```", "![real](b.png)"),
    );
    expect(refs.map((ref) => ref.target)).toEqual(["b.png"]);
  });

  it("records the line each reference sits on", () => {
    const refs = findAttachmentRefs(lines("text", "", "![a](a.png)"));
    expect(refs[0].line).toBe(2);
  });
});
