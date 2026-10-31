"use client";

import * as React from "react";
import {
  type SortBy,
  type SortOrder,
  usePreferencesStore,
  type ViewMode,
} from "@/features/preferences";
import { useFlip } from "@/lib/use-flip";
import { deltaToFullPlainText } from "../quill";
import { compareNotes } from "../sort";
import type { Note } from "../types";

const searchTextByNote = new WeakMap<Note, string>();

function searchTextOf(note: Note) {
  let text = searchTextByNote.get(note);
  if (text === undefined) {
    text = `${note.title}\n${deltaToFullPlainText(note.content)}`.toLowerCase();
    searchTextByNote.set(note, text);
  }
  return text;
}

const NO_NOTES: Note[] = [];

function findAndSort(
  notes: Note[],
  term: string,
  sortBy: SortBy,
  sortOrder: SortOrder,
) {
  const found = term
    ? notes.filter((note) => searchTextOf(note).includes(term))
    : notes;
  return [...found].sort(compareNotes(sortBy, sortOrder));
}

export function useNoteList(
  notes: Note[],
  {
    pinnedFirst = false,
    archived,
  }: {
    pinnedFirst?: boolean;
    archived?: {
      notes: Note[];
      isSearchOnly: boolean;
      canFold: boolean;
      /** Ignored while searching. */
      isFolded: boolean;
    };
  } = {},
) {
  const { viewMode, sortBy, sortOrder } = usePreferencesStore((s) => s.notes);
  const setNotesPreference = usePreferencesStore((s) => s.setNotesPreference);
  const boardRef = React.useRef<HTMLDivElement>(null);
  const searchRef = React.useRef<HTMLInputElement>(null);
  const flip = useFlip(boardRef);
  const [query, setQueryValue] = React.useState("");
  const searchedQuery = React.useDeferredValue(query);
  const [picking, setPicking] = React.useState(false);
  const [picked, setPicked] = React.useState<Set<string>>(new Set());
  const lastPick = React.useRef<string | null>(null);

  const term = searchedQuery.trim().toLowerCase();
  const visible = React.useMemo(
    () => findAndSort(notes, term, sortBy, sortOrder),
    [notes, term, sortBy, sortOrder],
  );
  const isSearching = term !== "";
  const hasArchived = !!archived && (isSearching || !archived.isSearchOnly);
  const archivedNotes = (hasArchived && archived?.notes) || NO_NOTES;
  const archivedVisible = React.useMemo(
    () => findAndSort(archivedNotes, term, sortBy, sortOrder),
    [archivedNotes, term, sortBy, sortOrder],
  );
  const isArchivedFoldable = hasArchived && !!archived?.canFold && !isSearching;
  const isArchivedOpen =
    hasArchived && !(isArchivedFoldable && archived?.isFolded);
  const pinned = React.useMemo(
    () => (pinnedFirst ? visible.filter((n) => n.isPinned) : []),
    [pinnedFirst, visible],
  );
  const others = React.useMemo(
    () => (pinnedFirst ? visible.filter((n) => !n.isPinned) : visible),
    [pinnedFirst, visible],
  );
  const shown = React.useMemo(
    () =>
      pinned.length || isArchivedOpen
        ? [...pinned, ...others, ...(isArchivedOpen ? archivedVisible : [])]
        : others,
    [pinned, others, isArchivedOpen, archivedVisible],
  );
  const shownRef = React.useRef(shown);
  React.useLayoutEffect(() => {
    shownRef.current = shown;
  });

  const stopPicking = React.useCallback(() => {
    setPicking(false);
    setPicked(new Set());
    lastPick.current = null;
  }, []);

  React.useEffect(() => {
    if (!picking) return;
    // An Esc that closed a menu, pop-over or dialog stops there.
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !e.defaultPrevented) stopPicking();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [picking, stopPicking]);

  React.useEffect(() => {
    const shownIds = new Set(shown.map((note) => note.id));
    setPicked((prev) => {
      const kept = [...prev].filter((id) => shownIds.has(id));
      return kept.length === prev.size ? prev : new Set(kept);
    });
  }, [shown]);

  const isEmpty = notes.length === 0 && archivedNotes.length === 0;
  React.useEffect(() => {
    if (picking && isEmpty) stopPicking();
  }, [picking, isEmpty, stopPicking]);

  const onPick = React.useCallback((id: string, range: boolean) => {
    const ids = shownRef.current.map((n) => n.id);
    const from = lastPick.current ? ids.indexOf(lastPick.current) : -1;
    const to = ids.indexOf(id);
    lastPick.current = id;
    setPicking(true);
    setPicked((prev) => {
      const next = new Set(prev);
      if (range && from >= 0 && to >= 0)
        for (const rangeId of ids.slice(
          Math.min(from, to),
          Math.max(from, to) + 1,
        ))
          next.add(rangeId);
      else if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleAll = () =>
    setPicked(
      picked.size === shown.length
        ? new Set()
        : new Set(shown.map((n) => n.id)),
    );
  const chosen = shown.filter((n) => picked.has(n.id));

  return {
    boardRef,
    searchRef,
    prepareCardMotion: flip.prepare,
    query,
    setQuery: (value: string) => {
      flip.prepare();
      setQueryValue(value);
    },
    layout: viewMode,
    setLayout: (layout: ViewMode) => {
      flip.prepare();
      setNotesPreference("viewMode", layout);
    },
    sortBy,
    sortOrder,
    setSort: (by: SortBy, order: SortOrder) => {
      flip.prepare();
      setNotesPreference("sortBy", by);
      setNotesPreference("sortOrder", order);
    },
    visible,
    pinned,
    others,
    isSearching,
    hasArchived,
    archived: archivedVisible,
    isArchivedFoldable,
    isArchivedOpen,
    shown,
    picking,
    togglePicking: () => (picking ? stopPicking() : setPicking(true)),
    picked,
    chosen,
    onPick,
    toggleAll,
    stopPicking,
  };
}

export type NoteList = ReturnType<typeof useNoteList>;
