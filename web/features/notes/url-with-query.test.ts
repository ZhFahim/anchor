import { describe, expect, it } from "vitest";
import { QUERY_PARAM, urlWithQuery } from "./url-with-query";

describe("urlWithQuery", () => {
  it("adds the search and keeps the tag", () => {
    expect(urlWithQuery("/notes", "?tagId=t1", "groceries")).toBe(
      "/notes?tagId=t1&q=groceries",
    );
  });

  it("drops the search when the box is empty", () => {
    expect(urlWithQuery("/notes", "?tagId=t1&q=milk", "")).toBe(
      "/notes?tagId=t1",
    );
    expect(urlWithQuery("/archive", "?q=milk", "")).toBe("/archive");
  });

  it("drops the request to focus the box", () => {
    expect(urlWithQuery("/notes", "?search", "milk")).toBe("/notes?q=milk");
  });

  it("keeps the text exactly as typed", () => {
    const text = "a&b #c  ";
    const url = new URL(urlWithQuery("/notes", "", text), "http://x");
    expect(url.searchParams.get(QUERY_PARAM)).toBe(text);
  });
});
