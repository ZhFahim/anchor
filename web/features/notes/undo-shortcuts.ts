export type UndoRedoAction = "undo" | "redo";

/** Inputs and contenteditable hosts handle the undo shortcut themselves. */
const OWN_UNDO_SELECTOR =
  'input, textarea, select, [contenteditable="true"], [contenteditable=""], [contenteditable="plaintext-only"]';

/** Maps a keydown to the undo/redo action it requests, if any. */
export function undoRedoActionForKeyEvent(e: {
  key: string;
  metaKey: boolean;
  ctrlKey: boolean;
  shiftKey: boolean;
  altKey: boolean;
}): UndoRedoAction | null {
  if (e.altKey || (!e.metaKey && !e.ctrlKey)) return null;
  const key = e.key.toLowerCase();
  if (key === "z") return e.shiftKey ? "redo" : "undo";
  if (key === "y" && !e.shiftKey) return "redo";
  return null;
}

/** True when the event target handles the undo shortcut itself. */
export function targetHandlesOwnUndo(target: EventTarget | null): boolean {
  const el = target as { closest?: (selector: string) => unknown } | null;
  if (!el || typeof el.closest !== "function") return false;
  return el.closest(OWN_UNDO_SELECTOR) != null;
}
