"use client";

import { useQueryClient } from "@tanstack/react-query";
import type { RefObject } from "react";
import { toast } from "@/components/ui/toast";
import { getNote, saveNote } from "../api";
import type { RichTextEditorHandle, UndoableEdit } from "../components/editor";
import { cacheSavedNote } from "../queries";
import { savesSettled } from "../save-queues";
import { useRefreshNotes } from "./use-refresh-notes";

const ACTIONS = {
  uncheck: {
    apply: (editor: RichTextEditorHandle) => editor.uncheckAll(),
    message: (count: number) =>
      count === 1 ? "Item unchecked" : `${count} items unchecked`,
  },
  delete: {
    apply: (editor: RichTextEditorHandle) => editor.deleteChecked(),
    message: (count: number) =>
      count === 1 ? "Checked item deleted" : `${count} checked items deleted`,
  },
};

export interface ChecklistActions {
  getCounts: () => { items: number; checked: number } | null;
  uncheckAll: () => void;
  deleteChecked: () => void;
}

export function useChecklistActions(
  noteId: string,
  editorRef: RefObject<RichTextEditorHandle | null>,
): ChecklistActions {
  const queryClient = useQueryClient();
  const refreshLists = useRefreshNotes();

  const undoInSavedNote = async (edit: UndoableEdit) => {
    try {
      await savesSettled(noteId);
      const note = await getNote(noteId);
      const content = edit.undoInContent(note.content);
      if (content === null) throw new Error();
      const outcome = await saveNote(noteId, {
        content,
        baseVersion: note.version,
      });
      if (outcome.status !== "saved") throw new Error();
      cacheSavedNote(queryClient, outcome.note);
      void refreshLists();
    } catch {
      toast.error("Couldn’t undo that");
    }
  };

  const run = (action: (typeof ACTIONS)[keyof typeof ACTIONS]) => {
    const editor = editorRef.current;
    const edit = editor && action.apply(editor);
    if (!edit) return;
    toast.success(action.message(edit.itemCount), {
      undo: () => {
        if (!edit.undo() && edit.isClosed) void undoInSavedNote(edit);
      },
      onClose: () => edit.dispose(),
    });
  };

  return {
    getCounts: () => editorRef.current?.checklistCount() ?? null,
    uncheckAll: () => run(ACTIONS.uncheck),
    deleteChecked: () => run(ACTIONS.delete),
  };
}
