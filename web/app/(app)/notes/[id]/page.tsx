"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import {
  getNote,
  createNote,
  updateNote,
  deleteNote,
  archiveNote,
  unarchiveNote,
  restoreNote,
  permanentDeleteNote,
  isStoredContentEmpty,
  NoteBackground,
  ArchiveDialog,
  RestoreDialog,
  DeleteDialog,
  PermanentDeleteDialog,
  ReadOnlyBanner,
  NoteEditorHeader,
  NoteEditorContent,
  ShareDialog,
} from "@/features/notes";
import type { CreateNoteDto, UpdateNoteDto, Note } from "@/features/notes";
import type { RichTextEditorHandle } from "@/features/notes/components/editor";
import { useAuth } from "@/features/auth";
import { toast } from "sonner";

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
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [archiveDialogOpen, setArchiveDialogOpen] = useState(false);
  const [restoreDialogOpen, setRestoreDialogOpen] = useState(false);
  const [permanentDeleteDialogOpen, setPermanentDeleteDialogOpen] = useState(false);
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  const saveTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const restoreFocusFrameRef = useRef<number | null>(null);
  const titleInputRef = useRef<HTMLInputElement | null>(null);
  const contentEditorRef = useRef<RichTextEditorHandle | null>(null);
  const hydratedNoteIdRef = useRef<string | null>(null);
  const initializedNewNoteRef = useRef(false);
  const autoFocusedNewNoteRef = useRef(false);
  const pendingFocusRestoreRef = useRef<PendingFocusRestore | null>(null);
  const pendingCreateNoteRef = useRef<Promise<Note> | null>(null);
  const lastSavedRef = useRef<{
    title: string;
    content: string;
    isPinned: boolean;
    tagIds: string[];
    background: string | null;
  } | null>(null);

  // Try to get note from sessionStorage first (passed from note card)
  const [noteFromStorage, setNoteFromStorage] = useState<Note | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;

    if (isNew) {
      setNoteFromStorage(null);
      return;
    }

    try {
      setNoteFromStorage(null);
      const stored = sessionStorage.getItem(`note-${noteId}`);
      if (stored) {
        const note = JSON.parse(stored) as Note;
        // Clean up after reading
        sessionStorage.removeItem(`note-${noteId}`);
        setNoteFromStorage(note);
      }
    } catch (error) {
      console.error("Failed to parse note from sessionStorage:", error);
    }
  }, [noteId, isNew]);

  // Fetch existing note (only if not in sessionStorage)
  const { data: noteFromApi, isLoading, refetch: refetchNote } = useQuery({
    queryKey: ["notes", noteId],
    queryFn: () => getNote(noteId),
    enabled: !isNew && !noteFromStorage,
  });

  // Use note from storage if available, otherwise use API data
  const note = isNew ? null : noteFromStorage || noteFromApi;

  // Check permissions
  const isOwner = note ? note.permission === "owner" : true;
  const isViewer = note ? note.permission === "viewer" : false;
  const isEditor = note ? note.permission === "editor" : false;

  // Check if note is read-only (trashed notes or viewers are read-only)
  const isReadOnly = note
    ? note.state === "trashed" || isViewer
    : false;
  const canUpload = isOwner || isEditor;

  const getTitleForSave = useCallback(() => {
    return title.trim() === "" ? "Untitled" : title;
  }, [title]);

  const capturePendingFocusRestore = useCallback((): PendingFocusRestore | null => {
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
    if (activeElement instanceof HTMLElement && activeElement.closest(".ql-editor")) {
      return { target: "content" };
    }

    return null;
  }, []);

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
    lastSavedRef.current = null;
    pendingFocusRestoreRef.current = null;
    setTitle("");
    setContent("");
    setIsPinned(false);
    setIsArchived(false);
    setBackground(null);
    setSelectedTagIds(tagIdFromUrl ? [tagIdFromUrl] : []);
  }, [isNew, tagIdFromUrl]);

  useEffect(() => {
    if (typeof window === "undefined" || !isNew || autoFocusedNewNoteRef.current) return;

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

    const tagIds = note.tagIds || note.tags?.map((t) => t.id) || [];
    setTitle(note.title);
    setContent(note.content || "");
    setIsPinned(note.isPinned);
    setSelectedTagIds(tagIds);
    setBackground(note.background || null);
    lastSavedRef.current = {
      title: note.title,
      content: note.content || "",
      isPinned: note.isPinned,
      tagIds,
      background: note.background || null,
    };
    hydratedNoteIdRef.current = note.id;
  }, [note]);

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
        title: getTitleForSave(),
        content: content || undefined,
        isPinned,
        background,
        tagIds: selectedTagIds,
      });

      pendingCreateNoteRef.current = createPromise.finally(() => {
        pendingCreateNoteRef.current = null;
      });

      return pendingCreateNoteRef.current;
    },
    [
      background,
      content,
      createMutation,
      getTitleForSave,
      isNew,
      isPinned,
      note,
      selectedTagIds,
    ],
  );

  // Update note mutation
  const updateMutation = useMutation({
    mutationFn: (data: UpdateNoteDto) => updateNote(noteId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setHasUnsavedChanges(false);
      lastSavedRef.current = {
        title,
        content,
        isPinned,
        tagIds: selectedTagIds,
        background,
      };
    },
    onError: () => {
      toast.error("Failed to save note");
    },
  });

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
      // Clear noteFromStorage so the query can refetch
      setNoteFromStorage(null);
      // Refetch the note to get updated data
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
      // Clear noteFromStorage so the query can refetch
      setNoteFromStorage(null);
      // Refetch the note to get updated data
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

  // Check for unsaved changes
  const checkUnsavedChanges = useCallback(() => {
    if (!lastSavedRef.current && isNew) {
      return title.trim() !== "" || !isStoredContentEmpty(content);
    }
    if (!lastSavedRef.current) return false;

    return (
      title !== lastSavedRef.current.title ||
      content !== lastSavedRef.current.content ||
      isPinned !== lastSavedRef.current.isPinned ||
      background !== lastSavedRef.current.background ||
      JSON.stringify([...selectedTagIds].sort()) !==
      JSON.stringify([...lastSavedRef.current.tagIds].sort())
    );
  }, [title, content, isPinned, selectedTagIds, background, isNew]);

  useEffect(() => {
    setHasUnsavedChanges(checkUnsavedChanges());
  }, [checkUnsavedChanges]);

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
          const selectionStart = Math.min(restoreTarget.selectionStart, maxPosition);
          const selectionEnd = Math.min(restoreTarget.selectionEnd, maxPosition);
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

  // Auto-save with debounce
  const save = useCallback(() => {
    if (isReadOnly) return;
    if (createMutation.isPending || updateMutation.isPending) return;
    if (!title.trim() && isStoredContentEmpty(content)) return;

    if (isNew) {
      void createNewNote(capturePendingFocusRestore());
    } else {
      pendingFocusRestoreRef.current = null;
      updateMutation.mutate({
        title: getTitleForSave(),
        content: content || undefined,
        isPinned,
        background: background,
        tagIds: selectedTagIds,
      });
    }
  }, [
    background,
    capturePendingFocusRestore,
    content,
    createMutation.isPending,
    createNewNote,
    getTitleForSave,
    isNew,
    isPinned,
    isReadOnly,
    selectedTagIds,
    title,
    updateMutation,
  ]);

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

  // Debounced auto-save (disabled when read-only)
  useEffect(() => {
    if (!hasUnsavedChanges || isReadOnly) return;

    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }

    saveTimeoutRef.current = setTimeout(() => {
      save();
    }, 1000); // Auto-save after 1 second of inactivity

    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
    };
  }, [hasUnsavedChanges, save, isReadOnly]);

  // Save on unmount if there are changes
  useEffect(() => {
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
      if (restoreFocusFrameRef.current !== null) {
        window.cancelAnimationFrame(restoreFocusFrameRef.current);
      }
    };
  }, []);

  const handleBack = () => {
    if (hasUnsavedChanges) {
      save();
    }
    router.back();
  };

  const togglePin = () => {
    setIsPinned((prev) => !prev);
  };

  // Only show loading if we don't have note from storage and are fetching from API
  if (isLoading && !isNew && !noteFromStorage) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 animate-spin text-accent" />
          <span className="text-sm text-muted-foreground">Loading note...</span>
        </div>
      </div>
    );
  }

  const isSaving = updateMutation.isPending || createMutation.isPending;
  const isSaved = !hasUnsavedChanges && !isSaving && !isNew;

  return (
    <div className="min-h-screen flex flex-col relative">
      <NoteBackground
        styleId={background}
        className="fixed inset-0 z-0"
      />

      {/* Header */}
      <NoteEditorHeader
        isNew={isNew}
        isReadOnly={isReadOnly}
        isPinned={isPinned}
        isArchived={isArchived}
        background={background}
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
        onArchiveClick={() => setArchiveDialogOpen(true)}
        onDeleteClick={() => setDeleteDialogOpen(true)}
        onRestoreClick={() => setRestoreDialogOpen(true)}
        onPermanentDeleteClick={() => setPermanentDeleteDialogOpen(true)}
        onShareClick={!isNew ? () => setShareDialogOpen(true) : undefined}
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
