import { randomInt } from 'crypto';

// No i, l, o, 0, 1: easy to misread on paper.
const ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789';
const CODE_LENGTH = 10;
export const RECOVERY_CODE_COUNT = 10;

/** `xxxxx-xxxxx`, about 50 bits each. */
export function generateRecoveryCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += ALPHABET[randomInt(ALPHABET.length)];
  }
  return `${code.slice(0, 5)}-${code.slice(5)}`;
}

export function generateRecoveryCodes(): string[] {
  const codes = new Set<string>();
  while (codes.size < RECOVERY_CODE_COUNT) codes.add(generateRecoveryCode());
  return [...codes];
}

/** Trimmed, lower-cased, dash optional. Null when it can't be a code. */
export function normalizeRecoveryCode(input: string): string | null {
  const clean = input.trim().toLowerCase().replace(/[\s-]/g, '');
  if (clean.length !== CODE_LENGTH) return null;
  for (const char of clean) if (!ALPHABET.includes(char)) return null;
  return clean;
}
