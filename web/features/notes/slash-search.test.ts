import { describe, expect, it } from "vitest";
import { findSlashItems } from "./slash-search";

const ITEMS = [
  { label: "Checklist", keywords: "todo task list", isPopular: true },
  { label: "Heading 1", keywords: "h1 title", isPopular: true },
  { label: "Heading 2", keywords: "h2 subheading" },
  { label: "Bullet list", keywords: "unordered ul", isPopular: true },
  { label: "Text", keywords: "paragraph plain" },
];
const labels = (query: string) =>
  findSlashItems(ITEMS, query).map((item) => item.label);

describe("findSlashItems", () => {
  it("finds the popular items before anything is typed", () => {
    expect(labels("")).toEqual(["Checklist", "Heading 1", "Bullet list"]);
    expect(labels("  ")).toEqual(["Checklist", "Heading 1", "Bullet list"]);
  });

  it("finds every item, not only the popular ones", () => {
    expect(labels("text")).toEqual(["Text"]);
    expect(labels("h2")).toEqual(["Heading 2"]);
    expect(labels("para")).toEqual(["Text"]);
  });

  it("puts label matches before other words", () => {
    expect(labels("list")).toEqual(["Bullet list", "Checklist"]);
    expect(labels("h")).toEqual(["Heading 1", "Heading 2"]);
  });

  it("matches across spaces and ignores case", () => {
    expect(labels("heading 2")).toEqual(["Heading 2"]);
    expect(labels("Heading2")).toEqual(["Heading 2"]);
    expect(labels("bul li")).toEqual(["Bullet list"]);
  });

  it("finds nothing for an unknown query", () => {
    expect(labels("zzz")).toEqual([]);
  });
});
