import {
  createCipheriv,
  createDecipheriv,
  createHmac,
  hkdfSync,
  randomBytes,
} from 'crypto';
import { Inject, Injectable } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { AuthConfig } from '../../config/configuration';

/**
 * Encrypts TOTP secrets and keys the recovery-code hashes. Both derive from
 * TOTP_ENCRYPTION_KEY; rotating the key invalidates every enrolled
 * authenticator.
 */
@Injectable()
export class TwoFactorCryptoService {
  private readonly encryptionKey: Buffer | null;
  private readonly macKey: Buffer | null;

  constructor(
    @Inject(AuthConfig.KEY)
    authConfig: ConfigType<typeof AuthConfig>,
  ) {
    const raw = authConfig.totpEncryptionKey;
    const master = raw ? Buffer.from(raw, 'base64') : null;
    if (master && master.length === 32) {
      this.encryptionKey = Buffer.from(
        hkdfSync('sha256', master, '', 'anchor/2fa/encrypt', 32),
      );
      this.macKey = Buffer.from(
        hkdfSync('sha256', master, '', 'anchor/2fa/mac', 32),
      );
    } else {
      this.encryptionKey = null;
      this.macKey = null;
    }
  }

  get isAvailable(): boolean {
    return this.encryptionKey !== null;
  }

  encrypt(plain: string): string {
    const key = this.requireKey(this.encryptionKey);
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const data = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return ['v1', iv, tag, data]
      .map((part, i) =>
        i === 0 ? part : (part as Buffer).toString('base64url'),
      )
      .join('.');
  }

  decrypt(payload: string): string {
    const key = this.requireKey(this.encryptionKey);
    const [version, iv, tag, data] = payload.split('.');
    if (version !== 'v1' || !iv || !tag || !data) {
      throw new Error('Unsupported secret format');
    }
    const decipher = createDecipheriv(
      'aes-256-gcm',
      key,
      Buffer.from(iv, 'base64url'),
    );
    decipher.setAuthTag(Buffer.from(tag, 'base64url'));
    return Buffer.concat([
      decipher.update(Buffer.from(data, 'base64url')),
      decipher.final(),
    ]).toString('utf8');
  }

  /** Keyed hash, so a copy of the database alone can't be brute-forced. */
  mac(value: string): string {
    const key = this.requireKey(this.macKey);
    return createHmac('sha256', key).update(value).digest('hex');
  }

  private requireKey(key: Buffer | null): Buffer {
    if (!key) throw new Error('TOTP_ENCRYPTION_KEY is not configured');
    return key;
  }
}
