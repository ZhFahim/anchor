import { HTTPError } from "ky";
import { getAccessToken } from "@/features/auth/store";
import { api, getJson } from "@/lib/api/client";
import { uploadWithProgress } from "@/lib/api/upload";
import { fitsKeepalive } from "@/lib/page-close";
import type { SaveOutcome } from "./save-queue";
import type {
  CreateNoteDto,
  Note,
  NoteAttachment,
  NoteRevision,
  NoteRevisionPage,
  NoteShare,
  NoteSharePermission,
  UpdateNoteDto,
  UserSearchResult,
} from "./types";

export async function getNotes(params?: { tagId?: string }): Promise<Note[]> {
  const url = params?.tagId
    ? `api/notes?${new URLSearchParams({ tagId: params.tagId })}`
    : "api/notes";
  return getJson<Note[]>(url);
}

export async function getNote(id: string): Promise<Note> {
  return getJson<Note>(`api/notes/${id}`);
}

export async function createNote(data: CreateNoteDto): Promise<Note> {
  return api.post("api/notes", { json: data }).json<Note>();
}

function isWorthAnotherTry(httpStatus: number): boolean {
  return httpStatus >= 500 || httpStatus === 408 || httpStatus === 429;
}

export function isRetryableError(error: unknown): boolean {
  return (
    !(error instanceof HTTPError) || isWorthAnotherTry(error.response.status)
  );
}

export async function saveNote(
  id: string,
  data: UpdateNoteDto,
): Promise<SaveOutcome> {
  const response = await api
    .patch(`api/notes/${id}`, { json: data, throwHttpErrors: false })
    .catch(() => null);

  if (!response) {
    return { status: "failed", httpStatus: null, retryable: true };
  }

  if (response.status === 409) {
    const body = await response.json<{ serverNote: Note }>();
    return { status: "conflict", serverNote: body.serverNote };
  }

  if (!response.ok) {
    return {
      status: "failed",
      httpStatus: response.status,
      retryable: isWorthAnotherTry(response.status),
    };
  }

  return { status: "saved", note: await response.json<Note>() };
}

// Sent while the page is closing; it carries no base version, so the text on
// screen wins.
export function flushNoteUpdate(id: string, data: UpdateNoteDto): void {
  const token = getAccessToken();
  const body = JSON.stringify(data);

  void fetch(`/api/notes/${id}`, {
    method: "PATCH",
    keepalive: fitsKeepalive(body),
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body,
  }).catch(() => {});
}

/** `trashedAt` puts back the old trash date when a restore is undone. */
export async function deleteNote(
  id: string,
  trashedAt?: string,
): Promise<void> {
  await api.delete(`api/notes/${id}`, {
    searchParams: trashedAt ? { trashedAt } : undefined,
  });
}

export async function getTrashedNotes(): Promise<Note[]> {
  return getJson<Note[]>("api/notes/trash");
}

export async function restoreNote(id: string): Promise<Note> {
  return api.patch(`api/notes/${id}/restore`).json<Note>();
}

export async function permanentDeleteNote(id: string): Promise<void> {
  await api.delete(`api/notes/${id}/permanent`);
}

export async function getArchivedNotes(): Promise<Note[]> {
  return getJson<Note[]>("api/notes/archive");
}

export async function archiveNote(id: string): Promise<Note> {
  return api
    .patch(`api/notes/${id}`, { json: { isArchived: true } })
    .json<Note>();
}

export async function unarchiveNote(id: string): Promise<Note> {
  return api
    .patch(`api/notes/${id}`, { json: { isArchived: false } })
    .json<Note>();
}

const BULK_NOTE_IDS_PER_REQUEST = 200;

async function inBulkBatches(
  noteIds: string[],
  send: (batch: string[]) => Promise<{ count: number }>,
): Promise<{ count: number }> {
  let count = 0;
  for (let i = 0; i < noteIds.length; i += BULK_NOTE_IDS_PER_REQUEST) {
    const result = await send(noteIds.slice(i, i + BULK_NOTE_IDS_PER_REQUEST));
    count += result.count;
  }
  return { count };
}

export async function bulkDeleteNotes(
  noteIds: string[],
): Promise<{ count: number }> {
  return inBulkBatches(noteIds, (batch) =>
    api
      .post("api/notes/bulk/delete", { json: { noteIds: batch } })
      .json<{ count: number }>(),
  );
}

export async function bulkArchiveNotes(
  noteIds: string[],
): Promise<{ count: number }> {
  return inBulkBatches(noteIds, (batch) =>
    api
      .post("api/notes/bulk/archive", { json: { noteIds: batch } })
      .json<{ count: number }>(),
  );
}

export async function bulkPinNotes(
  noteIds: string[],
  isPinned: boolean,
): Promise<{ count: number }> {
  return inBulkBatches(noteIds, (batch) =>
    api
      .post("api/notes/bulk/pin", { json: { noteIds: batch, isPinned } })
      .json<{ count: number }>(),
  );
}

export async function bulkAddTagsToNotes(
  noteIds: string[],
  tagIds: string[],
): Promise<{ count: number }> {
  return inBulkBatches(noteIds, (batch) =>
    api
      .post("api/notes/bulk/tags", { json: { noteIds: batch, tagIds } })
      .json<{ count: number }>(),
  );
}

export async function getNoteRevisions(
  noteId: string,
  cursor?: string,
): Promise<NoteRevisionPage> {
  return getJson<NoteRevisionPage>(`api/notes/${noteId}/revisions`, {
    searchParams: cursor ? { cursor } : {},
  });
}

export async function getNoteRevision(
  noteId: string,
  revisionId: string,
): Promise<NoteRevision> {
  return getJson<NoteRevision>(`api/notes/${noteId}/revisions/${revisionId}`);
}

export async function restoreNoteRevision(
  noteId: string,
  revisionId: string,
): Promise<Note> {
  return api
    .post(`api/notes/${noteId}/revisions/${revisionId}/restore`)
    .json<Note>();
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

export async function getRecentContacts(): Promise<UserSearchResult[]> {
  return api.get("api/users/recent-contacts").json<UserSearchResult[]>();
}

export async function uploadAttachment(
  noteId: string,
  file: File,
  options: { onProgress?: (done: number) => void; signal?: AbortSignal } = {},
): Promise<NoteAttachment> {
  const formData = new FormData();
  formData.append("file", file);
  return uploadWithProgress<NoteAttachment>(
    `api/notes/${noteId}/attachments`,
    formData,
    options,
  );
}

export async function getNoteAttachments(
  noteId: string,
): Promise<NoteAttachment[]> {
  return api.get(`api/notes/${noteId}/attachments`).json<NoteAttachment[]>();
}

export async function fetchAttachmentBlob(
  noteId: string,
  attachmentId: string,
): Promise<Blob> {
  const response = await api.get(
    `api/notes/${noteId}/attachments/${attachmentId}`,
  );
  return response.blob();
}

export async function deleteAttachment(
  noteId: string,
  attachmentId: string,
): Promise<{ success: boolean }> {
  return api
    .delete(`api/notes/${noteId}/attachments/${attachmentId}`)
    .json<{ success: boolean }>();
}

export async function reorderAttachments(
  noteId: string,
  orderedIds: string[],
): Promise<NoteAttachment[]> {
  return api
    .patch(`api/notes/${noteId}/attachments/reorder`, { json: { orderedIds } })
    .json<NoteAttachment[]>();
}
