import type { Translate } from "@/i18n/translate";
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

export function deletedNotesText(
  ownedCount: number,
  sharedCount: number,
  t: Translate,
) {
  if (!sharedCount) return t("notesMovedToTrashCount", { count: ownedCount });
  if (!ownedCount) return t("notesRemovedCount", { count: sharedCount });
  return t("notesTrashedMixed", { owned: ownedCount, shared: sharedCount });
}

export function deleteNotesWarning(
  ownedCount: number,
  sharedCount: number,
  t: Translate,
) {
  return ownedCount
    ? t("notesDeleteMixedWarning", { owned: ownedCount, shared: sharedCount })
    : t("notesDeleteSharedWarning", { count: sharedCount });
}
