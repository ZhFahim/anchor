import { describe, expect, it } from "vitest";
import { englishT } from "@/i18n/translate";
import {
  daysUntilDeletion,
  deletedNotesText,
  deleteNotesWarning,
} from "./trash";
import type { Note } from "./types";

const trashed = (at: string) => ({ stateChangedAt: at, updatedAt: at }) as Note;

describe("daysUntilDeletion", () => {
  it("counts down from 30 days after the note went to trash", () => {
    expect(
      daysUntilDeletion(
        trashed("2026-09-01T12:00:00Z"),
        new Date("2026-09-08T12:00:00Z"),
      ),
    ).toBe(23);
  });

  it("never says less than one day", () => {
    expect(
      daysUntilDeletion(
        trashed("2026-08-01T12:00:00Z"),
        new Date("2026-09-08T12:00:00Z"),
      ),
    ).toBe(1);
  });
});

describe("deletedNotesText", () => {
  it("names what went to the trash and what left the list", () => {
    expect(deletedNotesText(1, 0, englishT)).toBe("1 note moved to trash");
    expect(deletedNotesText(0, 2, englishT)).toBe(
      "2 notes removed from your notes",
    );
    expect(deletedNotesText(2, 1, englishT)).toBe(
      "2 notes moved to trash. 1 removed from your notes.",
    );
  });
});

describe("deleteNotesWarning", () => {
  it("says it or them for the shared notes", () => {
    expect(deleteNotesWarning(0, 1, englishT)).toBe(
      "1 note shared with you will be removed from your notes. To see it again, the owner has to share it with you again.",
    );
    expect(deleteNotesWarning(3, 2, englishT)).toBe(
      "3 notes will be moved to trash. 2 notes shared with you will be removed from your notes. To see them again, the owner has to share them with you again.",
    );
  });
});
