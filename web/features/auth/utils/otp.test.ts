import { describe, expect, it } from "vitest";
import { backspaceOtp, editOtp, isOtpComplete, otpDigits } from "./otp";

describe("otpDigits", () => {
  it("keeps the digits of a pasted code, however it is written", () => {
    expect(otpDigits("482 193")).toBe("482193");
    expect(otpDigits("482-193")).toBe("482193");
    expect(otpDigits(" 4a8b2c1d9e3 ")).toBe("482193");
  });

  it("drops what doesn’t fit", () => {
    expect(otpDigits("12345678")).toBe("123456");
  });
});

describe("editOtp", () => {
  it("types into the next box and moves on", () => {
    expect(editOtp("", 0, "4")).toEqual({ value: "4", focus: 1 });
    expect(editOtp("48", 2, "2")).toEqual({ value: "482", focus: 3 });
  });

  it("replaces the digit in a box that already has one", () => {
    expect(editOtp("482", 1, "9")).toEqual({ value: "492", focus: 2 });
  });

  it("ignores a letter without moving", () => {
    expect(editOtp("48", 2, "x")).toEqual({ value: "48", focus: 2 });
  });

  it("fills every box from a paste or an autofill in the first box", () => {
    expect(editOtp("", 0, "482193")).toEqual({ value: "482193", focus: 5 });
    expect(editOtp("4", 0, "482 193")).toEqual({ value: "482193", focus: 5 });
  });

  it("fills from the box that was pasted into", () => {
    expect(editOtp("48", 2, "2193")).toEqual({ value: "482193", focus: 5 });
  });

  it("takes a whole code whichever box it landed in", () => {
    expect(editOtp("48", 2, "219345")).toEqual({ value: "219345", focus: 5 });
    expect(editOtp("", 4, "219345")).toEqual({ value: "219345", focus: 5 });
  });

  it("never leaves a gap when a later box is typed into", () => {
    expect(editOtp("4", 4, "7")).toEqual({ value: "47", focus: 2 });
  });

  it("deletes the digit of an emptied box", () => {
    expect(editOtp("482", 1, "")).toEqual({ value: "42", focus: 1 });
  });

  it("stays in the last box after the sixth digit", () => {
    expect(editOtp("48219", 5, "3")).toEqual({ value: "482193", focus: 5 });
  });
});

describe("backspaceOtp", () => {
  it("deletes the digit before an empty box and goes back to it", () => {
    expect(backspaceOtp("48", 2)).toEqual({ value: "4", focus: 1 });
  });

  it("does nothing before the first box", () => {
    expect(backspaceOtp("", 0)).toEqual({ value: "", focus: 0 });
  });
});

describe("isOtpComplete", () => {
  it("is true at six digits only", () => {
    expect(isOtpComplete("48219")).toBe(false);
    expect(isOtpComplete("482193")).toBe(true);
  });
});
