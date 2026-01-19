"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import { HTTPError } from "ky";
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
  lockNote,
  unlockNote,
  NoteBackground,
  ArchiveDialog,
  RestoreDialog,
  DeleteDialog,
  PermanentDeleteDialog,
  ReadOnlyBanner,
  NoteEditorHeader,
  NoteEditorContent,
} from "@/features/notes";
import type { CreateNoteDto, UpdateNoteDto, Note, NoteLockResponse } from "@/features/notes";
import { toast } from "sonner";

export default function NoteEditorPage() {
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
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [lockStatus, setLockStatus] = useState<NoteLockResponse | null>(null);

  const saveTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const lockRefreshRef = useRef<NodeJS.Timeout | null>(null);
  const lastSavedRef = useRef<{
    title: string;
    content: string;
    isPinned: boolean;
    tagIds: string[];
    background: string | null;
  } | null>(null);

  const [noteFromStorage, setNoteFromStorage] = useState<Note | null>(null);

  useEffect(() => {
    if (isNew || typeof window === "undefined") return;

    try {
      const stored = sessionStorage.getItem(`note-${noteId}`);
      if (stored) {
        const note = JSON.parse(stored) as Note;
        sessionStorage.removeItem(`note-${noteId}`);
        setNoteFromStorage(note);
      }
    } catch (error) {
      console.error("Failed to parse note from sessionStorage:", error);
    }
  }, [noteId, isNew]);

  const { data: noteFromApi, isLoading, refetch: refetchNote } = useQuery({
    queryKey: ["notes", noteId],
    queryFn: () => getNote(noteId),
    enabled: !isNew && !noteFromStorage,
  });

  const note = isNew ? null : noteFromStorage || noteFromApi;
  const isLockedByHomarr = lockStatus?.status === "locked" && lockStatus.lockedBy === "homarr";

  const isReadOnly = note ? note.state === "trashed" || isLockedByHomarr : false;

  useEffect(() => {
    if (note) {
      setTitle(note.title);
      setContent(note.content || "");
      setIsPinned(note.isPinned);
      setIsArchived(note.isArchived);
      const tagIds = note.tagIds || note.tags?.map((t) => t.id) || [];
      setSelectedTagIds(tagIds);
      setBackground(note.background || null);
      lastSavedRef.current = {
        title: note.title,
        content: note.content || "",
        isPinned: note.isPinned,
        tagIds,
        background: note.background || null,
      };
    } else if (isNew && tagIdFromUrl) {
      setSelectedTagIds([tagIdFromUrl]);
    }
  }, [note, isNew, tagIdFromUrl]);

  useEffect(() => {
    if (isNew) {
      setLockStatus(null);
      return;
    }
    if (note?.state === "trashed") {
      setLockStatus(null);
      return;
    }

    let isActive = true;

    const requestLock = async () => {
      try {
        const result = await lockNote(noteId);
        if (!isActive) return;
        setLockStatus(result);
      } catch (error) {
        if (!isActive) return;
        console.error("Failed to lock note:", error);
      }
    };

    requestLock();
    lockRefreshRef.current = setInterval(requestLock, 45_000);

    return () => {
      isActive = false;
      if (lockRefreshRef.current) {
        clearInterval(lockRefreshRef.current);
        lockRefreshRef.current = null;
      }
      unlockNote(noteId).catch(() => {});
    };
  }, [isNew, lockNote, note?.state, noteId, unlockNote]);

  const createMutation = useMutation({
    mutationFn: (data: CreateNoteDto) => createNote(data),
    onSuccess: (newNote) => {
      queryClient.setQueryData(["notes", newNote.id], newNote);
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      toast.success("Note created");
      router.replace(`/notes/${newNote.id}`);
    },
    onError: () => {
      toast.error("Failed to create note");
    },
  });

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
    onError: (error) => {
      if (error instanceof HTTPError && error.response.status === 409) {
        setLockStatus({
          status: "locked",
          lockedBy: "homarr",
          expiresAt: new Date().toISOString(),
        });
        toast.error("Note is locked by Homarr");
        return;
      }
      toast.error("Failed to save note");
    },
  });

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

  const unarchiveMutation = useMutation({
    mutationFn: () => unarchiveNote(noteId),
    onSuccess: async () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "archive"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setIsArchived(false);
      setNoteFromStorage(null);
      await refetchNote();
      toast.success("Note unarchived");
    },
    onError: () => {
      toast.error("Failed to unarchive note");
    },
  });

  const restoreMutation = useMutation({
    mutationFn: () => restoreNote(noteId),
    onSuccess: async () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "trash"] });
      queryClient.invalidateQueries({ queryKey: ["notes", noteId] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setNoteFromStorage(null);
      await refetchNote();
      toast.success("Note restored");
    },
    onError: () => {
      toast.error("Failed to restore note");
    },
  });

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
      JSON.stringify(selectedTagIds.sort()) !==
      JSON.stringify(lastSavedRef.current.tagIds.sort())
    );
  }, [title, content, isPinned, selectedTagIds, background, isNew]);

  useEffect(() => {
    setHasUnsavedChanges(checkUnsavedChanges());
  }, [checkUnsavedChanges]);

  const save = useCallback(() => {
    if (isReadOnly) return;
    if (!title.trim() && isStoredContentEmpty(content)) return;

    if (isNew) {
      createMutation.mutate({
        title: title.trim() || "Untitled",
        content: content || undefined,
        isPinned,
        background: background,
        tagIds: selectedTagIds,
      });
    } else {
      updateMutation.mutate({
        title: title.trim() || "Untitled",
        content: content || undefined,
        isPinned,
        background: background,
        tagIds: selectedTagIds,
      });
    }
  }, [title, content, isPinned, selectedTagIds, background, isNew, isReadOnly, createMutation, updateMutation]);

  useEffect(() => {
    if (!hasUnsavedChanges || isReadOnly) return;

    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }

    saveTimeoutRef.current = setTimeout(() => {
      save();
    }, 1000);

    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
    };
  }, [hasUnsavedChanges, save, isReadOnly]);

  useEffect(() => {
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
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
        className="absolute inset-0 min-h-full"
      />

      <NoteEditorHeader
        isNew={isNew}
        isReadOnly={isReadOnly}
        isPinned={isPinned}
        isArchived={isArchived}
        background={background}
        isSaving={isSaving}
        hasUnsavedChanges={hasUnsavedChanges}
        isSaved={isSaved}
        onBack={handleBack}
        onTogglePin={togglePin}
        onBackgroundChange={setBackground}
        onArchiveClick={() => setArchiveDialogOpen(true)}
        onDeleteClick={() => setDeleteDialogOpen(true)}
        onRestoreClick={() => setRestoreDialogOpen(true)}
        onPermanentDeleteClick={() => setPermanentDeleteDialogOpen(true)}
        restorePending={restoreMutation.isPending}
        permanentDeletePending={permanentDeleteMutation.isPending}
      />

      {isReadOnly && (
        <ReadOnlyBanner
          message={
            isLockedByHomarr
              ? "This note is being edited in Homarr and is read-only here."
              : "This note is in trash and cannot be edited. Restore it to make changes."
          }
        />
      )}

      <NoteEditorContent
        title={title}
        content={content}
        selectedTagIds={selectedTagIds}
        isReadOnly={isReadOnly}
        onTitleChange={setTitle}
        onContentChange={setContent}
        onTagsChange={setSelectedTagIds}
      />

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
