"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { RotateCcw, Trash2 } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { AppPage, PageTitle, TopBarButton } from "@/components/layout/app-page";
import { IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { EmptyState, LoadFailedState } from "@/components/ui/empty-state";
import { SelectionBar } from "@/components/ui/selection-bar";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  deleteNote,
  getTrashedNotes,
  permanentDeleteNote,
  restoreNote,
} from "@/features/notes/api";
import {
  NoSearchResults,
  NoteListActions,
} from "@/features/notes/components/note-list-actions";
import {
  NotesBoard,
  NotesBoardSkeleton,
} from "@/features/notes/components/notes-board";
import { useNoteList } from "@/features/notes/hooks/use-note-list";
import { useRefreshNotes } from "@/features/notes/hooks/use-refresh-notes";
import {
  daysUntilDeletion,
  TRASH_RETENTION_DAYS,
} from "@/features/notes/trash";
import type { Note } from "@/features/notes/types";
import { eachLimited } from "@/lib/each";

const NO_NOTES: Note[] = [];

export default function TrashPage() {
  const t = useTranslations();
  const refresh = useRefreshNotes();
  const [pendingDelete, setPendingDelete] = React.useState<{
    ids: string[];
    all?: boolean;
  } | null>(null);
  const { data, isLoading, isError, isFetching, refetch } = useQuery({
    queryKey: ["notes", "trashed"],
    queryFn: getTrashedNotes,
  });
  const notes = data ?? NO_NOTES;
  const loadFailed = isError && !data;
  const list = useNoteList(notes);
  const timeLeft = React.useCallback(
    (note: Note) => t("trashDaysLeft", { count: daysUntilDeletion(note) }),
    [t],
  );

  const restore = useMutation({
    mutationFn: (ids: string[]) => eachLimited(ids, restoreNote),
    onMutate: (ids) => {
      list.prepareCardMotion();
      return new Map(
        ids.map((id) => [id, notes.find((n) => n.id === id)?.stateChangedAt]),
      );
    },
    onSuccess: (_, ids, trashDates) => {
      refresh();
      list.stopPicking();
      toast.success(t("trashRestored", { count: ids.length }), {
        undo: async () => {
          list.prepareCardMotion();
          try {
            await eachLimited(ids, (id) => deleteNote(id, trashDates?.get(id)));
          } catch {
            toast.error(t("notesUndoFailed"));
          }
          refresh();
        },
      });
    },
    onError: (_, ids) =>
      toast.error(t("trashRestoreFailed", { count: ids.length }), {
        retry: () => restore.mutate(ids),
      }),
  });

  const remove = useMutation({
    mutationFn: ({ ids }: { ids: string[]; all?: boolean }) =>
      eachLimited(ids, permanentDeleteNote),
    onMutate: () => list.prepareCardMotion(),
    onSuccess: async (_, { ids, all }) => {
      await refresh();
      list.stopPicking();
      setPendingDelete(null);
      toast.success(
        all ? t("trashEmptied") : t("trashDeleted", { count: ids.length }),
      );
    },
    onError: (_, variables) => {
      refresh();
      toast.error(
        variables.all
          ? t("trashEmptyFailed")
          : t("trashDeleteFailed", { count: variables.ids.length }),
        { retry: () => remove.mutate(variables) },
      );
    },
  });

  const restoreNotes = restore.mutate;
  const renderActions = React.useCallback(
    (note: Note) => (
      <>
        <Tip label={t("trashRestore")}>
          <IconButton
            size="sm"
            label={t("trashRestore")}
            onClick={() => restoreNotes([note.id])}
          >
            <RotateCcw />
          </IconButton>
        </Tip>
        <Tip label={t("trashDeletePermanently")}>
          <IconButton
            size="sm"
            tone="danger"
            label={t("trashDeletePermanently")}
            onClick={() => setPendingDelete({ ids: [note.id] })}
          >
            <Trash2 />
          </IconButton>
        </Tip>
      </>
    ),
    [restoreNotes, t],
  );

  const hasNotes = notes.length > 0;
  const chosenIds = list.chosen.map((n) => n.id);
  const deleteCount = pendingDelete?.ids.length ?? 0;
  return (
    <>
      <AppPage
        scrollKey="trash"
        title={
          <PageTitle
            count={isLoading || loadFailed ? undefined : list.visible.length}
          >
            {t("trashTitle")}
          </PageTitle>
        }
        actions={
          hasNotes && (
            <NoteListActions list={list} placeholder={t("trashSearch")}>
              <TopBarButton
                icon={<Trash2 aria-hidden />}
                onClick={() =>
                  setPendingDelete({ ids: notes.map((x) => x.id), all: true })
                }
              >
                {t("trashEmptyAction")}
              </TopBarButton>
            </NoteListActions>
          )
        }
      >
        <p className="m-0 -mt-2 mb-1 text-muted-foreground text-ui">
          {t("trashSubtitle", { count: TRASH_RETENTION_DAYS })}
        </p>
        <NotesBoardSkeleton loading={isLoading} />
        {loadFailed && (
          <LoadFailedState
            title={t("trashLoadFailed")}
            onRetry={() => refetch()}
            isRetrying={isFetching}
          />
        )}
        {!isLoading && !loadFailed && !hasNotes && (
          <EmptyState illustration="trash" title={t("trashEmptyStateTitle")}>
            {t("trashEmptyStateHelp", { count: TRASH_RETENTION_DAYS })}
          </EmptyState>
        )}
        {hasNotes && !list.visible.length && <NoSearchResults list={list} />}
        {list.visible.length > 0 && (
          <NotesBoard
            ref={list.boardRef}
            layout={list.layout}
            picking={list.picking}
            picked={list.picked}
            onPick={list.onPick}
            renderActions={renderActions}
            dateLabel={timeLeft}
            groups={[{ key: "all", notes: list.shown }]}
          />
        )}
      </AppPage>

      <SelectionBar
        open={list.picking}
        count={list.chosen.length}
        total={list.shown.length}
        onToggleAll={list.toggleAll}
        onClose={list.stopPicking}
        actions={[
          {
            key: "restore",
            label: t("trashRestore"),
            icon: <RotateCcw aria-hidden />,
            onClick: () => restore.mutate(chosenIds),
          },
          {
            key: "forever",
            label: t("trashDeletePermanently"),
            icon: <Trash2 aria-hidden />,
            onClick: () => setPendingDelete({ ids: chosenIds }),
          },
        ]}
      />

      <ConfirmationDialog
        open={!!pendingDelete}
        onOpenChange={(open) => !open && setPendingDelete(null)}
        title={
          pendingDelete?.all
            ? t("trashEmptyConfirmTitle")
            : t("trashDeleteConfirmTitle", { count: deleteCount })
        }
        description={
          pendingDelete?.all
            ? t("trashEmptyConfirmMessage", { count: deleteCount })
            : t("trashDeleteConfirmMessage", { count: deleteCount })
        }
        confirmLabel={
          pendingDelete?.all
            ? t("trashEmptyAction")
            : t("trashDeletePermanently")
        }
        busyLabel={pendingDelete?.all ? t("trashEmptying") : t("notesDeleting")}
        isPending={remove.isPending}
        onConfirm={() => pendingDelete && remove.mutate(pendingDelete)}
      />
    </>
  );
}
