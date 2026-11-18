"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import {
  Archive,
  ArchiveRestore,
  Hash,
  Pin,
  PinOff,
  Plus,
  Tag as TagIcon,
  Trash2,
  X,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import * as React from "react";
import { AppPage, Fab, PageTitle } from "@/components/layout/app-page";
import { newNoteHref } from "@/components/layout/sidebar";
import { Button, IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import {
  EmptyState,
  LoadFailedRow,
  LoadFailedState,
} from "@/components/ui/empty-state";
import { SelectionBar } from "@/components/ui/selection-bar";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  bulkAddTagsToNotes,
  bulkArchiveNotes,
  bulkDeleteNotes,
  bulkPinNotes,
  getNotes,
  restoreNote,
  saveNote,
  unarchiveNote,
} from "@/features/notes/api";
import { type DropTarget, noteHref } from "@/features/notes/columns";
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
import { useArchivedNotes } from "@/features/notes/hooks/use-archived-notes";
import { useNoteList } from "@/features/notes/hooks/use-note-list";
import { useNoteReorder } from "@/features/notes/hooks/use-note-reorder";
import { useRefreshNotes } from "@/features/notes/hooks/use-refresh-notes";
import { deletedNotesText, deleteNotesWarning } from "@/features/notes/trash";
import type { Note } from "@/features/notes/types";
import { tagColorStyle, useTagMap } from "@/features/tags";
import { eachLimited } from "@/lib/each";
import { rememberNewNoteButton } from "@/lib/morph";
import { isMac } from "@/lib/platform";
import { plural } from "@/lib/utils";

const NO_NOTES: Note[] = [];

const UNDOABLE_ACTIONS = {
  pin: {
    run: (ids: string[]) => bulkPinNotes(ids, true),
    undo: (ids: string[]) => bulkPinNotes(ids, false),
    done: "pinned",
  },
  unpin: {
    run: (ids: string[]) => bulkPinNotes(ids, false),
    undo: (ids: string[]) => bulkPinNotes(ids, true),
    done: "unpinned",
  },
  archive: {
    run: (ids: string[]) => bulkArchiveNotes(ids),
    undo: (ids: string[]) => eachLimited(ids, unarchiveNote),
    done: "archived",
    isArchived: true,
  },
  unarchive: {
    run: (ids: string[]) => eachLimited(ids, unarchiveNote),
    undo: (ids: string[]) => bulkArchiveNotes(ids),
    done: "unarchived",
    isArchived: false,
  },
} satisfies Record<
  string,
  {
    run: (ids: string[]) => Promise<unknown>;
    undo: (ids: string[]) => Promise<unknown>;
    done: string;
    isArchived?: boolean;
  }
>;

type NoteActionKind = keyof typeof UNDOABLE_ACTIONS | "trash";

const openNoteId = (pathname: string) => {
  const id = pathname.startsWith("/notes/")
    ? decodeURIComponent(pathname.slice("/notes/".length))
    : null;
  return id && id !== "new" ? id : null;
};

/**
 * The notes of one tag, or all of them. In columns, `openNote` is the page
 * beside the list: the open note, or nothing yet.
 */
export function NotesView({
  tagId,
  openNote,
}: {
  tagId: string | null;
  openNote?: React.ReactNode;
}) {
  const isColumns = openNote !== undefined;
  const router = useRouter();
  const pathname = usePathname();
  const openId = isColumns ? openNoteId(pathname) : null;
  const listHref = tagId
    ? `/notes?tagId=${encodeURIComponent(tagId)}`
    : "/notes";
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

  const archived = useArchivedNotes(tagId, notes);
  const list = useNoteList(notes, {
    pinnedFirst: true,
    archived: archived.listOptions,
  });
  const { visible, pinned, others, chosen } = list;
  const ordering = useNoteReorder({ list, notes, tagId });
  const isArchiveLoading = list.hasArchived && archived.query.isLoading;
  const archiveFailed =
    list.hasArchived && archived.query.isError && !archived.query.data;

  const allPinned = chosen.length > 0 && chosen.every((n) => n.isPinned);
  const allArchived = chosen.length > 0 && chosen.every((n) => n.isArchived);

  const noteAction = useMutation({
    mutationFn: async ({
      kind,
      ids,
    }: {
      kind: NoteActionKind;
      ids: string[];
    }) => {
      if (kind === "trash") await bulkDeleteNotes(ids);
      else await UNDOABLE_ACTIONS[kind].run(ids);
    },
    onMutate: ({ ids }) => {
      list.prepareCardMotion();
      return {
        ownedIds: ids.filter(
          (id) =>
            [...notes, ...archived.all].find((n) => n.id === id)?.permission ===
            "owner",
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
      if (kind === "trash") {
        // The open note went to the trash: close it.
        if (openId && ids.includes(openId)) router.replace(listHref);
        const ownedIds = context?.ownedIds ?? [];
        toast.success(
          deletedNotesText(ownedIds.length, ids.length - ownedIds.length),
          ownedIds.length
            ? { undo: () => undo(() => eachLimited(ownedIds, restoreNote)) }
            : undefined,
        );
        return;
      }
      const action = UNDOABLE_ACTIONS[kind];
      const isArchived = "isArchived" in action ? action.isArchived : null;
      if (isArchived !== null) archived.setArchivedInCache(ids, isArchived);
      toast.success(`${plural(ids.length, "note")} ${action.done}`, {
        undo: () =>
          undo(async () => {
            await action.undo(ids);
            if (isArchived !== null)
              archived.setArchivedInCache(ids, !isArchived);
          }),
      });
    },
    onError: (_, { kind, ids }) => {
      const verb = kind === "trash" ? "delete" : kind;
      toast.error(`Couldn’t ${verb} ${ids.length === 1 ? "note" : "notes"}`, {
        retry: () => noteAction.mutate({ kind, ids }),
      });
    },
  });

  // The first Ctrl-click beside an open note picks that note too.
  const { picking, onPick: pick, shown } = list;
  const onPick = React.useCallback(
    (id: string, range: boolean) => {
      if (
        !picking &&
        openId &&
        openId !== id &&
        shown.some((n) => n.id === openId)
      )
        pick(openId, false);
      pick(id, range);
    },
    [picking, pick, shown, openId],
  );

  const trashNotes = (picked: Note[]) => {
    const ids = picked.map((n) => n.id);
    const sharedCount = picked.filter((n) => n.permission !== "owner").length;
    if (sharedCount) setConfirmRemove({ ids, sharedCount });
    else noteAction.mutate({ kind: "trash", ids });
  };
  const deleteChosen = () => trashNotes(chosen);

  const tagNotes = useMutation({
    mutationFn: async ({ tagId, ids }: { tagId: string; ids: string[] }) => {
      await bulkAddTagsToNotes(ids, [tagId]);
    },
    onSuccess: (_, { tagId, ids }) => {
      refresh();
      list.stopPicking();
      const before = new Map(
        list.shown.map((n) => [n.id, n.tagIds ?? []] as const),
      );
      toast.success(
        `${plural(ids.length, "note")} tagged #${tagMap.get(tagId)?.name ?? ""}`,
        {
          undo: async () => {
            try {
              await eachLimited(ids, (id) =>
                saveNote(id, { tagIds: before.get(id) ?? [] }),
              );
            } catch {
              toast.error("Couldn’t undo that");
            }
            refresh();
          },
        },
      );
    },
    onError: (_, variables) =>
      toast.error("Couldn’t tag notes", {
        retry: () => tagNotes.mutate(variables),
      }),
  });

  // Columns: cards dropped on a tag, Archive or Trash in the sidebar.
  const dropNotes = (ids: string[], target: DropTarget) => {
    const dropped = list.shown.filter((n) => ids.includes(n.id));
    if (target.kind === "trash") return trashNotes(dropped);
    if (target.kind === "archive")
      return noteAction.mutate({
        kind: "archive",
        ids: dropped.filter((n) => !n.isArchived).map((n) => n.id),
      });
    const untagged = dropped.filter(
      (n) => !(n.tagIds ?? []).includes(target.tagId),
    );
    if (untagged.length)
      tagNotes.mutate({
        tagId: target.tagId,
        ids: untagged.map((n) => n.id),
      });
  };

  const newNote = newNoteHref("/notes", tagId);
  const noNotes =
    !isLoading &&
    !loadFailed &&
    notes.length === 0 &&
    !list.isSearching &&
    !(tagId && (isArchiveLoading || archiveFailed || archived.tagged.length));
  const hasArchivedSection = list.archived.length > 0 || archiveFailed;
  const noResults =
    list.isSearching &&
    visible.length === 0 &&
    !hasArchivedSection &&
    !isArchiveLoading;
  const count =
    isLoading || loadFailed || isArchiveLoading
      ? undefined
      : visible.length + list.archived.length;
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
  const page = (
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
            onSearchFocus={archived.loadForSearch}
          />
        )
      }
    >
      <NotesBoardSkeleton
        loading={
          isLoading ||
          (isArchiveLoading &&
            (list.isSearching ? !visible.length : !notes.length))
        }
      />
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
            Create a note, or import your notes from Google Keep or Markdown in
            Settings.
          </EmptyState>
        ))}
      {noResults && <NoSearchResults list={list} />}
      {(visible.length > 0 || (hasArchivedSection && !isLoading)) && (
        <NotesBoard
          ref={list.boardRef}
          layout={list.layout}
          picking={list.picking}
          picked={list.picked}
          onPick={onPick}
          onShare={setSharingNote}
          noteHref={isColumns ? (id) => noteHref(id, tagId) : undefined}
          openId={openId}
          onDropOut={isColumns ? dropNotes : undefined}
          reorder={ordering.reorder}
          onMoveByKey={ordering.onMoveByKey}
          groups={[
            ...(pinned.length || ordering.reorder
              ? [
                  {
                    key: "pinned",
                    label: "Pinned",
                    icon: <Pin aria-hidden />,
                    notes: pinned,
                    isDropOnly: !pinned.length,
                    dropHint: "Drop here to pin",
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
            ...(hasArchivedSection
              ? [
                  {
                    key: "archived",
                    label: "Archived",
                    icon: <Archive aria-hidden />,
                    notes: list.archived,
                    fold: list.isArchivedFoldable
                      ? {
                          isOpen: list.isArchivedOpen,
                          onToggle: () => {
                            list.prepareCardMotion();
                            archived.toggleFold();
                          },
                        }
                      : undefined,
                    fallback: archiveFailed ? (
                      <LoadFailedRow
                        message="Couldn’t load archived notes."
                        onRetry={() => archived.query.refetch()}
                        isRetrying={archived.query.isFetching}
                      />
                    ) : undefined,
                  },
                ]
              : []),
          ]}
        />
      )}
      <div className="sr-only" aria-live="polite">
        {ordering.announcement}
      </div>
    </AppPage>
  );
  const fab = !list.picking && (
    <Fab label="New note" asChild>
      <Link
        href={newNote}
        data-new-note="fab"
        onClick={(e) => rememberNewNoteButton(e.currentTarget)}
      >
        <Plus aria-hidden />
      </Link>
    </Fab>
  );
  const selectionBar = (
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
        allArchived
          ? {
              key: "unarchive",
              label: "Unarchive",
              icon: <ArchiveRestore aria-hidden />,
              onClick: () =>
                noteAction.mutate({
                  kind: "unarchive",
                  ids: chosen.map((n) => n.id),
                }),
            }
          : {
              key: "archive",
              label: "Archive",
              icon: <Archive aria-hidden />,
              onClick: () =>
                noteAction.mutate({
                  kind: "archive",
                  ids: chosen.filter((n) => !n.isArchived).map((n) => n.id),
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
  );

  return (
    <>
      {isColumns ? (
        <div data-columns className="flex min-h-0 flex-1">
          <section
            aria-label="Notes"
            className="notes-pane flex w-84 shrink-0 flex-col border-divider border-r"
          >
            {page}
          </section>
          <div className="relative flex min-w-0 flex-1 flex-col">
            {/* Stays mounted while picking, so Esc brings the note back. */}
            <div
              hidden={list.picking}
              className="absolute inset-0 flex flex-col"
            >
              {openNote}
            </div>
            {list.picking && <PickedSummary notes={chosen} />}
            {selectionBar}
          </div>
        </div>
      ) : (
        <>
          {page}
          {fab}
          {selectionBar}
        </>
      )}

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

function PickedSummary({ notes }: { notes: Note[] }) {
  const titles = notes.map((note) => note.title.trim() || "Untitled");
  return (
    <div className="grid flex-1 place-content-center justify-items-center gap-2 px-6 pb-24 text-center">
      <div aria-hidden className="mb-4 grid w-72 *:col-start-1 *:row-start-1">
        {titles
          .slice(0, 3)
          .reverse()
          .map((title, i, shown) => (
            <div
              key={`${i}-${title}`}
              style={{
                translate: `0 ${(shown.length - 1 - i) * -10}px`,
                scale: 1 - (shown.length - 1 - i) * 0.05,
              }}
              className="truncate rounded-card bg-card px-4.5 py-4 text-left font-semibold text-card-title shadow-[inset_0_0_0_1px_var(--border)]"
            >
              {title}
            </div>
          ))}
      </div>
      <h2 className="m-0 text-heading">
        {notes.length
          ? `${plural(notes.length, "note")} selected`
          : "Select notes"}
      </h2>
      <p className="m-0 max-w-90 text-muted-foreground text-ui">
        {notes.length
          ? titles.slice(0, 3).join(", ") +
            (notes.length > 3 ? ` and ${notes.length - 3} more` : "")
          : `Click the circle on a note, or ${isMac() ? "⌘" : "Ctrl"}-click it. Shift-click picks a range.`}
      </p>
    </div>
  );
}
