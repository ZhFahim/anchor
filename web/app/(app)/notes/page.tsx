"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import {
  Archive,
  Hash,
  Pin,
  PinOff,
  Plus,
  Tag as TagIcon,
  Trash2,
  X,
} from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import * as React from "react";
import { AppPage, Fab, PageTitle } from "@/components/layout/app-page";
import { newNoteHref } from "@/components/layout/sidebar";
import { Button, IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { EmptyState, LoadFailedState } from "@/components/ui/empty-state";
import { SelectionBar } from "@/components/ui/selection-bar";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  bulkArchiveNotes,
  bulkDeleteNotes,
  bulkPinNotes,
  getNotes,
  restoreNote,
  unarchiveNote,
} from "@/features/notes/api";
import { BulkTagPicker } from "@/features/notes/components/bulk-tag-picker";
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
import { deletedNotesText, deleteNotesWarning } from "@/features/notes/trash";
import type { Note } from "@/features/notes/types";
import { tagColorStyle, useTagMap } from "@/features/tags";
import { eachLimited } from "@/lib/each";
import { rememberNewNoteButton } from "@/lib/morph";
import { plural } from "@/lib/utils";

const NO_NOTES: Note[] = [];

export default function NotesPage() {
  const tagId = useSearchParams().get("tagId");
  // Next keeps the page mounted when only the tag changes.
  return <NotesView key={tagId ?? ""} tagId={tagId} />;
}

function NotesView({ tagId }: { tagId: string | null }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const refresh = useRefreshNotes();
  const tagMap = useTagMap();
  const tag = tagId ? tagMap.get(tagId) : undefined;
  const [tagAnchor, setTagAnchor] = React.useState<HTMLElement | null>(null);
  const [sharingNote, setSharingNote] = React.useState<Note | null>(null);
  const [confirmRemove, setConfirmRemove] = React.useState<{
    ids: string[];
    sharedCount: number;
  } | null>(null);

  const { data, isLoading, isError, isFetching, refetch } = useQuery({
    queryKey: ["notes", tagId],
    queryFn: () => getNotes({ tagId: tagId || undefined }),
  });
  const notes = data ?? NO_NOTES;
  const loadFailed = isError && !data;
  const list = useNoteList(notes, { pinnedFirst: true });
  const { visible, pinned, others, chosen } = list;

  const allPinned = chosen.length > 0 && chosen.every((n) => n.isPinned);

  const noteAction = useMutation({
    mutationFn: async ({
      kind,
      ids,
    }: {
      kind: "pin" | "unpin" | "archive" | "trash";
      ids: string[];
    }) => {
      if (kind === "pin" || kind === "unpin")
        await bulkPinNotes(ids, kind === "pin");
      else if (kind === "archive") await bulkArchiveNotes(ids);
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
      const undo = async (run: () => Promise<unknown>) => {
        list.prepareCardMotion();
        try {
          await run();
        } catch {
          toast.error("Couldn’t undo that");
        }
        refresh();
      };
      if (kind === "pin" || kind === "unpin")
        toast.success(
          `${plural(ids.length, "note")} ${kind === "pin" ? "pinned" : "unpinned"}`,
          {
            undo: () => undo(() => bulkPinNotes(ids, kind !== "pin")),
          },
        );
      else if (kind === "archive")
        toast.success(`${plural(ids.length, "note")} archived`, {
          undo: () => undo(() => eachLimited(ids, unarchiveNote)),
        });
      else {
        const ownedIds = context?.ownedIds ?? [];
        toast.success(
          deletedNotesText(ownedIds.length, ids.length - ownedIds.length),
          ownedIds.length
            ? { undo: () => undo(() => eachLimited(ownedIds, restoreNote)) }
            : undefined,
        );
      }
    },
    onError: (_, { kind, ids }) => {
      const verb = {
        pin: "pin",
        unpin: "unpin",
        archive: "archive",
        trash: "delete",
      }[kind];
      toast.error(`Couldn’t ${verb} ${ids.length === 1 ? "note" : "notes"}`, {
        retry: () => noteAction.mutate({ kind, ids }),
      });
    },
  });

  const deleteChosen = () => {
    const ids = chosen.map((n) => n.id);
    const sharedCount = chosen.filter((n) => n.permission !== "owner").length;
    if (sharedCount) setConfirmRemove({ ids, sharedCount });
    else noteAction.mutate({ kind: "trash", ids });
  };

  const newNote = newNoteHref("/notes", tagId);
  const noNotes = !isLoading && !loadFailed && notes.length === 0;
  const noResults = notes.length > 0 && visible.length === 0;
  const count = isLoading || loadFailed ? undefined : visible.length;
  const newNoteButton = (
    <Button asChild>
      <Link
        href={newNote}
        data-new-note="empty"
        onClick={(e) => rememberNewNoteButton(e.currentTarget)}
      >
        <Plus aria-hidden />
        New note
      </Link>
    </Button>
  );

  const title = tag ? (
    <div className="flex min-w-0 items-center gap-1">
      <PageTitle
        count={count}
        icon={
          <span
            aria-hidden
            style={tagColorStyle(tag.color)}
            className="tag-color inline-grid text-(--hash) [&_svg]:size-5.25 [&_svg]:stroke-[2.75]"
          >
            <Hash />
          </span>
        }
      >
        {tag.name}
      </PageTitle>
      <Tip label="Show all notes">
        <IconButton
          size="sm"
          label="Show all notes"
          onClick={() => router.push("/notes")}
        >
          <X />
        </IconButton>
      </Tip>
    </div>
  ) : (
    <PageTitle count={count}>Notes</PageTitle>
  );

  const removeCount = confirmRemove?.ids.length ?? 0;
  const removeSharedCount = confirmRemove?.sharedCount ?? 0;
  return (
    <>
      <AppPage
        scrollKey={`notes:${tagId ?? ""}`}
        title={title}
        actions={
          !noNotes &&
          !loadFailed && (
            <NoteListActions
              list={list}
              placeholder={tag ? `Search #${tag.name}` : "Search notes"}
              autoFocus={searchParams.has("search")}
            />
          )
        }
      >
        <NotesBoardSkeleton loading={isLoading} />
        {loadFailed && (
          <LoadFailedState
            title="Couldn’t load your notes"
            onRetry={() => refetch()}
            isRetrying={isFetching}
          />
        )}
        {noNotes &&
          (tag ? (
            <EmptyState
              illustration="notes"
              title={`No notes tagged #${tag.name}`}
              action={newNoteButton}
            >
              New notes you create here get this tag.
            </EmptyState>
          ) : (
            <EmptyState
              illustration="notes"
              title="No notes yet"
              action={newNoteButton}
            >
              Create a note, or import your notes from Google Keep or Markdown
              in Settings.
            </EmptyState>
          ))}
        {noResults && <NoSearchResults list={list} />}
        {visible.length > 0 && (
          <NotesBoard
            ref={list.boardRef}
            layout={list.layout}
            picking={list.picking}
            picked={list.picked}
            onPick={list.onPick}
            onShare={setSharingNote}
            groups={[
              ...(pinned.length
                ? [
                    {
                      key: "pinned",
                      label: "Pinned",
                      icon: <Pin aria-hidden />,
                      notes: pinned,
                    },
                  ]
                : []),
              ...(others.length
                ? [
                    {
                      key: "others",
                      label: pinned.length ? "Others" : undefined,
                      notes: others,
                    },
                  ]
                : []),
            ]}
          />
        )}
      </AppPage>

      {!list.picking && (
        <Fab label="New note" asChild>
          <Link
            href={newNote}
            data-new-note="fab"
            onClick={(e) => rememberNewNoteButton(e.currentTarget)}
          >
            <Plus aria-hidden />
          </Link>
        </Fab>
      )}

      <SelectionBar
        open={list.picking}
        count={chosen.length}
        total={list.shown.length}
        onToggleAll={list.toggleAll}
        onClose={list.stopPicking}
        actions={[
          {
            key: "tag",
            label: "Tag",
            icon: <TagIcon aria-hidden />,
            onClick: (button) =>
              setTagAnchor((current) => (current ? null : button)),
          },
          allPinned
            ? {
                key: "unpin",
                label: "Unpin",
                icon: <PinOff aria-hidden />,
                onClick: () =>
                  noteAction.mutate({
                    kind: "unpin",
                    ids: chosen.map((n) => n.id),
                  }),
              }
            : {
                key: "pin",
                label: "Pin",
                icon: <Pin aria-hidden />,
                onClick: () =>
                  noteAction.mutate({
                    kind: "pin",
                    ids: chosen.filter((n) => !n.isPinned).map((n) => n.id),
                  }),
              },
          {
            key: "archive",
            label: "Archive",
            icon: <Archive aria-hidden />,
            onClick: () =>
              noteAction.mutate({
                kind: "archive",
                ids: chosen.map((n) => n.id),
              }),
          },
          {
            key: "delete",
            label: "Delete",
            icon: <Trash2 aria-hidden />,
            onClick: deleteChosen,
          },
        ]}
      />

      <ConfirmationDialog
        open={!!confirmRemove}
        onOpenChange={(open) => !open && setConfirmRemove(null)}
        title={`Delete ${plural(removeCount, "note")}?`}
        description={deleteNotesWarning(
          removeCount - removeSharedCount,
          removeSharedCount,
        )}
        confirmLabel="Delete"
        busyLabel="Deleting…"
        isPending={noteAction.isPending}
        onConfirm={() =>
          confirmRemove &&
          noteAction.mutate({ kind: "trash", ids: confirmRemove.ids })
        }
      />

      <BulkTagPicker
        anchor={tagAnchor}
        notes={chosen}
        onClose={() => setTagAnchor(null)}
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
