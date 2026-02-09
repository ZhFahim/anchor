import { api } from "@/lib/api/client";
import type {
  Note,
  CreateNoteDto,
  UpdateNoteDto,
  ReorderNotesDto,
  NoteShare,
  NoteSharePermission,
  UserSearchResult,
} from "./types";

interface NotesQueryParams {
  search?: string;
  tagId?: string;
}

export async function getNotes(params?: NotesQueryParams): Promise<Note[]> {
  const searchParams = new URLSearchParams();
  if (params?.search) searchParams.set("search", params.search);
  if (params?.tagId) searchParams.set("tagId", params.tagId);

  const queryString = searchParams.toString();
  const url = queryString ? `api/notes?${queryString}` : "api/notes";

  return api.get(url).json<Note[]>();
}

export async function getNote(id: string): Promise<Note> {
  return api.get(`api/notes/${id}`).json<Note>();
}

export async function createNote(data: CreateNoteDto): Promise<Note> {
  return api.post("api/notes", { json: data }).json<Note>();
}

export async function updateNote(id: string, data: UpdateNoteDto): Promise<Note> {
  return api.patch(`api/notes/${id}`, { json: data }).json<Note>();
}

export async function deleteNote(id: string): Promise<void> {
  await api.delete(`api/notes/${id}`);
}

export async function getTrashedNotes(): Promise<Note[]> {
  return api.get("api/notes/trash").json<Note[]>();
}

export async function restoreNote(id: string): Promise<Note> {
  return api.patch(`api/notes/${id}/restore`).json<Note>();
}

export async function permanentDeleteNote(id: string): Promise<void> {
  await api.delete(`api/notes/${id}/permanent`);
}

export async function getArchivedNotes(): Promise<Note[]> {
  return api.get("api/notes/archive").json<Note[]>();
}

export async function archiveNote(id: string): Promise<Note> {
  return api.patch(`api/notes/${id}`, { json: { isArchived: true } }).json<Note>();
}

export async function unarchiveNote(id: string): Promise<Note> {
  return api.patch(`api/notes/${id}`, { json: { isArchived: false } }).json<Note>();
}

export async function bulkDeleteNotes(noteIds: string[]): Promise<{ count: number }> {
  return api.post("api/notes/bulk/delete", { json: { noteIds } }).json<{ count: number }>();
}

export async function bulkArchiveNotes(noteIds: string[]): Promise<{ count: number }> {
  return api.post("api/notes/bulk/archive", { json: { noteIds } }).json<{ count: number }>();
}

export async function reorderNotes(data: ReorderNotesDto): Promise<{ success: boolean }> {
  return api.post("api/notes/reorder", { json: data }).json<{ success: boolean }>();
}

// Sharing APIs
export async function shareNote(
  noteId: string,
  sharedWithUserId: string,
  permission: NoteSharePermission,
): Promise<NoteShare> {
  return api
    .post(`api/notes/${noteId}/shares`, {
      json: { sharedWithUserId, permission },
    })
    .json<NoteShare>();
}

export async function getNoteShares(noteId: string): Promise<NoteShare[]> {
  return api.get(`api/notes/${noteId}/shares`).json<NoteShare[]>();
}

export async function updateNoteSharePermission(
  noteId: string,
  shareId: string,
  permission: NoteSharePermission,
): Promise<NoteShare> {
  return api
    .patch(`api/notes/${noteId}/shares/${shareId}`, { json: { permission } })
    .json<NoteShare>();
}

export async function revokeShare(
  noteId: string,
  shareId: string,
): Promise<{ success: boolean }> {
  return api
    .delete(`api/notes/${noteId}/shares/${shareId}`)
    .json<{ success: boolean }>();
}

export async function searchUsers(query: string): Promise<UserSearchResult[]> {
  if (!query || query.trim().length < 2) {
    return [];
  }
  return api
    .get("api/users/search", {
      searchParams: { q: query.trim() },
    })
    .json<UserSearchResult[]>();
}