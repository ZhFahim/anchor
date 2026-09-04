/**
 * Constants for notes module
 * Centralized query patterns, user selections, and error messages
 */

import type { Prisma } from 'src/generated/prisma/client';

// Standard user fields for queries
export const USER_SELECT_FIELDS = {
  id: true,
  name: true,
  email: true,
  profileImage: true,
} as const;

// Fields for sharedWithUser relations (includes profileImage)
export const SHARED_WITH_USER_SELECT = {
  id: true,
  name: true,
  email: true,
  profileImage: true,
} as const;

// Common Prisma include patterns for notes
export const NOTE_INCLUDE_TAGS = {
  tags: {
    where: { isDeleted: false },
    select: { id: true, userId: true },
  },
} as const;

// Include attachment count and image previews for notes
export const NOTE_INCLUDE_ATTACHMENT_COUNT = {
  _count: {
    select: { attachments: true },
  },
  attachments: {
    where: { type: 'image' },
    select: { id: true },
    orderBy: { position: 'asc' as const },
    take: 4,
  },
} as const;

// Include the requesting user's pin state.
export const notePinInclude = (userId: string) =>
  ({
    pins: {
      where: { userId },
      select: { userId: true },
    },
  }) as const;

// Include the requesting user's reminder.
export const noteReminderInclude = (userId: string) =>
  ({
    reminders: {
      where: { userId },
      select: {
        remindAt: true,
        recurrence: true,
        version: true,
      },
    },
  }) as const;

// Include shares for notes (used in queries, filtered during transformation)
export const NOTE_INCLUDE_SHARES = {
  sharedWith: {
    where: {
      isDeleted: false,
    },
    select: {
      id: true,
      permission: true,
      sharedWithUserId: true,
      sharedByUser: {
        select: USER_SELECT_FIELDS,
      },
    },
  },
} as const;

export const NOTE_LIST_ORDER = [
  { updatedAt: 'desc' },
  { id: 'desc' },
] as const satisfies Prisma.NoteOrderByWithRelationInput[];

// Bulk action limits; the client splits a larger selection into batches.
export const BULK_MAX_NOTE_IDS = 200;
export const BULK_MAX_TAG_IDS = 50;

// A note's edit history is paged; the client asks for more with the cursor.
export const DEFAULT_REVISION_PAGE_SIZE = 30;
export const MAX_REVISION_PAGE_SIZE = 100;

// Attachment constants
export const ATTACHMENT_MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

export const ATTACHMENT_ALLOWED_MIME_TYPES = new Set([
  // Image
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  // Audio
  'audio/mpeg',
  'audio/wav',
  'audio/mp4',
  'audio/x-m4a',
  'audio/ogg',
  'audio/aac',
  'audio/webm',
]);

// Error messages
export const ERROR_MESSAGES = {
  NOTE_NOT_FOUND: 'Note not found',
  REVISION_NOT_FOUND: 'Revision not found',
  USER_NOT_FOUND: 'User not found',
  SHARE_NOT_FOUND: 'Share not found',
  ONLY_OWNER_CAN_SHARE: 'Only note owner can share notes',
  ONLY_OWNER_CAN_VIEW_SHARES: 'Only note owner can view shares',
  ONLY_OWNER_CAN_UPDATE_PERMISSIONS:
    'Only note owner can update share permissions',
  ONLY_OWNER_CAN_REVOKE_SHARES: 'Only note owner can revoke shares',
  CANNOT_SHARE_WITH_SELF: 'Cannot share note with yourself',
  VIEWERS_CANNOT_EDIT: 'Viewers cannot edit notes',
  ONLY_OWNER_CAN_DELETE: 'Only note owner can delete notes',
  ONLY_OWNER_CAN_RESTORE: 'Only note owner can restore notes',
  ONLY_OWNER_CAN_PERMANENTLY_DELETE:
    'Only note owner can permanently delete notes',
} as const;
