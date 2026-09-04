import { describe, expect, it, vi } from "vitest";
import {
  createNoteSaveQueue,
  type NoteDraft,
  type NoteSaveQueueHandlers,
  noteDraftsEqual,
  type SaveFailure,
  type SaveOutcome,
} from "./save-queue";
import type { Note } from "./types";

function makeNote(version: number, overrides: Partial<Note> = {}): Note {
  return {
    id: "n1",
    title: "",
    content: "",
    isPinned: false,
    isArchived: false,
    background: null,
    state: "active",
    version,
    createdAt: "2026-01-01T00:00:00.000Z",
    updatedAt: "2026-01-01T00:00:00.000Z",
    userId: "u1",
    tagIds: [],
    permission: "owner",
    ...overrides,
  };
}

function makeDraft(title: string): NoteDraft {
  return {
    title,
    content: "",
    isPinned: false,
    background: null,
    tagIds: [],
    reminder: null,
  };
}

function makeQueue(handlers: Partial<NoteSaveQueueHandlers> = {}) {
  return createNoteSaveQueue({
    save: () => Promise.resolve({ status: "saved", note: makeNote(2) }),
    onSaved: () => {},
    onConflict: () => "retry",
    onFailed: () => {},
    ...handlers,
  });
}

const offline: SaveOutcome = {
  status: "failed",
  httpStatus: null,
  retryable: true,
};

const gone: SaveOutcome = {
  status: "failed",
  httpStatus: 404,
  retryable: false,
};

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((res) => {
    resolve = res;
  });
  return { promise, resolve };
}

describe("noteDraftsEqual", () => {
  it("ignores the order tags were picked in", () => {
    const a = { ...makeDraft("t"), tagIds: ["one", "two"] };
    const b = { ...makeDraft("t"), tagIds: ["two", "one"] };
    expect(noteDraftsEqual(a, b)).toBe(true);
  });

  it("sees a removed tag", () => {
    const a = { ...makeDraft("t"), tagIds: ["one", "two"] };
    const b = { ...makeDraft("t"), tagIds: ["one"] };
    expect(noteDraftsEqual(a, b)).toBe(false);
  });

  it("sees a reminder being set, moved and cleared", () => {
    const none = makeDraft("t");
    const set = {
      ...none,
      reminder: {
        remindAt: "2026-09-04T09:00",
        recurrence: "none" as const,
        version: 1,
      },
    };
    const moved = {
      ...set,
      reminder: { ...set.reminder, remindAt: "2026-09-05T09:00" },
    };
    const repeating = {
      ...set,
      reminder: { ...set.reminder, recurrence: "daily" as const },
    };

    expect(noteDraftsEqual(none, set)).toBe(false);
    expect(noteDraftsEqual(set, moved)).toBe(false);
    expect(noteDraftsEqual(set, repeating)).toBe(false);
    expect(noteDraftsEqual(set, { ...set })).toBe(true);
  });

  it("ignores a version change on an otherwise identical reminder", () => {
    const a = {
      ...makeDraft("t"),
      reminder: {
        remindAt: "2026-09-04T09:00",
        recurrence: "none" as const,
        version: 1,
      },
    };
    const b = { ...a, reminder: { ...a.reminder, version: 9 } };
    expect(noteDraftsEqual(a, b)).toBe(true);
  });
});

describe("createNoteSaveQueue", () => {
  it("sends only the newest edit made while a save is running", async () => {
    const gate = deferred<SaveOutcome>();
    const sent: string[] = [];
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft.title);
        return sent.length === 1
          ? gate.promise
          : Promise.resolve({ status: "saved", note: makeNote(3) });
      },
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("b"));
    queue.push(makeDraft("c"));
    gate.resolve({ status: "saved", note: makeNote(2) });
    await queue.settled();

    expect(sent).toEqual(["a", "c"]);
  });

  it("reports the draft it sent, not the one typed since", async () => {
    const gate = deferred<SaveOutcome>();
    const saved: string[] = [];
    let first = true;
    const queue = makeQueue({
      save: () => {
        if (!first) {
          return Promise.resolve({ status: "saved", note: makeNote(3) });
        }
        first = false;
        return gate.promise;
      },
      onSaved: (draft) => saved.push(draft.title),
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("b"));
    gate.resolve({ status: "saved", note: makeNote(2) });
    await queue.settled();

    expect(saved).toEqual(["a", "b"]);
  });

  it("saves against the version the server last returned", async () => {
    const bases: (number | undefined)[] = [];
    let version = 4;
    const queue = makeQueue({
      save: (_draft, baseVersion) => {
        bases.push(baseVersion);
        version += 1;
        return Promise.resolve({ status: "saved", note: makeNote(version) });
      },
    });

    queue.setBaseVersion(4);
    queue.push(makeDraft("a"));
    await queue.settled();
    queue.push(makeDraft("b"));
    await queue.settled();

    expect(bases).toEqual([4, 5]);
  });

  it("re-sends the local draft on top of the server version", async () => {
    const attempts: Array<{ title: string; baseVersion?: number }> = [];
    const queue = makeQueue({
      save: (draft, baseVersion) => {
        attempts.push({ title: draft.title, baseVersion });
        return Promise.resolve(
          attempts.length === 1
            ? { status: "conflict", serverNote: makeNote(9) }
            : { status: "saved", note: makeNote(10) },
        );
      },
    });

    queue.setBaseVersion(3);
    queue.push(makeDraft("mine"));
    await queue.settled();

    expect(attempts).toEqual([
      { title: "mine", baseVersion: 3 },
      { title: "mine", baseVersion: 9 },
    ]);
  });

  it("keeps a newer edit instead of re-sending the one that conflicted", async () => {
    const gate = deferred<SaveOutcome>();
    const sent: string[] = [];
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft.title);
        return sent.length === 1
          ? gate.promise
          : Promise.resolve({ status: "saved", note: makeNote(10) });
      },
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("b"));
    gate.resolve({ status: "conflict", serverNote: makeNote(9) });
    await queue.settled();

    expect(sent).toEqual(["a", "b"]);
  });

  it("stops re-sending once the server keeps winning", async () => {
    const offers: boolean[] = [];
    let attempts = 0;
    const queue = makeQueue({
      save: () => {
        attempts += 1;
        return Promise.resolve({
          status: "conflict",
          serverNote: makeNote(attempts),
        });
      },
      onConflict: (_serverNote, _draft, canRetry) => {
        offers.push(canRetry);
        return canRetry ? "retry" : "adopt";
      },
    });

    queue.push(makeDraft("mine"));
    await queue.settled();

    expect(offers).toEqual([true, true, true, false]);
    expect(attempts).toBe(4);
  });

  it("sends nothing more once the server copy is adopted", async () => {
    let attempts = 0;
    const queue = makeQueue({
      save: () => {
        attempts += 1;
        return Promise.resolve({
          status: "conflict",
          serverNote: makeNote(9),
        });
      },
      onConflict: () => "adopt",
    });

    queue.push(makeDraft("mine"));
    await queue.settled();

    expect(attempts).toBe(1);
  });

  it("sends the draft again after an unanswered request", async () => {
    let attempts = 0;
    const saved: string[] = [];
    const queue = makeQueue({
      retryDelayMs: 1,
      save: () => {
        attempts += 1;
        return Promise.resolve(
          attempts === 1 ? offline : { status: "saved", note: makeNote(2) },
        );
      },
      onSaved: (draft) => saved.push(draft.title),
    });

    queue.push(makeDraft("a"));
    await vi.waitFor(() => expect(saved).toEqual(["a"]));
    expect(attempts).toBe(2);
  });

  it("keeps trying while the server is unreachable", async () => {
    let attempts = 0;
    const queue = makeQueue({
      retryDelayMs: 1,
      save: () => {
        attempts += 1;
        return Promise.resolve(offline);
      },
    });

    queue.push(makeDraft("a"));
    await vi.waitFor(() => expect(attempts).toBeGreaterThan(4));
  });

  it("stops after the server refuses the write", async () => {
    let attempts = 0;
    const failures: SaveFailure[] = [];
    const queue = makeQueue({
      retryDelayMs: 1,
      save: () => {
        attempts += 1;
        return Promise.resolve(gone);
      },
      onFailed: (failure) => failures.push(failure),
    });

    queue.push(makeDraft("a"));
    await queue.settled();
    await new Promise((resolve) => setTimeout(resolve, 20));

    expect(attempts).toBe(1);
    expect(failures).toEqual([gone]);
  });

  it("gives up when the save handler itself throws", async () => {
    let attempts = 0;
    const queue = makeQueue({
      retryDelayMs: 1,
      save: () => {
        attempts += 1;
        return Promise.reject(new Error("boom"));
      },
    });

    queue.push(makeDraft("a"));
    await queue.settled();
    await new Promise((resolve) => setTimeout(resolve, 20));

    expect(attempts).toBe(1);
  });

  it("sends the newest draft instead of waiting out a retry", async () => {
    let attempts = 0;
    const sent: string[] = [];
    const queue = makeQueue({
      retryDelayMs: 10_000,
      save: (draft) => {
        attempts += 1;
        sent.push(draft.title);
        return Promise.resolve(
          attempts === 1 ? offline : { status: "saved", note: makeNote(2) },
        );
      },
    });

    queue.push(makeDraft("a"));
    await queue.settled();
    queue.push(makeDraft("b"));
    await queue.settled();

    expect(sent).toEqual(["a", "b"]);
  });

  it("starts the retry delay over when a fresh edit arrives", async () => {
    vi.useFakeTimers();
    let attempts = 0;
    const queue = makeQueue({
      retryDelayMs: 1000,
      save: () => {
        attempts += 1;
        return Promise.resolve(offline);
      },
    });

    try {
      queue.push(makeDraft("a"));
      await queue.settled();
      await vi.advanceTimersByTimeAsync(1000);
      expect(attempts).toBe(2);

      // The second failure doubles the wait.
      await vi.advanceTimersByTimeAsync(1000);
      expect(attempts).toBe(2);

      queue.push(makeDraft("b"));
      await queue.settled();
      await vi.advanceTimersByTimeAsync(1000);
      expect(attempts).toBe(4);
    } finally {
      vi.useRealTimers();
    }
  });

  it("is busy only while a save is running", async () => {
    const gate = deferred<SaveOutcome>();
    const busy: boolean[] = [];
    const queue = makeQueue({
      save: () => gate.promise,
      onBusyChange: (value) => busy.push(value),
    });

    queue.push(makeDraft("a"));
    expect(busy).toEqual([true]);

    gate.resolve({ status: "saved", note: makeNote(2) });
    await queue.settled();

    expect(busy).toEqual([true, false]);
  });
});
