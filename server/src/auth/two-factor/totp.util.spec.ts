import { describe, expect, it } from 'vitest';
import {
  base32Decode,
  base32Encode,
  buildOtpauthUri,
  hotp,
  normalizeTotpCode,
  totpCode,
  totpStep,
  verifyTotp,
} from './totp.util';

// RFC 4226 appendix D and RFC 6238 appendix B use this 20-byte secret.
const RFC_SECRET = Buffer.from('12345678901234567890');

describe('hotp', () => {
  it('matches the RFC 4226 test vectors', () => {
    const expected = [
      '755224',
      '287082',
      '359152',
      '969429',
      '338314',
      '254676',
      '287922',
      '162583',
      '399871',
      '520489',
    ];
    expected.forEach((code, counter) => {
      expect(hotp(RFC_SECRET, counter)).toBe(code);
    });
  });
});

describe('totpCode', () => {
  // RFC 6238 gives 8 digits; the last 6 are what this app uses.
  it.each([
    [59, '287082'],
    [1111111109, '081804'],
    [1111111111, '050471'],
    [1234567890, '005924'],
    [2000000000, '279037'],
  ])('matches the RFC 6238 vector at t=%i', (seconds, code) => {
    expect(totpCode(RFC_SECRET, seconds * 1000)).toBe(code);
  });
});

describe('verifyTotp', () => {
  const now = 1_700_000_000_000;
  const step = totpStep(now);

  it('accepts the current code and returns its step', () => {
    expect(
      verifyTotp(RFC_SECRET, totpCode(RFC_SECRET, now), { nowMs: now }),
    ).toBe(step);
  });

  it('allows one step of clock drift either way, no more', () => {
    const before = hotp(RFC_SECRET, step - 1);
    const after = hotp(RFC_SECRET, step + 1);
    const tooOld = hotp(RFC_SECRET, step - 2);
    const tooNew = hotp(RFC_SECRET, step + 2);
    expect(verifyTotp(RFC_SECRET, before, { nowMs: now })).toBe(step - 1);
    expect(verifyTotp(RFC_SECRET, after, { nowMs: now })).toBe(step + 1);
    expect(verifyTotp(RFC_SECRET, tooOld, { nowMs: now })).toBeNull();
    expect(verifyTotp(RFC_SECRET, tooNew, { nowMs: now })).toBeNull();
  });

  it('refuses a step that was already used', () => {
    const code = totpCode(RFC_SECRET, now);
    expect(
      verifyTotp(RFC_SECRET, code, { nowMs: now, lastStep: step }),
    ).toBeNull();
    expect(
      verifyTotp(RFC_SECRET, code, { nowMs: now, lastStep: step - 1 }),
    ).toBe(step);
  });

  it('takes the code as a phone shows it, and nothing else', () => {
    const code = totpCode(RFC_SECRET, now);
    expect(
      verifyTotp(RFC_SECRET, `${code.slice(0, 3)} ${code.slice(3)}`, {
        nowMs: now,
      }),
    ).toBe(step);
    expect(verifyTotp(RFC_SECRET, '12345', { nowMs: now })).toBeNull();
    expect(verifyTotp(RFC_SECRET, '1234567', { nowMs: now })).toBeNull();
    expect(verifyTotp(RFC_SECRET, 'abcdef', { nowMs: now })).toBeNull();
    expect(verifyTotp(RFC_SECRET, '', { nowMs: now })).toBeNull();
  });
});

describe('normalizeTotpCode', () => {
  it('keeps six digits and drops whitespace', () => {
    expect(normalizeTotpCode(' 123 456 ')).toBe('123456');
    expect(normalizeTotpCode('12-3456')).toBeNull();
  });
});

describe('base32', () => {
  it('round-trips and matches the RFC 4648 vectors', () => {
    expect(base32Encode(Buffer.from('foobar'))).toBe('MZXW6YTBOI');
    expect(base32Decode('MZXW6YTBOI').toString()).toBe('foobar');
    const bytes = Buffer.from([0, 255, 17, 34, 51, 68, 85, 102, 119, 136]);
    expect(base32Decode(base32Encode(bytes))).toEqual(bytes);
  });

  it('reads lower case, spaces and padding, as people copy keys', () => {
    expect(base32Decode('mzxw 6ytb oi==').toString()).toBe('foobar');
  });

  it('rejects characters outside the alphabet', () => {
    expect(() => base32Decode('MZXW1')).toThrow();
  });
});

describe('buildOtpauthUri', () => {
  it('builds the URI authenticator apps import', () => {
    const uri = new URL(
      buildOtpauthUri({
        secret: 'JBSWY3DPEHPK3PXP',
        account: 'ada@example.com',
        issuer: 'Anchor',
      }),
    );
    expect(uri.protocol).toBe('otpauth:');
    expect(uri.host).toBe('totp');
    expect(decodeURIComponent(uri.pathname)).toBe('/Anchor:ada@example.com');
    expect(Object.fromEntries(uri.searchParams)).toEqual({
      secret: 'JBSWY3DPEHPK3PXP',
      issuer: 'Anchor',
      algorithm: 'SHA1',
      digits: '6',
      period: '30',
    });
  });
});
