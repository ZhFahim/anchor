import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { NewNoteMenu } from "./new-note-menu";

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

describe("NewNoteMenu", () => {
  it("renders a separate accessible menu trigger instead of a checklist link", () => {
    const html = renderToStaticMarkup(
      <NewNoteMenu checklistHref="/notes/new?type=checklist" />,
    );
    expect(html).toContain('type="button"');
    expect(html).toContain('aria-label="Choose note type"');
    expect(html).toContain('aria-haspopup="menu"');
    expect(html).toContain('aria-expanded="false"');
    expect(html).not.toContain("<a ");
  });

  it("starts closed without invoking navigation callbacks", () => {
    const onNavigate = vi.fn();
    const html = renderToStaticMarkup(
      <NewNoteMenu
        checklistHref="/notes/new?tagId=tag&type=checklist"
        onNavigate={onNavigate}
      />,
    );
    expect(onNavigate).not.toHaveBeenCalled();
    expect(html).not.toContain('role="menuitem"');
  });
});
