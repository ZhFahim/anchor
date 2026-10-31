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
      ? list.map((listed) => (listed.id === note.id ? note : listed))
      : list,
  );
}
