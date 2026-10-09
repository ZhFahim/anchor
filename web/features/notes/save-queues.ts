import { saveNote } from "./api";
import {
  createNoteSaveQueue,
  draftUpdate,
  type NoteDraft,
  type NoteSaveQueue,
  type SaveFailure,
} from "./save-queue";
import type { Note, UpdateNoteDto } from "./types";

interface EditorLink {
  buildUpdate: (draft: NoteDraft, baseVersion?: number) => UpdateNoteDto;
  onSaved: (draft: NoteDraft, note: Note) => void;
  onConflict: (serverNote: Note, canRetry: boolean) => NoteDraft | null;
  onFailed: (failure: SaveFailure) => void;
  onBusyChange: (busy: boolean) => void;
  save: () => void;
  retryCreate: () => void;
  flush: () => void;
  openHistory: () => void;
}

const unlinkedEditor: EditorLink = {
  buildUpdate: (draft, baseVersion) =>
    draftUpdate(draft, null, { isViewer: false, baseVersion }),
  onSaved: () => {},
  onConflict: () => null,
  onFailed: () => {},
  onBusyChange: () => {},
  save: () => {},
  retryCreate: () => {},
  flush: () => {},
  openHistory: () => {},
};

const saveQueues = new Map<
  string,
  { queue: NoteSaveQueue; live: { current: EditorLink } }
>();

/** One save queue per note, kept across visits while it has text to send. */
export function noteSaveQueue(noteId: string) {
  let entry = saveQueues.get(noteId);
  if (!entry) {
    const live = { current: unlinkedEditor };
    const queue = createNoteSaveQueue({
      save: (draft, baseVersion) =>
        saveNote(noteId, live.current.buildUpdate(draft, baseVersion)),
      onSaved: (draft, note) => live.current.onSaved(draft, note),
      onConflict: (serverNote, _draft, canRetry) =>
        live.current.onConflict(serverNote, canRetry),
      onFailed: (failure) => live.current.onFailed(failure),
      onBusyChange: (busy) => live.current.onBusyChange(busy),
    });
    entry = { queue, live };
    saveQueues.set(noteId, entry);
  }
  return entry;
}

export function releaseSaveQueue(noteId: string) {
  const entry = saveQueues.get(noteId);
  if (!entry) return;
  const link = entry.live.current;
  void entry.queue.settled().then(() => {
    if (
      saveQueues.get(noteId) === entry &&
      entry.live.current === link &&
      !entry.queue.newestDraft()
    )
      saveQueues.delete(noteId);
  });
}

if (typeof window !== "undefined")
  window.addEventListener("online", () => {
    for (const { queue } of saveQueues.values()) queue.retryNow();
  });
