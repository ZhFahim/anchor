import type { Note, NoteReminder, NoteReminderInput } from "./types";

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

export type ConflictResolution = "retry" | "adopt";

export interface NoteSaveQueueHandlers {
  save: (draft: NoteDraft, baseVersion?: number) => Promise<SaveOutcome>;
  onSaved: (draft: NoteDraft, note: Note) => void;
  onConflict: (
    serverNote: Note,
    draft: NoteDraft,
    canRetry: boolean,
  ) => ConflictResolution;
  onFailed: (failure: SaveFailure, draft: NoteDraft) => void;
  onBusyChange?: (busy: boolean) => void;
  retryDelayMs?: number;
}

export interface NoteSaveQueue {
  push: (draft: NoteDraft) => void;
  setBaseVersion: (version: number | undefined) => void;
  settled: () => Promise<void>;
}

const maxConflictRetries = 3;
const defaultRetryDelayMs = 2000;
const maxRetryDelayMs = 30_000;

export function noteToDraft(note: Note): NoteDraft {
  return {
    title: note.title,
    content: note.content || "",
    isPinned: note.isPinned,
    background: note.background || null,
    tagIds: note.tagIds || note.tags?.map((tag) => tag.id) || [],
    reminder: note.reminder ?? null,
  };
}

export function noteDraftsEqual(a: NoteDraft, b: NoteDraft): boolean {
  return (
    a.title === b.title &&
    a.content === b.content &&
    a.isPinned === b.isPinned &&
    a.background === b.background &&
    sameReminder(a.reminder, b.reminder) &&
    a.tagIds.length === b.tagIds.length &&
    [...a.tagIds].sort().join() === [...b.tagIds].sort().join()
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

// Holds one request open at a time and remembers only the newest draft, so
// edits made mid-request are sent next instead of being lost.
export function createNoteSaveQueue(
  handlers: NoteSaveQueueHandlers,
): NoteSaveQueue {
  let baseVersion: number | undefined;
  let pending: NoteDraft | null = null;
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
    setBusy(true);

    inFlight = handlers
      .save(draft, baseVersion)
      .then((outcome) => {
        if (outcome.status === "saved") {
          conflicts = 0;
          failures = 0;
          baseVersion = outcome.note.version;
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
        const resolution = handlers.onConflict(
          outcome.serverNote,
          draft,
          canRetry,
        );
        if (resolution === "retry" && canRetry && !pending) {
          pending = draft;
        }
      })
      .catch(() => {
        fail({ status: "failed", httpStatus: null, retryable: false }, draft);
      })
      .finally(() => {
        inFlight = null;
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
      pending = draft;
      failures = 0;
      clearTimeout(retryTimer);
      retryTimer = undefined;
      run();
    },
    setBaseVersion(version) {
      baseVersion = version;
      conflicts = 0;
    },
    async settled() {
      while (inFlight) {
        await inFlight;
      }
    },
  };
}
