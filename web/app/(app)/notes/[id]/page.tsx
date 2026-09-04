"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { useAuth } from "@/features/auth";
import type {
  ConflictResolution,
  CreateNoteDto,
  Note,
  NoteDraft,
  NoteReminder,
  NoteSaveQueue,
  SaveFailure,
} from "@/features/notes";
import {
  ArchiveDialog,
  archiveNote,
  createNote,
  createNoteSaveQueue,
  DeleteDialog,
  deleteNote,
  flushNoteUpdate,
  getNote,
  isStoredContentEmpty,
  NoteBackground,
  NoteEditorContent,
  NoteEditorHeader,
  NoteHistorySheet,
  noteDraftsEqual,
  noteToDraft,
  PermanentDeleteDialog,
  permanentDeleteNote,
  ReadOnlyBanner,
  RestoreDialog,
  reminderUpdate,
  restoreNote,
  ShareDialog,
  sameReminder,
  saveNote,
  unarchiveNote,
} from "@/features/notes";
import type { RichTextEditorHandle } from "@/features/notes/components/editor";

const autoSaveDelayMs = 1000;

const conflictToastId = "note-conflict";
const saveErrorToastId = "note-save-error";

function saveFailureMessage(failure: SaveFailure): string {
  if (failure.retryable) {
    return "Can't reach the server. Still trying to save.";
  }

  if (failure.httpStatus === 403 || failure.httpStatus === 404) {
    return "This note is no longer available to edit";
  }

  return "Failed to save note";
}

type PendingFocusRestore =
  | {
      target: "title";
      selectionStart: number;
      selectionEnd: number;
    }
  | {
      target: "content";
      index?: number;
      length?: number;
    };

function getFocusRestoreStorageKey(noteId: string) {
  return `note-focus-restore-${noteId}`;
}

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

export default function NoteEditorPage() {
  const { user } = useAuth();
  const params = useParams();
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const noteId = params.id as string;
  const isNew = noteId === "new";
  const tagIdFromUrl = searchParams.get("tagId");

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [isArchived, setIsArchived] = useState(false);
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [background, setBackground] = useState<string | null>(null);
  const [reminder, setReminder] = useState<NoteReminder | null>(null);
  const [lastSaved, setLastSaved] = useState<NoteDraft | null>(null);
  const [isSavingDraft, setIsSavingDraft] = useState(false);
  const [isSaveStuck, setIsSaveStuck] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [archiveDialogOpen, setArchiveDialogOpen] = useState(false);
  const [restoreDialogOpen, setRestoreDialogOpen] = useState(false);
  const [permanentDeleteDialogOpen, setPermanentDeleteDialogOpen] =
    useState(false);
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [historyOpen, setHistoryOpen] = useState(false);

  const restoreFocusFrameRef = useRef<number | null>(null);
  const titleInputRef = useRef<HTMLInputElement | null>(null);
  const contentEditorRef = useRef<RichTextEditorHandle | null>(null);
  const hydratedNoteIdRef = useRef<string | null>(null);
  const initializedNewNoteRef = useRef(false);
  const autoFocusedNewNoteRef = useRef(false);
  const pendingFocusRestoreRef = useRef<PendingFocusRestore | null>(null);
  const pendingCreateNoteRef = useRef<Promise<Note> | null>(null);
  const noteVersionRef = useRef<number | undefined>(undefined);
  // The reminder the server last told us about.
  const serverReminderRef = useRef<NoteReminder | null>(null);

  // The queue outlives every render and reaches the current handlers here.
  const live = useRef({
    noteId,
    onSaved: (_draft: NoteDraft, _note: Note) => {},
    onConflict: (_serverNote: Note, _canRetry: boolean) =>
      "adopt" as ConflictResolution,
    save: () => {},
    flush: () => {},
  });

  const queueRef = useRef<NoteSaveQueue | null>(null);
  queueRef.current ??= createNoteSaveQueue({
    save: (draft, baseVersion) =>
      saveNote(live.current.noteId, {
        ...draft,
        reminder: reminderUpdate(draft.reminder, serverReminderRef.current),
        baseVersion,
      }),
    onSaved: (draft, note) => live.current.onSaved(draft, note),
    onConflict: (serverNote, _draft, canRetry) =>
      live.current.onConflict(serverNote, canRetry),
    onFailed: (failure) => {
      setIsSaveStuck(failure.retryable);
      toast.error(saveFailureMessage(failure), {
        id: saveErrorToastId,
        duration: failure.retryable ? Number.POSITIVE_INFINITY : undefined,
      });
    },
    onBusyChange: setIsSavingDraft,
  });
  const queue = queueRef.current;

  const [storedNote] = useState<Note | null>(() =>
    isNew ? null : readStoredNote(noteId),
  );

  useEffect(() => {
    if (typeof window === "undefined" || isNew) return;
    sessionStorage.removeItem(getStoredNoteKey(noteId));
  }, [isNew, noteId]);

  const {
    data: noteFromApi,
    isLoading,
    refetch: refetchNote,
  } = useQuery({
    queryKey: ["notes", noteId],
    queryFn: () => getNote(noteId),
    enabled: !isNew,
    placeholderData: storedNote ?? undefined,
    staleTime: 0,
    refetchOnMount: "always",
  });

  const note = isNew ? null : (noteFromApi ?? null);

  // Check permissions
  const isOwner = note ? note.permission === "owner" : true;
  const isViewer = note ? note.permission === "viewer" : false;
  const isEditor = note ? note.permission === "editor" : false;

  // Check if note is read-only (trashed notes or viewers are read-only)
  const isReadOnly = note ? note.state === "trashed" || isViewer : false;
  const canUpload = isOwner || isEditor;

  const draft = useMemo<NoteDraft>(
    () => ({
      // Blank stays blank; cards render the "Untitled" placeholder.
      title: title.trim(),
      content,
      isPinned,
      background,
      tagIds: selectedTagIds,
      reminder,
    }),
    [title, content, isPinned, background, selectedTagIds, reminder],
  );

  const hasUnsavedChanges = lastSaved
    ? !noteDraftsEqual(draft, lastSaved)
    : isNew && (draft.title !== "" || !isStoredContentEmpty(content));

  const capturePendingFocusRestore =
    useCallback((): PendingFocusRestore | null => {
      const titleInput = titleInputRef.current;
      if (titleInput && document.activeElement === titleInput) {
        const fallbackPosition = titleInput.value.length;
        return {
          target: "title",
          selectionStart: titleInput.selectionStart ?? fallbackPosition,
          selectionEnd: titleInput.selectionEnd ?? fallbackPosition,
        };
      }

      const editorSelection = contentEditorRef.current?.getSelection();
      if (editorSelection) {
        return {
          target: "content",
          index: editorSelection.index,
          length: editorSelection.length,
        };
      }

      const activeElement = document.activeElement;
      if (
        activeElement instanceof HTMLElement &&
        activeElement.closest(".ql-editor")
      ) {
        return { target: "content" };
      }

      return null;
    }, []);

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

  // Initialize brand-new note state once per /new session.
  useEffect(() => {
    if (!isNew) {
      initializedNewNoteRef.current = false;
      autoFocusedNewNoteRef.current = false;
      return;
    }

    if (initializedNewNoteRef.current) return;

    initializedNewNoteRef.current = true;
    hydratedNoteIdRef.current = null;
    noteVersionRef.current = undefined;
    pendingFocusRestoreRef.current = null;
    setLastSaved(null);
    setTitle("");
    setContent("");
    setIsPinned(false);
    setIsArchived(false);
    setBackground(null);
    setReminder(null);
    serverReminderRef.current = null;
    setSelectedTagIds(tagIdFromUrl ? [tagIdFromUrl] : []);
  }, [isNew, tagIdFromUrl]);

  useEffect(() => {
    if (
      typeof window === "undefined" ||
      !isNew ||
      autoFocusedNewNoteRef.current
    )
      return;

    let frameId: number | null = null;

    const focusTitle = () => {
      const activeElement = document.activeElement;
      const hasInteractiveFocus =
        activeElement instanceof HTMLElement &&
        activeElement !== document.body &&
        (activeElement.tagName === "INPUT" ||
          activeElement.tagName === "TEXTAREA" ||
          activeElement.isContentEditable ||
          activeElement.closest(".ql-editor") !== null);

      if (hasInteractiveFocus) {
        autoFocusedNewNoteRef.current = true;
        return;
      }

      const titleInput = titleInputRef.current;
      if (!titleInput) return;

      titleInput.focus();
      const cursorPosition = titleInput.value.length;
      titleInput.setSelectionRange(cursorPosition, cursorPosition);
      autoFocusedNewNoteRef.current = true;
    };

    frameId = window.requestAnimationFrame(focusTitle);

    return () => {
      if (frameId !== null) {
        window.cancelAnimationFrame(frameId);
      }
    };
  }, [isNew]);

  // Initialize editor fields once per note id so background refetches don't reset focus.
  useEffect(() => {
    if (!note || hydratedNoteIdRef.current === note.id) return;

    const hydrated = noteToDraft(note);
    setTitle(hydrated.title);
    setContent(hydrated.content);
    setIsPinned(hydrated.isPinned);
    setSelectedTagIds(hydrated.tagIds);
    setBackground(hydrated.background);
    setReminder(hydrated.reminder);
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
  // unless there is an unsaved edit, which is re-based onto it and goes up next.
  useEffect(() => {
    if (!note || hydratedNoteIdRef.current !== note.id) return;

    const base = noteVersionRef.current;
    if (base !== undefined && note.version <= base) return;

    if (hasUnsavedChanges) {
      noteVersionRef.current = note.version;
      queue.setBaseVersion(note.version);
      return;
    }

    applyServerNote(note);
  }, [note, hasUnsavedChanges, applyServerNote, queue]);

  // Keep lightweight metadata in sync with fresh query data.
  useEffect(() => {
    if (note) {
      setIsArchived(note.isArchived);
    }
  }, [note]);

  // Create note mutation
  const createMutation = useMutation({
    mutationFn: (data: CreateNoteDto) => createNote(data),
    onSuccess: (newNote) => {
      // Pre-populate the cache with the new note data before navigation
      // This prevents the loading state when the component remounts with the new URL
      queryClient.setQueryData(["notes", newNote.id], newNote);
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });

      // Anything typed while the note was being created stays and goes up next.
      hydratedNoteIdRef.current = newNote.id;
      noteVersionRef.current = newNote.version;
      serverReminderRef.current = newNote.reminder ?? null;
      queue.setBaseVersion(newNote.version);
      setLastSaved(noteToDraft(newNote));

      if (typeof window !== "undefined" && pendingFocusRestoreRef.current) {
        sessionStorage.setItem(
          getFocusRestoreStorageKey(newNote.id),
          JSON.stringify(pendingFocusRestoreRef.current),
        );
      }
      toast.success("Note created");
      router.replace(`/notes/${newNote.id}`);
    },
    onError: () => {
      pendingFocusRestoreRef.current = null;
      toast.error("Failed to create note");
    },
  });

  const createNewNote = useCallback(
    (focusRestore: PendingFocusRestore | null) => {
      if (!isNew) {
        return Promise.resolve(note);
      }

      if (pendingCreateNoteRef.current) {
        return pendingCreateNoteRef.current;
      }

      pendingFocusRestoreRef.current = focusRestore;

      const createPromise = createMutation.mutateAsync({
        title: draft.title,
        content: draft.content || undefined,
        isPinned: draft.isPinned,
        background: draft.background,
        tagIds: draft.tagIds,
      });

      pendingCreateNoteRef.current = createPromise.finally(() => {
        pendingCreateNoteRef.current = null;
      });

      return pendingCreateNoteRef.current;
    },
    [createMutation, draft, isNew, note],
  );

  const handleSaved = useCallback(
    (savedDraft: NoteDraft, savedNote: Note) => {
      setLastSaved(savedDraft);
      noteVersionRef.current = savedNote.version;
      serverReminderRef.current = savedNote.reminder ?? null;
      setIsSaveStuck(false);
      toast.dismiss(saveErrorToastId);
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    [queryClient],
  );

  const handleConflict = useCallback(
    (serverNote: Note, canRetry: boolean): ConflictResolution => {
      const serverWins =
        !canRetry ||
        serverNote.permission === "viewer" ||
        serverNote.state !== "active";

      if (serverWins) {
        applyServerNote(serverNote);
        toast.info("This note was changed elsewhere, so it has been reloaded", {
          id: conflictToastId,
        });
        return "adopt";
      }

      noteVersionRef.current = serverNote.version;
      toast.info(
        "This note was changed elsewhere. Your version is kept and the other one is in its history.",
        { id: conflictToastId },
      );
      return "retry";
    },
    [applyServerNote],
  );

  const save = useCallback(() => {
    if (isReadOnly || !hasUnsavedChanges) return;

    if (isNew) {
      void createNewNote(capturePendingFocusRestore());
      return;
    }

    pendingFocusRestoreRef.current = null;
    queue.push(draft);
  }, [
    capturePendingFocusRestore,
    createNewNote,
    draft,
    hasUnsavedChanges,
    isNew,
    isReadOnly,
    queue,
  ]);

  const flush = useCallback(() => {
    if (isNew || isReadOnly || !hasUnsavedChanges) return;

    flushNoteUpdate(noteId, {
      ...draft,
      reminder: reminderUpdate(draft.reminder, serverReminderRef.current),
    });
  }, [draft, hasUnsavedChanges, isNew, isReadOnly, noteId]);

  useEffect(() => {
    live.current = {
      noteId,
      onSaved: handleSaved,
      onConflict: handleConflict,
      save,
      flush,
    };
  });

  const ensureNoteIdForAttachmentUpload = useCallback(async () => {
    if (isReadOnly || !canUpload) {
      return null;
    }

    if (!isNew) {
      return noteId;
    }

    const newNote = await createNewNote(null);
    return newNote?.id ?? null;
  }, [canUpload, createNewNote, isNew, isReadOnly, noteId]);

  useEffect(() => {
    if (!hasUnsavedChanges || isReadOnly) return;

    const timeout = setTimeout(save, autoSaveDelayMs);

    return () => clearTimeout(timeout);
  }, [hasUnsavedChanges, isReadOnly, save]);

  useEffect(() => {
    const save = () => live.current.save();
    const flush = () => live.current.flush();
    const saveWhenHidden = () => {
      if (document.visibilityState === "hidden") live.current.save();
    };

    window.addEventListener("pagehide", flush);
    window.addEventListener("online", save);
    document.addEventListener("visibilitychange", saveWhenHidden);

    return () => {
      window.removeEventListener("pagehide", flush);
      window.removeEventListener("online", save);
      document.removeEventListener("visibilitychange", saveWhenHidden);
      live.current.save();
      if (restoreFocusFrameRef.current !== null) {
        window.cancelAnimationFrame(restoreFocusFrameRef.current);
      }
    };
  }, []);

  // Closing now would drop the text the retries have not managed to send.
  useEffect(() => {
    if (!isSaveStuck) return;

    const warn = (event: BeforeUnloadEvent) => event.preventDefault();
    window.addEventListener("beforeunload", warn);

    return () => window.removeEventListener("beforeunload", warn);
  }, [isSaveStuck]);

  useEffect(() => {
    if (typeof window === "undefined" || isNew || !note) return;
    if (hydratedNoteIdRef.current !== note.id) return;

    const storageKey = getFocusRestoreStorageKey(note.id);
    const storedRestore = sessionStorage.getItem(storageKey);
    if (!storedRestore) return;

    let restoreTarget: PendingFocusRestore;
    try {
      restoreTarget = JSON.parse(storedRestore) as PendingFocusRestore;
    } catch {
      sessionStorage.removeItem(storageKey);
      return;
    }

    let attemptCount = 0;

    const restoreFocus = () => {
      attemptCount += 1;

      if (restoreTarget.target === "title") {
        const input = titleInputRef.current;
        if (input) {
          const maxPosition = input.value.length;
          const selectionStart = Math.min(
            restoreTarget.selectionStart,
            maxPosition,
          );
          const selectionEnd = Math.min(
            restoreTarget.selectionEnd,
            maxPosition,
          );
          input.focus();
          input.setSelectionRange(selectionStart, selectionEnd);
          sessionStorage.removeItem(storageKey);
          restoreFocusFrameRef.current = null;
          return;
        }
      } else {
        const editor = contentEditorRef.current;
        if (editor) {
          editor.focus();
          if (
            typeof restoreTarget.index === "number" &&
            typeof restoreTarget.length === "number"
          ) {
            editor.setSelection(restoreTarget.index, restoreTarget.length);
          }
          sessionStorage.removeItem(storageKey);
          restoreFocusFrameRef.current = null;
          return;
        }
      }

      if (attemptCount >= 10) {
        sessionStorage.removeItem(storageKey);
        restoreFocusFrameRef.current = null;
        return;
      }

      restoreFocusFrameRef.current = window.requestAnimationFrame(restoreFocus);
    };

    restoreFocusFrameRef.current = window.requestAnimationFrame(restoreFocus);

    return () => {
      if (restoreFocusFrameRef.current !== null) {
        window.cancelAnimationFrame(restoreFocusFrameRef.current);
        restoreFocusFrameRef.current = null;
      }
    };
  }, [isNew, note]);

  // Delete note mutation
  const deleteMutation = useMutation({
    mutationFn: () => deleteNote(noteId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      toast.success("Note moved to trash");
      router.back();
    },
    onError: () => {
      toast.error("Failed to delete note");
    },
  });

  // Archive note mutation
  const archiveMutation = useMutation({
    mutationFn: () => archiveNote(noteId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "archive"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setIsArchived(true);
      toast.success("Note archived");
      router.back();
    },
    onError: () => {
      toast.error("Failed to archive note");
    },
  });

  // Unarchive note mutation
  const unarchiveMutation = useMutation({
    mutationFn: () => unarchiveNote(noteId),
    onSuccess: async () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "archive"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setIsArchived(false);
      await refetchNote();
      toast.success("Note unarchived");
    },
    onError: () => {
      toast.error("Failed to unarchive note");
    },
  });

  // Restore note mutation (for trashed notes)
  const restoreMutation = useMutation({
    mutationFn: () => restoreNote(noteId),
    onSuccess: async () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "trash"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      await refetchNote();
      toast.success("Note restored");
    },
    onError: () => {
      toast.error("Failed to restore note");
    },
  });

  // Permanent delete mutation (for trashed notes)
  const permanentDeleteMutation = useMutation({
    mutationFn: () => permanentDeleteNote(noteId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "trash"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      toast.success("Note permanently deleted");
      router.back();
    },
    onError: () => {
      toast.error("Failed to delete note");
    },
  });

  const handleBack = () => {
    save();
    router.back();
  };

  const openHistory = () => {
    save();
    setHistoryOpen(true);
  };

  const handleRestored = (restored: Note) => {
    applyServerNote(restored);
  };

  const togglePin = () => {
    setIsPinned((prev) => !prev);
  };

  // Only show loading if we have nothing to render yet
  if (isLoading && !isNew) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 animate-spin text-accent" />
          <span className="text-sm text-muted-foreground">Loading note...</span>
        </div>
      </div>
    );
  }

  const isSaving = isSavingDraft || createMutation.isPending;
  const isSaved = !hasUnsavedChanges && !isSaving && !isNew;

  return (
    <div className="min-h-screen flex flex-col relative">
      <NoteBackground styleId={background} className="fixed inset-0 z-0" />

      {/* Header */}
      <NoteEditorHeader
        isNew={isNew}
        isReadOnly={isReadOnly}
        isPinned={isPinned}
        isArchived={isArchived}
        background={background}
        reminder={reminder}
        isSaving={isSaving}
        hasUnsavedChanges={hasUnsavedChanges}
        isSaved={isSaved}
        isOwner={isOwner}
        permission={note?.permission || "owner"}
        isTrashed={note?.state === "trashed"}
        hasShares={(note?.shareIds?.length ?? 0) > 0}
        onBack={handleBack}
        onTogglePin={togglePin}
        onBackgroundChange={setBackground}
        onReminderChange={setReminder}
        onArchiveClick={() => setArchiveDialogOpen(true)}
        onDeleteClick={() => setDeleteDialogOpen(true)}
        onRestoreClick={() => setRestoreDialogOpen(true)}
        onPermanentDeleteClick={() => setPermanentDeleteDialogOpen(true)}
        onShareClick={!isNew ? () => setShareDialogOpen(true) : undefined}
        onHistoryClick={!isNew && !isViewer ? openHistory : undefined}
        restorePending={restoreMutation.isPending}
        permanentDeletePending={permanentDeleteMutation.isPending}
      />

      {/* Read-only Banner */}
      {isReadOnly && (
        <ReadOnlyBanner
          message={
            note?.state === "trashed"
              ? "This note is in trash and cannot be edited. Restore it to make changes."
              : "You have viewer access. Only the owner can edit this note."
          }
        />
      )}

      {/* Content */}
      <NoteEditorContent
        noteId={!isNew ? noteId : undefined}
        canUpload={canUpload}
        isOwner={isOwner}
        currentUserId={user?.id ?? null}
        title={title}
        content={content}
        selectedTagIds={selectedTagIds}
        attachmentCount={note?.attachmentCount}
        isReadOnly={isReadOnly}
        isTrashed={note?.state === "trashed"}
        titleInputRef={titleInputRef}
        contentEditorRef={contentEditorRef}
        onEnsureNoteIdForAttachmentUpload={ensureNoteIdForAttachmentUpload}
        onTitleChange={setTitle}
        onContentChange={setContent}
        onTagsChange={setSelectedTagIds}
      />

      {/* Dialogs */}
      <ArchiveDialog
        open={archiveDialogOpen}
        onOpenChange={setArchiveDialogOpen}
        isArchived={isArchived}
        onConfirm={() => {
          if (isArchived) {
            unarchiveMutation.mutate();
          } else {
            archiveMutation.mutate();
          }
          setArchiveDialogOpen(false);
        }}
        isPending={archiveMutation.isPending || unarchiveMutation.isPending}
      />

      <RestoreDialog
        open={restoreDialogOpen}
        onOpenChange={setRestoreDialogOpen}
        onConfirm={() => {
          restoreMutation.mutate();
          setRestoreDialogOpen(false);
        }}
        isPending={restoreMutation.isPending}
      />

      <DeleteDialog
        open={deleteDialogOpen}
        onOpenChange={setDeleteDialogOpen}
        onConfirm={() => {
          deleteMutation.mutate();
          setDeleteDialogOpen(false);
        }}
        isPending={deleteMutation.isPending}
      />

      {!isNew && (
        <ShareDialog
          open={shareDialogOpen}
          onOpenChange={setShareDialogOpen}
          noteId={noteId}
        />
      )}

      {!isNew && (
        <NoteHistorySheet
          open={historyOpen}
          onOpenChange={setHistoryOpen}
          noteId={noteId}
          note={note}
          currentUserId={user?.id ?? null}
          isSaving={isSaving || hasUnsavedChanges}
          onRestored={handleRestored}
        />
      )}

      <PermanentDeleteDialog
        open={permanentDeleteDialogOpen}
        onOpenChange={setPermanentDeleteDialogOpen}
        onConfirm={() => {
          permanentDeleteMutation.mutate();
          setPermanentDeleteDialogOpen(false);
        }}
        isPending={permanentDeleteMutation.isPending}
      />
    </div>
  );
}
