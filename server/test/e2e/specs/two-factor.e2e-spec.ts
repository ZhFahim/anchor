import {
  afterAll,
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import {
  Actor,
  bodyOf,
  createE2EApp,
  E2EApp,
  enableTotp,
  passwordLogin,
  Authenticator,
  type Tokens,
} from '../support';

interface Challenge {
  twoFactorRequired: true;
  challenge: string;
  message: string;
}

describe('two-factor with an authenticator app', () => {
  let ctx: E2EApp;
  let admin: Actor;
  let user: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    // Only the clock: codes live in 30 second steps.
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(Date.now());
    await ctx.resetDb();
    admin = await ctx.registerUser('Admin');
    user = await ctx.registerUser('Person');
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const startLogin = async () =>
    bodyOf<Challenge>(await passwordLogin(ctx, user.email).expect(401));

  const verify = (body: Record<string, unknown>) =>
    request(ctx.http).post('/api/auth/login/2fa').send(body);

  it('starts out off, and says what the server can do', async () => {
    const caps = await request(ctx.http)
      .get('/api/auth/capabilities')
      .expect(200);
    expect(bodyOf(caps)).toEqual({ totp: true, passkeys: true });

    const status = bodyOf<{
      totp: { enabled: boolean; recoveryCodesRemaining: number };
      passkeys: unknown[];
      required: boolean;
      policy: string;
    }>(await user.http.get('/api/auth/2fa').expect(200));
    expect(status).toMatchObject({
      totp: { enabled: false, recoveryCodesRemaining: 0 },
      passkeys: [],
      required: false,
      policy: 'optional',
    });
  });

  describe('turning it on', () => {
    it('hands out an otpauth link and ten recovery codes', async () => {
      const setup = bodyOf<{ secret: string; otpauthUri: string }>(
        await user.http.post('/api/auth/2fa/setup').send({}).expect(200),
      );
      expect(setup.secret).toMatch(/^[A-Z2-7]{32}$/);
      expect(setup.otpauthUri).toContain(`secret=${setup.secret}`);
      expect(decodeURIComponent(setup.otpauthUri)).toContain(
        `Anchor:${user.email}`,
      );

      const authenticator = new Authenticator(setup.secret);
      const enabled = bodyOf<{ recoveryCodes: string[] } & Tokens>(
        await user.http
          .post('/api/auth/2fa/enable')
          .send({ code: authenticator.current() })
          .expect(200),
      );
      expect(enabled.recoveryCodes).toHaveLength(10);
      for (const code of enabled.recoveryCodes) {
        expect(code).toMatch(/^[a-z0-9]{5}-[a-z0-9]{5}$/);
      }

      const status = bodyOf<{
        totp: { enabled: boolean; recoveryCodesRemaining: number };
      }>(await user.http.get('/api/auth/2fa').expect(200));
      expect(status.totp).toMatchObject({
        enabled: true,
        recoveryCodesRemaining: 10,
      });
    });

    it('keeps the secret encrypted and the recovery codes hashed', async () => {
      const { secret, recoveryCodes } = await enableTotp(ctx, user);

      const row = await ctx.prisma.user.findUniqueOrThrow({
        where: { id: user.id },
        select: { totpSecretEnc: true, totpPendingSecretEnc: true },
      });
      expect(row.totpSecretEnc).not.toContain(secret);
      expect(row.totpSecretEnc).toMatch(/^v1\./);
      expect(row.totpPendingSecretEnc).toBeNull();

      const stored = await ctx.prisma.recoveryCode.findMany({
        where: { userId: user.id },
      });
      expect(stored).toHaveLength(10);
      for (const code of recoveryCodes) {
        expect(stored.map((row) => row.codeHash)).not.toContain(code);
        expect(JSON.stringify(stored)).not.toContain(code.replace('-', ''));
      }
    });

    it('refuses a wrong code and does not turn on', async () => {
      await user.http.post('/api/auth/2fa/setup').send({}).expect(200);

      const res = await user.http
        .post('/api/auth/2fa/enable')
        .send({ code: '000000' })
        .expect(400);

      expect(bodyOf<{ message: string }>(res).message).toBe('Invalid code');
      await passwordLogin(ctx, user.email).expect(200);
    });

    it('cannot enable before setup', async () => {
      await user.http
        .post('/api/auth/2fa/enable')
        .send({ code: '123456' })
        .expect(400);
    });

    it('signs out every other session and returns a working new one', async () => {
      const other = bodyOf<Tokens>(
        await passwordLogin(ctx, user.email).expect(200),
      );

      const { access_token, refresh_token } = await enableTotp(ctx, user);

      await request(ctx.http)
        .post('/api/auth/refresh')
        .send({ refresh_token: other.refresh_token })
        .expect(401);
      await request(ctx.http)
        .post('/api/auth/refresh')
        .send({ refresh_token })
        .expect(200);
      await request(ctx.http)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${access_token}`)
        .expect(200);
    });

    it('is only for accounts with a password', async () => {
      const oidcOnly = await ctx.prisma.user.create({
        data: { email: 'sso@e2e.test', name: 'SSO', oidcSubject: 'sub-1' },
      });
      const token = ctx
        .get(JwtService)
        .sign({ email: oidcOnly.email, sub: oidcOnly.id });
      const res = await request(ctx.http)
        .post('/api/auth/2fa/setup')
        .set('Authorization', `Bearer ${token}`)
        .send({})
        .expect(400);
      expect(bodyOf<{ message: string }>(res).message).toMatch(/password/);
    });
  });

  describe('signing in with a code', () => {
    let authenticator: Authenticator;
    let recoveryCodes: string[];

    beforeEach(async () => {
      ({ authenticator, recoveryCodes } = await enableTotp(ctx, user));
    });

    it('does not hand out tokens for the password alone', async () => {
      const body = await startLogin();

      expect(body).toMatchObject({
        twoFactorRequired: true,
        message: 'Two-factor code required',
      });
      expect(body.challenge).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(JSON.stringify(body)).not.toContain('access_token');
    });

    it('signs in with the right code', async () => {
      const { challenge } = await startLogin();

      const res = await verify({
        challenge,
        code: authenticator.next(),
      }).expect(200);

      const session = bodyOf<
        Tokens & { user: { id: string; hasPassword: boolean } }
      >(res);
      expect(session.user).toMatchObject({ id: user.id, hasPassword: true });
      await request(ctx.http)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${session.access_token}`)
        .expect(200);
    });

    it('takes the code as a phone shows it', async () => {
      const { challenge } = await startLogin();
      const code = authenticator.next();

      await verify({
        challenge,
        code: `${code.slice(0, 3)} ${code.slice(3)}`,
      }).expect(200);
    });

    it('rejects a wrong code and lets the person try again', async () => {
      const { challenge } = await startLogin();

      const wrong = await verify({ challenge, code: '000000' }).expect(401);
      expect(bodyOf<{ message: string }>(wrong).message).toBe('Invalid code');

      await verify({ challenge, code: authenticator.next() }).expect(200);
    });

    it('never accepts the same code twice', async () => {
      const code = authenticator.next();
      const first = await startLogin();
      await verify({ challenge: first.challenge, code }).expect(200);

      const second = await startLogin();
      await verify({ challenge: second.challenge, code }).expect(401);
    });

    it('uses a challenge up on success', async () => {
      const { challenge } = await startLogin();
      await verify({ challenge, code: authenticator.next() }).expect(200);

      const res = await verify({
        challenge,
        code: authenticator.next(),
      }).expect(401);
      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Challenge expired',
      );
    });

    it('lets a challenge expire after five minutes', async () => {
      const { challenge } = await startLogin();
      const code = authenticator.next();
      vi.setSystemTime(Date.now() + 5 * 60_000 + 1000);

      const res = await verify({ challenge, code }).expect(401);
      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Challenge expired',
      );
    });

    it('does not take a made-up challenge, or one for something else', async () => {
      await verify({ challenge: 'x'.repeat(43), code: '123456' }).expect(401);
      const enroll = await ctx.prisma.loginChallenge.count();
      expect(enroll).toBe(0);
    });

    it('needs exactly one of code and recovery code', async () => {
      const { challenge } = await startLogin();
      await verify({ challenge }).expect(400);
      await verify({
        challenge,
        code: '123456',
        recoveryCode: recoveryCodes[0],
      }).expect(400);
    });

    it('accepts a recovery code once, in any spelling', async () => {
      const code = recoveryCodes[0];
      const first = await startLogin();
      await verify({
        challenge: first.challenge,
        recoveryCode: code.toUpperCase().replace('-', ' '),
      }).expect(200);

      const again = await startLogin();
      await verify({ challenge: again.challenge, recoveryCode: code }).expect(
        401,
      );

      const mine = await ctx.prisma.recoveryCode.count({
        where: { userId: user.id, usedAt: null },
      });
      expect(mine).toBe(9);
    });

    describe('locking out', () => {
      const failFive = async () => {
        const { challenge } = await startLogin();
        for (let i = 0; i < 5; i++) {
          await verify({ challenge, code: '000000' }).expect(401);
        }
      };

      it('kills the challenge after five wrong codes', async () => {
        const { challenge } = await startLogin();
        for (let i = 0; i < 5; i++) {
          await verify({ challenge, code: '000000' }).expect(401);
        }

        const res = await verify({
          challenge,
          code: authenticator.next(),
        }).expect(401);
        expect(bodyOf<{ message: string }>(res).message).toBe(
          'Challenge expired',
        );
      });

      it('then refuses even the right code, with the wait', async () => {
        await failFive();

        const fresh = await startLogin();
        const res = await verify({
          challenge: fresh.challenge,
          code: authenticator.next(),
        }).expect(429);

        const body = bodyOf<{ message: string; retryAfterSeconds: number }>(
          res,
        );
        expect(body.message).toBe('Too many attempts. Try again later.');
        expect(body.retryAfterSeconds).toBeGreaterThan(9 * 60);
        expect(body.retryAfterSeconds).toBeLessThanOrEqual(10 * 60);
      });

      it('locks recovery codes the same way', async () => {
        await failFive();

        const fresh = await startLogin();
        await verify({
          challenge: fresh.challenge,
          recoveryCode: recoveryCodes[0],
        }).expect(429);
      });

      it('opens again after ten minutes', async () => {
        await failFive();
        vi.setSystemTime(Date.now() + 10 * 60_000 + 1000);

        const fresh = await startLogin();
        await verify({
          challenge: fresh.challenge,
          code: authenticator.next(),
        }).expect(200);
      });

      it('starts counting from zero after a success', async () => {
        const first = await startLogin();
        for (let i = 0; i < 4; i++) {
          await verify({ challenge: first.challenge, code: '000000' }).expect(
            401,
          );
        }
        await verify({
          challenge: first.challenge,
          code: authenticator.next(),
        }).expect(200);

        const second = await startLogin();
        for (let i = 0; i < 4; i++) {
          await verify({ challenge: second.challenge, code: '000000' }).expect(
            401,
          );
        }
        await verify({
          challenge: second.challenge,
          code: authenticator.next(),
        }).expect(200);
      });

      it('shares one counter with every other place a code is checked', async () => {
        for (let i = 0; i < 5; i++) {
          await user.http
            .post('/api/auth/2fa/disable')
            .send({ password: 'password-123', code: '000000' })
            .expect(400);
        }

        const fresh = await startLogin();
        await verify({
          challenge: fresh.challenge,
          code: authenticator.next(),
        }).expect(429);
        await user.http
          .post('/api/auth/2fa/recovery-codes')
          .send({ password: 'password-123', code: authenticator.next() })
          .expect(429);
      });

      it('holds when guesses arrive in parallel', async () => {
        const { challenge } = await startLogin();
        const results = await Promise.all(
          Array.from({ length: 20 }, () =>
            verify({ challenge, code: '000000' }),
          ),
        );
        // Late arrivals may find the challenge already spent (401, "Challenge
        // expired") or the account locked (429); either way no more than five
        // guesses ever reach the code check.
        const wrongGuesses = results.filter(
          (res) =>
            res.status === 401 &&
            (res.body as { message?: string }).message === 'Invalid code',
        );
        expect(wrongGuesses.length).toBeLessThanOrEqual(5);
        for (const res of results) {
          expect([401, 429]).toContain(res.status);
        }
      });
    });

    describe('managing it', () => {
      it('turns off with the password and a code', async () => {
        await user.http
          .post('/api/auth/2fa/disable')
          .send({ password: 'wrong-password', code: authenticator.next() })
          .expect(403);

        await user.http
          .post('/api/auth/2fa/disable')
          .send({ password: 'password-123', code: authenticator.next() })
          .expect(200);

        await passwordLogin(ctx, user.email).expect(200);
        expect(
          await ctx.prisma.recoveryCode.count({ where: { userId: user.id } }),
        ).toBe(0);
      });

      it('turns off with a recovery code', async () => {
        await user.http
          .post('/api/auth/2fa/disable')
          .send({ password: 'password-123', recoveryCode: recoveryCodes[3] })
          .expect(200);
        await passwordLogin(ctx, user.email).expect(200);
      });

      it('replaces all recovery codes', async () => {
        const res = await user.http
          .post('/api/auth/2fa/recovery-codes')
          .send({ password: 'password-123', code: authenticator.next() })
          .expect(200);
        const fresh = bodyOf<{ recoveryCodes: string[] }>(res).recoveryCodes;

        expect(fresh).toHaveLength(10);
        expect(fresh.filter((c) => recoveryCodes.includes(c))).toEqual([]);

        const { challenge } = await startLogin();
        await verify({ challenge, recoveryCode: recoveryCodes[0] }).expect(401);
      });

      it('asks for the current code before swapping the authenticator', async () => {
        const noCode = await user.http
          .post('/api/auth/2fa/setup')
          .send({})
          .expect(403);
        expect(bodyOf<{ message: string }>(noCode).message).toBe(
          'Current code required',
        );

        const replaced = bodyOf<{ secret: string }>(
          await user.http
            .post('/api/auth/2fa/setup')
            .send({ code: authenticator.next() })
            .expect(200),
        );
        const next = new Authenticator(replaced.secret);

        // The old authenticator keeps working until the new one is confirmed.
        const stillOld = await startLogin();
        await verify({
          challenge: stillOld.challenge,
          code: authenticator.next(),
        }).expect(200);

        await user.http
          .post('/api/auth/2fa/enable')
          .send({ code: next.current() })
          .expect(200);

        const after = await startLogin();
        await verify({
          challenge: after.challenge,
          code: authenticator.next(),
        }).expect(401);
        await verify({
          challenge: after.challenge,
          code: next.next(),
        }).expect(200);
      });
    });

    describe('what it does not cover', () => {
      it('leaves API tokens alone', async () => {
        const session = bodyOf<Tokens>(
          await verify({
            challenge: (await startLogin()).challenge,
            code: authenticator.next(),
          }).expect(200),
        );
        const { apiToken } = bodyOf<{ apiToken: string }>(
          await request(ctx.http)
            .post('/api/auth/api-token/regenerate')
            .set('Authorization', `Bearer ${session.access_token}`)
            .expect(200),
        );

        // Tags accept API tokens, as do import and export.
        await request(ctx.http)
          .get('/api/tags')
          .set('Authorization', `Bearer ${apiToken}`)
          .expect(200);
      });

      it('leaves the person next to you alone', async () => {
        await passwordLogin(ctx, admin.email).expect(200);
      });
    });
  });

  describe('admin reset', () => {
    it('wipes the factors, the sessions and the lockout', async () => {
      const { access_token, refresh_token } = await enableTotp(ctx, user);
      await ctx.prisma.user.update({
        where: { id: user.id },
        data: { twoFactorFailedAttempts: 3 },
      });

      await admin.http
        .post(`/api/admin/users/${user.id}/reset-2fa`)
        .expect(200);

      await passwordLogin(ctx, user.email).expect(200);
      await request(ctx.http)
        .post('/api/auth/refresh')
        .send({ refresh_token })
        .expect(401);
      const status = bodyOf<{ totp: { enabled: boolean } }>(
        await request(ctx.http)
          .get('/api/auth/2fa')
          .set('Authorization', `Bearer ${access_token}`)
          .expect(200),
      );
      expect(status.totp.enabled).toBe(false);
      const row = await ctx.prisma.user.findUniqueOrThrow({
        where: { id: user.id },
      });
      expect(row).toMatchObject({
        totpSecretEnc: null,
        twoFactorFailedAttempts: 0,
      });
    });

    it('is for admins only', async () => {
      await user.http
        .post(`/api/admin/users/${admin.id}/reset-2fa`)
        .expect(403);
    });

    it('answers 404 for someone who is not there', async () => {
      await admin.http
        .post('/api/admin/users/00000000-0000-0000-0000-000000000000/reset-2fa')
        .expect(404);
    });

    it('shows who has what in the people list', async () => {
      await enableTotp(ctx, user);

      const res = await admin.http.get('/api/admin/users').expect(200);
      const users = bodyOf<{
        users: { id: string; twoFactor: string; hasPassword: boolean }[];
      }>(res).users;

      expect(users.find((u) => u.id === user.id)).toMatchObject({
        twoFactor: 'totp',
        hasPassword: true,
      });
      expect(users.find((u) => u.id === admin.id)).toMatchObject({
        twoFactor: 'none',
      });
    });
  });
});
