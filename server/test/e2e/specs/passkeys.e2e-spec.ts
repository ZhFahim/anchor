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
  addPasskey,
  bodyOf,
  createE2EApp,
  E2EApp,
  enableTotp,
  passkeyLogin,
  passwordLogin,
  VirtualPasskey,
  type Tokens,
} from '../support';

interface Options {
  challenge: string;
  rp: { id: string };
  authenticatorSelection: { residentKey: string; userVerification: string };
}

describe('passkeys', () => {
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
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(Date.now());
    await ctx.resetDb();
    admin = await ctx.registerUser('Admin');
    user = await ctx.registerUser('Person');
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const registrationOptions = async (actor: Actor) =>
    bodyOf<{ options: Options; challenge: string }>(
      await actor.http.post('/api/auth/passkeys/register/options').expect(200),
    );

  describe('adding one', () => {
    it('asks for a discoverable, user-verified credential bound to this site', async () => {
      const { options, challenge } = await registrationOptions(user);

      expect(options.rp.id).toBe('localhost');
      expect(options.authenticatorSelection).toMatchObject({
        residentKey: 'required',
        userVerification: 'required',
      });
      expect(challenge).toMatch(/^[A-Za-z0-9_-]{43}$/);
      // The WebAuthn challenge is not the token handed to the client.
      expect(options.challenge).not.toBe(challenge);
    });

    it('stores a verified passkey and lists it', async () => {
      const passkey = await addPasskey(
        user,
        new VirtualPasskey(),
        '  MacBook  ',
      );

      expect(passkey.name).toBe('MacBook');
      const status = bodyOf<{
        passkeys: { id: string; name: string; lastUsedAt: string | null }[];
      }>(await user.http.get('/api/auth/2fa').expect(200));
      expect(status.passkeys).toEqual([
        expect.objectContaining({
          id: passkey.id,
          name: 'MacBook',
          lastUsedAt: null,
          deviceType: 'singleDevice',
        }),
      ]);
    });

    it('does not keep the private parts anywhere it could leak', async () => {
      await addPasskey(user, new VirtualPasskey());
      const status = await user.http.get('/api/auth/2fa').expect(200);

      expect(JSON.stringify(status.body)).not.toMatch(/publicKey|credentialId/);
    });

    it('refuses a credential made for another site, and burns the challenge', async () => {
      const authenticator = new VirtualPasskey();
      const { options, challenge } = await registrationOptions(user);

      await user.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options, {
            origin: 'https://evil.example',
          }),
          name: 'Phish',
        })
        .expect(400);

      await user.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options),
          name: 'Retry',
        })
        .expect(401);
      expect(await ctx.prisma.passkey.count()).toBe(0);
    });

    it('refuses a key that did not verify the person', async () => {
      const authenticator = new VirtualPasskey();
      const { options, challenge } = await registrationOptions(user);

      await user.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options, { userVerified: false }),
          name: 'No PIN',
        })
        .expect(400);
    });

    it('refuses a challenge someone else was given', async () => {
      const authenticator = new VirtualPasskey();
      const { options, challenge } = await registrationOptions(user);

      await admin.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options),
          name: 'Stolen',
        })
        .expect(401);
    });

    it('lets a challenge go stale', async () => {
      const authenticator = new VirtualPasskey();
      const { options, challenge } = await registrationOptions(user);
      vi.setSystemTime(Date.now() + 5 * 60_000 + 1000);

      await user.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options),
          name: 'Late',
        })
        .expect(401);
    });

    it('does not add the same key twice', async () => {
      const authenticator = new VirtualPasskey();
      await addPasskey(user, authenticator);

      const { options, challenge } = await registrationOptions(user);
      await user.http
        .post('/api/auth/passkeys/register/verify')
        .send({
          challenge,
          response: authenticator.create(options),
          name: 'Again',
        })
        .expect(409);
    });

    it('stops at ten', async () => {
      for (let i = 0; i < 10; i++) {
        await addPasskey(user, new VirtualPasskey(), `Key ${i}`);
      }

      await user.http.post('/api/auth/passkeys/register/options').expect(409);
    });

    it('is for accounts with a password', async () => {
      const sso = await ctx.prisma.user.create({
        data: { email: 'sso@e2e.test', name: 'SSO', oidcSubject: 'sub-1' },
      });
      const token = ctx.get(JwtService).sign({ email: sso.email, sub: sso.id });

      await request(ctx.http)
        .post('/api/auth/passkeys/register/options')
        .set('Authorization', `Bearer ${token}`)
        .expect(400);
    });
  });

  describe('signing in', () => {
    let authenticator: VirtualPasskey;

    beforeEach(async () => {
      authenticator = new VirtualPasskey();
      await addPasskey(user, authenticator);
    });

    it('signs in with nothing but the passkey', async () => {
      const res = await passkeyLogin(ctx, authenticator, 200);

      const session = bodyOf<
        Tokens & { user: { id: string; email: string; hasPassword: boolean } }
      >(res);
      expect(session.user).toMatchObject({
        id: user.id,
        email: user.email,
        hasPassword: true,
      });
      await request(ctx.http)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${session.access_token}`)
        .expect(200);
    });

    it('skips the code even when an authenticator app is on', async () => {
      await enableTotp(ctx, user);

      await passkeyLogin(ctx, authenticator, 200);
    });

    it('records the use', async () => {
      await passkeyLogin(ctx, authenticator, 200);
      await passkeyLogin(ctx, authenticator, 200);

      const row = await ctx.prisma.passkey.findFirstOrThrow({
        where: { userId: user.id },
      });
      expect(Number(row.counter)).toBe(2);
      expect(row.lastUsedAt).not.toBeNull();
    });

    it('works once per challenge', async () => {
      const { options, challenge } = bodyOf<{
        options: { challenge: string };
        challenge: string;
      }>(await request(ctx.http).post('/api/auth/passkeys/login/options'));
      const response = authenticator.get(options);

      await request(ctx.http)
        .post('/api/auth/passkeys/login/verify')
        .send({ challenge, response })
        .expect(200);
      await request(ctx.http)
        .post('/api/auth/passkeys/login/verify')
        .send({ challenge, response })
        .expect(401);
    });

    it('turns down a key the server has never seen', async () => {
      await passkeyLogin(ctx, new VirtualPasskey(), 401);
    });

    it('turns down a response for another site', async () => {
      const { options, challenge } = bodyOf<{
        options: { challenge: string };
        challenge: string;
      }>(await request(ctx.http).post('/api/auth/passkeys/login/options'));

      const res = await request(ctx.http)
        .post('/api/auth/passkeys/login/verify')
        .send({
          challenge,
          response: authenticator.get(options, {
            origin: 'https://evil.example',
          }),
        })
        .expect(401);
      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Passkey sign-in failed',
      );
    });

    it('turns down a signature over a different challenge', async () => {
      const first = bodyOf<{
        options: { challenge: string };
        challenge: string;
      }>(await request(ctx.http).post('/api/auth/passkeys/login/options'));
      const second = bodyOf<{
        options: { challenge: string };
        challenge: string;
      }>(await request(ctx.http).post('/api/auth/passkeys/login/options'));

      await request(ctx.http)
        .post('/api/auth/passkeys/login/verify')
        .send({
          challenge: second.challenge,
          response: authenticator.get(first.options),
        })
        .expect(401);
    });

    it('turns down a clone whose counter went backwards', async () => {
      await passkeyLogin(ctx, authenticator, 200);
      await passkeyLogin(ctx, authenticator, 200);
      authenticator.counter = 0;

      await passkeyLogin(ctx, authenticator, 401);
    });

    it('turns down a key that did not verify the person', async () => {
      const { options, challenge } = bodyOf<{
        options: { challenge: string };
        challenge: string;
      }>(await request(ctx.http).post('/api/auth/passkeys/login/options'));

      await request(ctx.http)
        .post('/api/auth/passkeys/login/verify')
        .send({
          challenge,
          response: authenticator.get(options, { userVerified: false }),
        })
        .expect(401);
    });

    it('does not sign in someone waiting for approval', async () => {
      await ctx.prisma.user.update({
        where: { id: user.id },
        data: { status: 'pending' },
      });

      await passkeyLogin(ctx, authenticator, 401);
    });

    it('is off when passwords are switched off', async () => {
      await ctx.prisma.settings.createMany({
        data: Object.entries({
          oidc_enabled: 'true',
          oidc_provider_name: 'Pocket ID',
          oidc_issuer_url: 'https://auth.e2e.test',
          oidc_client_id: 'anchor',
          oidc_disable_internal_auth: 'true',
        }).map(([key, value]) => ({ key, value })),
      });

      await request(ctx.http)
        .post('/api/auth/passkeys/login/options')
        .expect(403);
    });
  });

  describe('managing them', () => {
    it('renames only your own', async () => {
      const mine = await addPasskey(user, new VirtualPasskey(), 'Old');
      const theirs = await addPasskey(admin, new VirtualPasskey(), 'Theirs');

      const renamed = await user.http
        .patch(`/api/auth/passkeys/${mine.id}`)
        .send({ name: 'New' })
        .expect(200);
      expect(bodyOf<{ passkey: { name: string } }>(renamed).passkey.name).toBe(
        'New',
      );
      await user.http
        .patch(`/api/auth/passkeys/${theirs.id}`)
        .send({ name: 'Hijacked' })
        .expect(404);
      await user.http
        .patch(`/api/auth/passkeys/${mine.id}`)
        .send({ name: '' })
        .expect(400);
    });

    it('removes only your own', async () => {
      const mine = await addPasskey(user, new VirtualPasskey());
      const theirs = await addPasskey(admin, new VirtualPasskey());

      await user.http.delete(`/api/auth/passkeys/${theirs.id}`).expect(404);
      await user.http.delete(`/api/auth/passkeys/${mine.id}`).expect(200);

      expect(await ctx.prisma.passkey.count()).toBe(1);
    });

    it('is cleared with the rest by an admin reset', async () => {
      await addPasskey(user, new VirtualPasskey());
      await enableTotp(ctx, user);

      await admin.http
        .post(`/api/admin/users/${user.id}/reset-2fa`)
        .expect(200);

      expect(
        await ctx.prisma.passkey.count({ where: { userId: user.id } }),
      ).toBe(0);
      await passwordLogin(ctx, user.email).expect(200);
    });

    it('shows up in the people list', async () => {
      await addPasskey(user, new VirtualPasskey());

      const res = await admin.http.get('/api/admin/users').expect(200);
      const row = bodyOf<{ users: { id: string; twoFactor: string }[] }>(
        res,
      ).users.find((u) => u.id === user.id);
      expect(row?.twoFactor).toBe('passkey');
    });
  });

  describe('when two-factor is required', () => {
    beforeEach(async () => {
      await enableTotp(ctx, admin);
      await admin.http
        .patch('/api/admin/settings/two-factor')
        .send({ policy: 'everyone' })
        .expect(200);
    });

    it('lets someone enroll a passkey at the gate', async () => {
      const gate = bodyOf<{ challenge: string; methods: { passkey: boolean } }>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      expect(gate.methods.passkey).toBe(true);
      const authenticator = new VirtualPasskey();

      const { options } = bodyOf<{ options: { challenge: string } }>(
        await request(ctx.http)
          .post('/api/auth/enroll/passkey/options')
          .send({ challenge: gate.challenge })
          .expect(200),
      );
      const res = await request(ctx.http)
        .post('/api/auth/enroll/passkey/verify')
        .send({
          challenge: gate.challenge,
          response: authenticator.create(options),
          name: 'First key',
        })
        .expect(200);

      const session = bodyOf<Tokens & { user: { id: string } }>(res);
      expect(session.user.id).toBe(user.id);
      expect(
        await ctx.prisma.passkey.count({ where: { userId: user.id } }),
      ).toBe(1);
      // The gate challenge is spent.
      await request(ctx.http)
        .post('/api/auth/enroll/passkey/options')
        .send({ challenge: gate.challenge })
        .expect(401);
    });

    it('needs the options step first, and gives each ceremony one try', async () => {
      const gate = bodyOf<{ challenge: string }>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      const authenticator = new VirtualPasskey();

      await request(ctx.http)
        .post('/api/auth/enroll/passkey/verify')
        .send({
          challenge: gate.challenge,
          response: authenticator.create({ challenge: 'AAAA' }),
        })
        .expect(400);

      const { options } = bodyOf<{ options: { challenge: string } }>(
        await request(ctx.http)
          .post('/api/auth/enroll/passkey/options')
          .send({ challenge: gate.challenge }),
      );
      await request(ctx.http)
        .post('/api/auth/enroll/passkey/verify')
        .send({
          challenge: gate.challenge,
          response: authenticator.create(options, {
            origin: 'https://evil.example',
          }),
        })
        .expect(400);
      await request(ctx.http)
        .post('/api/auth/enroll/passkey/verify')
        .send({
          challenge: gate.challenge,
          response: authenticator.create(options),
        })
        .expect(400);
    });

    it('sends someone whose only factor is a passkey to the passkey', async () => {
      await addPasskey(user, new VirtualPasskey());

      const res = await passwordLogin(ctx, user.email).expect(403);

      expect(bodyOf(res)).toMatchObject({
        passkeyRequired: true,
        message: 'Sign in with your passkey',
      });
      expect(JSON.stringify(res.body)).not.toContain('access_token');
    });

    it('lets that passkey sign in', async () => {
      const authenticator = new VirtualPasskey();
      await addPasskey(user, authenticator);

      await passkeyLogin(ctx, authenticator, 200);
    });

    it('keeps the last factor, but not when another one remains', async () => {
      const first = new VirtualPasskey();
      const a = await addPasskey(user, first, 'A');
      const b = await addPasskey(user, new VirtualPasskey(), 'B');

      await user.http.delete(`/api/auth/passkeys/${a.id}`).expect(200);
      const res = await user.http
        .delete(`/api/auth/passkeys/${b.id}`)
        .expect(403);

      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Two-factor is required by your admin',
      );
    });

    it('lets the last passkey go once an authenticator app covers it', async () => {
      const only = await addPasskey(user, new VirtualPasskey());
      await enableTotp(ctx, user);

      await user.http.delete(`/api/auth/passkeys/${only.id}`).expect(200);
    });

    it('lets the last passkey go when nothing is required', async () => {
      await admin.http
        .patch('/api/admin/settings/two-factor')
        .send({ policy: 'optional' })
        .expect(200);
      const only = await addPasskey(user, new VirtualPasskey());

      await user.http.delete(`/api/auth/passkeys/${only.id}`).expect(200);
    });
  });
});
