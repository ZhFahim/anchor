import { format, isSameDay } from "date-fns";
import type { Translate } from "@/i18n/translate";
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

const labels = {
  edit: "historyEarlierVersion",
  conflict: "historyNotSaved",
  restore: "historyBeforeRestore",
} as const satisfies Record<NoteRevisionCause, string>;

export function revisionLabel(t: Translate, cause: NoteRevisionCause): string {
  return t(labels[cause]);
}

export function revisionAuthorName(
  t: Translate,
  entry: { author: NoteRevisionAuthor | null },
  currentUserId: string | null,
): string {
  if (!entry.author) return t("historySomeone");
  return entry.author.id === currentUserId
    ? t("historyYou")
    : entry.author.name;
}

const formats = new Map<string, Intl.DateTimeFormat>();

function formatOf(locale: string, kind: "time" | "date") {
  const key = `${locale} ${kind}`;
  let found = formats.get(key);
  if (!found) {
    found = new Intl.DateTimeFormat(
      locale,
      kind === "time"
        ? { hour: "numeric", minute: "2-digit" }
        : { year: "numeric", month: "long", day: "numeric" },
    );
    formats.set(key, found);
  }
  return found;
}

export interface RevisionMoment {
  day: "today" | "yesterday" | "earlier";
  date: string;
  time: string;
}

export function revisionMoment(
  locale: string,
  entry: { createdAt: string },
  now: Date = new Date(),
): RevisionMoment {
  const date = new Date(entry.createdAt);
  return {
    day: dayOf(date, now),
    date: formatOf(locale, "date").format(date),
    time: formatOf(locale, "time").format(date),
  };
}

export function revisionTime(
  locale: string,
  entry: { createdAt: string },
): string {
  return formatOf(locale, "time").format(new Date(entry.createdAt));
}

export function revisionDayTime(
  t: Translate,
  locale: string,
  entry: { createdAt: string },
  now: Date = new Date(),
): string {
  const { day, date, time } = revisionMoment(locale, entry, now);
  if (day === "today") return t("historyTodayAt", { time });
  if (day === "yesterday") return t("historyYesterdayAt", { time });
  return t("historyDateAt", { date, time });
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
  t: Translate,
  locale: string,
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

    const day = dayOf(date, now);
    const label =
      day === "today"
        ? t("historyToday")
        : day === "yesterday"
          ? t("historyYesterday")
          : formatOf(locale, "date").format(date);
    days.push({ key, label, entries: [entry] });
  }

  return days;
}

function dayOf(date: Date, now: Date): RevisionMoment["day"] {
  if (isSameDay(date, now)) return "today";

  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  if (isSameDay(date, yesterday)) return "yesterday";

  return "earlier";
}
