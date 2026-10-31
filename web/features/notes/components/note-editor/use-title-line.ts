"use client";

import type * as React from "react";
import { type RefObject, useRef } from "react";
import {
  type UndoRedoAction,
  undoRedoActionForKeyEvent,
} from "../../undo-shortcuts";
import type { FirstLineHandlers, RichTextEditorHandle } from "../editor";

interface TitleLineEdit {
  kind: "split" | "join";
  titleBefore: string;
  titleAfter: string;
  /** The text's undo (or, once undone, redo) depth right after it. */
  depth: number;
  hasTitleChange: boolean;
  hasTextChange: boolean;
}

const LINE_BREAKS = /\s*[\r\n]\s*/g;

export const withoutLineBreaks = (title: string) =>
  title.replace(LINE_BREAKS, " ");

export function useTitleLine(
  titleRef: RefObject<HTMLTextAreaElement | null>,
  editorRef: RefObject<RichTextEditorHandle | null>,
  onTitleChange: (title: string) => void,
) {
  const lastEdit = useRef<TitleLineEdit | null>(null);
  const undoneEdit = useRef<TitleLineEdit | null>(null);

  // Setting a field's value clears its Undo; execCommand keeps it.
  const editTitle = (start: number, end: number, text: string) => {
    const input = titleRef.current;
    if (!input || (!text && start === end)) return;
    input.focus();
    input.setSelectionRange(start, end);
    if (!document.execCommand(text ? "insertText" : "delete", false, text))
      onTitleChange(
        input.value.slice(0, start) + text + input.value.slice(end),
      );
  };

  const placeCaretInTitle = (at: number) => {
    const input = titleRef.current;
    input?.focus();
    input?.setSelectionRange(at, at);
  };

  const record = (
    kind: TitleLineEdit["kind"],
    titleBefore: string,
    hasTitleChange: boolean,
    hasTextChange: boolean,
  ) => {
    lastEdit.current =
      hasTitleChange || hasTextChange
        ? {
            kind,
            titleBefore,
            titleAfter: titleRef.current?.value ?? "",
            depth: editorRef.current?.historyDepth().undo ?? 0,
            hasTitleChange,
            hasTextChange,
          }
        : null;
    undoneEdit.current = null;
  };

  const split = () => {
    const input = titleRef.current;
    const editor = editorRef.current;
    if (!input || !editor) return;
    const { value, selectionStart, selectionEnd } = input;
    const hasTitleChange = selectionStart < value.length;
    if (hasTitleChange) editTitle(selectionStart, value.length, "");
    const hasTextChange = editor.addFirstLine(value.slice(selectionEnd));
    record("split", value, hasTitleChange, hasTextChange);
  };

  const join = (words: string, hasRemovedLine: boolean) => {
    const titleBefore = titleRef.current?.value ?? "";
    if (words) editTitle(titleBefore.length, titleBefore.length, words);
    placeCaretInTitle(titleBefore.length);
    record("join", titleBefore, !!words, hasRemovedLine);
  };

  const undoOrRedo = (action: UndoRedoAction) => {
    const input = titleRef.current;
    const editor = editorRef.current;
    const isUndo = action === "undo";
    const edit = isUndo ? lastEdit.current : undoneEdit.current;
    if (!input || !editor || !edit) return false;
    const depthOf = (depth: { undo: number; redo: number }) =>
      isUndo ? depth.redo : depth.undo;
    const from = isUndo ? edit.titleAfter : edit.titleBefore;
    const to = isUndo ? edit.titleBefore : edit.titleAfter;
    const depthBefore = editor.historyDepth();
    if (
      input.value !== from ||
      (isUndo ? depthBefore.undo : depthBefore.redo) !== edit.depth
    ) {
      lastEdit.current = undoneEdit.current = null;
      return false;
    }
    if (edit.hasTextChange) editor.undoOrRedoText(action);
    if (edit.hasTitleChange) {
      input.focus();
      document.execCommand(action);
      if (input.value !== to) onTitleChange(to);
    }
    const isCaretInTitle = (edit.kind === "split") === isUndo;
    if (isCaretInTitle)
      placeCaretInTitle(
        edit.kind === "split"
          ? edit.titleAfter.length
          : edit.titleBefore.length,
      );
    else editor.setSelection(0, 0);
    const next = { ...edit, depth: depthOf(editor.historyDepth()) };
    lastEdit.current = isUndo ? null : next;
    undoneEdit.current = isUndo ? next : null;
    return true;
  };

  const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    const input = e.currentTarget;
    if (e.nativeEvent.isComposing || e.keyCode === 229) return;
    const action = undoRedoActionForKeyEvent(e);
    if (action) {
      if (undoOrRedo(action)) e.preventDefault();
      return;
    }
    if (e.key === "Enter" && !e.metaKey && !e.ctrlKey && !e.altKey) {
      e.preventDefault();
      split();
      return;
    }
    const isAtEnd =
      input.selectionStart === input.value.length &&
      input.selectionEnd === input.value.length;
    if (
      (e.key === "ArrowDown" || e.key === "ArrowRight") &&
      isAtEnd &&
      !e.shiftKey &&
      !e.metaKey &&
      !e.ctrlKey &&
      !e.altKey
    ) {
      e.preventDefault();
      editorRef.current?.setSelection(0, 0);
    }
  };

  const onPaste = (e: React.ClipboardEvent<HTMLTextAreaElement>) => {
    const text = e.clipboardData.getData("text/plain");
    if (!/[\r\n]/.test(text)) return;
    e.preventDefault();
    const input = e.currentTarget;
    editTitle(
      input.selectionStart,
      input.selectionEnd,
      withoutLineBreaks(text.replace(/^\s*[\r\n]+|[\r\n]+\s*$/g, "")),
    );
  };

  const firstLine: FirstLineHandlers = {
    onJoin: join,
    onLeave: () => placeCaretInTitle(titleRef.current?.value.length ?? 0),
    onUndoRedo: undoOrRedo,
  };

  return { onKeyDown, onPaste, firstLine };
}
