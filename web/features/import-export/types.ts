import type { QuillDelta } from "@/features/notes/quill";

// Mirrors ATTACHMENT_ALLOWED_MIME_TYPES on the server
export const IMPORT_ALLOWED_MIME_TYPES = new Set([
  // Image
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  // Audio
  "audio/mpeg",
  "audio/wav",
  "audio/mp4",
  "audio/x-m4a",
  "audio/ogg",
  "audio/aac",
  "audio/webm",
]);

export type CanonicalAttachment = {
  filename: string;
  mimeType: string;
  /** Pre-checked against IMPORT_ALLOWED_MIME_TYPES */
  supported: boolean;
  /** Lazy: decompresses the zip entry only when uploading */
  getBlob: () => Promise<Blob>;
};

export type CanonicalNote = {
  /** Adapter-generated stable key, echoed back by the server per result */
  ref: string;
  /** Only set for anchor-native owned notes (preserved across restore) */
  id?: string;
  title: string;
  contentDelta: QuillDelta;
  isPinned: boolean;
  isArchived: boolean;
  isTrashed: boolean;
  background: string | null;
  tagNames: string[];
  createdAt?: string;
  updatedAt?: string;
  attachments: CanonicalAttachment[];
};

export type ImportSkippedItem = {
  item: string;
  reason: string;
};

export type ImportTag = {
  name: string;
  color: string | null;
};

export type ParsedImport = {
  formatId: "anchor" | "google-keep";
  formatLabel: string;
  notes: CanonicalNote[];
  /** Unique tags referenced across all notes, carrying colors for restore */
  tags: ImportTag[];
  attachmentCount: number;
  /** Items known up-front to be excluded (trashed Keep notes, unsupported media, ...) */
  skipped: ImportSkippedItem[];
};

export type ImportNoteItem = {
  ref: string;
  id?: string;
  title: string;
  content?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  isTrashed?: boolean;
  background?: string;
  tagNames?: string[];
  createdAt?: string;
  updatedAt?: string;
};

export type ImportNotesRequest = {
  notes: ImportNoteItem[];
  tags?: { name: string; color?: string }[];
  skipExisting?: boolean;
};

export type ImportNoteStatus = "created" | "skipped" | "remapped" | "failed";

export type ImportNoteResult = {
  ref: string;
  status: ImportNoteStatus;
  noteId?: string;
  warning?: string;
  error?: string;
};

export type ImportNotesResponse = {
  results: ImportNoteResult[];
  tags: { created: number; reused: number };
};
