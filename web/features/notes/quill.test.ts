import { describe, expect, it } from "vitest";
import { fakeQuill } from "./fixtures/fake-quill";
import {
  capPastedHeading,
  findTickedLines,
  orderedPreviewMarker,
  type QuillDelta,
  type QuillOp,
  startTypedBlock,
  undoConversion,
} from "./quill";

describe("orderedPreviewMarker", () => {
  it("cycles number styles by depth like the editor", () => {
    expect(orderedPreviewMarker(2, 0)).toBe("2.");
    expect(orderedPreviewMarker(2, 1)).toBe("b.");
    expect(orderedPreviewMarker(4, 2)).toBe("iv.");
    expect(orderedPreviewMarker(3, 3)).toBe("3.");
  });
});

describe("findTickedLines", () => {
  const doc = (lines: [string, string | null][]): QuillDelta => {
    const ops: QuillOp[] = [];
    for (const [text, list] of lines) {
      if (text) ops.push({ insert: text });
      ops.push(
        list ? { insert: "\n", attributes: { list } } : { insert: "\n" },
      );
    }
    return { ops };
  };
  const before = doc([
    ["Intro", null],
    ["Milk", "unchecked"],
    ["Eggs", "unchecked"],
    ["Done", "checked"],
  ]);

  it("finds a ticked item's newline", () => {
    const change = {
      ops: [{ retain: 10 }, { retain: 1, attributes: { list: "checked" } }],
    };
    expect(findTickedLines(change, before)).toEqual([10]);
  });

  it("finds every item a range ticked", () => {
    const change = {
      ops: [
        { retain: 10 },
        { retain: 1, attributes: { list: "checked" } },
        { retain: 4 },
        { retain: 1, attributes: { list: "checked" } },
      ],
    };
    expect(findTickedLines(change, before)).toEqual([10, 15]);
  });

  it("ignores unticks, new checklist lines and edits", () => {
    const untick = {
      ops: [{ retain: 20 }, { retain: 1, attributes: { list: "unchecked" } }],
    };
    const fromText = {
      ops: [{ retain: 5 }, { retain: 1, attributes: { list: "checked" } }],
    };
    const typed = { ops: [{ retain: 10 }, { insert: "!" }] };
    expect(findTickedLines(untick, before)).toEqual([]);
    expect(findTickedLines(fromText, before)).toEqual([]);
    expect(findTickedLines(typed, before)).toEqual([]);
  });
});

describe("capPastedHeading", () => {
  it("turns headings 4 to 6 into heading 3", () => {
    const delta = {
      ops: [{ insert: "Deep" }, { insert: "\n", attributes: { header: 5 } }],
    };
    expect(capPastedHeading({} as Node, delta).ops[1].attributes).toEqual({
      header: 3,
    });
  });

  it("leaves other headings alone", () => {
    const delta = { ops: [{ insert: "\n", attributes: { header: 2 } }] };
    expect(capPastedHeading({} as Node, delta).ops[0].attributes).toEqual({
      header: 2,
    });
  });
});

describe("startTypedBlock", () => {
  const typed = (ops: QuillOp[], change: QuillOp[], caret: number) => {
    const fake = fakeQuill(ops, caret);
    startTypedBlock(fake.quill, { ops: change });
    return { ops: fake.ops(), caret: fake.caret() };
  };

  it.each([
    ["- ", { list: "bullet" }],
    ["* ", { list: "bullet" }],
    ["+ ", { list: "bullet" }],
    ["1. ", { list: "ordered" }],
    ["1) ", { list: "ordered" }],
    ["[] ", { list: "unchecked" }],
    ["[ ] ", { list: "unchecked" }],
    ["[x] ", { list: "checked" }],
    ["# ", { header: 1 }],
    ["## ", { header: 2 }],
    ["### ", { header: 3 }],
    ["> ", { blockquote: true }],
    ["``` ", { "code-block": "plain" }],
  ])("turns %j typed as text into a block", (starter, attributes) => {
    const at = 4 + starter.length - 1;
    expect(
      typed(
        [{ insert: `Top\n${starter}\n` }],
        [{ retain: at }, { insert: " " }],
        at + 1,
      ),
    ).toEqual({
      ops: [{ insert: "Top\n" }, { insert: "\n", attributes }],
      caret: 4,
    });
  });

  it("keeps the text after the caret", () => {
    expect(
      typed([{ insert: "- item\n" }], [{ retain: 1 }, { insert: " " }], 2),
    ).toEqual({
      ops: [
        { insert: "item" },
        { insert: "\n", attributes: { list: "bullet" } },
      ],
      caret: 0,
    });
  });

  it("replaces the line's own kind, keeping a list's indent for a list", () => {
    const item = (attributes: Record<string, unknown>) => [
      { insert: "# " },
      { insert: "\n", attributes },
    ];
    expect(
      typed(
        item({ list: "bullet", indent: 1 }),
        [{ retain: 1 }, { insert: " " }],
        2,
      ).ops,
    ).toEqual([{ insert: "\n", attributes: { header: 1 } }]);
    expect(
      typed(
        [
          { insert: "1. " },
          { insert: "\n", attributes: { list: "bullet", indent: 1 } },
        ],
        [{ retain: 2 }, { insert: " " }],
        3,
      ).ops,
    ).toEqual([{ insert: "\n", attributes: { list: "ordered", indent: 1 } }]);
  });

  it("leaves code blocks and quotes alone", () => {
    for (const attributes of [
      { "code-block": "plain" },
      { blockquote: true },
    ]) {
      const ops = [{ insert: "- " }, { insert: "\n", attributes }];
      expect(typed(ops, [{ retain: 1 }, { insert: " " }], 2).ops).toEqual(ops);
    }
  });

  it("leaves a space typed anywhere else alone", () => {
    const ops = [{ insert: "a - \n" }];
    expect(typed(ops, [{ retain: 3 }, { insert: " " }], 4).ops).toEqual(ops);
    const elsewhere = [{ insert: "- \nnext\n" }];
    expect(typed(elsewhere, [{ retain: 1 }, { insert: " " }], 6).ops).toEqual(
      elsewhere,
    );
    const heading = [{ insert: "#### \n" }];
    expect(typed(heading, [{ retain: 4 }, { insert: " " }], 5).ops).toEqual(
      heading,
    );
  });
});

describe("undoConversion", () => {
  const converted = () => {
    const fake = fakeQuill([{ insert: "> \n" }], 2);
    startTypedBlock(fake.quill, { ops: [{ retain: 1 }, { insert: " " }] });
    return fake;
  };

  it("undoes a starter while the caret stays where it left it", () => {
    const fake = converted();
    expect(undoConversion(fake.quill)).toBe(true);
    expect(fake.undoCount()).toBe(1);
    expect(undoConversion(fake.quill)).toBe(false);
  });

  it("does nothing once the text or selection has changed", () => {
    const fake = converted();
    fake.emitChange();
    expect(undoConversion(fake.quill)).toBe(false);
    const moved = converted();
    moved.quill.setSelection(1, 0);
    expect(undoConversion(moved.quill)).toBe(false);
    expect(fake.undoCount() + moved.undoCount()).toBe(0);
  });
});
