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
