"use client";

import {
  type QueryClient,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "@/components/ui/toast";
import { useSyncStatus } from "@/features/sync";
import { newId } from "@/lib/id";
import { basePath } from "@/lib/local-backend/mode";
import {
  createNote,
  flushNoteUpdate,
  getNote,
  isRetryableError,
  saveNote,
} from "../api";
import { outboxEntry } from "../outbox";
import { cacheSavedNote } from "../queries";
import { isStoredContentEmpty } from "../quill";
import {
  draftUpdate,
  flushUpdate,
  type NoteDraft,
  noteDraftsEqual,
  noteToDraft,
  rebaseDraft,
  replacesText,
  type SaveFailure,
  sameReminder,
  toReminderInput,
} from "../save-queue";
import { keepNewNote, noteSaveQueue, releaseSaveQueue } from "../save-queues";
import { draftTitle } from "../title";
import type {
  CreateNoteDto,
  Note,
  NoteReminder,
  ReminderRecurrence,
} from "../types";
import { useRefreshNotes } from "./use-refresh-notes";

const autoSaveDelayMs = 1000;
const longestSaveWaitMs = 10_000;

const conflictToastId = "note-conflict";

function getStoredNoteKey(noteId: string) {
  return `note-${noteId}`;
}

// Written by the note card so the editor can paint before the fetch lands.
function readStoredNote(noteId: string): Note | null {
  if (typeof window === "undefined") return null;

  try {
    const stored = sessionStorage.getItem(getStoredNoteKey(noteId));
    return stored ? (JSON.parse(stored) as Note) : null;
  } catch {
    return null;
  }
}

/** The note as a loaded notes list has it. */
function cachedListNote(queryClient: QueryClient, noteId: string) {
  for (const [, data] of queryClient.getQueriesData<unknown>({
    queryKey: ["notes"],
  })) {
    if (!Array.isArray(data)) continue;
    const found = (data as Note[]).find((n) => n?.id === noteId);
    if (found) return found;
  }
  return null;
}

const createFields = (id: string, draft: NoteDraft): CreateNoteDto => ({
  id,
  title: draft.title,
  content: draft.content || undefined,
  isPinned: draft.isPinned,
  background: draft.background,
  tagIds: draft.tagIds,
});

const textChanged = (draft: NoteDraft, saved: NoteDraft) =>
  draft.title !== saved.title || draft.content !== saved.content;

const sameTags = (a: string[], b: string[]) =>
  a.length === b.length && a.every((id, index) => id === b[index]);

export function useNoteEditor({
  routeId,
  onCreated,
  onOpenHistory,
}: {
  routeId: string;
  onCreated: (id: string) => void;
  onOpenHistory: () => void;
}) {
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const refreshLists = useRefreshNotes();
  const [createdId, setCreatedId] = useState<string | null>(null);
  const noteId = createdId ?? routeId;
  const isNew = noteId === "new";

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [isArchived, setIsArchived] = useState(false);
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>(() => {
    const tagIdFromUrl = searchParams.get("tagId");
    return isNew && tagIdFromUrl ? [tagIdFromUrl] : [];
  });
  const [background, setBackground] = useState<string | null>(null);
  const [reminder, setReminder] = useState<NoteReminder | null>(null);
  const [lastSaved, setLastSaved] = useState<NoteDraft | null>(null);
  const [isSavingDraft, setIsSavingDraft] = useState(false);
  const [isSaveStuck, setIsSaveStuck] = useState(false);
  const [saveFailure, setSaveFailure] = useState<SaveFailure | null>(null);
  const [historyOpen, setHistoryOpen] = useState(false);

  const titleInputRef = useRef<HTMLTextAreaElement | null>(null);
  const hydratedNoteIdRef = useRef<string | null>(null);
  const pendingCreateNoteRef = useRef<Promise<Note> | null>(null);
  const noteVersionRef = useRef<number | undefined>(undefined);
  // The reminder the server last told us about.
  const serverReminderRef = useRef<NoteReminder | null>(null);

  const replacesOtherEdit = useRef(false);
  const [newNoteId] = useState(newId);
  const queueId = isNew ? newNoteId : noteId;
  const { queue, live } = noteSaveQueue(queueId);

  // Painted before the fetch lands, and shown read-only if it can't.
  const [storedNote] = useState<Note | null>(() =>
    isNew
      ? null
      : (readStoredNote(noteId) ?? cachedListNote(queryClient, noteId)),
  );

  useEffect(() => {
    if (typeof window === "undefined" || isNew) return;
    sessionStorage.removeItem(getStoredNoteKey(noteId));
  }, [isNew, noteId]);

  const {
    data: noteFromApi,
    isLoading,
    isPlaceholderData,
    error: noteError,
    refetch: refetchNote,
  } = useQuery({
    queryKey: ["notes", noteId],
    queryFn: () => getNote(noteId),
    enabled: !isNew,
    placeholderData: storedNote ?? undefined,
    staleTime: 0,
    refetchOnMount: "always",
  });

  const online = useSyncStatus((s) => s.online);
  // A note made offline that the server doesn't have yet.
  const [madeOffline] = useState(() => !isNew && !!outboxEntry(noteId)?.create);
  // Offline, the copy kept on this device is edited; the edits go up later.
  const isOfflineCopy =
    !isNew &&
    !!storedNote &&
    (isPlaceholderData || !noteFromApi) &&
    (!online ||
      madeOffline ||
      (!!noteError && !(noteError instanceof HTTPError)));
  const note = isNew
    ? null
    : (noteFromApi ?? (isOfflineCopy ? storedNote : null));

  const isOwner = note ? note.permission === "owner" : true;
  const isViewer = note ? note.permission === "viewer" : false;
  const isEditor = note ? note.permission === "editor" : false;

  const isFrozen = !!note?.isFrozen;
  const isReadOnly = note
    ? note.state === "trashed" || isViewer || isFrozen
    : false;
  const canSaveDraft = note ? note.state !== "trashed" : true;
  const canUpload = isOwner || isEditor;

  const draft = useMemo<NoteDraft>(
    () => ({
      title: draftTitle(title),
      content,
      isPinned,
      background,
      tagIds: selectedTagIds,
      reminder,
    }),
    [title, content, isPinned, background, selectedTagIds, reminder],
  );

  const latestDraft = useRef(draft);
  latestDraft.current = draft;
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  const hasUnsavedChanges = lastSaved
    ? !noteDraftsEqual(draft, lastSaved)
    : isNew && (draft.title !== "" || !isStoredContentEmpty(content));

  const applyServerNote = useCallback(
    (serverNote: Note) => {
      const incoming = noteToDraft(serverNote);
      setTitle(incoming.title);
      setContent(incoming.content);
      setIsPinned(incoming.isPinned);
      setBackground(incoming.background);
      setReminder(incoming.reminder);
      setSelectedTagIds(incoming.tagIds);
      setLastSaved(incoming);
      noteVersionRef.current = serverNote.version;
      serverReminderRef.current = incoming.reminder;
      queue.setBaseVersion(serverNote.version);
    },
    [queue],
  );

  // Viewers can't change the text, so the server's copy always wins.
  const applyServerText = useCallback(
    (serverNote: Note) => {
      const incoming = noteToDraft(serverNote);
      setTitle(incoming.title);
      setContent(incoming.content);
      setBackground(incoming.background);
      setLastSaved((saved) =>
        saved
          ? {
              ...saved,
              title: incoming.title,
              content: incoming.content,
              background: incoming.background,
            }
          : saved,
      );
      noteVersionRef.current = serverNote.version;
      queue.setBaseVersion(serverNote.version);
    },
    [queue],
  );

  // Moves what is on screen onto a newer server copy, keeping unsaved edits.
  const rebaseOnto = useCallback(
    (serverNote: Note) => {
      const incoming = noteToDraft(serverNote);
      const base = lastSaved ?? incoming;
      const merge =
        <K extends keyof NoteDraft>(field: K) =>
        (current: NoteDraft[K]) =>
          rebaseDraft({ ...base, [field]: current }, base, incoming)[field];

      setTitle((current) => merge("title")(draftTitle(current)));
      setContent(merge("content"));
      setIsPinned(merge("isPinned"));
      setBackground(merge("background"));
      setSelectedTagIds(merge("tagIds"));
      setReminder(merge("reminder"));
      setLastSaved(incoming);
      noteVersionRef.current = serverNote.version;
      serverReminderRef.current = incoming.reminder;
    },
    [lastSaved],
  );

  const keepOtherEdit = useCallback(() => {
    replacesOtherEdit.current = true;
    toast.info(
      "This note was changed elsewhere. Your version is kept, and the other one is in History.",
      {
        id: conflictToastId,
        action: {
          label: "History",
          onClick: () => live.current.openHistory(),
        },
      },
    );
  }, [live]);

  // A new note's caret goes to its text; the editor page puts it there.

  // Fields fill once per note, so background refetches don't reset focus.
  useEffect(() => {
    if (!note || hydratedNoteIdRef.current === note.id) return;

    const hydrated = noteToDraft(note);
    // A save still on its way from an earlier visit holds newer text.
    const shown = queue.newestDraft() ?? hydrated;
    setTitle(shown.title);
    setContent(shown.content);
    setIsPinned(shown.isPinned);
    setSelectedTagIds(shown.tagIds);
    setBackground(shown.background);
    setReminder(shown.reminder);
    setLastSaved(hydrated);
    noteVersionRef.current = note.version;
    serverReminderRef.current = hydrated.reminder;
    queue.setBaseVersion(note.version);
    hydratedNoteIdRef.current = note.id;
  }, [note, queue]);

  // A reminder set elsewhere leaves the note version alone, so the rebase
  // below never sees it.
  useEffect(() => {
    if (!note || hydratedNoteIdRef.current !== note.id) return;

    const incoming = note.reminder ?? null;
    if (sameReminder(incoming, serverReminderRef.current)) return;

    const untouched = sameReminder(reminder, serverReminderRef.current);
    serverReminderRef.current = incoming;
    if (!untouched) return;

    setReminder(incoming);
    setLastSaved((saved) => (saved ? { ...saved, reminder: incoming } : saved));
  }, [note, reminder]);

  // A newer copy arrived from somewhere else: it replaces what is on screen,
  // apart from any unsaved edit, which stays and goes up next.
  useEffect(() => {
    if (!note || hydratedNoteIdRef.current !== note.id) return;

    const base = noteVersionRef.current;
    if (base !== undefined && note.version <= base) return;

    if (hasUnsavedChanges) {
      const incoming = noteToDraft(note);
      // The answer to our own save can arrive here before its response does.
      const sent = queue.sendingDraft();
      const isOwnSave =
        !!sent &&
        sent.title === incoming.title &&
        sent.content === incoming.content;
      if (!isOwnSave && replacesText(draft, lastSaved ?? incoming, incoming))
        keepOtherEdit();
      rebaseOnto(note);
      queue.setBaseVersion(note.version);
      return;
    }

    applyServerNote(note);
  }, [
    note,
    hasUnsavedChanges,
    applyServerNote,
    rebaseOnto,
    queue,
    draft,
    lastSaved,
    keepOtherEdit,
  ]);

  useEffect(() => {
    if (note) {
      setIsArchived(note.isArchived);
    }
  }, [note]);

  const createRetries = useRef(0);
  const createRetryTimer = useRef<number | undefined>(undefined);
  const createdNote = useRef<Note | null>(null);
  const createWaiters = useRef<((note: Note) => void)[]>([]);
  const createMutation = useMutation({
    mutationFn: (data: CreateNoteDto) => createNote(data),
    // Offline, the create fails at once instead of pausing.
    networkMode: "always",
    onSuccess: (newNote) => {
      createRetries.current = 0;
      setIsSaveStuck(false);
      // Switching the query to the new id must find the note already there,
      // or the editor would unmount for a loading state.
      queryClient.setQueryData(["notes", newNote.id], newNote);
      for (const [key, list] of queryClient.getQueriesData<Note[]>({
        queryKey: ["notes"],
      })) {
        const tagId = key[1];
        if (
          Array.isArray(list) &&
          (tagId === null || newNote.tagIds?.includes(tagId as string))
        )
          queryClient.setQueryData(key, [
            newNote,
            ...list.filter((note) => note.id !== newNote.id),
          ]);
      }
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });

      // Anything typed while the note was being created stays and goes up next.
      hydratedNoteIdRef.current = newNote.id;
      noteVersionRef.current = newNote.version;
      serverReminderRef.current = newNote.reminder ?? null;
      queue.setBaseVersion(newNote.version);
      createdNote.current = newNote;
      window.clearTimeout(createRetryTimer.current);
      for (const resolve of createWaiters.current.splice(0)) resolve(newNote);
      useSyncStatus.getState().setWaiting("new", 0);
      keepNewNote(newNote.id, null);
      if (!mounted.current) {
        const latest = latestDraft.current;
        if (!noteDraftsEqual(latest, noteToDraft(newNote)))
          void saveNote(
            newNote.id,
            draftUpdate(latest, null, {
              isViewer: false,
              baseVersion: newNote.version,
            }),
          );
        return;
      }
      setLastSaved(noteToDraft(newNote));
      setCreatedId(newNote.id);
      onCreated(newNote.id);
      window.history.replaceState(null, "", `${basePath}/notes/${newNote.id}`);
    },
    onError: (error) => {
      if (isRetryableError(error)) {
        setIsSaveStuck(true);
        const delay = Math.min(30_000, 2000 * 2 ** createRetries.current++);
        window.clearTimeout(createRetryTimer.current);
        createRetryTimer.current = window.setTimeout(() => {
          createRetryTimer.current = undefined;
          live.current.save();
        }, delay);
        return;
      }
      setSaveFailure({ status: "failed", httpStatus: null, retryable: false });
    },
  });

  const createAsync = createMutation.mutateAsync;
  const createNewNote = useCallback(() => {
    if (!isNew) {
      return Promise.resolve(note);
    }

    if (createdNote.current) {
      return Promise.resolve(createdNote.current);
    }

    if (pendingCreateNoteRef.current) {
      return pendingCreateNoteRef.current;
    }

    const createPromise = createAsync(
      createFields(newNoteId, latestDraft.current),
    );

    pendingCreateNoteRef.current = createPromise.finally(() => {
      pendingCreateNoteRef.current = null;
    });

    return pendingCreateNoteRef.current;
  }, [createAsync, isNew, newNoteId, note]);

  const wasViewer = useRef(isViewer);
  useEffect(() => {
    const lostEditRights = !wasViewer.current && isViewer;
    wasViewer.current = isViewer;
    if (lostEditRights && lastSaved && textChanged(draft, lastSaved))
      setSaveFailure({ status: "failed", httpStatus: 403, retryable: false });
  }, [isViewer, draft, lastSaved]);

  const handleSaved = useCallback(
    (savedDraft: NoteDraft, savedNote: Note) => {
      if (isViewer && lastSaved && textChanged(savedDraft, lastSaved)) {
        setSaveFailure({ status: "failed", httpStatus: 403, retryable: false });
        return;
      }
      useSyncStatus.getState().setWaiting(noteId, 0);
      replacesOtherEdit.current = false;
      setLastSaved(savedDraft);
      noteVersionRef.current = savedNote.version;
      if (isViewer) {
        applyServerText(savedNote);
      }
      serverReminderRef.current = savedNote.reminder ?? null;
      setIsSaveStuck(false);
      setSaveFailure(null);
      cacheSavedNote(queryClient, savedNote);
      queryClient.invalidateQueries({
        queryKey: ["notes"],
        predicate: (query) => query.queryKey[1] !== noteId,
      });
      if (!lastSaved || !sameTags(savedDraft.tagIds, lastSaved.tagIds))
        queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    [applyServerText, isViewer, lastSaved, noteId, queryClient],
  );

  const handleConflict = useCallback(
    (serverNote: Note, canRetry: boolean): NoteDraft | null => {
      const serverWins =
        !canRetry ||
        serverNote.permission === "viewer" ||
        serverNote.state !== "active";

      if (serverWins) {
        applyServerNote(serverNote);
        toast.info("This note was changed elsewhere and has been reloaded.", {
          id: conflictToastId,
        });
        return null;
      }

      const isNewer = serverNote.version > (noteVersionRef.current ?? 0);
      const incoming =
        isNewer || !lastSaved ? noteToDraft(serverNote) : lastSaved;
      const base = lastSaved ?? incoming;
      const next = rebaseDraft(draft, base, incoming);
      if (isNewer) rebaseOnto(serverNote);
      if (replacesText(next, base, incoming)) keepOtherEdit();
      return noteDraftsEqual(next, incoming) ? null : next;
    },
    [applyServerNote, draft, keepOtherEdit, lastSaved, rebaseOnto],
  );

  const dirtySince = useRef<number | null>(null);
  const pushDraft = useCallback(() => {
    const isWaitingForCreate = isNew && createWaiters.current.length > 0;
    if (!canSaveDraft || (!hasUnsavedChanges && !isWaitingForCreate)) return;
    dirtySince.current = Date.now();

    if (isNew) {
      // Failures are handled by the create mutation.
      if (createRetryTimer.current === undefined)
        createNewNote().catch(() => {});
      return;
    }

    queue.push(draft);
  }, [canSaveDraft, createNewNote, draft, hasUnsavedChanges, isNew, queue]);

  // A new note is kept on the device until the server has it, so a reload
  // while offline doesn't lose it.
  useEffect(() => {
    if (!isNew || createdNote.current || !canSaveDraft) return;
    const timer = window.setTimeout(
      () => keepNewNote(newNoteId, hasUnsavedChanges ? draft : null),
      300,
    );
    return () => window.clearTimeout(timer);
  }, [isNew, canSaveDraft, hasUnsavedChanges, draft, newNoteId]);

  const save = useCallback(() => {
    if (saveFailure && !saveFailure.retryable) return;
    pushDraft();
  }, [pushDraft, saveFailure]);

  const retrySave = () => {
    setSaveFailure(null);
    pushDraft();
  };

  const flushEdits = async () => {
    live.current.save();
    await queue.settled();
  };

  const flush = useCallback(() => {
    if (isNew) {
      if (canSaveDraft && hasUnsavedChanges && !createdNote.current)
        createNote(createFields(newNoteId, draft)).catch(() => {});
      return;
    }
    if (!canSaveDraft || !hasUnsavedChanges || !lastSaved) return;

    flushNoteUpdate(noteId, {
      ...flushUpdate(draft, lastSaved, serverReminderRef.current, { isViewer }),
      ...(replacesOtherEdit.current ? { replacesOtherEdit: true } : {}),
    });
  }, [
    canSaveDraft,
    draft,
    hasUnsavedChanges,
    isNew,
    isViewer,
    lastSaved,
    newNoteId,
    noteId,
  ]);

  useEffect(() => {
    live.current = {
      buildUpdate: (draftToSend, baseVersion) => ({
        ...draftUpdate(draftToSend, serverReminderRef.current, {
          isViewer,
          baseVersion,
        }),
        ...(replacesOtherEdit.current ? { replacesOtherEdit: true } : {}),
      }),
      onSaved: handleSaved,
      onConflict: (serverNote, _draft, canRetry) =>
        handleConflict(serverNote, canRetry),
      base: () => lastSaved,
      onFailed: (failure) => {
        setIsSaveStuck(failure.retryable);
        setSaveFailure(failure);
      },
      onBusyChange: setIsSavingDraft,
      save,
      retryCreate: () => {
        if (!isNew) return;
        window.clearTimeout(createRetryTimer.current);
        createRetryTimer.current = undefined;
        save();
      },
      flush,
      openHistory: onOpenHistory,
    };
  });

  const ensureNoteIdForAttachmentUpload = useCallback(async () => {
    if (isReadOnly || !canUpload) {
      return null;
    }

    if (!isNew) {
      return noteId;
    }

    try {
      const newNote = await createNewNote();
      return newNote?.id ?? null;
    } catch (error) {
      if (!isRetryableError(error)) throw error;
      const newNote = await new Promise<Note>((resolve) =>
        createWaiters.current.push(resolve),
      );
      return newNote.id;
    }
  }, [canUpload, createNewNote, isNew, isReadOnly, noteId]);

  useEffect(() => {
    if (!hasUnsavedChanges || !canSaveDraft) {
      dirtySince.current = null;
      return;
    }
    dirtySince.current ??= Date.now();
    const waited = Date.now() - dirtySince.current;
    const timeout = setTimeout(
      save,
      Math.max(0, Math.min(autoSaveDelayMs, longestSaveWaitMs - waited)),
    );

    return () => clearTimeout(timeout);
  }, [canSaveDraft, hasUnsavedChanges, save]);

  useEffect(() => {
    const retryOnline = () => {
      setIsSaveStuck(false);
      live.current.retryCreate();
    };
    const flush = () => live.current.flush();
    const saveWhenHidden = () => {
      if (document.visibilityState === "hidden") live.current.save();
    };

    window.addEventListener("pagehide", flush);
    window.addEventListener("online", retryOnline);
    document.addEventListener("visibilitychange", saveWhenHidden);

    return () => {
      window.removeEventListener("pagehide", flush);
      window.removeEventListener("online", retryOnline);
      document.removeEventListener("visibilitychange", saveWhenHidden);
      live.current.save();
      releaseSaveQueue(queueId);
    };
  }, [live, queueId]);

  // Closing now would drop the text the retries have not managed to send.
  const unsavedAtRisk = (isSaveStuck || !!saveFailure) && hasUnsavedChanges;
  useEffect(() => {
    if (!unsavedAtRisk) return;

    const warn = (event: BeforeUnloadEvent) => event.preventDefault();
    window.addEventListener("beforeunload", warn);

    return () => window.removeEventListener("beforeunload", warn);
  }, [unsavedAtRisk]);

  const setWaiting = useSyncStatus((st) => st.setWaiting);
  useEffect(() => {
    setWaiting(noteId, isSaveStuck && hasUnsavedChanges ? 1 : 0);
  }, [setWaiting, noteId, isSaveStuck, hasUnsavedChanges]);

  const changeReminder = (
    next: { remindAt: string; recurrence: ReminderRecurrence } | null,
  ) => {
    setReminder(next ? { ...next, version: reminder?.version ?? 0 } : null);
    if (next || !reminder) return;
    const removed = reminder;
    const removedFromId = isNew ? null : noteId;
    toast.success("Reminder removed", {
      undo: () => {
        if (mounted.current) setReminder(removed);
        else if (removedFromId)
          void saveNote(removedFromId, {
            reminder: toReminderInput(removed),
          }).then((outcome) => {
            if (outcome.status === "saved") refreshLists();
            else toast.error("Couldn’t undo that");
          });
      },
    });
  };

  return {
    noteId,
    isNew,
    /** The id a new note is made with. */
    newNoteId,
    note,
    isLoading,
    noteError,
    refetchNote,
    isOwner,
    isViewer,
    isReadOnly,
    isFrozen,
    isOfflineCopy,
    canUpload,
    title,
    setTitle,
    content,
    setContent,
    isPinned,
    setIsPinned,
    isArchived,
    setIsArchived,
    selectedTagIds,
    setSelectedTagIds,
    background,
    setBackground,
    reminder,
    changeReminder,
    hasUnsavedChanges,
    isSavingDraft,
    isSaveStuck,
    saveFailure,
    isCreating: createMutation.isPending,
    save,
    retrySave,
    flushEdits,
    applyServerNote,
    ensureNoteIdForAttachmentUpload,
    historyOpen,
    setHistoryOpen,
    titleInputRef,
  };
}
