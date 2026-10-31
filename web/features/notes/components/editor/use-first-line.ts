"use client";

import { useCallback, useEffect, useRef } from "react";
import type { QuillInstance } from "../../quill";
import {
  type UndoRedoAction,
  undoRedoActionForKeyEvent,
} from "../../undo-shortcuts";
import { isSlashMenuOpen } from "./slash-menu";

export interface FirstLineHandlers {
  onJoin: (words: string, hasRemovedLine: boolean) => void;
  onLeave: () => void;
  /** True when handled. */
  onUndoRedo: (action: UndoRedoAction) => boolean;
}

const FIRST_LINE_SLACK = 2;

export function useFirstLine({
  containerEl,
  getQuill,
  readOnly,
  handlers,
}: {
  containerEl: HTMLElement | null;
  getQuill: () => QuillInstance | null;
  readOnly: boolean;
  handlers?: FirstLineHandlers;
}) {
  const handlersRef = useRef(handlers);
  handlersRef.current = handlers;

  useEffect(() => {
    const el = containerEl;
    if (!el || readOnly) return;
    const onKey = (e: KeyboardEvent) => {
      const quill = getQuill();
      const firstLine = handlersRef.current;
      if (
        !quill ||
        !firstLine ||
        e.defaultPrevented ||
        e.isComposing ||
        !quill.root.contains(e.target as Node)
      )
        return;
      const handled = () => {
        e.preventDefault();
        e.stopPropagation();
      };
      const action = undoRedoActionForKeyEvent(e);
      if (action) {
        if (firstLine.onUndoRedo(action)) handled();
        return;
      }
      if (e.shiftKey) return;
      const selection = quill.getSelection();
      if (!selection || selection.length) return;
      const hasModifier = e.metaKey || e.ctrlKey || e.altKey;
      if (
        !hasModifier &&
        !isSlashMenuOpen(quill.root) &&
        (e.key === "ArrowUp" || (e.key === "ArrowLeft" && !selection.index))
      ) {
        const caret = quill.getBounds(selection.index);
        const first = quill.getBounds(0);
        if (!caret || !first || caret.top > first.top + FIRST_LINE_SLACK)
          return;
        handled();
        firstLine.onLeave();
        return;
      }
      if (e.key !== "Backspace" || selection.index) return;
      const [line] = quill.getLine(0);
      if (!line || Object.keys(line.formats()).length) return;
      const length = line.length() - 1;
      const isText = quill
        .getContents(0, length)
        .ops.every((op) => typeof op.insert === "string");
      if (!isText) return;
      handled();
      const words = quill.getText(0, length);
      const isOnlyLine = quill.getLength() === line.length();
      const removed = isOnlyLine ? length : length + 1;
      if (removed) {
        quill.history.cutoff();
        quill.updateContents({ ops: [{ delete: removed }] }, "user");
        quill.history.cutoff();
      }
      firstLine.onJoin(words, removed > 0);
    };
    el.addEventListener("keydown", onKey, true);
    return () => el.removeEventListener("keydown", onKey, true);
  }, [containerEl, getQuill, readOnly]);

  return useCallback(
    (action: UndoRedoAction) => {
      if (!handlersRef.current?.onUndoRedo(action))
        getQuill()?.history[action]();
    },
    [getQuill],
  );
}
