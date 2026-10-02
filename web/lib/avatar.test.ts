import { describe, expect, it } from "vitest";
import { AVATAR_COLORS, avatarColor, initials } from "./avatar";

describe("avatarColor", () => {
  it("gives the same person the same color", () => {
    expect(avatarColor("39fb31d5-790c")).toBe(avatarColor("39fb31d5-790c"));
    expect(AVATAR_COLORS).toContain(avatarColor("anyone"));
  });
});

describe("initials", () => {
  it("takes the first and last word", () => {
    expect(initials("Alex Kim")).toBe("AK");
    expect(initials("Maya van der Berg")).toBe("MB");
    expect(initials("maya")).toBe("M");
    expect(initials("  ")).toBe("?");
  });
});
