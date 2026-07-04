import { describe, expect, it } from "vitest";
import {
  keepColorToBackground,
  keepContentToDelta,
  keepTimestampToIso,
  resolveKeepMediaPath,
} from "./keep-mapping";

describe("keepColorToBackground", () => {
  it("maps known colors", () => {
    expect(keepColorToBackground("TEAL")).toBe("color_teal");
    expect(keepColorToBackground("CERULEAN")).toBe("color_dark_blue");
  });

  it("falls back to null for DEFAULT, GRAY, unknown and missing", () => {
    expect(keepColorToBackground("DEFAULT")).toBeNull();
    expect(keepColorToBackground("GRAY")).toBeNull();
    expect(keepColorToBackground("CHARTREUSE")).toBeNull();
    expect(keepColorToBackground(undefined)).toBeNull();
  });
});

describe("keepTimestampToIso", () => {
  it("converts microseconds to ISO milliseconds", () => {
    expect(keepTimestampToIso(1700000400123456)).toBe(
      new Date(1700000400123).toISOString(),
    );
  });

  it("returns undefined for missing or zero timestamps", () => {
    expect(keepTimestampToIso(undefined)).toBeUndefined();
    expect(keepTimestampToIso(0)).toBeUndefined();
  });
});

describe("keepContentToDelta", () => {
  it("converts plain text with a trailing newline", () => {
    expect(keepContentToDelta({ textContent: "Buy milk\nAnd bread" })).toEqual({
      ops: [{ insert: "Buy milk\nAnd bread\n" }],
    });
  });

  it("converts checklists to quill checked/unchecked lines", () => {
    const delta = keepContentToDelta({
      listContent: [
        { text: "Passport", isChecked: true },
        { text: "Charger", isChecked: false },
      ],
    });
    expect(delta.ops).toEqual([
      { insert: "Passport" },
      { insert: "\n", attributes: { list: "checked" } },
      { insert: "Charger" },
      { insert: "\n", attributes: { list: "unchecked" } },
    ]);
  });

  it("appends annotation urls as linked lines", () => {
    const delta = keepContentToDelta({
      textContent: "Plans",
      annotations: [{ url: "https://example.com" }],
    });
    expect(delta.ops).toEqual([
      { insert: "Plans\n" },
      { insert: "\n" },
      {
        insert: "https://example.com",
        attributes: { link: "https://example.com" },
      },
      { insert: "\n" },
    ]);
  });

  it("produces an empty delta for empty notes", () => {
    expect(keepContentToDelta({})).toEqual({ ops: [{ insert: "\n" }] });
  });
});

describe("resolveKeepMediaPath", () => {
  const media = ["Takeout/Keep/receipt.jpg", "Takeout/Keep/photo.png"];

  it("matches exact basenames case-insensitively", () => {
    expect(resolveKeepMediaPath("RECEIPT.JPG", media)).toBe(
      "Takeout/Keep/receipt.jpg",
    );
  });

  it("falls back to same stem with a different extension", () => {
    expect(resolveKeepMediaPath("receipt.jpeg", media)).toBe(
      "Takeout/Keep/receipt.jpg",
    );
  });

  it("returns undefined when nothing matches", () => {
    expect(resolveKeepMediaPath("missing.gif", media)).toBeUndefined();
  });
});
