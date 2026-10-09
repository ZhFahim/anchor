import { describe, expect, it } from "vitest";
import { cn } from "./utils";

describe("cn", () => {
  it("keeps a theme text size next to a text color", () => {
    expect(cn("text-meta", "text-muted-foreground")).toBe(
      "text-meta text-muted-foreground",
    );
  });

  it("lets a later theme size replace an earlier one", () => {
    expect(cn("text-meta text-ui")).toBe("text-ui");
    expect(cn("rounded-button", "rounded-pill")).toBe("rounded-pill");
    expect(cn("shadow-xs", "shadow-menu")).toBe("shadow-menu");
  });

  it("knows the theme's sizes and gutters", () => {
    expect(cn("h-field", "h-9")).toBe("h-9");
    expect(cn("size-target-desktop", "size-7")).toBe("size-7");
    expect(cn("px-gutter", "px-0")).toBe("px-0");
  });
});
