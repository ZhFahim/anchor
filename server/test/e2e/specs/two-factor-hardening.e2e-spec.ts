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
import request from 'supertest';
import {
  Actor,
  addPasskey,
  Authenticator,
  bodyOf,
  createE2EApp,
  E2EApp,
  enableTotp,
  passwordLogin,
  VirtualPasskey,
} from '../support';

interface Gate {
  challenge: string;
}

describe('two-factor edge cases', () => {
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

  const me = (token: string) =>
    request(ctx.http)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);
  const tags = (token: string) =>
    request(ctx.http).get('/api/tags').set('Authorization', `Bearer ${token}`);

  const requireEveryone = async () => {
    await enableTotp(ctx, admin);
    await admin.http
      .patch('/api/admin/settings/two-factor')
      .send({ policy: 'everyone' })
      .expect(200);
  };

  describe('signing out everywhere', () => {
    it('ends open access tokens when an authenticator is turned on', async () => {
      await me(user.token).expect(200);
      vi.setSystemTime(Date.now() + 5000);

      const { access_token } = await enableTotp(ctx, user);

      await me(user.token).expect(401);
      await tags(user.token).expect(401);
      await me(access_token).expect(200);
      await tags(access_token).expect(200);
    });

    it('ends open access tokens when an admin resets two-factor', async () => {
      const { access_token } = await enableTotp(ctx, user);
      await me(access_token).expect(200);
      vi.setSystemTime(Date.now() + 5000);

      await admin.http
        .post(`/api/admin/users/${user.id}/reset-2fa`)
        .expect(200);

      await me(access_token).expect(401);
      await tags(access_token).expect(401);
    });
  });

  describe('replacing the authenticator', () => {
    it('accepts a recovery code instead of a code', async () => {
      const { recoveryCodes } = await enableTotp(ctx, user);

      const res = await user.http
        .post('/api/auth/2fa/setup')
        .send({ recoveryCode: recoveryCodes[0] })
        .expect(200);

      expect(bodyOf<{ secret: string }>(res).secret).toBeTruthy();
    });
  });

  describe('the enrollment gate', () => {
    it('does not let a second challenge get around a factor added since', async () => {
      await requireEveryone();
      const first = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );
      const second = bodyOf<Gate>(
        await passwordLogin(ctx, user.email).expect(403),
      );

      const { secret } = bodyOf<{ secret: string }>(
        await request(ctx.http)
          .post('/api/auth/enroll/totp/setup')
          .send({ challenge: first.challenge })
          .expect(200),
      );
      await request(ctx.http)
        .post('/api/auth/enroll/totp/enable')
        .send({
          challenge: first.challenge,
          code: new Authenticator(secret).current(),
        })
        .expect(200);

      // Neither route works with the other challenge any more.
      await request(ctx.http)
        .post('/api/auth/enroll/passkey/options')
        .send({ challenge: second.challenge })
        .expect(401);
      await request(ctx.http)
        .post('/api/auth/enroll/totp/setup')
        .send({ challenge: second.challenge })
        .expect(401);
      await passwordLogin(ctx, user.email).expect(401);
    });
  });

  describe('simultaneous requests', () => {
    it('lets only one of two enable calls win', async () => {
      const setup = bodyOf<{ secret: string }>(
        await user.http.post('/api/auth/2fa/setup').send({}).expect(200),
      );
      const code = new Authenticator(setup.secret).current();

      const results = await Promise.all([
        user.http.post('/api/auth/2fa/enable').send({ code }),
        user.http.post('/api/auth/2fa/enable').send({ code }),
      ]);

      expect(results.map((res) => res.status).sort()).toEqual([200, 400]);
      const winner = results.find((res) => res.status === 200)!;
      const { recoveryCodes } = bodyOf<{ recoveryCodes: string[] }>(winner);
      expect(recoveryCodes).toHaveLength(10);
      const status = bodyOf<{ totp: { recoveryCodesRemaining: number } }>(
        await request(ctx.http)
          .get('/api/auth/2fa')
          .set(
            'Authorization',
            `Bearer ${bodyOf<{ access_token: string }>(winner).access_token}`,
          )
          .expect(200),
      );
      expect(status.totp.recoveryCodesRemaining).toBe(10);
    });

    it('never removes the last required factor twice over', async () => {
      await requireEveryone();
      const a = await addPasskey(user, new VirtualPasskey(), 'A');
      const b = await addPasskey(user, new VirtualPasskey(), 'B');

      const results = await Promise.all([
        user.http.delete(`/api/auth/passkeys/${a.id}`),
        user.http.delete(`/api/auth/passkeys/${b.id}`),
      ]);

      expect(results.map((res) => res.status).sort()).toEqual([200, 403]);
      const status = bodyOf<{ passkeys: unknown[] }>(
        await user.http.get('/api/auth/2fa').expect(200),
      );
      expect(status.passkeys).toHaveLength(1);
    });
  });
});
