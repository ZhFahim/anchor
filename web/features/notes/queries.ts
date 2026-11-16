import { type QueryClient, queryOptions } from "@tanstack/react-query";
import { getArchivedNotes } from "./api";
import type { Note } from "./types";

export const archivedNotesQuery = queryOptions({
  queryKey: ["notes", "archived"],
  queryFn: getArchivedNotes,
});

export function cacheSavedNote(queryClient: QueryClient, note: Note) {
  queryClient.setQueryData(["notes", note.id], note);
  queryClient.setQueriesData<Note[]>({ queryKey: ["notes"] }, (list) =>
    Array.isArray(list)
      ? list.map((listed) =>
          listed.id === note.id ? keepPosition(note, listed) : listed,
        )
      : list,
  );
}

/** A response that didn't load the note's place keeps the one we know. */
function keepPosition(note: Note, known: Note): Note {
  return note.position === undefined && known.position !== undefined
    ? { ...note, position: known.position }
    : note;
}
