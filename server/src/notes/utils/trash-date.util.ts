import { TRASH_RETENTION_DAYS } from '../constants/notes.constants';

const DAY_MS = 24 * 60 * 60 * 1000;

/** A missing or invalid date means now. */
export function trashDate(trashedAt?: string, now = new Date()): Date {
  const at = trashedAt ? Date.parse(trashedAt) : Number.NaN;
  if (Number.isNaN(at)) return now;
  const earliest = now.getTime() - TRASH_RETENTION_DAYS * DAY_MS;
  return new Date(Math.min(now.getTime(), Math.max(earliest, at)));
}
