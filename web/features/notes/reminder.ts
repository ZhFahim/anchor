import type { NoteReminder, ReminderRecurrence } from "./types";

export const recurrenceLabels: Record<ReminderRecurrence, string> = {
  none: "Does not repeat",
  daily: "Every day",
  weekly: "Every week",
  monthly: "Every month",
  yearly: "Every year",
};

/** One word, for the repeat toggles and the chip on a note card. */
export const recurrenceShortLabels: Record<ReminderRecurrence, string> = {
  none: "Never",
  daily: "Daily",
  weekly: "Weekly",
  monthly: "Monthly",
  yearly: "Yearly",
};

const pad = (value: number) => String(value).padStart(2, "0");

export function toWallClock(date: Date): string {
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}`
  );
}

export function parseWallClock(value: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(value);
  if (!match) return null;
  const [, y, mo, d, h, mi] = match.map(Number);
  const date = new Date(y, mo - 1, d, h, mi);
  return Number.isNaN(date.getTime()) ? null : date;
}

export interface ReminderPreset {
  label: string;
  remindAt: string;
}

export function presetReminders(now = new Date()): ReminderPreset[] {
  const at = (date: Date, hours: number, minutes = 0) => {
    const copy = new Date(date);
    copy.setHours(hours, minutes, 0, 0);
    return copy;
  };
  const laterToday = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  laterToday.setSeconds(0, 0);

  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const nextWeek = new Date(now);
  nextWeek.setDate(nextWeek.getDate() + 7);

  return [
    { label: "Later today", remindAt: toWallClock(laterToday) },
    { label: "This evening", remindAt: toWallClock(at(now, 18)) },
    { label: "Tomorrow", remindAt: toWallClock(at(tomorrow, 9)) },
    { label: "Next week", remindAt: toWallClock(at(nextWeek, 9)) },
  ];
}

export function isReminderPast(
  reminder: NoteReminder,
  now = new Date(),
): boolean {
  if (reminder.recurrence !== "none") return false;
  const at = parseWallClock(reminder.remindAt);
  return at !== null && at.getTime() < now.getTime();
}

export function reminderLabel(
  reminder: NoteReminder,
  now = new Date(),
): string {
  const at = parseWallClock(reminder.remindAt);
  if (!at) return reminder.remindAt;

  const sameYear = at.getFullYear() === now.getFullYear();
  const date = at.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    ...(sameYear ? {} : { year: "numeric" }),
  });
  const time = at.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });

  const repeat =
    reminder.recurrence === "none"
      ? ""
      : ` · ${recurrenceShortLabels[reminder.recurrence]}`;
  return `${date}, ${time}${repeat}`;
}

const daysInMonth = (year: number, month: number) =>
  new Date(year, month + 1, 0).getDate();

// Steps whole days, rebuilding from calendar parts so the wall-clock time
// survives a daylight-saving change.
function advanceDays(anchor: Date, from: Date, step: number): Date {
  let next = anchor;
  while (next.getTime() < from.getTime()) {
    next = new Date(
      next.getFullYear(),
      next.getMonth(),
      next.getDate() + step,
      anchor.getHours(),
      anchor.getMinutes(),
    );
  }
  return next;
}

// Steps whole months, clamped to the end of short ones.
function advanceMonths(anchor: Date, from: Date, step: number): Date {
  let months = anchor.getFullYear() * 12 + anchor.getMonth();
  let next = anchor;
  while (next.getTime() < from.getTime()) {
    months += step;
    const year = Math.floor(months / 12);
    const month = months % 12;
    next = new Date(
      year,
      month,
      Math.min(anchor.getDate(), daysInMonth(year, month)),
      anchor.getHours(),
      anchor.getMinutes(),
    );
  }
  return next;
}

/** When the reminder next fires, or null if it does not repeat and has passed. */
export function nextOccurrence(
  reminder: NoteReminder,
  now = new Date(),
): Date | null {
  const anchor = parseWallClock(reminder.remindAt);
  if (!anchor) return null;
  if (anchor.getTime() >= now.getTime()) return anchor;

  switch (reminder.recurrence) {
    case "daily":
      return advanceDays(anchor, now, 1);
    case "weekly":
      return advanceDays(anchor, now, 7);
    case "monthly":
      return advanceMonths(anchor, now, 1);
    case "yearly":
      return advanceMonths(anchor, now, 12);
    default:
      return null;
  }
}

export function formatTime(date: Date): string {
  return date.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}

/** "Today at 9:00 AM" / "Tomorrow at 9:00 AM" / "Sat, Sep 5 at 9:00 AM". */
export function formatOccurrence(at: Date, now = new Date()): string {
  const midnight = (date: Date) =>
    new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const days = Math.round(
    (midnight(at) - midnight(now)) / (24 * 60 * 60 * 1000),
  );

  const day =
    days === 0
      ? "Today"
      : days === 1
        ? "Tomorrow"
        : at.toLocaleDateString(undefined, {
            weekday: "short",
            month: "short",
            day: "numeric",
            ...(at.getFullYear() === now.getFullYear()
              ? {}
              : { year: "numeric" }),
          });

  return `${day} at ${formatTime(at)}`;
}

/** Reads a typed time into "HH:mm", taking "4:10 PM", "16:10", "4pm" or "9". */
export function parseTimeInput(text: string): string | null {
  const match = text
    .trim()
    .toLowerCase()
    .replace(/\./g, "")
    .match(/^(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?$/);
  if (!match) return null;

  let hours = Number(match[1]);
  const minutes = Number(match[2] ?? 0);
  const meridiem = match[3];

  if (minutes > 59) return null;
  if (meridiem) {
    if (hours < 1 || hours > 12) return null;
    hours = (hours % 12) + (meridiem === "pm" ? 12 : 0);
  } else if (hours > 23) {
    return null;
  }

  return `${pad(hours)}:${pad(minutes)}`;
}

/** The next five-minute mark that is at least five minutes away. */
export function nextRoundTime(now = new Date()): string {
  const at = new Date(now.getTime() + 5 * 60 * 1000);
  at.setMinutes(Math.ceil(at.getMinutes() / 5) * 5, 0, 0);
  if (at.getDate() !== now.getDate()) return "23:59";
  return `${pad(at.getHours())}:${pad(at.getMinutes())}`;
}
