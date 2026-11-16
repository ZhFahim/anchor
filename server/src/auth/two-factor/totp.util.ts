import { createHmac, randomBytes, timingSafeEqual } from 'crypto';

const BASE32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

export const TOTP_PERIOD_SECONDS = 30;
export const TOTP_DIGITS = 6;
// One step either side absorbs clock drift between the phone and the server.
export const TOTP_WINDOW = 1;
export const TOTP_SECRET_BYTES = 20;

export function base32Encode(buffer: Buffer): string {
  let bits = 0;
  let value = 0;
  let out = '';
  for (const byte of buffer) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      out += BASE32[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) out += BASE32[(value << (5 - bits)) & 31];
  return out;
}

export function base32Decode(input: string): Buffer {
  const clean = input.replace(/[\s=-]/g, '').toUpperCase();
  const bytes: number[] = [];
  let bits = 0;
  let value = 0;
  for (const char of clean) {
    const index = BASE32.indexOf(char);
    if (index < 0) throw new Error('Invalid base32 character');
    value = (value << 5) | index;
    bits += 5;
    if (bits >= 8) {
      bytes.push((value >>> (bits - 8)) & 255);
      bits -= 8;
    }
  }
  return Buffer.from(bytes);
}

export function generateTotpSecret(): Buffer {
  return randomBytes(TOTP_SECRET_BYTES);
}

/** RFC 4226 HOTP with HMAC-SHA1. */
export function hotp(secret: Buffer, counter: number): string {
  const message = Buffer.alloc(8);
  message.writeBigUInt64BE(BigInt(counter));
  const digest = createHmac('sha1', secret).update(message).digest();
  const offset = digest[digest.length - 1] & 0x0f;
  const binary =
    ((digest[offset] & 0x7f) << 24) |
    (digest[offset + 1] << 16) |
    (digest[offset + 2] << 8) |
    digest[offset + 3];
  return String(binary % 10 ** TOTP_DIGITS).padStart(TOTP_DIGITS, '0');
}

export function totpStep(nowMs = Date.now()): number {
  return Math.floor(nowMs / 1000 / TOTP_PERIOD_SECONDS);
}

export function totpCode(secret: Buffer, nowMs = Date.now()): string {
  return hotp(secret, totpStep(nowMs));
}

/** Digits only; accepts the "123 456" a phone shows. */
export function normalizeTotpCode(input: string): string | null {
  const digits = input.replace(/\s/g, '');
  return /^\d{6}$/.test(digits) ? digits : null;
}

/**
 * The time step the code belongs to, or null. A step at or before
 * `lastStep` is refused so one code can't be used twice.
 */
export function verifyTotp(
  secret: Buffer,
  input: string,
  options: { nowMs?: number; lastStep?: number | null } = {},
): number | null {
  const code = normalizeTotpCode(input);
  if (!code) return null;
  const current = totpStep(options.nowMs);
  const expected = Buffer.from(code);
  let matched: number | null = null;
  // No early exit: every candidate is compared.
  for (
    let step = current - TOTP_WINDOW;
    step <= current + TOTP_WINDOW;
    step++
  ) {
    const candidate = Buffer.from(hotp(secret, step));
    if (
      timingSafeEqual(candidate, expected) &&
      (options.lastStep == null || step > options.lastStep)
    ) {
      matched = step;
    }
  }
  return matched;
}

export function buildOtpauthUri(params: {
  secret: string;
  account: string;
  issuer: string;
}): string {
  const label = `${encodeURIComponent(params.issuer)}:${encodeURIComponent(params.account)}`;
  const query = new URLSearchParams({
    secret: params.secret,
    issuer: params.issuer,
    algorithm: 'SHA1',
    digits: String(TOTP_DIGITS),
    period: String(TOTP_PERIOD_SECONDS),
  });
  return `otpauth://totp/${label}?${query.toString()}`;
}
