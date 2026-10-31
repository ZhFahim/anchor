import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { writeChecklist } from "../checklist";
import type { Note } from "../types";
import { type CardLayout, NoteCard } from "./note-card";

const note: Note = {
  id: "tasks",
  title: "Shopping",
  noteType: "checklist",
  content: writeChecklist([
    { text: "Milk", done: false },
    { text: "Bread", done: true },
  ]),
  isPinned: false,
  isArchived: false,
  state: "active",
  version: 1,
  createdAt: "2026-10-31T12:00:00Z",
  updatedAt: "2026-10-31T12:00:00Z",
  userId: "user",
  permission: "owner",
};

function render(overrides: Partial<Note> = {}, layout: CardLayout = "masonry") {
  return renderToStaticMarkup(
    <NoteCard
      note={{ ...note, ...overrides }}
      tagMap={new Map()}
      layout={layout}
    />,
  );
}

describe("checklist card identity", () => {
  it.each<CardLayout>(["masonry", "grid", "list"])(
    "marks checklist cards and shows progress in %s layout",
    (layout) => {
      const html = render({}, layout);
      expect(html).toContain("nc-type-icon");
      expect(html).toContain("1 of 2 done");
      expect(html).toContain("Checklist: Shopping. 1 of 2 tasks completed.");
      expect(html).not.toContain("Bread");
    },
  );

  it("shows a checkmark and All done for completed lists", () => {
    const html = render({
      content: writeChecklist([
        { text: "Milk", done: true },
        { text: "", done: false },
      ]),
    });
    expect(html).toContain("All done");
    expect(html).toContain("lucide-circle-check");
    expect(html).not.toContain("0 of 0");
  });

  it("keeps an empty untitled checklist recognizable", () => {
    const html = render({ title: "", content: "" });
    expect(html).toContain("nc-type-icon");
    expect(html).toContain("Checklist</div>");
    expect(html).toContain("No tasks");
    expect(html).not.toContain("All done");
  });

  it("leaves regular notes with checkboxes visually unchanged", () => {
    const html = render({ noteType: "note" });
    expect(html).not.toContain("nc-type-icon");
    expect(html).not.toContain("nc-checklist-progress");
    expect(html).not.toContain("Checklist: Shopping");
  });
});
