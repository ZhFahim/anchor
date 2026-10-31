import { describe, expect, it, vi } from "vitest";
import { ChecklistEdit } from "./checklist-edit";

describe("ChecklistEdit", () => {
  it("restores a live bulk action only once", () => {
    const restore = vi.fn(() => true);
    const edit = new ChecklistEdit(2, restore, "before", "after");
    expect(edit.itemCount).toBe(2);
    expect(edit.undo()).toBe(true);
    expect(edit.undo()).toBe(false);
    expect(restore).toHaveBeenCalledTimes(1);
  });

  it("does not claim a failed live undo succeeded", () => {
    const edit = new ChecklistEdit(1, () => false, "before", "after");
    expect(edit.undo()).toBe(false);
  });

  it("can undo after closing if the saved content is unchanged", () => {
    const edit = new ChecklistEdit(1, () => true, "before", "after");
    edit.closeChecklist("after");
    expect(edit.isLive).toBe(false);
    expect(edit.isClosed).toBe(true);
    expect(edit.undo()).toBe(false);
    expect(edit.undoInContent("after")).toBe("before");
    expect(edit.undoInContent("after")).toBeNull();
  });

  it("preserves changes made before or after closing", () => {
    const edit = new ChecklistEdit(1, () => true, "before", "after");
    edit.closeChecklist("later typing");
    expect(edit.undoInContent("later typing")).toBeNull();
    const other = new ChecklistEdit(1, () => true, "before", "after");
    other.closeChecklist("after");
    expect(other.undoInContent("remote edit")).toBeNull();
  });

  it("disposes without restoring anything", () => {
    const edit = new ChecklistEdit(1, () => true, "before", "after");
    edit.dispose();
    edit.closeChecklist("after");
    expect(edit.undo()).toBe(false);
    expect(edit.undoInContent("after")).toBeNull();
  });
});
