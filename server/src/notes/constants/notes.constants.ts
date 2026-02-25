/**
 * Constants for notes module
 * Centralized query patterns, user selections, and error messages
 */

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

// Attachment constants
export const ATTACHMENT_MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

export const ATTACHMENT_ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'audio/mpeg',
  'audio/wav',
  'audio/mp4',
  'audio/ogg',
  'audio/x-m4a',
]);

// Error messages
export const ERROR_MESSAGES = {
  NOTE_NOT_FOUND: 'Note not found',
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
