import { describe, expect, it } from "vitest";
import { toModelContextTool, webmcpToolCatalog } from "./index";

describe("webmcp tool catalogue", () => {
  it("exposes note_search and note_get", () => {
    const names = webmcpToolCatalog.map((t) => t.name).sort();
    expect(names).toEqual(["note_get", "note_search"]);
  });

  it("maps a tool to the WebMCP registerTool shape", () => {
    const [tool] = webmcpToolCatalog;
    const mapped = toModelContextTool(tool);
    expect(mapped.name).toBe(tool.name);
    expect(mapped.inputSchema).toBe(tool.inputSchema);
    expect(mapped.annotations?.readOnlyHint).toBe(true);
    expect(typeof mapped.execute).toBe("function");
  });
});
