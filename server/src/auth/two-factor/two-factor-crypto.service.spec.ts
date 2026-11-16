import { randomBytes } from 'crypto';
import { describe, expect, it } from 'vitest';
import { TwoFactorCryptoService } from './two-factor-crypto.service';

const config = (totpEncryptionKey?: string) =>
  ({ totpEncryptionKey }) as ConstructorParameters<
    typeof TwoFactorCryptoService
  >[0];
const key = () => randomBytes(32).toString('base64');

describe('TwoFactorCryptoService', () => {
  it('is unavailable without a usable key', () => {
    expect(new TwoFactorCryptoService(config()).isAvailable).toBe(false);
    expect(new TwoFactorCryptoService(config('too-short')).isAvailable).toBe(
      false,
    );
    expect(new TwoFactorCryptoService(config(key())).isAvailable).toBe(true);
  });

  it('refuses to work unconfigured instead of storing plain text', () => {
    const service = new TwoFactorCryptoService(config());
    expect(() => service.encrypt('secret')).toThrow(/TOTP_ENCRYPTION_KEY/);
    expect(() => service.mac('code')).toThrow(/TOTP_ENCRYPTION_KEY/);
  });

  it('round-trips a secret and never stores it readable', () => {
    const service = new TwoFactorCryptoService(config(key()));
    const stored = service.encrypt('JBSWY3DPEHPK3PXP');
    expect(stored).not.toContain('JBSWY3DPEHPK3PXP');
    expect(service.decrypt(stored)).toBe('JBSWY3DPEHPK3PXP');
    // A fresh IV each time.
    expect(service.encrypt('JBSWY3DPEHPK3PXP')).not.toBe(stored);
  });

  it('detects tampering and a different key', () => {
    const service = new TwoFactorCryptoService(config(key()));
    const stored = service.encrypt('JBSWY3DPEHPK3PXP');
    const [version, iv, tag, data] = stored.split('.');
    const flipped = Buffer.from(data, 'base64url');
    flipped[0] ^= 1;
    expect(() =>
      service.decrypt(
        [version, iv, tag, flipped.toString('base64url')].join('.'),
      ),
    ).toThrow();
    expect(() =>
      new TwoFactorCryptoService(config(key())).decrypt(stored),
    ).toThrow();
  });

  it('keys the recovery-code hash, so it differs per server', () => {
    const a = new TwoFactorCryptoService(config(key()));
    const b = new TwoFactorCryptoService(config(key()));
    expect(a.mac('k7m29xqp3a')).toBe(a.mac('k7m29xqp3a'));
    expect(a.mac('k7m29xqp3a')).not.toBe(b.mac('k7m29xqp3a'));
    expect(a.mac('k7m29xqp3a')).toMatch(/^[0-9a-f]{64}$/);
  });
});
