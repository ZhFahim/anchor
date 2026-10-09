import { plural } from "@/lib/utils";
import type { Note } from "./types";

export const TRASH_RETENTION_DAYS = 30;

export function deletionDate(note: Note): Date {
  const since = new Date(note.stateChangedAt ?? note.updatedAt);
  return new Date(since.getTime() + TRASH_RETENTION_DAYS * 86400000);
}

export function daysUntilDeletion(note: Note, now = new Date()): number {
  return Math.max(
    1,
    Math.ceil((deletionDate(note).getTime() - now.getTime()) / 86400000),
  );
}

export function deletedNotesText(ownedCount: number, sharedCount: number) {
  if (!sharedCount) return `${plural(ownedCount, "note")} moved to trash`;
  if (!ownedCount)
    return `${plural(sharedCount, "note")} removed from your notes`;
  return `${plural(ownedCount, "note")} moved to trash. ${sharedCount} removed from your notes.`;
}

export function deleteNotesWarning(ownedCount: number, sharedCount: number) {
  const them = sharedCount === 1 ? "it" : "them";
  const sharedText = `${plural(sharedCount, "note")} shared with you will be removed from your notes. To see ${them} again, the owner has to share ${them} with you again.`;
  return ownedCount
    ? `${plural(ownedCount, "note")} will be moved to trash. ${sharedText}`
    : sharedText;
}
