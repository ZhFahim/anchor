import { describe, expect, it } from "vitest";
import {
  canRestoreRevisions,
  comparisonTargetId,
  groupTimelineByDay,
  historyHasMultipleAuthors,
  revisionAuthorName,
  revisionDayTime,
  revisionsFromPages,
  timelineEntries,
} from "./history";
import type { Note, NoteRevisionCause, NoteRevisionSummary } from "./types";

const revision = (
  id: string,
  createdAt: string,
  over: Partial<NoteRevisionSummary> = {},
): NoteRevisionSummary => ({
  id,
  noteId: "note-1",
  version: 1,
  title: "groceries",
  cause: "edit" as NoteRevisionCause,
  createdAt,
  author: { id: "user-1", name: "Ada", email: "ada@example.com" },
  ...over,
});

const note = (over: Partial<Note> = {}): Note =>
  ({
    id: "note-1",
    title: "groceries",
    state: "active",
    permission: "owner",
    version: 1,
    isPinned: false,
    isArchived: false,
    createdAt: "2026-08-01T00:00:00.000Z",
    updatedAt: "2026-08-01T00:00:00.000Z",
    userId: "user-1",
    ...over,
  }) as Note;

describe("revisionAuthorName", () => {
  it("names the reader themselves", () => {
    expect(
      revisionAuthorName(revision("r-1", "2026-08-16T10:00:00Z"), "user-1"),
    ).toBe("You");
  });

  it("names anyone else", () => {
    expect(
      revisionAuthorName(revision("r-1", "2026-08-16T10:00:00Z"), "user-2"),
    ).toBe("Ada");
  });

  it("copes with an author whose account is gone", () => {
    expect(
      revisionAuthorName(
        revision("r-1", "2026-08-16T10:00:00Z", { author: null }),
        "user-1",
      ),
    ).toBe("Someone");
  });
});

describe("historyHasMultipleAuthors", () => {
  const by = (id: string) => ({
    author: { id, name: id, email: `${id}@example.com` },
  });

  it("stays quiet when one person wrote every version", () => {
    expect(
      historyHasMultipleAuthors([
        revision("r-1", "2026-08-16T11:00:00.000Z", by("user-1")),
        revision("r-2", "2026-08-16T10:00:00.000Z", by("user-1")),
      ]),
    ).toBe(false);
  });

  it("speaks up once a second person has edited", () => {
    expect(
      historyHasMultipleAuthors([
        revision("r-1", "2026-08-16T11:00:00.000Z", by("user-1")),
        revision("r-2", "2026-08-16T10:00:00.000Z", by("user-2")),
      ]),
    ).toBe(true);
  });

  it("counts a lost author as someone else", () => {
    expect(
      historyHasMultipleAuthors([
        revision("r-1", "2026-08-16T11:00:00.000Z", by("user-1")),
        revision("r-2", "2026-08-16T10:00:00.000Z", { author: null }),
      ]),
    ).toBe(true);
  });
});

describe("revisionDayTime", () => {
  const now = new Date("2026-08-16T12:00:00.000Z");

  it("names the day and the time", () => {
    expect(
      revisionDayTime({ createdAt: "2026-08-16T10:00:00.000Z" }, now),
    ).toMatch(/^Today at /);
    expect(
      revisionDayTime({ createdAt: "2026-08-15T10:00:00.000Z" }, now),
    ).toMatch(/^Yesterday at /);
    expect(
      revisionDayTime({ createdAt: "2026-08-02T10:00:00.000Z" }, now),
    ).toMatch(/^August 2, 2026 at /);
  });
});

describe("canRestoreRevisions", () => {
  it("allows an owner or editor on an active note", () => {
    expect(canRestoreRevisions(note())).toBe(true);
    expect(canRestoreRevisions(note({ isArchived: true }))).toBe(true);
    expect(canRestoreRevisions(note({ permission: "editor" }))).toBe(true);
  });

  it("refuses a viewer, a trashed note, and a note that has not loaded", () => {
    expect(canRestoreRevisions(note({ permission: "viewer" }))).toBe(false);
    expect(canRestoreRevisions(note({ state: "trashed" }))).toBe(false);
    expect(canRestoreRevisions(null)).toBe(false);
  });
});

describe("revisionsFromPages", () => {
  it("joins the pages in the order they arrived", () => {
    const pages = [
      {
        revisions: [revision("r-1", "2026-08-16T10:00:00Z")],
        nextCursor: "r-1",
      },
      {
        revisions: [revision("r-2", "2026-08-15T10:00:00Z")],
        nextCursor: null,
      },
    ];

    expect(revisionsFromPages(pages).map((r) => r.id)).toEqual(["r-1", "r-2"]);
  });

  it("has nothing to join before the first page lands", () => {
    expect(revisionsFromPages(undefined)).toEqual([]);
  });
});

describe("timelineEntries", () => {
  it("carries each revision through", () => {
    const entries = timelineEntries([
      revision("r-1", "2026-08-16T10:00:00.000Z"),
    ]);

    expect(entries.map((entry) => entry.id)).toEqual(["r-1"]);
    expect(entries[0].revision).not.toBeNull();
  });
});

describe("comparisonTargetId", () => {
  it("compares a version with the one after it", () => {
    const revisions = [
      revision("r-1", "2026-08-16T11:00:00.000Z"),
      revision("r-2", "2026-08-16T10:00:00.000Z"),
    ];

    expect(comparisonTargetId(revisions, "r-2")).toBe("r-1");
  });

  it("compares the newest version with the note as it is now", () => {
    const revisions = [revision("r-1", "2026-08-16T11:00:00.000Z")];

    expect(comparisonTargetId(revisions, "r-1")).toBeNull();
  });

  it("skips a rejected edit, which the note never took", () => {
    const revisions = [
      revision("r-1", "2026-08-16T12:00:00.000Z", { cause: "conflict" }),
      revision("r-2", "2026-08-16T11:00:00.000Z"),
      revision("r-3", "2026-08-16T10:00:00.000Z"),
    ];

    expect(comparisonTargetId(revisions, "r-3")).toBe("r-2");
  });

  it("compares a rejected edit with the note as it is now", () => {
    const revisions = [
      revision("r-1", "2026-08-16T12:00:00.000Z", { cause: "conflict" }),
      revision("r-2", "2026-08-16T11:00:00.000Z"),
    ];

    expect(comparisonTargetId(revisions, "r-1")).toBeNull();
  });
});

describe("groupTimelineByDay", () => {
  const now = new Date("2026-08-16T12:00:00.000Z");
  const entries = (...revisions: NoteRevisionSummary[]) =>
    timelineEntries(revisions);

  it("names today and yesterday, and dates the rest", () => {
    const days = groupTimelineByDay(
      entries(
        revision("r-1", "2026-08-16T10:00:00.000Z"),
        revision("r-2", "2026-08-15T10:00:00.000Z"),
        revision("r-3", "2026-08-02T10:00:00.000Z"),
      ),
      now,
    );

    expect(days.map((day) => day.label)).toEqual([
      "Today",
      "Yesterday",
      "August 2, 2026",
    ]);
  });

  it("keeps a day's entries together in the order given", () => {
    const days = groupTimelineByDay(
      entries(
        revision("r-1", "2026-08-16T11:00:00.000Z"),
        revision("r-2", "2026-08-16T09:00:00.000Z"),
        revision("r-3", "2026-08-15T09:00:00.000Z"),
      ),
      now,
    );

    expect(days).toHaveLength(2);
    expect(days[0].entries.map((entry) => entry.id)).toEqual(["r-1", "r-2"]);
    expect(days[1].entries.map((entry) => entry.id)).toEqual(["r-3"]);
  });

  it("has no days when there is nothing to show", () => {
    expect(groupTimelineByDay([], now)).toEqual([]);
  });
});
