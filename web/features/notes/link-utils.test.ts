import { describe, expect, it } from "vitest";
import { fakeQuill } from "./fixtures/fake-quill";
import {
  isLikelyUrl,
  LINK_PROTOCOLS,
  linkAtIndex,
  linkTypedAddress,
  normalizeUrl,
  siteAndPath,
  typedAddressLink,
} from "./link-utils";
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

describe("siteAndPath", () => {
  it("shows the site and the path", () => {
    expect(siteAndPath("https://www.visitlisboa.com/en/sights")).toBe(
      "visitlisboa.com/en/sights",
    );
    expect(siteAndPath("http://example.com")).toBe("example.com");
    expect(siteAndPath("ftp://files.example.com/pub/")).toBe(
      "files.example.com/pub",
    );
  });

  it("drops the trailing slash, the query and the fragment", () => {
    expect(
      siteAndPath("https://www.visitlisboa.com/en/sights/?ref=note#top"),
    ).toBe("visitlisboa.com/en/sights");
    expect(siteAndPath("https://example.com/?q=1")).toBe("example.com");
  });

  it("keeps the port and leaves out a sign-in", () => {
    expect(siteAndPath("http://me:secret@localhost:3000/notes/")).toBe(
      "localhost:3000/notes",
    );
  });

  it("reads addresses typed without a scheme", () => {
    expect(siteAndPath("www.example.com/menu")).toBe("example.com/menu");
    expect(siteAndPath("example.com")).toBe("example.com");
  });

  it("shows readable paths", () => {
    expect(siteAndPath("https://example.com/caf%C3%A9/a%20b")).toBe(
      "example.com/café/a b",
    );
    expect(siteAndPath("https://example.com/%E0%A4%A")).toBe(
      "example.com/%E0%A4%A",
    );
  });

  it("shows the address of other kinds of links", () => {
    expect(siteAndPath("mailto:maya@example.com?subject=Hi")).toBe(
      "maya@example.com",
    );
    expect(siteAndPath("tel:+351210000000")).toBe("+351210000000");
    expect(siteAndPath("file:///Users/maya/list.txt")).toBe(
      "/Users/maya/list.txt",
    );
  });

  it("gives back what it can't read", () => {
    expect(siteAndPath("not a link")).toBe("not a link");
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

describe("LINK_PROTOCOLS", () => {
  it("names every scheme the link box accepts, without its colon", () => {
    expect(LINK_PROTOCOLS).toEqual([
      "http",
      "https",
      "mailto",
      "tel",
      "sms",
      "ftp",
      "ftps",
      "file",
      "geo",
    ]);
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

describe("typedAddressLink", () => {
  it("links web addresses with a scheme or www, and emails", () => {
    expect(typedAddressLink("https://example.com/a?b=1")).toBe(
      "https://example.com/a?b=1",
    );
    expect(typedAddressLink("www.example.com")).toBe("https://www.example.com");
    expect(typedAddressLink("me.name+tag@mail.example.org")).toBe(
      "mailto:me.name+tag@mail.example.org",
    );
  });

  it("leaves plain words, file names and bare schemes alone", () => {
    for (const word of [
      "example.com",
      "notes.md",
      "e.g.",
      "3.14",
      "https://",
      "me@host",
    ])
      expect(typedAddressLink(word)).toBeNull();
  });
});

describe("linkTypedAddress", () => {
  const typedAfter = (text: string, typed: string) => {
    const fake = fakeQuill([{ insert: `${text}${typed}\n` }], text.length + 1);
    linkTypedAddress(fake.quill, {
      ops: [{ retain: text.length }, { insert: typed }],
    });
    return fake.ops();
  };

  it("links the address before a typed space or line break", () => {
    expect(typedAfter("see www.example.com", " ")).toEqual([
      { insert: "see " },
      {
        insert: "www.example.com",
        attributes: { link: "https://www.example.com" },
      },
      { insert: " \n" },
    ]);
    expect(typedAfter("me@example.com", "\n")).toEqual([
      {
        insert: "me@example.com",
        attributes: { link: "mailto:me@example.com" },
      },
      { insert: "\n\n" },
    ]);
  });

  it("leaves the brackets and punctuation around it out", () => {
    expect(typedAfter("(https://example.com/a).", " ")).toEqual([
      { insert: "(" },
      {
        insert: "https://example.com/a",
        attributes: { link: "https://example.com/a" },
      },
      { insert: "). \n" },
    ]);
    expect(typedAfter("https://en.wikipedia.org/wiki/A_(b)", " ")[0]).toEqual({
      insert: "https://en.wikipedia.org/wiki/A_(b)",
      attributes: { link: "https://en.wikipedia.org/wiki/A_(b)" },
    });
  });

  it("leaves plain words, code and links alone", () => {
    expect(typedAfter("notes.md", " ")).toEqual([{ insert: "notes.md \n" }]);
    const code = fakeQuill(
      [
        { insert: "www.example.com " },
        { insert: "\n", attributes: { "code-block": "plain" } },
      ],
      16,
    );
    linkTypedAddress(code.quill, { ops: [{ retain: 15 }, { insert: " " }] });
    expect(code.ops()[0]).toEqual({ insert: "www.example.com " });
    const linked = fakeQuill(
      [
        {
          insert: "www.example.com",
          attributes: { link: "https://other.org" },
        },
        { insert: " \n" },
      ],
      16,
    );
    linkTypedAddress(linked.quill, { ops: [{ retain: 15 }, { insert: " " }] });
    expect(linked.ops()[0].attributes).toEqual({ link: "https://other.org" });
  });

  it("links only after a single typed space or line break", () => {
    expect(typedAfter("www.example.com", "  ")).toEqual([
      { insert: "www.example.com  \n" },
    ]);
  });
});
