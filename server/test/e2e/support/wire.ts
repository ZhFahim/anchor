// Wire shapes as observed by these tests, deliberately duplicated from the
// server source so a type change there breaks the tests here.

export interface NoteOnWire {
  id: string;
  version: number;
  title: string;
  content: string | null;
  isArchived: boolean;
  isPinned: boolean;
  background: string | null;
  state: 'active' | 'trashed' | 'deleted';
  permission: 'owner' | 'viewer' | 'editor';
  tagIds: string[];
  attachmentCount: number;
  imagePreviewIds: string[];
  userId: string;
  createdAt: string;
  updatedAt: string;
  reminder?: ReminderOnWire | null;
  shareIds?: string[];
  sharedBy?: {
    id: string;
    name: string;
    email: string;
    profileImage: string | null;
  };
}

export interface TagOnWire {
  id: string;
  name: string;
  color: string | null;
  isDeleted: boolean;
  userId: string;
  createdAt: string;
  updatedAt: string;
  _count?: { notes: number };
}

export interface AttachmentOnWire {
  id: string;
  noteId: string;
  type: 'image' | 'audio';
  originalFilename: string;
  mimeType: string;
  fileSize: number;
  position: number;
  uploadedByUserId: string;
  createdAt: string;
}

export interface ShareOnWire {
  id: string;
  permission: 'viewer' | 'editor';
  sharedWithUser: {
    id: string;
    name: string;
    email: string;
    profileImage: string | null;
  };
  createdAt: string;
  updatedAt: string;
}

export interface ImportResultOnWire {
  ref: string;
  status: 'created' | 'skipped' | 'remapped' | 'failed';
  noteId?: string;
  warning?: string;
  error?: string;
}

export interface RevisionOnWire {
  id: string;
  noteId: string;
  version: number;
  title: string;
  content?: string | null;
  cause: 'edit' | 'conflict' | 'restore';
  createdAt: string;
  author: {
    id: string;
    name: string;
    email: string;
    profileImage: string | null;
  } | null;
}

export interface RevisionPageOnWire {
  revisions: RevisionOnWire[];
  nextCursor: string | null;
}

export interface SyncTagOnWire {
  id: string;
  name: string;
  color: string | null;
  version: number;
  createdAt: string;
  updatedAt: string;
}

export interface ReminderOnWire {
  remindAt: string;
  recurrence: 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly';
  version: number;
}

export interface SyncEntry {
  seq: string;
  entityType: 'note' | 'tag' | 'pin' | 'attachments' | 'reminder';
  entityId: string;
  op: 'upsert' | 'remove';
  note?: NoteOnWire & { version: number };
  tag?: SyncTagOnWire;
  attachments?: AttachmentOnWire[];
  reminder?: ReminderOnWire;
}

interface SyncResult {
  type: 'note' | 'tag' | 'pin' | 'reminder';
  id: string;
  status: 'applied' | 'conflict' | 'denied';
  version?: number;
  serverCopy?:
    (NoteOnWire & { version: number }) | SyncTagOnWire | ReminderOnWire;
}

export interface SyncResponse {
  protocol: number;
  results: SyncResult[];
  entries: SyncEntry[];
  nextCursor: string | null;
  hasMore: boolean;
  resetRequired?: boolean;
}

interface ExportManifestNoteOnWire {
  id: string;
  origin: 'owned' | 'shared';
  title: string;
  content: string | null;
  state: 'active' | 'trashed';
  isArchived: boolean;
  isPinned: boolean;
  background: string | null;
  tagIds: string[];
  createdAt: string;
  updatedAt: string;
  reminder?: { remindAt: string; recurrence: string };
  sharedBy?: { name: string; email: string };
  attachments: {
    id: string;
    type: 'image' | 'audio';
    originalFilename: string;
    mimeType: string;
    fileSize: number;
    position: number;
    archivePath: string;
  }[];
}

export interface ExportManifestOnWire {
  format: 'anchor-export';
  version: 1;
  exportedAt: string;
  server: { version: string | null };
  user: { id: string; email: string };
  counts: { notes: number; tags: number; attachments: number };
  tags: { id: string; name: string; color: string | null }[];
  notes: ExportManifestNoteOnWire[];
  warnings: string[];
}
