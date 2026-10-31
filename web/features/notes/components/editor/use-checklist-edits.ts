"use client";

import Delta from "quill-delta";
import { type RefObject, useCallback, useEffect, useMemo, useRef } from "react";
import type { QuillDelta, QuillInstance } from "../../quill";
import {
  buildDeleteCheckedDelta,
  buildUncheckAllDelta,
  countChecklistItems,
} from "../../quill-checklist";
import { UndoableEdit } from "./undoable-edit";

export function useChecklistEdits({
  getQuill,
  readOnly,
  contentsRef,
  onBeforeEdit,
}: {
  getQuill: () => QuillInstance | null;
  readOnly: boolean;
  contentsRef: RefObject<QuillDelta>;
  onBeforeEdit: () => void;
}) {
  const editsRef = useRef(new Set<UndoableEdit>());
  const isApplyingRef = useRef(false);

  useEffect(() => {
    const edits = editsRef.current;
    return () => {
      for (const edit of edits) edit.close(contentsRef.current);
      edits.clear();
    };
  }, [contentsRef]);

  const apply = useCallback(
    (build: (contents: QuillDelta) => QuillDelta | null) => {
      const quill = readOnly ? null : getQuill();
      const contents = quill?.getContents() as QuillDelta | undefined;
      const change = contents && build(contents);
      if (!quill || !contents || !change) return null;
      onBeforeEdit();
      quill.history.cutoff();
      isApplyingRef.current = true;
      try {
        quill.updateContents(change, "user");
      } finally {
        isApplyingRef.current = false;
      }
      quill.history.cutoff();
      const edit = new UndoableEdit(
        quill,
        countChecklistItems(contents).checked,
        new Delta(change.ops as never),
        new Delta(contents.ops as never),
        quill.history.stack.undo.length,
      );
      editsRef.current.add(edit);
      return edit;
    },
    [getQuill, onBeforeEdit, readOnly],
  );

  /** Call with each change to the text. */
  const follow = useCallback((change: QuillDelta) => {
    for (const edit of editsRef.current) {
      if (!edit.isLive) editsRef.current.delete(edit);
      else if (!isApplyingRef.current) edit.follow(change);
    }
  }, []);

  const isApplying = useCallback(() => isApplyingRef.current, []);

  return useMemo(
    () => ({
      count: () => {
        const quill = getQuill();
        return quill
          ? countChecklistItems(quill.getContents() as QuillDelta)
          : null;
      },
      uncheckAll: () => apply(buildUncheckAllDelta),
      deleteChecked: () => apply(buildDeleteCheckedDelta),
      follow,
      isApplying,
    }),
    [apply, follow, getQuill, isApplying],
  );
}
