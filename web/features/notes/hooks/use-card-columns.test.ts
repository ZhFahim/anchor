import { describe, expect, it } from "vitest";
import { columnCount, pickColumn } from "./use-card-columns";

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

describe("columnCount", () => {
  const count = (width: number) => columnCount(width, 16, 200, 300);

  it("keeps four columns on laptop boards", () => {
    expect([964, 1124, 1196].map(count)).toEqual([4, 4, 4]);
  });

  it("adds columns on wide boards instead of stretching cards", () => {
    expect([1364, 1604, 2244].map(count)).toEqual([5, 6, 8]);
  });

  it("keeps cards 200 to 300 wide on any board from three columns up", () => {
    for (let width = 632; width <= 4000; width += 7) {
      const columns = count(width);
      const card = (width - 16 * (columns - 1)) / columns;
      expect(card).toBeGreaterThanOrEqual(200);
      expect(card).toBeLessThanOrEqual(300);
    }
  });

  it("takes slightly wider cards over ones narrower than 200", () => {
    expect(count(620)).toBe(2);
  });

  it("gives a box narrower than one card a single column", () => {
    expect(count(150)).toBe(1);
  });
});
