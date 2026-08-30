import { stringifyDelta } from "@/features/notes/quill";
import type { NoteAttachment } from "@/features/notes/types";
import { api } from "@/lib/api/client";
import type {
  CanonicalNote,
  ExportFormat,
  ImportNoteItem,
  ImportNotesResponse,
  ImportTag,
} from "./types";

export const IMPORT_BATCH_SIZE = 25;

export async function downloadExport(
  format: ExportFormat = "anchor",
): Promise<void> {
  // Export can take a while for large accounts; disable the 30s default
  const response = await api.get("api/export", {
    searchParams: { format },
    timeout: false,
  });
  const blob = await response.blob();

  const disposition = response.headers.get("Content-Disposition") ?? "";
  const match = disposition.match(/filename="([^"]+)"/);
  const fallbackName =
    format === "markdown" ? "anchor-markdown" : "anchor-export";
  const filename =
    match?.[1] ??
    `${fallbackName}-${new Date().toISOString().slice(0, 10)}.zip`;

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  // Revoking synchronously can cancel the download in some browsers
  setTimeout(() => URL.revokeObjectURL(url), 30_000);
}

export function toImportNoteItem(
  note: CanonicalNote,
  tagNames: string[] = note.tagNames,
): ImportNoteItem {
  return {
    ref: note.ref,
    id: note.id,
    title: note.title,
    content: stringifyDelta(note.contentDelta),
    isPinned: note.isPinned,
    isArchived: note.isArchived,
    isTrashed: note.isTrashed,
    background: note.background ?? undefined,
    tagNames: tagNames.length ? tagNames : undefined,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  };
}

export async function importNotes(
  notes: ImportNoteItem[],
  tags: ImportTag[],
  skipExisting: boolean,
): Promise<ImportNotesResponse> {
  const palette = tags.map((tag) => ({
    name: tag.name,
    ...(tag.color ? { color: tag.color } : {}),
  }));
  return api
    .post("api/import/notes", {
      json: { notes, tags: palette, skipExisting },
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
