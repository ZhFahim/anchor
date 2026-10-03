type NoteState = "active" | "trashed" | "deleted";
export type NoteSharePermission = "viewer" | "editor";
type NotePermission = "owner" | NoteSharePermission;

type AttachmentType = "image" | "audio";

export interface NoteAttachment {
  id: string;
  noteId: string;
  type: AttachmentType;
  originalFilename: string;
  mimeType: string;
  fileSize: number;
  position: number;
  uploadedByUserId?: string | null;
  createdAt: string;
}

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

export type ReminderRecurrence =
  | "none"
  | "daily"
  | "weekly"
  | "monthly"
  | "yearly";

export interface NoteReminder {
  remindAt: string;
  recurrence: ReminderRecurrence;
  version: number;
}

export interface Note {
  id: string;
  title: string;
  content?: string | null;
  isPinned: boolean;
  isArchived: boolean;
  background?: string | null;
  state: NoteState;
  version: number;
  createdAt: string;
  updatedAt: string;
  userId: string;
  tagIds?: string[];
  permission: NotePermission;
  shareIds?: string[];
  sharedBy?: {
    id: string;
    name: string;
    email: string;
    profileImage?: string | null;
  };
  attachmentCount?: number;
  imagePreviewIds?: string[];
  reminder?: NoteReminder | null;
  stateChangedAt?: string;
}

// "conflict" holds content the server turned down, which never reached the note.
export type NoteRevisionCause = "edit" | "conflict" | "restore";

export interface NoteRevisionAuthor {
  id: string;
  name: string;
  email: string;
  profileImage?: string | null;
}

export interface NoteRevisionSummary {
  id: string;
  noteId: string;
  version: number;
  title: string;
  cause: NoteRevisionCause;
  createdAt: string;
  author: NoteRevisionAuthor | null;
}

export interface NoteRevision extends NoteRevisionSummary {
  content: string | null;
}

export interface NoteRevisionPage {
  revisions: NoteRevisionSummary[];
  nextCursor: string | null;
}

export interface UserSearchResult {
  id: string;
  name: string;
  email: string;
  profileImage?: string | null;
}

export interface CreateNoteDto {
  id?: string;
  title: string;
  content?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  background?: string | null;
  tagIds?: string[];
  reminder?: NoteReminderInput | null;
}

export interface UpdateNoteDto {
  title?: string;
  content?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  background?: string | null;
  tagIds?: string[];
  reminder?: NoteReminderInput | null;
  baseVersion?: number;
  replacesOtherEdit?: boolean;
}

export interface NoteReminderInput {
  remindAt: string;
  recurrence?: ReminderRecurrence;
}
