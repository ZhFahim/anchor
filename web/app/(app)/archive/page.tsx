"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { ArchiveRestore, Trash2 } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { AppPage, PageTitle } from "@/components/layout/app-page";
import { IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { EmptyState, LoadFailedState } from "@/components/ui/empty-state";
import { SelectionBar } from "@/components/ui/selection-bar";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  bulkArchiveNotes,
  bulkDeleteNotes,
  restoreNote,
  unarchiveNote,
} from "@/features/notes/api";
import {
  NoSearchResults,
  NoteListActions,
} from "@/features/notes/components/note-list-actions";
import {
  NotesBoard,
  NotesBoardSkeleton,
} from "@/features/notes/components/notes-board";
import { ShareDialog } from "@/features/notes/components/share-dialog";
import { useNoteList } from "@/features/notes/hooks/use-note-list";
import { useRefreshNotes } from "@/features/notes/hooks/use-refresh-notes";
import { archivedNotesQuery } from "@/features/notes/queries";
import { deletedNotesText, deleteNotesWarning } from "@/features/notes/trash";
import type { Note } from "@/features/notes/types";
import { eachLimited } from "@/lib/each";

const NO_NOTES: Note[] = [];

export default function ArchivePage() {
  const t = useTranslations();
  const refresh = useRefreshNotes();
  const [confirmRemove, setConfirmRemove] = React.useState<{
    ids: string[];
    sharedCount: number;
  } | null>(null);
  const [sharingNote, setSharingNote] = React.useState<Note | null>(null);
  const { data, isLoading, isError, isFetching, refetch } =
    useQuery(archivedNotesQuery);
  const notes = data ?? NO_NOTES;
  const loadFailed = isError && !data;
  const list = useNoteList(notes);

  const undo = async (run: () => Promise<unknown>) => {
    list.prepareCardMotion();
    try {
      await run();
    } catch {
      toast.error(t("notesUndoFailed"));
    }
    refresh();
  };

  const noteAction = useMutation({
    mutationFn: async ({
      kind,
      ids,
    }: {
      kind: "unarchive" | "trash";
      ids: string[];
    }) => {
      if (kind === "unarchive") await eachLimited(ids, unarchiveNote);
      else await bulkDeleteNotes(ids);
    },
    onMutate: ({ ids }) => {
      list.prepareCardMotion();
      return {
        ownedIds: ids.filter(
          (id) => notes.find((n) => n.id === id)?.permission === "owner",
        ),
      };
    },
    onSuccess: (_, { kind, ids }, context) => {
      refresh();
      list.stopPicking();
      setConfirmRemove(null);
      if (kind === "unarchive") {
        toast.success(t("archiveUnarchived", { count: ids.length }), {
          undo: () => undo(() => bulkArchiveNotes(ids)),
        });
        return;
      }
      const ownedIds = context?.ownedIds ?? [];
      toast.success(
        deletedNotesText(ownedIds.length, ids.length - ownedIds.length, t),
        ownedIds.length
          ? { undo: () => undo(() => eachLimited(ownedIds, restoreNote)) }
          : undefined,
      );
    },
    onError: (_, variables) =>
      toast.error(
        t(
          variables.kind === "unarchive"
            ? "notesUnarchiveFailed"
            : "notesDeleteFailed",
          { count: variables.ids.length },
        ),
        { retry: () => noteAction.mutate(variables) },
      ),
  });

  const mutateNotes = noteAction.mutate;
  const renderActions = React.useCallback(
    (note: Note) => (
      <Tip label={t("notesUnarchive")}>
        <IconButton
          size="sm"
          label={t("notesUnarchive")}
          onClick={() => mutateNotes({ kind: "unarchive", ids: [note.id] })}
        >
          <ArchiveRestore />
        </IconButton>
      </Tip>
    ),
    [mutateNotes, t],
  );

  const deleteChosen = () => {
    const ids = list.chosen.map((n) => n.id);
    const sharedCount = list.chosen.filter(
      (n) => n.permission !== "owner",
    ).length;
    if (sharedCount) setConfirmRemove({ ids, sharedCount });
    else noteAction.mutate({ kind: "trash", ids });
  };

  const hasNotes = notes.length > 0;
  const removeCount = confirmRemove?.ids.length ?? 0;
  const removeSharedCount = confirmRemove?.sharedCount ?? 0;
  return (
    <>
      <AppPage
        scrollKey="archive"
        title={
          <PageTitle
            count={isLoading || loadFailed ? undefined : list.visible.length}
          >
            {t("archiveTitle")}
          </PageTitle>
        }
        actions={
          hasNotes && (
            <NoteListActions list={list} placeholder={t("archiveSearch")} />
          )
        }
      >
        <p className="m-0 -mt-2 mb-1 text-muted-foreground text-ui">
          {t("archiveSubtitle")}
        </p>
        <NotesBoardSkeleton loading={isLoading} />
        {loadFailed && (
          <LoadFailedState
            title={t("archiveLoadFailed")}
            onRetry={() => refetch()}
            isRetrying={isFetching}
          />
        )}
        {!isLoading && !loadFailed && !hasNotes && (
          <EmptyState illustration="archive" title={t("archiveEmptyTitle")}>
            {t("archiveEmptyHelp")}
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
            onShare={setSharingNote}
            renderActions={renderActions}
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
            key: "unarchive",
            label: t("notesUnarchive"),
            icon: <ArchiveRestore aria-hidden />,
            onClick: () =>
              noteAction.mutate({
                kind: "unarchive",
                ids: list.chosen.map((n) => n.id),
              }),
          },
          {
            key: "delete",
            label: t("commonDelete"),
            icon: <Trash2 aria-hidden />,
            onClick: deleteChosen,
          },
        ]}
      />

      <ConfirmationDialog
        open={!!confirmRemove}
        onOpenChange={(open) => !open && setConfirmRemove(null)}
        title={t("notesDeleteTitle", { count: removeCount })}
        description={deleteNotesWarning(
          removeCount - removeSharedCount,
          removeSharedCount,
          t,
        )}
        confirmLabel={t("commonDelete")}
        busyLabel={t("notesDeleting")}
        isPending={noteAction.isPending}
        onConfirm={() =>
          confirmRemove &&
          noteAction.mutate({ kind: "trash", ids: confirmRemove.ids })
        }
      />
      {sharingNote && (
        <ShareDialog
          open
          noteId={sharingNote.id}
          title={sharingNote.title}
          onOpenChange={(open) => !open && setSharingNote(null)}
        />
      )}
    </>
  );
}
