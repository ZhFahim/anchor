import { afterEach, describe, expect, it, vi } from "vitest";
import { getSafeRedirectUrl } from "./redirect";

const LEAVING = [
  "/\\evil.com",
  "//evil.com",
  "https://evil.com",
  "https://evil.com/notes",
  "javascript:alert(1)",
];

describe("getSafeRedirectUrl in the browser", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  const inBrowser = () =>
    vi.stubGlobal("window", { location: { origin: "https://anchor.test" } });

  it.each(LEAVING)("turns down %s", (redirect) => {
    inBrowser();
    expect(getSafeRedirectUrl(redirect, "/notes")).toBe("/notes");
  });

  it("keeps an encoded backslash as part of the path on this site", () => {
    inBrowser();
    expect(getSafeRedirectUrl("/%5Cevil.com")).toBe("/%5Cevil.com");
  });

  it("keeps a path with its search and hash", () => {
    inBrowser();
    expect(getSafeRedirectUrl("/notes/abc?x=1#y")).toBe("/notes/abc?x=1#y");
  });

  it("turns an address on this site into its path", () => {
    inBrowser();
    expect(getSafeRedirectUrl("https://anchor.test/notes/abc?x=1#y")).toBe(
      "/notes/abc?x=1#y",
    );
  });

  it("uses the fallback when there is nothing to return to", () => {
    inBrowser();
    expect(getSafeRedirectUrl(null, "/notes")).toBe("/notes");
    expect(getSafeRedirectUrl("  ", "/notes")).toBe("/notes");
  });
});

describe("getSafeRedirectUrl on the server", () => {
  it.each([...LEAVING, "/notes abc", "notes"])("turns down %s", (redirect) => {
    expect(getSafeRedirectUrl(redirect, "/notes")).toBe("/notes");
  });

  it("keeps a plain path", () => {
    expect(getSafeRedirectUrl("/notes/abc?x=1#y")).toBe("/notes/abc?x=1#y");
    expect(getSafeRedirectUrl("/%5Cevil.com")).toBe("/%5Cevil.com");
  });
});
