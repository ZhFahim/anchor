import * as path from 'path';

export const EXPORT_FORMAT = 'anchor-export';
export const EXPORT_VERSION = 1;

export interface ExportManifestTag {
  id: string;
  name: string;
  color: string | null;
}

export interface ExportManifestAttachment {
  id: string;
  type: string;
  originalFilename: string;
  mimeType: string;
  fileSize: number;
  position: number;
  archivePath: string;
}

export interface ExportManifestNote {
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
  sharedBy?: { name: string; email: string };
  attachments: ExportManifestAttachment[];
}

export interface ExportManifestV1 {
  format: typeof EXPORT_FORMAT;
  version: typeof EXPORT_VERSION;
  exportedAt: string;
  server: { version: string | null };
  user: { id: string; email: string };
  counts: { notes: number; tags: number; attachments: number };
  tags: ExportManifestTag[];
  notes: ExportManifestNote[];
  warnings: string[];
}

/** Minimal structural shape of a note row queried for export. */
export interface ExportNoteRow {
  id: string;
  title: string;
  content: string | null;
  state: string;
  isArchived: boolean;
  background: string | null;
  createdAt: Date;
  updatedAt: Date;
  tags: { id: string; userId: string }[];
  pins: { userId: string }[];
  attachments: {
    id: string;
    type: string;
    originalFilename: string;
    storedFilename: string;
    mimeType: string;
    fileSize: number;
    position: number;
  }[];
  sharedWith?: {
    sharedWithUserId: string;
    sharedByUser: { name: string; email: string };
  }[];
}

export const attachmentArchivePath = (
  noteId: string,
  attachmentId: string,
  storedFilename: string,
) => {
  const ext = path.extname(storedFilename).toLowerCase();
  return `attachments/${noteId}/${attachmentId}${ext}`;
};

export function buildManifestNote(
  note: ExportNoteRow,
  origin: 'owned' | 'shared',
  userId: string,
): ExportManifestNote {
  const entry: ExportManifestNote = {
    id: note.id,
    origin,
    title: note.title,
    content: note.content,
    state: note.state === 'trashed' ? 'trashed' : 'active',
    isArchived: note.isArchived,
    isPinned: note.pins.some((pin) => pin.userId === userId),
    background: note.background,
    // Only the exporting user's tags are meaningful in their backup
    tagIds: note.tags.filter((tag) => tag.userId === userId).map((t) => t.id),
    createdAt: note.createdAt.toISOString(),
    updatedAt: note.updatedAt.toISOString(),
    attachments: note.attachments.map((attachment) => ({
      id: attachment.id,
      type: attachment.type,
      originalFilename: attachment.originalFilename,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      position: attachment.position,
      archivePath: attachmentArchivePath(
        note.id,
        attachment.id,
        attachment.storedFilename,
      ),
    })),
  };

  if (origin === 'shared') {
    const share = note.sharedWith?.find((s) => s.sharedWithUserId === userId);
    if (share) {
      entry.sharedBy = {
        name: share.sharedByUser.name,
        email: share.sharedByUser.email,
      };
    }
  }

  return entry;
}

export function buildManifest(params: {
  user: { id: string; email: string };
  serverVersion: string | null;
  tags: ExportManifestTag[];
  ownedNotes: ExportNoteRow[];
  sharedNotes: ExportNoteRow[];
  warnings: string[];
}): ExportManifestV1 {
  const notes = [
    ...params.ownedNotes.map((note) =>
      buildManifestNote(note, 'owned', params.user.id),
    ),
    ...params.sharedNotes.map((note) =>
      buildManifestNote(note, 'shared', params.user.id),
    ),
  ];

  return {
    format: EXPORT_FORMAT,
    version: EXPORT_VERSION,
    exportedAt: new Date().toISOString(),
    server: { version: params.serverVersion },
    user: params.user,
    counts: {
      notes: notes.length,
      tags: params.tags.length,
      attachments: notes.reduce((sum, n) => sum + n.attachments.length, 0),
    },
    tags: params.tags,
    notes,
    warnings: params.warnings,
  };
}
