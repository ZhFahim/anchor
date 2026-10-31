import { describe, expect, it, vi } from "vitest";
import { navigateChecklist } from "./checklist-navigation";

function input(value: string, selectionStart = 0) {
  return { value, selectionStart, focus: vi.fn(), setSelectionRange: vi.fn() };
}
function key(key: string, overrides = {}) {
  return {
    key,
    altKey: false,
    ctrlKey: false,
    metaKey: false,
    shiftKey: false,
    isComposing: false,
    preventDefault: vi.fn(),
    ...overrides,
  };
}

describe("checklist keyboard navigation", () => {
  it("moves down and up while keeping the cursor column", () => {
    const first = input("First task", 3);
    const second = input("Second task", 3);
    navigateChecklist(key("ArrowDown"), [first, second], first);
    expect(second.focus).toHaveBeenCalledOnce();
    expect(second.setSelectionRange).toHaveBeenCalledWith(3, 3);
    navigateChecklist(key("ArrowUp"), [first, second], second);
    expect(first.setSelectionRange).toHaveBeenCalledWith(3, 3);
  });

  it("clamps the column for shorter and empty tasks", () => {
    const first = input("Long task", 8);
    const short = input("Hi");
    const empty = input("");
    navigateChecklist(key("ArrowDown"), [first, short], first);
    expect(short.setSelectionRange).toHaveBeenCalledWith(2, 2);
    navigateChecklist(key("ArrowDown"), [first, empty], first);
    expect(empty.setSelectionRange).toHaveBeenCalledWith(0, 0);
  });

  it("stays in place at the first and last task", () => {
    const only = input("Task", 2);
    for (const direction of ["ArrowUp", "ArrowDown"]) {
      const event = key(direction);
      navigateChecklist(event, [only], only);
      expect(event.preventDefault).toHaveBeenCalledOnce();
    }
    expect(only.focus).not.toHaveBeenCalled();
  });

  it("uses visible display order, including expanded completed tasks", () => {
    const active = input("Active", 2);
    const completed = input("Completed");
    navigateChecklist(key("ArrowDown"), [active], active);
    expect(completed.focus).not.toHaveBeenCalled();
    navigateChecklist(key("ArrowDown"), [active, completed], active);
    expect(completed.setSelectionRange).toHaveBeenCalledWith(2, 2);
  });

  it("leaves modified arrows, composition and other keys untouched", () => {
    const first = input("First");
    const second = input("Second");
    for (const override of [
      { altKey: true },
      { ctrlKey: true },
      { metaKey: true },
      { shiftKey: true },
      { isComposing: true },
    ]) {
      const event = key("ArrowDown", override);
      navigateChecklist(event, [first, second], first);
      expect(event.preventDefault).not.toHaveBeenCalled();
    }
    navigateChecklist(key("ArrowLeft"), [first, second], first);
    expect(second.focus).not.toHaveBeenCalled();
  });
});
