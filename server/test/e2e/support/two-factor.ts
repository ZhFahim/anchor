import {
  createHash,
  createPrivateKey,
  generateKeyPairSync,
  randomBytes,
  sign,
  type KeyObject,
} from 'crypto';
import request from 'supertest';
import { vi } from 'vitest';
import { base32Decode, totpCode } from 'src/auth/two-factor/totp.util';
import { Actor } from './actor';
import { bodyOf } from './http';
import type { E2EApp } from './app';

export interface Tokens {
  access_token: string;
  refresh_token: string;
}

/** A code that is valid now, and a step later each time it is asked for. */
export class Authenticator {
  private readonly secret: Buffer;

  constructor(base32Secret: string) {
    this.secret = base32Decode(base32Secret);
  }

  /** Moves the clock one step on so the code was never used before. */
  next(): string {
    vi.setSystemTime(Date.now() + 31_000);
    return totpCode(this.secret, Date.now());
  }

  current(): string {
    return totpCode(this.secret, Date.now());
  }
}

/** Turns an authenticator on for `actor`; returns what the person would keep. */
export async function enableTotp(ctx: E2EApp, actor: Actor) {
  const setup = bodyOf<{ secret: string; otpauthUri: string }>(
    await actor.http.post('/api/auth/2fa/setup').send({}).expect(200),
  );
  const authenticator = new Authenticator(setup.secret);
  const enabled = bodyOf<{ recoveryCodes: string[] } & Tokens>(
    await actor.http
      .post('/api/auth/2fa/enable')
      .send({ code: authenticator.current() })
      .expect(200),
  );
  return { authenticator, ...enabled, secret: setup.secret };
}

export const passwordLogin = (
  ctx: E2EApp,
  email: string,
  password = 'password-123',
) => request(ctx.http).post('/api/auth/login').send({ email, password });

// ---- a passkey, in software ------------------------------------------------

const b64 = (buffer: Buffer) => buffer.toString('base64url');

function cbor(value: unknown): Buffer {
  const head = (major: number, length: number) => {
    if (length < 24) return Buffer.from([(major << 5) | length]);
    if (length < 256) return Buffer.from([(major << 5) | 24, length]);
    return Buffer.from([(major << 5) | 25, length >> 8, length & 255]);
  };
  if (typeof value === 'number') {
    return value >= 0 ? head(0, value) : head(1, -1 - value);
  }
  if (typeof value === 'string') {
    const bytes = Buffer.from(value);
    return Buffer.concat([head(3, bytes.length), bytes]);
  }
  if (Buffer.isBuffer(value))
    return Buffer.concat([head(2, value.length), value]);
  if (value instanceof Map) {
    return Buffer.concat([
      head(5, value.size),
      ...[...value].flatMap(([k, v]) => [cbor(k), cbor(v)]),
    ]);
  }
  throw new Error('unsupported CBOR value');
}

/** Enough of an authenticator for the server's WebAuthn checks: ES256, no attestation. */
export class VirtualPasskey {
  readonly credentialId = randomBytes(32);
  private readonly privateKey: KeyObject;
  private readonly publicJwk: { x: string; y: string };
  counter = 0;

  constructor(
    private readonly origin = 'http://localhost:3000',
    private readonly rpId = 'localhost',
    private readonly userHandle = 'user-handle',
  ) {
    const { privateKey, publicKey } = generateKeyPairSync('ec', {
      namedCurve: 'P-256',
    });
    this.privateKey = createPrivateKey(
      privateKey.export({ type: 'pkcs8', format: 'pem' }),
    );
    this.publicJwk = publicKey.export({ format: 'jwk' }) as {
      x: string;
      y: string;
    };
  }

  private rpIdHash() {
    return createHash('sha256').update(this.rpId).digest();
  }

  private clientData(type: string, challenge: string, origin = this.origin) {
    return Buffer.from(
      JSON.stringify({ type, challenge, origin, crossOrigin: false }),
    );
  }

  /** The reply to navigator.credentials.create() for these options. */
  create(
    options: { challenge: string },
    overrides: { origin?: string; userVerified?: boolean } = {},
  ) {
    const flags = 0x41 | (overrides.userVerified === false ? 0 : 0x04);
    const cose = cbor(
      new Map<number, unknown>([
        [1, 2],
        [3, -7],
        [-1, 1],
        [-2, Buffer.from(this.publicJwk.x, 'base64url')],
        [-3, Buffer.from(this.publicJwk.y, 'base64url')],
      ]),
    );
    const idLength = Buffer.alloc(2);
    idLength.writeUInt16BE(this.credentialId.length);
    const counter = Buffer.alloc(4);
    const authData = Buffer.concat([
      this.rpIdHash(),
      Buffer.from([flags]),
      counter,
      Buffer.alloc(16),
      idLength,
      this.credentialId,
      cose,
    ]);
    const attestationObject = cbor(
      new Map<string, unknown>([
        ['fmt', 'none'],
        ['attStmt', new Map()],
        ['authData', authData],
      ]),
    );
    return {
      id: b64(this.credentialId),
      rawId: b64(this.credentialId),
      type: 'public-key',
      response: {
        clientDataJSON: b64(
          this.clientData(
            'webauthn.create',
            options.challenge,
            overrides.origin,
          ),
        ),
        attestationObject: b64(attestationObject),
        transports: ['internal'],
      },
      clientExtensionResults: {},
      authenticatorAttachment: 'platform',
    };
  }

  /** The reply to navigator.credentials.get() for these options. */
  get(
    options: { challenge: string },
    overrides: { origin?: string; userVerified?: boolean } = {},
  ) {
    this.counter += 1;
    const flags = 0x01 | (overrides.userVerified === false ? 0 : 0x04);
    const counter = Buffer.alloc(4);
    counter.writeUInt32BE(this.counter);
    const authData = Buffer.concat([
      this.rpIdHash(),
      Buffer.from([flags]),
      counter,
    ]);
    const clientData = this.clientData(
      'webauthn.get',
      options.challenge,
      overrides.origin,
    );
    const signature = sign(
      'sha256',
      Buffer.concat([
        authData,
        createHash('sha256').update(clientData).digest(),
      ]),
      { key: this.privateKey, dsaEncoding: 'der' },
    );
    return {
      id: b64(this.credentialId),
      rawId: b64(this.credentialId),
      type: 'public-key',
      response: {
        authenticatorData: b64(authData),
        clientDataJSON: b64(clientData),
        signature: b64(signature),
        userHandle: b64(Buffer.from(this.userHandle)),
      },
      clientExtensionResults: {},
      authenticatorAttachment: 'platform',
    };
  }
}

/** Registers `passkey` for `actor` through the signed-in settings flow. */
export async function addPasskey(
  actor: Actor,
  passkey: VirtualPasskey,
  name = 'Test key',
) {
  const { options, challenge } = bodyOf<{
    options: { challenge: string };
    challenge: string;
  }>(await actor.http.post('/api/auth/passkeys/register/options').expect(200));
  return bodyOf<{ passkey: { id: string; name: string } }>(
    await actor.http
      .post('/api/auth/passkeys/register/verify')
      .send({ challenge, response: passkey.create(options), name })
      .expect(200),
  ).passkey;
}

/** Signs in with `passkey`, usernameless. */
export async function passkeyLogin(
  ctx: E2EApp,
  passkey: VirtualPasskey,
  expectedStatus: number,
): Promise<{ body: unknown }> {
  const { options, challenge } = bodyOf<{
    options: { challenge: string };
    challenge: string;
  }>(
    await request(ctx.http)
      .post('/api/auth/passkeys/login/options')
      .expect(200),
  );
  return request(ctx.http)
    .post('/api/auth/passkeys/login/verify')
    .send({ challenge, response: passkey.get(options) })
    .expect(expectedStatus);
}
