import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';

/**
 * AuthService against in-memory user/refresh-token stores with real bcrypt.
 * Covers registration modes, login failure modes, refresh-token rotation,
 * and password changes.
 */
describe('AuthService', () => {
  interface UserRecord {
    id: string;
    email: string;
    password: string | null;
    name: string;
    profileImage: string | null;
    isAdmin: boolean;
    status: 'active' | 'pending';
    apiToken: string | null;
    createdAt: Date;
    updatedAt: Date;
  }

  interface RefreshTokenRecord {
    id: string;
    token: string;
    userId: string;
    expiresAt: Date;
  }

  let users: Map<string, UserRecord>; // by id
  let refreshTokens: Map<string, RefreshTokenRecord>; // by token
  let registrationMode: 'open' | 'review' | 'disabled';
  let service: AuthService;

  // Cost 4 keeps the suite fast; production uses 10 via the service itself.
  const passwordHash = bcrypt.hashSync('correct horse', 4);

  const addUser = (overrides: Partial<UserRecord> & { id: string }) => {
    const user: UserRecord = {
      email: `${overrides.id}@example.com`,
      password: passwordHash,
      name: 'Test User',
      profileImage: null,
      isAdmin: false,
      status: 'active',
      apiToken: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      ...overrides,
    };
    users.set(user.id, user);
    return user;
  };

  interface UserWhere {
    id?: string;
    email?: string;
    apiToken?: string;
  }

  const findUser = (where: UserWhere) =>
    [...users.values()].find(
      (u) =>
        (where.id === undefined || u.id === where.id) &&
        (where.email === undefined || u.email === where.email) &&
        (where.apiToken === undefined || u.apiToken === where.apiToken),
    ) ?? null;

  const prisma = {
    user: {
      findUnique: jest.fn(({ where }: { where: UserWhere }) =>
        Promise.resolve(findUser(where)),
      ),
      count: jest.fn(({ where }: { where?: Partial<UserRecord> } = {}) =>
        Promise.resolve(
          [...users.values()].filter(
            (u) => where?.isAdmin === undefined || u.isAdmin === where.isAdmin,
          ).length,
        ),
      ),
      create: jest.fn(
        ({
          data,
          select,
        }: {
          data: Partial<UserRecord> & { email: string };
          select?: Record<string, boolean>;
        }) => {
          const user = addUser({
            id: `user-${users.size + 1}`,
            ...data,
          } as UserRecord);
          // Honor `select` like Prisma does — the caller must not see
          // unselected fields (e.g. the password hash).
          if (!select) return Promise.resolve(user);
          return Promise.resolve(
            Object.fromEntries(
              Object.keys(select)
                .filter((key) => select[key])
                .map((key) => [key, user[key as keyof UserRecord]]),
            ),
          );
        },
      ),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<UserRecord>;
        }) => {
          const user = users.get(where.id)!;
          Object.assign(user, data);
          return Promise.resolve(user);
        },
      ),
    },
    refreshToken: {
      findUnique: jest.fn(({ where }: { where: { token: string } }) => {
        const stored = refreshTokens.get(where.token);
        if (!stored) return Promise.resolve(null);
        return Promise.resolve({ ...stored, user: users.get(stored.userId) });
      }),
      create: jest.fn(({ data }: { data: Omit<RefreshTokenRecord, 'id'> }) => {
        const record = { id: `rt-${refreshTokens.size + 1}`, ...data };
        refreshTokens.set(record.token, record);
        return Promise.resolve(record);
      }),
      deleteMany: jest.fn(
        ({ where }: { where: { token?: string; id?: string } }) => {
          let count = 0;
          for (const [token, record] of refreshTokens) {
            if (record.token === where.token || record.id === where.id) {
              refreshTokens.delete(token);
              count++;
            }
          }
          return Promise.resolve({ count });
        },
      ),
    },
  } as unknown as PrismaService;

  const jwtService = {
    sign: jest.fn(() => 'signed-access-token'),
  } as unknown as JwtService;

  const settingsService = {
    getRegistrationMode: jest.fn(() => Promise.resolve(registrationMode)),
  } as unknown as SettingsService;

  beforeEach(() => {
    users = new Map();
    refreshTokens = new Map();
    registrationMode = 'open';
    service = new AuthService(prisma, jwtService, settingsService);
    jest.clearAllMocks();
  });

  describe('register', () => {
    const dto = {
      email: 'new@example.com',
      password: 'pw-123456',
      name: 'New',
    };

    it('is forbidden when registration is disabled', async () => {
      registrationMode = 'disabled';
      await expect(service.register(dto)).rejects.toThrow(ForbiddenException);
    });

    it('rejects an already-registered email', async () => {
      addUser({ id: 'u1', email: dto.email });
      await expect(service.register(dto)).rejects.toThrow(ConflictException);
    });

    it('makes the first user an admin and returns tokens', async () => {
      const result = await service.register(dto);
      expect(result.user.isAdmin).toBe(true);
      expect(result).toHaveProperty('access_token', 'signed-access-token');
      expect(result).toHaveProperty('refresh_token');
    });

    it('does not make later users admins', async () => {
      addUser({ id: 'admin', isAdmin: true });
      const result = await service.register(dto);
      expect(result.user.isAdmin).toBe(false);
    });

    it('still promotes the next registrant when users exist but no admin does', async () => {
      addUser({ id: 'u1', isAdmin: false });
      addUser({ id: 'u2', isAdmin: false });
      const result = await service.register(dto);
      expect(result.user.isAdmin).toBe(true);
    });

    it('does not leak the password hash in the register response', async () => {
      const result = await service.register(dto);
      expect(result.user).not.toHaveProperty('password');
    });

    it('creates pending users without tokens in review mode', async () => {
      addUser({ id: 'admin', isAdmin: true });
      registrationMode = 'review';
      const result = await service.register(dto);
      expect(result.user.status).toBe('pending');
      expect(result).not.toHaveProperty('access_token');
      expect(result).toHaveProperty('message');
    });

    it('never stores the plaintext password', async () => {
      await service.register(dto);
      const stored = findUser({ email: dto.email })!;
      expect(stored.password).not.toBe(dto.password);
      expect(await bcrypt.compare(dto.password, stored.password!)).toBe(true);
    });
  });

  describe('login', () => {
    it('rejects an unknown email', async () => {
      await expect(
        service.login({ email: 'nobody@example.com', password: 'x' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects password login for OIDC-only accounts', async () => {
      addUser({ id: 'u1', password: null });
      await expect(
        service.login({ email: 'u1@example.com', password: 'anything' }),
      ).rejects.toThrow(/OIDC/);
    });

    it('rejects a wrong password', async () => {
      addUser({ id: 'u1' });
      await expect(
        service.login({ email: 'u1@example.com', password: 'wrong' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects pending accounts even with valid credentials', async () => {
      addUser({ id: 'u1', status: 'pending' });
      await expect(
        service.login({ email: 'u1@example.com', password: 'correct horse' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('returns tokens and a user object without the password hash', async () => {
      addUser({ id: 'u1' });
      const result = await service.login({
        email: 'u1@example.com',
        password: 'correct horse',
      });
      expect(result.access_token).toBe('signed-access-token');
      expect(refreshTokens.has(result.refresh_token)).toBe(true);
      expect(result.user).not.toHaveProperty('password');
    });
  });

  describe('refreshTokens', () => {
    const loginAndGetRefreshToken = async () => {
      addUser({ id: 'u1' });
      const { refresh_token } = await service.login({
        email: 'u1@example.com',
        password: 'correct horse',
      });
      return refresh_token;
    };

    it('rejects an unknown refresh token', async () => {
      await expect(service.refreshTokens('nope')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('rejects and deletes an expired refresh token', async () => {
      const token = await loginAndGetRefreshToken();
      refreshTokens.get(token)!.expiresAt = new Date(Date.now() - 1000);
      await expect(service.refreshTokens(token)).rejects.toThrow(/expired/);
      expect(refreshTokens.has(token)).toBe(false);
    });

    it('rejects tokens of users that became pending', async () => {
      const token = await loginAndGetRefreshToken();
      users.get('u1')!.status = 'pending';
      await expect(service.refreshTokens(token)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('rotates the token: old one is revoked, new one works', async () => {
      const oldToken = await loginAndGetRefreshToken();
      const result = await service.refreshTokens(oldToken);

      expect(refreshTokens.has(oldToken)).toBe(false);
      expect(result.refresh_token).not.toBe(oldToken);
      expect(refreshTokens.has(result.refresh_token)).toBe(true);
      // The old token must not be reusable.
      await expect(service.refreshTokens(oldToken)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('changePassword', () => {
    it('rejects a wrong current password', async () => {
      addUser({ id: 'u1' });
      await expect(
        service.changePassword('u1', {
          currentPassword: 'wrong',
          newPassword: 'brand new pw',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('rejects reusing the current password', async () => {
      addUser({ id: 'u1' });
      await expect(
        service.changePassword('u1', {
          currentPassword: 'correct horse',
          newPassword: 'correct horse',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('is unavailable for OIDC accounts', async () => {
      addUser({ id: 'u1', password: null });
      await expect(
        service.changePassword('u1', {
          currentPassword: 'x',
          newPassword: 'y',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('stores the new password hashed', async () => {
      addUser({ id: 'u1' });
      await service.changePassword('u1', {
        currentPassword: 'correct horse',
        newPassword: 'brand new pw',
      });
      const stored = users.get('u1')!;
      expect(stored.password).not.toBe('brand new pw');
      expect(await bcrypt.compare('brand new pw', stored.password!)).toBe(true);
    });
  });
});
