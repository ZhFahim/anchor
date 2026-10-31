import { describe, expect, it } from "vitest";
import {
  checkedFoldStyles,
  checkedItemsLabel,
  findCheckedFolds,
} from "./checked-folds";

const open = "unchecked";
const checked = "checked";

describe("findCheckedFolds", () => {
  it("folds the checked items that end each checklist", () => {
    expect(
      findCheckedFolds([null, [open, open, checked, checked], null, [checked]]),
    ).toEqual([
      { block: 2, first: 3, last: 4 },
      { block: 4, first: 1, last: 1 },
    ]);
  });

  it("leaves a checklist with no checked items at its end alone", () => {
    expect(findCheckedFolds([[checked, open]])).toEqual([]);
  });

  it("treats other lists in the same block as the checklist's ends", () => {
    expect(
      findCheckedFolds([[open, checked, "bullet", checked, open, checked]]),
    ).toEqual([
      { block: 1, first: 2, last: 2 },
      { block: 1, first: 6, last: 6 },
    ]);
  });
});

describe("checkedFoldStyles", () => {
  const scope = '[data-folds="a"]';
  const folds = [{ block: 2, first: 3, last: 5 }];

  it("makes room for the row above the first checked item", () => {
    expect(checkedFoldStyles(scope, folds, false)).toBe(
      '[data-folds="a"] .ql-editor > :nth-child(2) > li:nth-child(3){margin-top:var(--fold-row)}',
    );
  });

  it("hides the checked items when folded and keeps the row's room", () => {
    const css = checkedFoldStyles(scope, folds, true);
    expect(css).toContain(
      "li:nth-child(3){margin-top:var(--fold-row);height:0",
    );
    expect(css).toContain("li:nth-child(n+4):nth-child(-n+5){display:none}");
  });

  it("names the count", () => {
    expect(checkedItemsLabel(1)).toBe("1 checked item");
    expect(checkedItemsLabel(4)).toBe("4 checked items");
  });
});
