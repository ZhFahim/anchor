import { stringifyDelta } from "@/features/notes/quill";
import type { NoteAttachment } from "@/features/notes/types";
import { api } from "@/lib/api/client";
import type {
  CanonicalNote,
  ImportNoteItem,
  ImportNotesResponse,
  ImportTag,
} from "./types";

export const IMPORT_BATCH_SIZE = 25;

export async function downloadExport(): Promise<void> {
  // Export can take a while for large accounts; disable the 30s default
  const response = await api.get("api/export", { timeout: false });
  const blob = await response.blob();

  const disposition = response.headers.get("Content-Disposition") ?? "";
  const match = disposition.match(/filename="([^"]+)"/);
  const filename =
    match?.[1] ?? `anchor-export-${new Date().toISOString().slice(0, 10)}.zip`;

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  // Revoking synchronously can cancel the download in some browsers
  setTimeout(() => URL.revokeObjectURL(url), 30_000);
}

export function toImportNoteItem(note: CanonicalNote): ImportNoteItem {
  return {
    ref: note.ref,
    id: note.id,
    title: note.title,
    content: stringifyDelta(note.contentDelta),
    isPinned: note.isPinned,
    isArchived: note.isArchived,
    isTrashed: note.isTrashed,
    background: note.background ?? undefined,
    tagNames: note.tagNames.length ? note.tagNames : undefined,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  };
}

export async function importNotes(
  notes: ImportNoteItem[],
  tags: ImportTag[],
): Promise<ImportNotesResponse> {
  const palette = tags.map((tag) => ({
    name: tag.name,
    ...(tag.color ? { color: tag.color } : {}),
  }));
  return api
    .post("api/import/notes", {
      json: { notes, tags: palette },
      timeout: false,
    })
    .json<ImportNotesResponse>();
}

export async function importAttachment(
  noteId: string,
  blob: Blob,
  filename: string,
  mimeType: string,
  position: number,
): Promise<NoteAttachment> {
  const formData = new FormData();
  formData.append("file", new File([blob], filename, { type: mimeType }));
  formData.append("position", String(position));

  return api
    .post(`api/import/notes/${noteId}/attachments`, {
      body: formData,
      timeout: false,
    })
    .json<NoteAttachment>();
}
