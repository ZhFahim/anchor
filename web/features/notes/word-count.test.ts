import { describe, expect, it } from "vitest";
import { countWords } from "./word-count";

describe("countWords", () => {
  it("counts words between spaces", () => {
    expect(countWords("Design review, Sep 26")).toBe(4);
    expect(countWords("  to-do   don't\n1. ")).toBe(3);
    expect(countWords("")).toBe(0);
  });

  it("skips dashes, arrows and emoji standing alone", () => {
    expect(countWords("Lisbon — Porto → Faro 🎉")).toBe(3);
  });

  it("counts each Chinese or Japanese character", () => {
    expect(countWords("你好世界")).toBe(4);
    expect(countWords("iPhone用のメモ")).toBe(5);
  });

  it("counts other scripts by their spaces", () => {
    expect(countWords("Привет мир")).toBe(2);
    expect(countWords("안녕하세요 세계")).toBe(2);
  });
});
