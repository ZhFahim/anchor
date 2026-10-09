import { describe, expect, it } from "vitest";
import { pickColumn } from "./use-masonry";

describe("pickColumn", () => {
  it("picks the shortest column", () => {
    expect(pickColumn([300, 120, 200], 16)).toBe(1);
  });

  it("treats columns within the tolerance as level and takes the leftmost", () => {
    expect(pickColumn([272, 270, 272], 16)).toBe(0);
  });

  it("skips a column that is taller by more than the tolerance", () => {
    expect(pickColumn([300, 270, 280], 16)).toBe(1);
  });

  it("takes the first of equal columns", () => {
    expect(pickColumn([0, 0, 0, 0], 16)).toBe(0);
  });
});
