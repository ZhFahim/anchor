import type { Tag } from "@/features/tags/types";

export type NoteState = "active" | "trashed" | "deleted";
export type NoteSharePermission = "viewer" | "editor";
export type NotePermission = "owner" | NoteSharePermission;

export interface NoteShare {
  id: string;
  sharedWithUser: {
    id: string;
    name: string;
    email: string;
    profileImage?: string | null;
  };
  permission: NoteSharePermission;
  createdAt: string;
  updatedAt: string;
}

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
  permission: NotePermission;
  shareIds?: string[];
  sharedBy?: {
    id: string;
    name: string;
    email: string;
    profileImage?: string | null;
  };
}

export interface UserSearchResult {
  id: string;
  name: string;
  email: string;
  profileImage?: string | null;
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

