import { draftTitle } from "./title";
import type {
  Note,
  NoteReminder,
  NoteReminderInput,
  UpdateNoteDto,
} from "./types";

export interface NoteDraft {
  title: string;
  content: string;
  isPinned: boolean;
  background: string | null;
  tagIds: string[];
  reminder: NoteReminder | null;
}

export type SaveOutcome =
  | { status: "saved"; note: Note }
  | { status: "conflict"; serverNote: Note }
  | { status: "failed"; httpStatus: number | null; retryable: boolean };

export type SaveFailure = Extract<SaveOutcome, { status: "failed" }>;

export interface NoteSaveQueueHandlers {
  save: (draft: NoteDraft, baseVersion?: number) => Promise<SaveOutcome>;
  onSaved: (draft: NoteDraft, note: Note) => void;
  /** Returns the draft to send on the server's version, or null to stop. */
  onConflict: (
    serverNote: Note,
    draft: NoteDraft,
    canRetry: boolean,
  ) => NoteDraft | null;
  onFailed: (failure: SaveFailure, draft: NoteDraft) => void;
  onBusyChange?: (busy: boolean) => void;
  retryDelayMs?: number;
}

export interface NoteSaveQueue {
  push: (draft: NoteDraft) => void;
  retryNow: () => void;
  sendingDraft: () => NoteDraft | null;
  /** The newest draft not yet saved: waiting, retrying or on its way. */
  newestDraft: () => NoteDraft | null;
  setBaseVersion: (version: number | undefined) => void;
  settled: () => Promise<void>;
}

const maxConflictRetries = 3;
const defaultRetryDelayMs = 2000;
const maxRetryDelayMs = 30_000;

export function noteToDraft(note: Note): NoteDraft {
  return {
    title: draftTitle(note.title),
    content: note.content || "",
    isPinned: note.isPinned,
    background: note.background || null,
    tagIds: note.tagIds || [],
    reminder: note.reminder ?? null,
  };
}

const draftFields = [
  "title",
  "content",
  "isPinned",
  "background",
  "tagIds",
  "reminder",
] as const;

type DraftField = (typeof draftFields)[number];

function sameField(field: DraftField, a: NoteDraft, b: NoteDraft): boolean {
  switch (field) {
    case "tagIds":
      return (
        a.tagIds.length === b.tagIds.length &&
        [...a.tagIds].sort().join() === [...b.tagIds].sort().join()
      );
    case "reminder":
      return sameReminder(a.reminder, b.reminder);
    default:
      return a[field] === b[field];
  }
}

export function noteDraftsEqual(a: NoteDraft, b: NoteDraft): boolean {
  return draftFields.every((field) => sameField(field, a, b));
}

/** Moves a draft onto a newer server copy, keeping the fields changed since [base]. */
export function rebaseDraft(
  draft: NoteDraft,
  base: NoteDraft,
  server: NoteDraft,
): NoteDraft {
  const pick = <K extends DraftField>(field: K): NoteDraft[K] =>
    sameField(field, draft, base) ? server[field] : draft[field];

  return {
    title: pick("title"),
    content: pick("content"),
    isPinned: pick("isPinned"),
    background: pick("background"),
    tagIds: pick("tagIds"),
    reminder: pick("reminder"),
  };
}

/** Whether [draft] replaces text the server changed since [base]. */
export function replacesText(
  draft: NoteDraft,
  base: NoteDraft,
  server: NoteDraft,
): boolean {
  return (["title", "content"] as const).some(
    (field) => server[field] !== base[field] && draft[field] !== server[field],
  );
}

/** The same time and repeat, whatever version each side is on. */
export function sameReminder(
  a: NoteReminder | null,
  b: NoteReminder | null,
): boolean {
  return a?.remindAt === b?.remindAt && a?.recurrence === b?.recurrence;
}

export function toReminderInput(
  reminder: NoteReminder | null,
): NoteReminderInput | null {
  if (!reminder) return null;
  return { remindAt: reminder.remindAt, recurrence: reminder.recurrence };
}

/** The reminder to send; nothing at all keeps the one the server holds. */
export function reminderUpdate(
  draft: NoteReminder | null,
  server: NoteReminder | null,
): NoteReminderInput | null | undefined {
  if (sameReminder(draft, server)) return undefined;
  return toReminderInput(draft);
}

// What a save sends. Viewers send only their own pin, tags and reminder.
export function draftUpdate(
  draft: NoteDraft,
  serverReminder: NoteReminder | null,
  { isViewer, baseVersion }: { isViewer: boolean; baseVersion?: number },
): UpdateNoteDto {
  const reminder = reminderUpdate(draft.reminder, serverReminder);
  if (isViewer) {
    return { isPinned: draft.isPinned, tagIds: draft.tagIds, reminder };
  }
  return { ...draft, reminder, baseVersion };
}

// The save sent as the page closes: only the fields changed since [base].
export function flushUpdate(
  draft: NoteDraft,
  base: NoteDraft,
  serverReminder: NoteReminder | null,
  { isViewer }: { isViewer: boolean },
): UpdateNoteDto {
  const update = draftUpdate(draft, serverReminder, { isViewer });
  return Object.fromEntries(
    Object.entries(update).filter(
      ([field]) =>
        field === "reminder" || !sameField(field as DraftField, draft, base),
    ),
  );
}

// Holds one request open at a time and remembers only the newest draft, so
// edits made mid-request are sent next instead of being lost.
export function createNoteSaveQueue(
  handlers: NoteSaveQueueHandlers,
): NoteSaveQueue {
  let baseVersion: number | undefined;
  let pending: NoteDraft | null = null;
  let sending: NoteDraft | null = null;
  let inFlight: Promise<void> | null = null;
  let conflicts = 0;
  let failures = 0;
  let busy = false;
  let retryIn = 0;
  let retryTimer: ReturnType<typeof setTimeout> | undefined;
  const retryDelayMs = handlers.retryDelayMs ?? defaultRetryDelayMs;

  function setBusy(next: boolean): void {
    if (busy === next) return;
    busy = next;
    handlers.onBusyChange?.(next);
  }

  // A request that never reached an answer is worth repeating; a refusal is not.
  function fail(failure: SaveFailure, draft: NoteDraft): void {
    handlers.onFailed(failure, draft);
    if (!failure.retryable || pending) return;

    failures += 1;
    pending = draft;
    retryIn = Math.min(retryDelayMs * 2 ** (failures - 1), maxRetryDelayMs);
  }

  function run(): void {
    if (inFlight) return;
    if (!pending) {
      setBusy(false);
      return;
    }

    const draft = pending;
    pending = null;
    sending = draft;
    setBusy(true);

    inFlight = handlers
      .save(draft, baseVersion)
      .then((outcome) => {
        if (outcome.status === "saved") {
          conflicts = 0;
          failures = 0;
          baseVersion = outcome.note.version;
          if (pending && noteDraftsEqual(pending, draft)) pending = null;
          handlers.onSaved(draft, outcome.note);
          return;
        }

        if (outcome.status === "failed") {
          fail(outcome, draft);
          return;
        }

        baseVersion = outcome.serverNote.version;
        conflicts += 1;
        const canRetry = conflicts <= maxConflictRetries;
        const next = handlers.onConflict(outcome.serverNote, draft, canRetry);
        pending = canRetry ? next : null;
      })
      .catch(() => {
        fail({ status: "failed", httpStatus: null, retryable: false }, draft);
      })
      .finally(() => {
        inFlight = null;
        sending = null;
        if (retryIn === 0) {
          run();
          return;
        }

        const delay = retryIn;
        retryIn = 0;
        setBusy(false);
        retryTimer = setTimeout(() => {
          retryTimer = undefined;
          run();
        }, delay);
      });
  }

  return {
    push(draft) {
      // The same draft again waits out the backoff; a fresh edit goes now.
      if (retryTimer && pending && noteDraftsEqual(pending, draft)) return;
      pending = draft;
      failures = 0;
      clearTimeout(retryTimer);
      retryTimer = undefined;
      run();
    },
    retryNow() {
      clearTimeout(retryTimer);
      retryTimer = undefined;
      run();
    },
    setBaseVersion(version) {
      baseVersion = version;
      conflicts = 0;
    },
    sendingDraft: () => sending,
    newestDraft: () => pending ?? sending,
    async settled() {
      while (inFlight) {
        await inFlight;
      }
    },
  };
}
