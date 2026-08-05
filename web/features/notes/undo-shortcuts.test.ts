import { describe, expect, it } from "vitest";
import {
  targetHandlesOwnUndo,
  undoRedoActionForKeyEvent,
} from "./undo-shortcuts";

function keyEvent(
  overrides: Partial<Parameters<typeof undoRedoActionForKeyEvent>[0]>,
) {
  return {
    key: "z",
    metaKey: false,
    ctrlKey: false,
    shiftKey: false,
    altKey: false,
    ...overrides,
  };
}

describe("undoRedoActionForKeyEvent", () => {
  it("matches undo on Ctrl+Z and Cmd+Z", () => {
    expect(undoRedoActionForKeyEvent(keyEvent({ ctrlKey: true }))).toBe("undo");
    expect(undoRedoActionForKeyEvent(keyEvent({ metaKey: true }))).toBe("undo");
  });

  it("matches redo on Shift+Ctrl/Cmd+Z and Ctrl+Y", () => {
    expect(
      undoRedoActionForKeyEvent(
        keyEvent({ key: "Z", ctrlKey: true, shiftKey: true }),
      ),
    ).toBe("redo");
    expect(
      undoRedoActionForKeyEvent(
        keyEvent({ key: "Z", metaKey: true, shiftKey: true }),
      ),
    ).toBe("redo");
    expect(
      undoRedoActionForKeyEvent(keyEvent({ key: "y", ctrlKey: true })),
    ).toBe("redo");
  });

  it("ignores plain keys, Alt combos, and unrelated shortcuts", () => {
    expect(undoRedoActionForKeyEvent(keyEvent({}))).toBeNull();
    expect(
      undoRedoActionForKeyEvent(keyEvent({ ctrlKey: true, altKey: true })),
    ).toBeNull();
    expect(
      undoRedoActionForKeyEvent(keyEvent({ key: "a", ctrlKey: true })),
    ).toBeNull();
    expect(
      undoRedoActionForKeyEvent(
        keyEvent({ key: "y", ctrlKey: true, shiftKey: true }),
      ),
    ).toBeNull();
  });
});

describe("targetHandlesOwnUndo", () => {
  it("is false for null and non-element targets (window, document)", () => {
    expect(targetHandlesOwnUndo(null)).toBe(false);
    expect(targetHandlesOwnUndo({} as EventTarget)).toBe(false);
  });

  it("defers to inputs and contenteditable hosts", () => {
    let seenSelector = "";
    const insideEditor = {
      closest: (selector: string) => {
        seenSelector = selector;
        return {};
      },
    };
    expect(targetHandlesOwnUndo(insideEditor as unknown as EventTarget)).toBe(
      true,
    );
    for (const part of [
      "input",
      "textarea",
      "select",
      '[contenteditable="true"]',
    ]) {
      expect(seenSelector).toContain(part);
    }
  });

  it("claims plain page elements", () => {
    const plain = { closest: () => null };
    expect(targetHandlesOwnUndo(plain as unknown as EventTarget)).toBe(false);
  });
});
