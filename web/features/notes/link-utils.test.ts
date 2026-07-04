import { describe, expect, it } from "vitest";
import { isLikelyUrl, linkAtIndex, normalizeUrl } from "./link-utils";
import type { QuillInstance } from "./quill";

describe("normalizeUrl", () => {
  it("keeps URLs that already have a scheme", () => {
    expect(normalizeUrl("https://example.com")).toBe("https://example.com");
    expect(normalizeUrl("mailto:me@example.com")).toBe("mailto:me@example.com");
    expect(normalizeUrl("tel:+123456")).toBe("tel:+123456");
  });

  it("prefixes bare hosts with https://", () => {
    expect(normalizeUrl("example.com")).toBe("https://example.com");
    expect(normalizeUrl("sub.example.com:8080/path?q=1")).toBe(
      "https://sub.example.com:8080/path?q=1",
    );
    expect(normalizeUrl("localhost:3000")).toBe("https://localhost:3000");
  });

  it("leaves non-URL text untouched", () => {
    expect(normalizeUrl("just some words")).toBe("just some words");
    expect(normalizeUrl("")).toBe("");
    expect(normalizeUrl("  spaced.com  ")).toBe("https://spaced.com");
  });

  it("does not treat dotted numbers as hosts", () => {
    // Pasting "3.14" into a note must not produce a link to https://3.14
    expect(normalizeUrl("3.14")).toBe("3.14");
    expect(normalizeUrl("192.168")).toBe("192.168");
    expect(normalizeUrl("1.2.3.4")).toBe("https://1.2.3.4");
  });

  it("preserves the original casing", () => {
    expect(normalizeUrl("Example.COM/Path")).toBe("https://Example.COM/Path");
    expect(normalizeUrl("HTTPS://Example.com/Path")).toBe(
      "HTTPS://Example.com/Path",
    );
  });
});

describe("isLikelyUrl", () => {
  it("accepts schemes and host-like strings", () => {
    expect(isLikelyUrl("https://example.com")).toBe(true);
    expect(isLikelyUrl("example.com/path")).toBe(true);
    expect(isLikelyUrl("localhost")).toBe(true);
  });

  it("rejects plain text, whitespace, and empty input", () => {
    expect(isLikelyUrl("hello world")).toBe(false);
    expect(isLikelyUrl("no-dots")).toBe(false);
    expect(isLikelyUrl("")).toBe(false);
    expect(isLikelyUrl("http://a b")).toBe(false);
  });

  it("rejects dotted numbers that are not full IPv4 addresses", () => {
    expect(isLikelyUrl("3.14")).toBe(false);
    expect(isLikelyUrl("192.168")).toBe(false);
    expect(isLikelyUrl("1.2.3.4")).toBe(true);
    expect(isLikelyUrl("1.2.3.4:8080/admin")).toBe(true);
  });
});

describe("linkAtIndex", () => {
  const quillWith = (ops: unknown[]) =>
    ({ getContents: () => ({ ops }) }) as unknown as QuillInstance;

  it("returns null when the index is not inside a link", () => {
    const quill = quillWith([{ insert: "plain text" }]);
    expect(linkAtIndex(quill, 3)).toBeNull();
    expect(linkAtIndex(quill, -1)).toBeNull();
    expect(linkAtIndex(quill, 100)).toBeNull();
  });

  it("resolves the boundary between plain text and a link to the link", () => {
    const quill = quillWith([
      { insert: "see " },
      { insert: "docs", attributes: { link: "https://example.com" } },
    ]);

    // Cursor exactly between "see " and "docs" (index 4).
    expect(linkAtIndex(quill, 4)).toMatchObject({
      url: "https://example.com",
      start: 4,
    });
  });

  it("finds the link op under the cursor", () => {
    const quill = quillWith([
      { insert: "see " },
      { insert: "docs", attributes: { link: "https://example.com" } },
      { insert: " for more" },
    ]);

    expect(linkAtIndex(quill, 6)).toEqual({
      url: "https://example.com",
      text: "docs",
      start: 4,
      length: 4,
    });
  });

  it("merges adjacent ops that share the same link", () => {
    // Quill splits a link across ops when part of it is bold.
    const quill = quillWith([
      { insert: "go " },
      { insert: "click", attributes: { link: "https://a.io" } },
      { insert: " here", attributes: { link: "https://a.io", bold: true } },
      { insert: " end" },
    ]);

    expect(linkAtIndex(quill, 10)).toEqual({
      url: "https://a.io",
      text: "click here",
      start: 3,
      length: 10,
    });
  });

  it("does not merge neighbouring ops linking somewhere else", () => {
    const quill = quillWith([
      { insert: "a", attributes: { link: "https://one.io" } },
      { insert: "b", attributes: { link: "https://two.io" } },
    ]);

    const hit = linkAtIndex(quill, 2);
    expect(hit?.url).toBe("https://two.io");
    expect(hit?.text).toBe("b");
  });

  it("skips embeds (images) when computing positions", () => {
    const quill = quillWith([
      { insert: { image: "data:..." } },
      { insert: "link", attributes: { link: "https://x.io" } },
    ]);

    // Embed occupies index 0; the link starts at 1.
    expect(linkAtIndex(quill, 2)).toEqual({
      url: "https://x.io",
      text: "link",
      start: 1,
      length: 4,
    });
  });
});
