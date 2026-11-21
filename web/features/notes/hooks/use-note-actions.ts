"use client";

import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { toast } from "@/components/ui/toast";
import { canGoBackInApp } from "@/lib/app-history";
import {
  archiveNote,
  deleteNote,
  permanentDeleteNote,
  restoreNote,
  unarchiveNote,
} from "../api";
import type { Note } from "../types";
import { useRefreshNotes } from "./use-refresh-notes";

export function useNoteActions({
  noteId,
  note,
  isOwner,
  save,
  refetchNote,
  setIsArchived,
}: {
  noteId: string;
  note: Note | null;
  isOwner: boolean;
  save: () => void;
  refetchNote: () => Promise<unknown>;
  setIsArchived: (isArchived: boolean) => void;
}) {
  const t = useTranslations();
  const router = useRouter();
  const refreshLists = useRefreshNotes();
  const [confirmPermanentDelete, setConfirmPermanentDelete] = useState(false);
  const [confirmLeaveShare, setConfirmLeaveShare] = useState(false);

  const goBack = () => {
    if (!canGoBackInApp()) {
      router.push(
        note?.state === "trashed"
          ? "/trash"
          : note?.isArchived
            ? "/archive"
            : "/notes",
      );
    } else router.back();
  };
  const leave = () => {
    save();
    goBack();
  };

  const archiveMutation = useMutation({
    mutationFn: () => archiveNote(noteId),
    onSuccess: () => {
      refreshLists();
      leave();
      toast.success(t("notesArchived"), {
        undo: () =>
          unarchiveNote(noteId).then(refreshLists, () =>
            toast.error(t("notesUndoFailed")),
          ),
      });
    },
    onError: () =>
      toast.error(t("notesArchiveFailed", { count: 1 }), {
        retry: () => archiveMutation.mutate(),
      }),
  });

  const unarchiveMutation = useMutation({
    mutationFn: () => unarchiveNote(noteId),
    onSuccess: async () => {
      refreshLists();
      setIsArchived(false);
      await refetchNote();
      toast.success(t("archiveUnarchived", { count: 1 }), {
        undo: async () => {
          await archiveNote(noteId).catch(() =>
            toast.error(t("notesUndoFailed")),
          );
          setIsArchived(true);
          refreshLists();
          refetchNote();
        },
      });
    },
    onError: () =>
      toast.error(t("notesUnarchiveFailed", { count: 1 }), {
        retry: () => unarchiveMutation.mutate(),
      }),
  });

  const trashMutation = useMutation({
    mutationFn: () => deleteNote(noteId),
    onSuccess: () => {
      refreshLists();
      setConfirmLeaveShare(false);
      leave();
      if (isOwner)
        toast.success(t("notesMovedToTrash"), {
          undo: () =>
            restoreNote(noteId).then(refreshLists, () =>
              toast.error(t("notesUndoFailed")),
            ),
        });
      else toast.success(t("notesRemoved"));
    },
    onError: () =>
      toast.error(
        isOwner ? t("notesMoveToTrashFailed") : t("notesRemoveFailed"),
        {
          retry: () => trashMutation.mutate(),
        },
      ),
  });

  const restoreMutation = useMutation({
    mutationFn: () => restoreNote(noteId),
    onSuccess: async () => {
      const trashedAt = note?.stateChangedAt;
      refreshLists();
      await refetchNote();
      toast.success(t("trashRestored", { count: 1 }), {
        undo: async () => {
          await deleteNote(noteId, trashedAt).catch(() =>
            toast.error(t("notesUndoFailed")),
          );
          refreshLists();
          refetchNote();
        },
      });
    },
    onError: () =>
      toast.error(t("trashRestoreFailed", { count: 1 }), {
        retry: () => restoreMutation.mutate(),
      }),
  });

  const permanentDeleteMutation = useMutation({
    mutationFn: () => permanentDeleteNote(noteId),
    onSuccess: () => {
      refreshLists();
      setConfirmPermanentDelete(false);
      goBack();
      toast.success(t("trashDeleted", { count: 1 }));
    },
    onError: () =>
      toast.error(t("trashDeleteFailed", { count: 1 }), {
        retry: () => permanentDeleteMutation.mutate(),
      }),
  });

  return {
    goBack,
    archive: () => archiveMutation.mutate(),
    unarchive: () => unarchiveMutation.mutate(),
    trash: () =>
      isOwner ? trashMutation.mutate() : setConfirmLeaveShare(true),
    leaveShare: () => trashMutation.mutate(),
    isLeavingShare: trashMutation.isPending,
    restore: () => restoreMutation.mutate(),
    isRestoring: restoreMutation.isPending,
    deletePermanently: () => permanentDeleteMutation.mutate(),
    isDeletingPermanently: permanentDeleteMutation.isPending,
    confirmPermanentDelete,
    setConfirmPermanentDelete,
    confirmLeaveShare,
    setConfirmLeaveShare,
  };
}
