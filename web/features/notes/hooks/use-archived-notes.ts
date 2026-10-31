"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import * as React from "react";
import { usePreferencesStore } from "@/features/preferences";
import { archivedNotesQuery } from "../queries";
import type { Note } from "../types";

const NO_NOTES: Note[] = [];

export function useArchivedNotes(tagId: string | null, notes: Note[]) {
  const queryClient = useQueryClient();
  const [isSearchUsed, setIsSearchUsed] = React.useState(false);
  const query = useQuery({
    ...archivedNotesQuery,
    enabled: !!tagId || isSearchUsed,
  });
  const all = query.data ?? NO_NOTES;
  const tagged = React.useMemo(
    () => (tagId ? all.filter((note) => note.tagIds?.includes(tagId)) : all),
    [all, tagId],
  );
  const isOpenSaved = usePreferencesStore(
    (s) => !!tagId && s.notes.openArchivedTagIds.includes(tagId),
  );
  const setArchivedOpen = usePreferencesStore((s) => s.setArchivedOpen);

  const setArchivedInCache = (ids: string[], isArchived: boolean) => {
    const moving = new Set(ids);
    const moved = [...notes, ...all]
      .filter((note) => moving.has(note.id))
      .map((note) => ({ ...note, isArchived }));
    const without = (listed: Note[]) =>
      listed.filter((note) => !moving.has(note.id));
    queryClient.setQueryData<Note[]>(
      ["notes", tagId],
      (listed) =>
        listed &&
        (isArchived ? without(listed) : [...moved, ...without(listed)]),
    );
    queryClient.setQueryData<Note[]>(
      archivedNotesQuery.queryKey,
      (listed) =>
        listed &&
        (isArchived ? [...moved, ...without(listed)] : without(listed)),
    );
  };

  return {
    query,
    all,
    tagged,
    listOptions: {
      notes: tagged,
      isSearchOnly: !tagId,
      canFold: !!tagId && notes.length > 0,
      isFolded: !isOpenSaved,
    },
    loadForSearch: () => setIsSearchUsed(true),
    toggleFold: () => {
      if (tagId) setArchivedOpen(tagId, !isOpenSaved);
    },
    setArchivedInCache,
  };
}
