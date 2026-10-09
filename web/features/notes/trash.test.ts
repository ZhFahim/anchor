import { describe, expect, it } from "vitest";
import { daysUntilDeletion } from "./trash";
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
