import { describe, expect, it } from "vitest";
import {
  formatOccurrence,
  isReminderPast,
  nextOccurrence,
  nextRoundTime,
  parseTimeInput,
  parseWallClock,
  presetReminders,
  reminderLabel,
  toWallClock,
} from "./reminder";
import type { NoteReminder } from "./types";

const reminder = (overrides: Partial<NoteReminder> = {}): NoteReminder => ({
  remindAt: "2026-09-04T09:00",
  recurrence: "none",
  version: 1,
  ...overrides,
});

describe("wall clock", () => {
  it("round-trips through a local Date without touching the zone", () => {
    const value = "2026-09-04T09:00";
    expect(toWallClock(parseWallClock(value)!)).toBe(value);
  });

  it("pads single-digit parts", () => {
    expect(toWallClock(new Date(2026, 0, 5, 7, 3))).toBe("2026-01-05T07:03");
  });

  it("rejects anything carrying a zone or seconds", () => {
    expect(parseWallClock("2026-09-04T09:00:00Z")).toBeNull();
    expect(parseWallClock("2026-09-04T09:00:00")).toBeNull();
    expect(parseWallClock("tomorrow")).toBeNull();
  });
});

describe("isReminderPast", () => {
  const now = new Date(2026, 8, 4, 12, 0);

  it("is true for a reminder that does not repeat and has passed", () => {
    expect(isReminderPast(reminder(), now)).toBe(true);
  });

  it("is false for a reminder that is still to come", () => {
    expect(
      isReminderPast(reminder({ remindAt: "2026-09-04T18:00" }), now),
    ).toBe(false);
  });

  it("is false for a repeating reminder anchored in the past", () => {
    expect(isReminderPast(reminder({ recurrence: "daily" }), now)).toBe(false);
  });
});

describe("presetReminders", () => {
  it("offers times that are all valid wall clocks", () => {
    const now = new Date(2026, 8, 4, 12, 0);
    for (const preset of presetReminders(now)) {
      expect(parseWallClock(preset.remindAt)).not.toBeNull();
    }
  });

  it("puts tomorrow and next week on the right days at 09:00", () => {
    const now = new Date(2026, 8, 4, 12, 0);
    const presets = presetReminders(now);
    expect(presets[2]).toEqual({
      label: "Tomorrow",
      remindAt: "2026-09-05T09:00",
    });
    expect(presets[3]).toEqual({
      label: "Next week",
      remindAt: "2026-09-11T09:00",
    });
  });
});

describe("reminderLabel", () => {
  const now = new Date(2026, 8, 4, 12, 0);

  it("names the repeat when there is one", () => {
    expect(reminderLabel(reminder({ recurrence: "daily" }), now)).toContain(
      "· Daily",
    );
  });

  it("says nothing about repeating when it does not repeat", () => {
    expect(reminderLabel(reminder(), now)).not.toContain("·");
  });

  it("falls back to the raw value it cannot parse", () => {
    expect(reminderLabel(reminder({ remindAt: "nonsense" }), now)).toBe(
      "nonsense",
    );
  });
});

describe("nextOccurrence", () => {
  const now = new Date(2026, 8, 4, 12, 0);

  it("returns the anchor itself when it is still ahead", () => {
    const at = nextOccurrence(reminder({ remindAt: "2026-09-04T18:00" }), now);
    expect(toWallClock(at!)).toBe("2026-09-04T18:00");
  });

  it("returns nothing when it does not repeat and has passed", () => {
    expect(nextOccurrence(reminder(), now)).toBeNull();
  });

  it("rolls a daily anchor forward to today", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2026-08-01T18:00", recurrence: "daily" }),
      now,
    );
    expect(toWallClock(at!)).toBe("2026-09-04T18:00");
  });

  it("keeps the weekday when stepping weeks", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2026-08-01T09:00", recurrence: "weekly" }),
      now,
    );
    expect(toWallClock(at!)).toBe("2026-09-05T09:00");
  });

  it("clamps a monthly anchor to the end of a short month", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2026-01-31T09:00", recurrence: "monthly" }),
      new Date(2026, 1, 1),
    );
    expect(toWallClock(at!)).toBe("2026-02-28T09:00");
  });

  it("restores the full day once a longer month comes round", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2026-01-31T09:00", recurrence: "monthly" }),
      new Date(2026, 2, 1),
    );
    expect(toWallClock(at!)).toBe("2026-03-31T09:00");
  });

  it("moves a Feb 29 yearly anchor to Feb 28 in a common year", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2024-02-29T09:00", recurrence: "yearly" }),
      new Date(2025, 0, 1),
    );
    expect(toWallClock(at!)).toBe("2025-02-28T09:00");
  });

  it("holds the wall time while stepping across months", () => {
    const at = nextOccurrence(
      reminder({ remindAt: "2026-01-01T09:00", recurrence: "daily" }),
      new Date(2026, 6, 15, 12, 0),
    );
    expect(at!.getHours()).toBe(9);
    expect(at!.getMinutes()).toBe(0);
  });

  it("returns nothing for a value it cannot parse", () => {
    expect(nextOccurrence(reminder({ remindAt: "nonsense" }), now)).toBeNull();
  });
});

describe("formatOccurrence", () => {
  const now = new Date(2026, 8, 4, 12, 0);

  it("names today and tomorrow instead of dating them", () => {
    expect(formatOccurrence(new Date(2026, 8, 4, 18, 0), now)).toMatch(
      /^Today at /,
    );
    expect(formatOccurrence(new Date(2026, 8, 5, 9, 0), now)).toMatch(
      /^Tomorrow at /,
    );
  });

  it("dates anything further out", () => {
    const label = formatOccurrence(new Date(2026, 8, 11, 9, 0), now);
    expect(label).not.toMatch(/Today|Tomorrow/);
    expect(label).toContain("at");
  });

  it("counts calendar days, not elapsed hours", () => {
    const late = new Date(2026, 8, 4, 23, 30);
    expect(formatOccurrence(new Date(2026, 8, 5, 0, 30), late)).toMatch(
      /^Tomorrow at /,
    );
  });
});

describe("nextRoundTime", () => {
  it("rounds up to the next five-minute mark", () => {
    expect(nextRoundTime(new Date(2026, 8, 4, 12, 1))).toBe("12:10");
    expect(nextRoundTime(new Date(2026, 8, 4, 12, 0))).toBe("12:05");
  });

  it("rolls into the next hour rather than reporting minute 60", () => {
    expect(nextRoundTime(new Date(2026, 8, 4, 12, 51))).toBe("13:00");
  });

  it("stops at the end of the day", () => {
    expect(nextRoundTime(new Date(2026, 8, 4, 23, 56))).toBe("23:59");
    expect(nextRoundTime(new Date(2026, 8, 4, 23, 50))).toBe("23:55");
  });

  it("always lands ahead of the clock it was given", () => {
    for (const minute of [0, 1, 29, 44, 55, 58]) {
      const now = new Date(2026, 8, 4, 14, minute);
      expect(
        nextRoundTime(now) > `${14}:${String(minute).padStart(2, "0")}`,
      ).toBe(true);
    }
  });
});

describe("parseTimeInput", () => {
  it("reads a 12-hour time with a meridiem", () => {
    expect(parseTimeInput("4:10 PM")).toBe("16:10");
    expect(parseTimeInput("12:30 am")).toBe("00:30");
    expect(parseTimeInput("12:30 pm")).toBe("12:30");
  });

  it("reads a bare 24-hour time", () => {
    expect(parseTimeInput("16:10")).toBe("16:10");
    expect(parseTimeInput("00:00")).toBe("00:00");
    expect(parseTimeInput("23:59")).toBe("23:59");
  });

  it("fills in the minutes when only an hour is typed", () => {
    expect(parseTimeInput("9")).toBe("09:00");
    expect(parseTimeInput("9pm")).toBe("21:00");
  });

  it("shrugs off spacing, case and dotted meridiems", () => {
    expect(parseTimeInput("  4:10pm ")).toBe("16:10");
    expect(parseTimeInput("4:10 P.M.")).toBe("16:10");
  });

  it("pads a single-digit minute", () => {
    expect(parseTimeInput("4:5")).toBe("04:05");
  });

  it("rejects times that do not exist", () => {
    expect(parseTimeInput("24:00")).toBeNull();
    expect(parseTimeInput("12:60")).toBeNull();
    expect(parseTimeInput("13:00 pm")).toBeNull();
    expect(parseTimeInput("0:30 am")).toBeNull();
  });

  it("rejects anything that is not a time", () => {
    expect(parseTimeInput("")).toBeNull();
    expect(parseTimeInput("noon")).toBeNull();
    expect(parseTimeInput("4:10 xm")).toBeNull();
  });
});
