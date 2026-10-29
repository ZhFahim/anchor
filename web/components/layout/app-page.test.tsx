import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SearchField } from "./app-page";

function renderSearch(value: string) {
  return renderToStaticMarkup(
    <TooltipProvider>
      <SearchField
        value={value}
        onChange={() => {}}
        placeholder="Search notes"
      />
    </TooltipProvider>,
  );
}

describe("SearchField", () => {
  it("expands a restored query so it is visible on small screens", () => {
    const html = renderSearch("A");
    expect(html).toContain('data-open="true"');
    expect(html).toContain('value="A"');
  });

  it("leaves an empty search collapsed", () => {
    expect(renderSearch("")).not.toContain("data-open=");
  });
});
