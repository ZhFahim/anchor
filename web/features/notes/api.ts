import { api } from "@/lib/api/client";
import type {
  CreateNoteDto,
  Note,
  NoteLockResponse,
  NoteUnlockResponse,
  UpdateNoteDto,
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

export async function lockNote(id: string): Promise<NoteLockResponse> {
  const response = await api.post(`api/notes/${id}/lock`, { throwHttpErrors: false });
  if (!response.ok && response.status !== 409) {
    throw new Error("Failed to lock note");
  }
  return response.json<NoteLockResponse>();
}

export async function unlockNote(id: string): Promise<NoteUnlockResponse> {
  return api.delete(`api/notes/${id}/lock`).json<NoteUnlockResponse>();
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