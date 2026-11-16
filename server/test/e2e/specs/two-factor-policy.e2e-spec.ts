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
  Authenticator,
  bodyOf,
  createE2EApp,
  E2EApp,
  enableTotp,
  passwordLogin,
  type Tokens,
} from '../support';

interface Gate {
  twoFactorSetupRequired: true;
  challenge: string;
  methods: { totp: boolean; passkey: boolean };
  message: string;
}

describe('requiring two-factor', () => {
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

  const setPolicy = (actor: Actor, policy: string) =>
    actor.http.patch('/api/admin/settings/two-factor').send({ policy });

  /** The admin turns their own on first, as the server insists. */
  const requireFor = async (policy: 'admins' | 'everyone') => {
    const { authenticator } = await enableTotp(ctx, admin);
    await setPolicy(admin, policy).expect(200);
    return authenticator;
  };

  describe('the admin setting', () => {
    it('starts optional and reports who is covered', async () => {
      const res = await admin.http
        .get('/api/admin/settings/two-factor')
        .expect(200);

      expect(bodyOf(res)).toEqual({
        policy: 'optional',
        isLocked: false,
        available: { totp: true, passkeys: true },
        coverage: { covered: 0, total: 2 },
      });
    });

    it('is for admins only', async () => {
      await user.http.get('/api/admin/settings/two-factor').expect(403);
      await setPolicy(user, 'everyone').expect(403);
    });

    it('takes only the three known values', async () => {
      await setPolicy(admin, 'nobody').expect(400);
      await setPolicy(admin, 'optional').expect(200);
    });

    it("won't lock out the admin who sets it", async () => {
      const res = await setPolicy(admin, 'everyone').expect(409);

      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Set up two-factor for your own account first',
      );
      expect(
        bodyOf<{ policy: string }>(
          await admin.http.get('/api/admin/settings/two-factor'),
        ).policy,
      ).toBe('optional');
    });

    it('counts people as they set it up', async () => {
      await requireFor('everyone');
      await enableTotp(ctx, user);

      const settings = bodyOf<{
        policy: string;
        coverage: { covered: number; total: number };
      }>(await admin.http.get('/api/admin/settings/two-factor').expect(200));
      expect(settings).toMatchObject({
        policy: 'everyone',
        coverage: { covered: 2, total: 2 },
      });
    });

    it('can be lifted again', async () => {
      await requireFor('everyone');
      await setPolicy(admin, 'optional').expect(200);

      await passwordLogin(ctx, user.email).expect(200);
    });
  });

  describe('for everyone', () => {
    beforeEach(async () => {
      await requireFor('everyone');
    });

    it('stops a sign-in that has no second step yet, and says what to do', async () => {
      const res = await passwordLogin(ctx, user.email).expect(403);

      const gate = bodyOf<Gate>(res);
      expect(gate).toMatchObject({
        twoFactorSetupRequired: true,
        message: 'Two-factor setup required',
        methods: { totp: true, passkey: true },
      });
      expect(gate.challenge).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(JSON.stringify(gate)).not.toContain('access_token');
    });

    it('still asks the enrolled admin for a code, not for setup', async () => {
      const res = await passwordLogin(ctx, admin.email).expect(401);
      expect(bodyOf(res)).toMatchObject({ twoFactorRequired: true });
    });

    it('lets the person set up an authenticator from the gate and signs them in', async () => {
      const { challenge } = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );

      const setup = bodyOf<{ secret: string }>(
        await request(ctx.http)
          .post('/api/auth/enroll/totp/setup')
          .send({ challenge })
          .expect(200),
      );
      const authenticator = new Authenticator(setup.secret);
      const done = bodyOf<
        { recoveryCodes: string[]; user: { id: string } } & Tokens
      >(
        await request(ctx.http)
          .post('/api/auth/enroll/totp/enable')
          .send({ challenge, code: authenticator.current() })
          .expect(200),
      );

      expect(done.recoveryCodes).toHaveLength(10);
      expect(done.user.id).toBe(user.id);
      await request(ctx.http)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${done.access_token}`)
        .expect(200);
      // Next time it is a normal two-factor sign-in.
      await passwordLogin(ctx, user.email).expect(401);
    });

    it('turns down a wrong code and keeps the gate open', async () => {
      const { challenge } = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      const { secret } = bodyOf<{ secret: string }>(
        await request(ctx.http)
          .post('/api/auth/enroll/totp/setup')
          .send({ challenge })
          .expect(200),
      );

      const res = await request(ctx.http)
        .post('/api/auth/enroll/totp/enable')
        .send({ challenge, code: '000000' })
        .expect(400);
      expect(bodyOf<{ message: string }>(res).message).toBe('Invalid code');

      await request(ctx.http)
        .post('/api/auth/enroll/totp/enable')
        .send({ challenge, code: new Authenticator(secret).current() })
        .expect(200);
    });

    it('uses the gate challenge up, and only for the gate', async () => {
      const { challenge } = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      // It is not a sign-in challenge.
      await request(ctx.http)
        .post('/api/auth/login/2fa')
        .send({ challenge, code: '123456' })
        .expect(401);

      const { secret } = bodyOf<{ secret: string }>(
        await request(ctx.http)
          .post('/api/auth/enroll/totp/setup')
          .send({ challenge })
          .expect(200),
      );
      await request(ctx.http)
        .post('/api/auth/enroll/totp/enable')
        .send({ challenge, code: new Authenticator(secret).current() })
        .expect(200);

      await request(ctx.http)
        .post('/api/auth/enroll/totp/setup')
        .send({ challenge })
        .expect(401);
    });

    it('lets a gate challenge go stale after fifteen minutes', async () => {
      const { challenge } = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      vi.setSystemTime(Date.now() + 15 * 60_000 + 1000);

      await request(ctx.http)
        .post('/api/auth/enroll/totp/setup')
        .send({ challenge })
        .expect(401);
    });

    it('holds a new account at the gate instead of handing it tokens', async () => {
      const res = await request(ctx.http)
        .post('/api/auth/register')
        .send({
          email: 'fresh@e2e.test',
          password: 'password-123',
          name: 'Fresh',
        })
        .expect(201);

      const body = bodyOf<Gate & { user: { email: string } }>(res);
      expect(body).toMatchObject({
        twoFactorSetupRequired: true,
        user: { email: 'fresh@e2e.test' },
      });
      expect(JSON.stringify(body)).not.toContain('access_token');
      expect(body.challenge).toBeTruthy();
    });

    it('leaves a session that is already open alone, but marks it as required', async () => {
      // `user` signed in before the policy existed.
      await user.http.get('/api/auth/me').expect(200);
      const status = bodyOf<{ required: boolean; policy: string }>(
        await user.http.get('/api/auth/2fa').expect(200),
      );
      expect(status).toMatchObject({ required: true, policy: 'everyone' });
    });

    it('keeps people from switching their last factor off', async () => {
      const { authenticator } = await enableTotp(ctx, user);

      const res = await user.http
        .post('/api/auth/2fa/disable')
        .send({ password: 'password-123', code: authenticator.next() })
        .expect(403);

      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Two-factor is required by your admin',
      );
      const status = bodyOf<{ totp: { enabled: boolean } }>(
        await user.http.get('/api/auth/2fa'),
      );
      expect(status.totp.enabled).toBe(true);
    });

    it('lets an admin reset someone back to the gate', async () => {
      await enableTotp(ctx, user);
      await passwordLogin(ctx, user.email).expect(401);

      await admin.http
        .post(`/api/admin/users/${user.id}/reset-2fa`)
        .expect(200);

      const res = await passwordLogin(ctx, user.email).expect(403);
      expect(bodyOf(res)).toMatchObject({ twoFactorSetupRequired: true });
    });
  });

  describe('for admins only', () => {
    beforeEach(async () => {
      await requireFor('admins');
    });

    it('leaves everybody else alone', async () => {
      await passwordLogin(ctx, user.email).expect(200);
      const status = bodyOf<{ required: boolean }>(
        await user.http.get('/api/auth/2fa'),
      );
      expect(status.required).toBe(false);
    });

    it('holds a second admin at the gate', async () => {
      await ctx.prisma.user.update({
        where: { id: user.id },
        data: { isAdmin: true },
      });

      const res = await passwordLogin(ctx, user.email).expect(403);
      expect(bodyOf(res)).toMatchObject({ twoFactorSetupRequired: true });
    });
  });

  describe('accounts that sign in through a provider', () => {
    it('are outside the policy', async () => {
      await requireFor('everyone');
      const sso = await ctx.prisma.user.create({
        data: { email: 'sso@e2e.test', name: 'SSO', oidcSubject: 'sub-1' },
      });
      const token = ctx.get(JwtService).sign({ email: sso.email, sub: sso.id });

      const status = bodyOf<{ required: boolean; policy: string }>(
        await request(ctx.http)
          .get('/api/auth/2fa')
          .set('Authorization', `Bearer ${token}`)
          .expect(200),
      );
      expect(status).toEqual(
        expect.objectContaining({ policy: 'everyone', required: false }),
      );
      const settings = bodyOf<{ coverage: { total: number } }>(
        await admin.http.get('/api/admin/settings/two-factor'),
      );
      // Only the two people with a password count.
      expect(settings.coverage.total).toBe(2);
    });
  });

  describe('when the server can not offer it', () => {
    const providerOnly = {
      oidc_enabled: 'true',
      oidc_provider_name: 'Pocket ID',
      oidc_issuer_url: 'https://auth.e2e.test',
      oidc_client_id: 'anchor',
      oidc_disable_internal_auth: 'true',
    };

    it('reports nothing available when passwords are switched off', async () => {
      await ctx.prisma.settings.createMany({
        data: Object.entries(providerOnly).map(([key, value]) => ({
          key,
          value,
        })),
      });

      const caps = await request(ctx.http).get('/api/auth/capabilities');
      expect(bodyOf(caps)).toEqual({ totp: false, passkeys: false });
      const res = await setPolicy(admin, 'everyone').expect(409);
      expect(bodyOf<{ message: string }>(res).message).toBe(
        'Two-factor is not available on this server',
      );
    });
  });
});
