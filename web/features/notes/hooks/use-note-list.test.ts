import { createElement } from "react";
import { renderToString } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Note } from "../types";
import { type NoteList, useNoteList } from "./use-note-list";

vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams(window.location.search),
}));

const notes: Note[] = ["A", "B"].map((title) => ({
  id: title.toLowerCase(),
  title,
  isPinned: false,
  isArchived: false,
  state: "active",
  version: 1,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
  userId: "u",
  permission: "owner",
}));

function renderList() {
  let list: NoteList | undefined;
  function List() {
    list = useNoteList(notes);
    return null;
  }
  renderToString(createElement(List));
  return list!;
}

const replaceState = vi.fn((_state, _unused, href: string | URL) => {
  browser.location = new URL(href, browser.location.href);
});
const browser = {
  location: new URL("https://anchor.test/notes"),
  history: { replaceState },
};

beforeEach(() => {
  replaceState.mockClear();
  browser.location = new URL("https://anchor.test/notes");
  vi.stubGlobal("window", browser);
});

afterEach(() => vi.unstubAllGlobals());

describe("note list search history", () => {
  it("restores the query and filtered notes after visiting a result", () => {
    renderList().setQuery("A");
    const listUrl = browser.location.href;
    browser.location = new URL("https://anchor.test/notes/a");
    browser.location = new URL(listUrl);

    const returned = renderList();
    expect(returned.query).toBe("A");
    expect(returned.visible.map((note) => note.id)).toEqual(["a"]);
  });

  it("reads the current URL on each visit, including back and forward", () => {
    for (const query of ["A", "B", "", "B"]) {
      browser.location = new URL(
        `https://anchor.test/notes?${new URLSearchParams({ q: query })}`,
      );
      const list = renderList();
      expect(list.query).toBe(query);
      expect(list.visible.map((note) => note.id).sort()).toEqual(
        query ? [query.toLowerCase()] : ["a", "b"],
      );
    }
    expect(replaceState).not.toHaveBeenCalled();
  });

  it("preserves the tag filter, focus flag, other parameters and hash", () => {
    browser.location = new URL(
      "https://anchor.test/notes?tagId=t&search&other=keep#results",
    );
    renderList().setQuery("A");

    const params = browser.location.searchParams;
    expect(params.get("q")).toBe("A");
    expect(params.get("tagId")).toBe("t");
    expect(params.has("search")).toBe(true);
    expect(params.get("other")).toBe("keep");
    expect(browser.location.hash).toBe("#results");
  });

  it("round-trips spaces, non-ASCII text and query delimiters", () => {
    const query = " café & 日本語 + #? ";
    renderList().setQuery(query);
    expect(renderList().query).toBe(query);
    expect(browser.location.searchParams.get("q")).toBe(query);
  });

  it.each([
    ["/notes?q=A", "/notes"],
    ["/notes?tagId=t&q=A#results", "/notes?tagId=t#results"],
  ])("clears the search from %s", (before, after) => {
    browser.location = new URL(before, "https://anchor.test");
    renderList().setQuery("");

    expect(browser.location.href).toBe(`https://anchor.test${after}`);
    const cleared = renderList();
    expect(cleared.query).toBe("");
    expect(cleared.visible).toHaveLength(2);
  });

  it("replaces the current history entry while typing", () => {
    const list = renderList();
    list.setQuery("A");
    list.setQuery("AB");

    expect(replaceState).toHaveBeenCalledTimes(2);
    expect(renderList().query).toBe("AB");
  });
});
