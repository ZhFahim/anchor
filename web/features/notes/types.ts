import type { Tag } from "@/features/tags/types";

export type NoteState = "active" | "trashed" | "deleted";
export type NoteLockOwner = "anchor" | "homarr";

export interface Note {
  id: string;
  title: string;
  content?: string | null;
  isPinned: boolean;
  isArchived: boolean;
  background?: string | null;
  state: NoteState;
  createdAt: string;
  updatedAt: string;
  userId: string;
  tagIds?: string[];
  tags?: Tag[];
}

export interface CreateNoteDto {
  title: string;
  content?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  background?: string | null;
  tagIds?: string[];
}

export interface UpdateNoteDto {
  title?: string;
  content?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  background?: string | null;
  tagIds?: string[];
}

export interface NoteLockResponse {
  status: "acquired" | "locked";
  lockedBy: NoteLockOwner;
  expiresAt: string;
}

export interface NoteUnlockResponse {
  status: "released";
}