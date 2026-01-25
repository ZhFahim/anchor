import { NoteSharePermission } from 'src/generated/prisma/enums';

// Type definitions for transformed note structures
export type NotePermission = 'owner' | NoteSharePermission;

interface SharedByUser {
  id: string;
  name: string;
  email: string;
  profileImage?: string | null;
}

export interface TransformedNote {
  id: string;
  title: string;
  content: string | null;
  isPinned: boolean;
  isArchived: boolean;
  background: string | null;
  state: string;
  updatedAt: string;
  createdAt: string;
  userId: string;
  tagIds: string[];
  permission: NotePermission;
  shareIds?: string[];
  sharedBy?: SharedByUser;
}

// Input type for notes from Prisma with includes
interface NoteWithIncludes {
  id: string;
  title: string;
  content: string | null;
  isPinned: boolean;
  isArchived: boolean;
  background: string | null;
  state: string;
  createdAt: Date;
  updatedAt: Date;
  userId: string;
  tags?: Array<{ id: string; userId: string }>;
  sharedWith?: Array<{
    id: string;
    sharedWithUserId: string;
    permission: NoteSharePermission;
    sharedByUser: SharedByUser;
  }>;
}

// Convert Date to ISO string
function toISOString(date: Date): string {
  return date.toISOString();
}

// Transform a note with includes to a clean response format
// Automatically determines ownership and extracts share metadata from sharedWith
export function transformNote(
  note: NoteWithIncludes,
  userId: string,
): TransformedNote {
  const { tags, sharedWith, ...rest } = note;

  // Determine if user is owner or shared user
  const isOwner = note.userId === userId;

  // Filter tags to only include those owned by the requesting user
  const filteredTags = tags?.filter((t) => t.userId === userId) || [];

  // Extract share metadata for shared notes
  let permission: NotePermission = 'owner';
  let sharedBy: SharedByUser | undefined;

  if (!isOwner && sharedWith) {
    const userShare = sharedWith.find(
      (share) => share.sharedWithUserId === userId,
    );
    if (userShare) {
      permission = userShare.permission;
      sharedBy = userShare.sharedByUser;
    }
  }

  const transformed: TransformedNote = {
    ...rest,
    tagIds: filteredTags.map((t) => t.id),
    createdAt: toISOString(rest.createdAt),
    updatedAt: toISOString(rest.updatedAt),
    permission,
  };

  // Add shareIds for owners
  if (isOwner && sharedWith) {
    transformed.shareIds = sharedWith.map((share) => share.id);
  }

  // Add sharedBy for shared notes
  if (sharedBy) {
    transformed.sharedBy = sharedBy;
  }

  return transformed;
}
