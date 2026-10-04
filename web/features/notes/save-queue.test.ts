import { describe, expect, it, vi } from "vitest";
import {
  createNoteSaveQueue,
  draftUpdate,
  flushUpdate,
  type NoteDraft,
  type NoteSaveQueueHandlers,
  noteDraftsEqual,
  noteToDraft,
  rebaseDraft,
  reminderUpdate,
  replacesText,
  type SaveFailure,
  type SaveOutcome,
} from "./save-queue";
import { draftTitle } from "./title";
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
    onConflict: (_serverNote, draft) => draft,
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

describe("noteToDraft", () => {
  it("leaves an untouched note with a spaced title unchanged", () => {
    const stored = noteToDraft(makeNote(1, { title: "Renovierung " }));

    expect(noteDraftsEqual(stored, makeDraft(draftTitle("Renovierung ")))).toBe(
      true,
    );
  });

  it("leaves an untouched note with a blank title unchanged", () => {
    const stored = noteToDraft(makeNote(1, { title: "   " }));

    expect(noteDraftsEqual(stored, makeDraft(draftTitle("")))).toBe(true);
  });
});

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

describe("reminderUpdate", () => {
  const reminder = {
    remindAt: "2026-09-04T09:00",
    recurrence: "none" as const,
    version: 1,
  };

  it("leaves the server's reminder out of a save that did not touch it", () => {
    expect(
      reminderUpdate(reminder, { ...reminder, version: 4 }),
    ).toBeUndefined();
    expect(reminderUpdate(null, null)).toBeUndefined();
  });

  it("sends the reminder the user set here", () => {
    expect(reminderUpdate(reminder, null)).toEqual({
      remindAt: "2026-09-04T09:00",
      recurrence: "none",
    });
  });

  it("sends null for the reminder the user removed here", () => {
    expect(reminderUpdate(null, reminder)).toBeNull();
  });
});

describe("draftUpdate", () => {
  const draft: NoteDraft = {
    title: "Groceries",
    content: "milk",
    isPinned: true,
    background: "color_teal",
    tagIds: ["t1"],
    reminder: { remindAt: "2026-09-04T09:00", recurrence: "none", version: 1 },
  };

  it("sends the whole draft for someone who can edit", () => {
    expect(
      draftUpdate(draft, null, { isViewer: false, baseVersion: 3 }),
    ).toEqual({
      title: "Groceries",
      content: "milk",
      isPinned: true,
      background: "color_teal",
      tagIds: ["t1"],
      reminder: { remindAt: "2026-09-04T09:00", recurrence: "none" },
      baseVersion: 3,
    });
  });

  it("sends only a viewer's own pin, tags and reminder", () => {
    expect(
      draftUpdate(draft, null, { isViewer: true, baseVersion: 3 }),
    ).toEqual({
      isPinned: true,
      tagIds: ["t1"],
      reminder: { remindAt: "2026-09-04T09:00", recurrence: "none" },
    });
  });
});

describe("rebaseDraft", () => {
  const base: NoteDraft = {
    title: "Shopping",
    content: "milk",
    isPinned: false,
    background: null,
    tagIds: ["t1"],
    reminder: null,
  };
  const server: NoteDraft = {
    ...base,
    content: "milk, eggs",
    background: "color_red",
  };

  it("takes the server's value for everything left alone here", () => {
    expect(rebaseDraft({ ...base, isPinned: true }, base, server)).toEqual({
      ...server,
      isPinned: true,
    });
  });

  it("keeps every field changed here", () => {
    const mine = {
      ...base,
      title: "Weekly shop",
      content: "bread",
      background: "color_teal",
    };

    expect(rebaseDraft(mine, base, server)).toEqual(mine);
  });

  it("sees tags picked in another order as untouched", () => {
    const base2 = { ...base, tagIds: ["t1", "t2"] };
    const mine = { ...base, tagIds: ["t2", "t1"] };

    expect(
      rebaseDraft(mine, base2, { ...base2, tagIds: ["t3"] }).tagIds,
    ).toEqual(["t3"]);
  });

  it("keeps a reminder set here and takes one set elsewhere", () => {
    const reminder = {
      remindAt: "2026-09-04T09:00",
      recurrence: "none" as const,
      version: 1,
    };

    expect(rebaseDraft({ ...base, reminder }, base, server).reminder).toEqual(
      reminder,
    );
    expect(rebaseDraft(base, base, { ...server, reminder }).reminder).toEqual(
      reminder,
    );
  });
});

describe("replacesText", () => {
  const base: NoteDraft = {
    title: "Shopping",
    content: "milk",
    isPinned: false,
    background: null,
    tagIds: [],
    reminder: null,
  };

  it("is true when both sides changed the text", () => {
    const server = { ...base, content: "milk, eggs" };

    expect(replacesText({ ...base, content: "bread" }, base, server)).toBe(
      true,
    );
  });

  it("is false when the other side changed only the color", () => {
    const server = { ...base, background: "color_red" };
    const next = rebaseDraft({ ...base, content: "bread" }, base, server);

    expect(replacesText(next, base, server)).toBe(false);
  });

  it("is false when each side changed a different part of the text", () => {
    const server = { ...base, content: "milk, eggs" };
    const next = rebaseDraft({ ...base, title: "Weekly shop" }, base, server);

    expect(replacesText(next, base, server)).toBe(false);
  });
});

describe("flushUpdate", () => {
  const base: NoteDraft = {
    title: "Shopping",
    content: "milk",
    isPinned: false,
    background: null,
    tagIds: [],
    reminder: null,
  };

  it("sends only what changed since the last save, with no base version", () => {
    expect(
      flushUpdate({ ...base, isPinned: true }, base, null, { isViewer: false }),
    ).toEqual({ isPinned: true });
  });

  it("sends changed text so it is not lost", () => {
    expect(
      flushUpdate({ ...base, content: "milk, eggs" }, base, null, {
        isViewer: false,
      }),
    ).toEqual({ content: "milk, eggs" });
  });

  it("sends a reminder only when it differs from the server's", () => {
    const reminder = {
      remindAt: "2026-09-04T09:00",
      recurrence: "none" as const,
      version: 1,
    };

    expect(
      flushUpdate({ ...base, reminder }, base, null, { isViewer: false }),
    ).toEqual({
      reminder: { remindAt: "2026-09-04T09:00", recurrence: "none" },
    });
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

  it("replaces an edit queued on the old copy with what the conflict hands back", async () => {
    const gate = deferred<SaveOutcome>();
    const sent: string[] = [];
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft.title);
        return sent.length === 1
          ? gate.promise
          : Promise.resolve({ status: "saved", note: makeNote(10) });
      },
      onConflict: () => makeDraft("merged"),
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("b"));
    gate.resolve({ status: "conflict", serverNote: makeNote(9) });
    await queue.settled();

    expect(sent).toEqual(["a", "merged"]);
  });

  it("sends the draft the conflict hands back", async () => {
    const sent: NoteDraft[] = [];
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft);
        return Promise.resolve(
          sent.length === 1
            ? { status: "conflict", serverNote: makeNote(9) }
            : { status: "saved", note: makeNote(10) },
        );
      },
      onConflict: (_serverNote, draft) => ({ ...draft, content: "theirs" }),
    });

    queue.push(makeDraft("mine"));
    await queue.settled();

    expect(sent[1]).toMatchObject({ title: "mine", content: "theirs" });
  });

  it("drops a newer edit once the server copy is adopted", async () => {
    const gate = deferred<SaveOutcome>();
    const sent: string[] = [];
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft.title);
        return gate.promise;
      },
      onConflict: () => null,
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("b"));
    gate.resolve({ status: "conflict", serverNote: makeNote(9) });
    await queue.settled();

    expect(sent).toEqual(["a"]);
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
      onConflict: (_serverNote, draft, canRetry) => {
        offers.push(canRetry);
        return canRetry ? draft : null;
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
      onConflict: () => null,
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

  it("waits out the retry delay when the same draft is pushed again", async () => {
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
      queue.push(makeDraft("a"));
      queue.push(makeDraft("a"));
      await vi.advanceTimersByTimeAsync(999);
      expect(attempts).toBe(1);
      await vi.advanceTimersByTimeAsync(1);
      expect(attempts).toBe(2);
    } finally {
      vi.useRealTimers();
    }
  });

  it("sends at once on retryNow", async () => {
    let attempts = 0;
    const queue = makeQueue({
      retryDelayMs: 10_000,
      save: () => {
        attempts += 1;
        return Promise.resolve(
          attempts === 1 ? offline : { status: "saved", note: makeNote(2) },
        );
      },
    });

    queue.push(makeDraft("a"));
    await queue.settled();
    queue.retryNow();
    await queue.settled();

    expect(attempts).toBe(2);
  });

  it("does not send the same draft twice when it was pushed again mid-save", async () => {
    const sent: string[] = [];
    let answer: (outcome: SaveOutcome) => void = () => {};
    const queue = makeQueue({
      save: (draft) => {
        sent.push(draft.title);
        return new Promise((resolve) => {
          answer = resolve;
        });
      },
    });

    queue.push(makeDraft("a"));
    queue.push(makeDraft("a"));
    answer({ status: "saved", note: makeNote(2) });
    await queue.settled();

    expect(sent).toEqual(["a"]);
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
