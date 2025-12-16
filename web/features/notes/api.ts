import { api } from "@/lib/api/client";
import type { Note, CreateNoteDto, UpdateNoteDto } from "./types";

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

