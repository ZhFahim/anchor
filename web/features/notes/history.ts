import { format, isSameDay } from "date-fns";
import type {
  Note,
  NoteRevisionAuthor,
  NoteRevisionCause,
  NoteRevisionPage,
  NoteRevisionSummary,
} from "./types";

export const CURRENT_ENTRY_ID = "current";

export interface TimelineEntry {
  id: string;
  createdAt: string;
  title: string;
  author: NoteRevisionAuthor | null;
  revision: NoteRevisionSummary | null;
}

export interface TimelineDay {
  key: string;
  label: string;
  entries: TimelineEntry[];
}

const labels: Record<NoteRevisionCause, string> = {
  edit: "Earlier version",
  conflict: "Not saved",
  restore: "Before a restore",
};

export function revisionLabel(cause: NoteRevisionCause): string {
  return labels[cause];
}

export function revisionAuthorName(
  entry: { author: NoteRevisionAuthor | null },
  currentUserId: string | null,
): string {
  if (!entry.author) return "Someone";
  return entry.author.id === currentUserId ? "You" : entry.author.name;
}

export function revisionTime(entry: { createdAt: string }): string {
  return format(new Date(entry.createdAt), "h:mm a");
}

export function revisionDayTime(
  entry: { createdAt: string },
  now: Date = new Date(),
): string {
  const date = new Date(entry.createdAt);
  return `${dayLabel(date, now)} at ${format(date, "h:mm a")}`;
}

export function historyHasMultipleAuthors(
  revisions: NoteRevisionSummary[],
): boolean {
  const authors = new Set(
    revisions.map((revision) => revision.author?.id ?? "unknown"),
  );
  return authors.size > 1;
}

export function canRestoreRevisions(note: Note | null): boolean {
  if (!note) return false;
  return note.state === "active" && note.permission !== "viewer";
}

export function revisionsFromPages(
  pages: NoteRevisionPage[] | undefined,
): NoteRevisionSummary[] {
  return pages?.flatMap((page) => page.revisions) ?? [];
}

export function timelineEntries(
  revisions: NoteRevisionSummary[],
): TimelineEntry[] {
  return revisions.map((revision) => ({
    id: revision.id,
    createdAt: revision.createdAt,
    title: revision.title,
    author: revision.author,
    revision,
  }));
}

export function comparisonTargetId(
  revisions: NoteRevisionSummary[],
  revisionId: string,
): string | null {
  const index = revisions.findIndex((revision) => revision.id === revisionId);
  if (index < 0 || revisions[index].cause === "conflict") return null;

  for (let i = index - 1; i >= 0; i--) {
    if (revisions[i].cause !== "conflict") return revisions[i].id;
  }
  return null;
}

export function groupTimelineByDay(
  entries: TimelineEntry[],
  now: Date = new Date(),
): TimelineDay[] {
  const days: TimelineDay[] = [];

  for (const entry of entries) {
    const date = new Date(entry.createdAt);
    const key = format(date, "yyyy-MM-dd");
    const last = days[days.length - 1];

    if (last?.key === key) {
      last.entries.push(entry);
      continue;
    }

    days.push({ key, label: dayLabel(date, now), entries: [entry] });
  }

  return days;
}

function dayLabel(date: Date, now: Date): string {
  if (isSameDay(date, now)) return "Today";

  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  if (isSameDay(date, yesterday)) return "Yesterday";

  return format(date, "MMMM d, yyyy");
}
