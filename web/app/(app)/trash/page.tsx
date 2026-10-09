"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { RotateCcw, Trash2 } from "lucide-react";
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
import { plural } from "@/lib/utils";

const NO_NOTES: Note[] = [];

const timeLeft = (note: Note) =>
  `${plural(daysUntilDeletion(note), "day")} left`;

export default function TrashPage() {
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
      toast.success(
        ids.length === 1
          ? "Note restored"
          : `${plural(ids.length, "note")} restored`,
        {
          undo: async () => {
            list.prepareCardMotion();
            try {
              await eachLimited(ids, (id) =>
                deleteNote(id, trashDates?.get(id)),
              );
            } catch {
              toast.error("Couldn’t undo that");
            }
            refresh();
          },
        },
      );
    },
    onError: (_, ids) =>
      toast.error(`Couldn’t restore ${ids.length === 1 ? "note" : "notes"}`, {
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
        all
          ? "Trash emptied"
          : ids.length === 1
            ? "Note permanently deleted"
            : `${plural(ids.length, "note")} permanently deleted`,
      );
    },
    onError: (_, variables) => {
      refresh();
      toast.error(
        variables.all
          ? "Couldn’t empty trash"
          : `Couldn’t delete ${variables.ids.length === 1 ? "note" : "notes"}`,
        { retry: () => remove.mutate(variables) },
      );
    },
  });

  const restoreNotes = restore.mutate;
  const renderActions = React.useCallback(
    (note: Note) => (
      <>
        <Tip label="Restore">
          <IconButton
            size="sm"
            label="Restore"
            onClick={() => restoreNotes([note.id])}
          >
            <RotateCcw />
          </IconButton>
        </Tip>
        <Tip label="Delete permanently">
          <IconButton
            size="sm"
            tone="danger"
            label="Delete permanently"
            onClick={() => setPendingDelete({ ids: [note.id] })}
          >
            <Trash2 />
          </IconButton>
        </Tip>
      </>
    ),
    [restoreNotes],
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
            Trash
          </PageTitle>
        }
        actions={
          hasNotes && (
            <NoteListActions list={list} placeholder="Search trash">
              <TopBarButton
                icon={<Trash2 aria-hidden />}
                onClick={() =>
                  setPendingDelete({ ids: notes.map((x) => x.id), all: true })
                }
              >
                Empty trash
              </TopBarButton>
            </NoteListActions>
          )
        }
      >
        <p className="m-0 -mt-2 mb-1 text-muted-foreground text-ui">
          {`Notes in the trash are permanently deleted after ${TRASH_RETENTION_DAYS} days.`}
        </p>
        <NotesBoardSkeleton loading={isLoading} />
        {loadFailed && (
          <LoadFailedState
            title="Couldn’t load your trash"
            onRetry={() => refetch()}
            isRetrying={isFetching}
          />
        )}
        {!isLoading && !loadFailed && !hasNotes && (
          <EmptyState illustration="trash" title="Trash is empty">
            {`Notes you delete stay here for ${TRASH_RETENTION_DAYS} days.`}
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
            label: "Restore",
            icon: <RotateCcw aria-hidden />,
            onClick: () => restore.mutate(chosenIds),
          },
          {
            key: "forever",
            label: "Delete permanently",
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
            ? "Empty trash?"
            : deleteCount === 1
              ? "Permanently delete this note?"
              : `Permanently delete ${deleteCount} notes?`
        }
        description={
          pendingDelete?.all
            ? `${plural(deleteCount, "note")} will be permanently deleted. This can’t be undone.`
            : `This can’t be undone. People you shared ${deleteCount === 1 ? "it" : "them"} with will lose access too.`
        }
        confirmLabel={pendingDelete?.all ? "Empty trash" : "Delete permanently"}
        busyLabel={pendingDelete?.all ? "Emptying trash…" : "Deleting…"}
        isPending={remove.isPending}
        onConfirm={() => pendingDelete && remove.mutate(pendingDelete)}
      />
    </>
  );
}
