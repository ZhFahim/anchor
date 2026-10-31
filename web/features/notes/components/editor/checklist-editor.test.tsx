import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { writeChecklist } from "../../checklist";
import { ChecklistEditor } from "./checklist-editor";

describe("ChecklistEditor", () => {
  const content = writeChecklist([
    { text: "Buy milk", done: false },
    { text: "Already finished", done: true },
  ]);

  it("shows active tasks and hides completed task text by default", () => {
    const html = renderToStaticMarkup(
      <ChecklistEditor value={content} onChange={() => {}} />,
    );
    expect(html).toContain('value="Buy milk"');
    expect(html).not.toContain("Already finished");
    expect(html).toContain("Completed (1)");
    expect(html).toContain('aria-expanded="false"');
    expect(html).not.toContain("ql-toolbar");
  });

  it("disables checking and hides edit controls for viewers", () => {
    const html = renderToStaticMarkup(
      <ChecklistEditor value={content} onChange={() => {}} readOnly />,
    );
    expect(html).toContain('disabled=""');
    expect(html).toContain('readOnly=""');
    expect(html).not.toContain("Add task</button>");
    expect(html).not.toContain("Reorder");
    expect(html).not.toContain("Delete Buy milk");
  });
});
