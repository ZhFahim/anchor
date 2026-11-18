"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as React from "react";
import { toast } from "@/components/ui/toast";
import {
  moveNextToNeighbours,
  type PositionChange,
  planPositions,
  stepInOrder,
  withPositions,
} from "@/features/ordering";
import { REORDER_MUTATION_KEY } from "@/features/sync/use-sync";
import { bulkPinNotes, getNotes, setNotePositions } from "../api";
import type { BoardDrop, BoardReorder } from "../components/board-drag";
import { compareNotes } from "../sort";
import { hasTitle } from "../title";
import type { Note } from "../types";
import type { NoteList } from "./use-note-list";

interface OrderWrite {
  changes: Pick<PositionChange, "id" | "position">[];
  pin?: { noteId: string; isPinned: boolean };
}

const SORTABLE_GROUPS = ["pinned", "others"];
const noteLabel = (note?: Note) =>
  note && hasTitle(note.title) ? `“${note.title}”` : "note";

/**
 * Drag and drop on the Notes page: works out the new places, shows them at
 * once, and saves them one after another.
 */
export function useNoteReorder({
  list,
  notes,
  tagId,
}: {
  list: NoteList;
  notes: Note[];
  tagId: string | null;
}) {
  const queryClient = useQueryClient();
  const [announcement, setAnnouncement] = React.useState("");
  const isEnabled = !list.isSearching && !list.picking;

  // A tag view places notes among all of them, so it keeps the full list near.
  useQuery({
    queryKey: ["notes", null],
    queryFn: () => getNotes(),
    enabled: isEnabled && !!tagId,
  });

  const showInCache = React.useCallback(
    ({ changes, pin }: OrderWrite) => {
      queryClient.setQueriesData<Note[]>({ queryKey: ["notes"] }, (cached) => {
        if (!Array.isArray(cached)) return cached;
        const placed = withPositions(cached, changes);
        return pin
          ? placed.map((note) =>
              note.id === pin.noteId
                ? { ...note, isPinned: pin.isPinned }
                : note,
            )
          : placed;
      });
    },
    [queryClient],
  );

  const save = useMutation({
    mutationKey: REORDER_MUTATION_KEY,
    scope: { id: "note-order" },
    mutationFn: async ({ changes, pin }: OrderWrite) => {
      if (pin) await bulkPinNotes([pin.noteId], pin.isPinned);
      if (changes.length)
        await setNotePositions(
          changes.map(({ id, position }) => ({ noteId: id, position })),
        );
    },
    onError: (_, { pin }) => {
      const note = notes.find((n) => n.id === pin?.noteId);
      toast.error(
        pin
          ? `Couldn’t move ${noteLabel(note)}`
          : "Couldn’t save the new order",
      );
    },
    onSettled: () => {
      // Pulls wait while orders are on their way, so the last one refreshes.
      if (queryClient.isMutating({ mutationKey: REORDER_MUTATION_KEY }) <= 1) {
        void queryClient.invalidateQueries({ queryKey: ["notes"] });
      }
    },
  });

  const allNotes = React.useCallback(async (): Promise<Note[]> => {
    if (!tagId) return notes;
    return queryClient.ensureQueryData({
      queryKey: ["notes", null],
      queryFn: () => getNotes(),
    });
  }, [notes, queryClient, tagId]);

  const place = React.useCallback(
    async ({ noteId, fromGroup, toGroup, orderedIds }: BoardDrop) => {
      const all = await allNotes();
      const wasCustom = list.sortBy === "custom";
      const shown = [...all]
        .filter((note) => !note.isArchived)
        .sort(compareNotes(list.sortBy, list.sortOrder));
      const ordered = moveNextToNeighbours(shown, noteId, orderedIds);
      const changes = planPositions(ordered, noteId, { placeAll: !wasCustom });
      const pin =
        fromGroup === toGroup
          ? undefined
          : { noteId, isPinned: toGroup === "pinned" };

      await queryClient.cancelQueries({ queryKey: ["notes"] });
      list.prepareCardMotion();
      const write: OrderWrite = { changes, pin };
      showInCache(write);
      save.mutate(write);

      if (wasCustom) return;
      const previousSort = { by: list.sortBy, order: list.sortOrder };
      list.setSort("custom", list.sortOrder);
      toast.success("Switched to Custom order", {
        undo: () => {
          const back: OrderWrite = {
            changes: changes.map(({ id, previous }) => ({
              id,
              position: previous,
            })),
            pin: pin && { noteId, isPinned: !pin.isPinned },
          };
          list.setSort(previousSort.by, previousSort.order);
          showInCache(back);
          save.mutate(back);
        },
      });
    },
    [allNotes, list, queryClient, save, showInCache],
  );

  const onMoveByKey = React.useCallback(
    (noteId: string, step: -1 | 1) => {
      const group = list.pinned.some((n) => n.id === noteId)
        ? "pinned"
        : "others";
      const groupNotes = group === "pinned" ? list.pinned : list.others;
      const orderedIds = stepInOrder(
        groupNotes.map((n) => n.id),
        noteId,
        step,
      );
      if (!orderedIds) return;
      void place({ noteId, fromGroup: group, toGroup: group, orderedIds });
      const note = groupNotes.find((n) => n.id === noteId);
      setAnnouncement(
        `Moved ${noteLabel(note)} to position ${orderedIds.indexOf(noteId) + 1} of ${orderedIds.length}`,
      );
      // Moving the card in the page takes focus away from it.
      requestAnimationFrame(() =>
        document
          .querySelector<HTMLElement>(`.nc[data-flip="${noteId}"] .nc-link`)
          ?.focus(),
      );
    },
    [list.others, list.pinned, place],
  );

  const reorder = React.useMemo<BoardReorder | undefined>(
    () =>
      isEnabled
        ? {
            groups: SORTABLE_GROUPS,
            onDrop: place,
            onHold: (noteId) => list.onPick(noteId, false),
            prepareMotion: list.prepareCardMotion,
          }
        : undefined,
    [isEnabled, place, list.onPick, list.prepareCardMotion],
  );

  return {
    reorder,
    onMoveByKey: isEnabled ? onMoveByKey : undefined,
    announcement,
  };
}
