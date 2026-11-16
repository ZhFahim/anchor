export const OTP_LENGTH = 6;

/** Digits only, as many as fit. */
export function otpDigits(raw: string, max = OTP_LENGTH): string {
  return raw.replace(/\D/g, "").slice(0, max);
}

export interface OtpEdit {
  value: string;
  /** The box to put the cursor in. */
  focus: number;
}

const lastBox = OTP_LENGTH - 1;

/**
 * A box changed to `raw`. One digit replaces the digit in that box; several
 * (a paste, or an autofill) fill from that box on, and six or more replace the
 * whole code. An empty box deletes.
 * The value stays one run of digits, so it never has a gap.
 */
export function editOtp(value: string, index: number, raw: string): OtpEdit {
  const digits = otpDigits(raw);
  // A whole code is a whole code, whichever box it landed in.
  if (digits.length >= OTP_LENGTH) index = 0;
  if (!digits) {
    return {
      value: value.slice(0, index) + value.slice(index + 1),
      focus: Math.min(index, lastBox),
    };
  }
  const at = Math.min(index, value.length);
  const next = (
    value.slice(0, at) +
    digits +
    value.slice(at + digits.length)
  ).slice(0, OTP_LENGTH);
  return { value: next, focus: Math.min(at + digits.length, lastBox) };
}

/** Backspace in an empty box deletes the digit before it. */
export function backspaceOtp(value: string, index: number): OtpEdit {
  const before = Math.max(index - 1, 0);
  return {
    value: value.slice(0, before) + value.slice(before + 1),
    focus: before,
  };
}

export const isOtpComplete = (value: string) => value.length === OTP_LENGTH;
