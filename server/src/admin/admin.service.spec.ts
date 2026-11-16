import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AdminService } from './admin.service';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { TwoFactorService } from '../auth/two-factor/two-factor.service';
import { OidcConfigService } from '../auth/oidc/oidc-config.service';

describe('AdminService.findUsers', () => {
  let findMany: ReturnType<typeof vi.fn>;
  let count: ReturnType<typeof vi.fn>;
  let service: AdminService;

  beforeEach(() => {
    findMany = vi.fn().mockResolvedValue([
      {
        id: 'u1',
        email: 'sam@example.com',
        name: 'Sam',
        oidcSubject: 'sub-1',
        password: null,
        totpEnabledAt: null,
        _count: { passkeys: 0, notes: 3, tags: 1 },
      },
    ]);
    count = vi.fn().mockResolvedValue(7);
    service = new AdminService(
      { user: { findMany, count } } as unknown as PrismaService,
      {} as SettingsService,
      {} as OidcConfigService,
      {} as TwoFactorService,
    );
  });

  it('lists everyone when nothing is asked for', async () => {
    const page = await service.findUsers(0, 50);

    expect(findMany.mock.calls[0][0]).toMatchObject({
      where: {},
      skip: 0,
      take: 50,
    });
    expect(count).toHaveBeenCalledWith({ where: {} });
    expect(page).toMatchObject({ total: 7, skip: 0, take: 50 });
    expect(page.users[0]).toMatchObject({ id: 'u1', authMethod: 'oidc' });
  });

  it('matches the name or email in any case, and counts only matches', async () => {
    await service.findUsers(0, 50, { q: 'SAM', status: 'active' });

    const where = {
      status: 'active',
      OR: [
        { name: { contains: 'SAM', mode: 'insensitive' } },
        { email: { contains: 'SAM', mode: 'insensitive' } },
      ],
    };
    expect(findMany.mock.calls[0][0]).toMatchObject({ where });
    expect(count).toHaveBeenCalledWith({ where });
  });

  it("sends each person's profile picture", async () => {
    findMany.mockResolvedValue([
      {
        id: 'u1',
        email: 'sam@example.com',
        name: 'Sam',
        profileImage: '/uploads/profiles/u1.jpg',
        oidcSubject: null,
        password: 'hash',
        totpEnabledAt: null,
        _count: { passkeys: 0 },
      },
    ]);

    const page = await service.findUsers(0, 50);

    expect(findMany.mock.calls[0][0]).toMatchObject({
      select: { profileImage: true },
    });
    expect(page.users[0]).toMatchObject({
      profileImage: '/uploads/profiles/u1.jpg',
      authMethod: 'local',
    });
  });

  it.each([
    [{ totp: false, passkeys: 0 }, 'none'],
    [{ totp: true, passkeys: 0 }, 'totp'],
    [{ totp: false, passkeys: 2 }, 'passkey'],
    [{ totp: true, passkeys: 1 }, 'both'],
  ])('reports the second factors of %j as %s', async (factors, expected) => {
    findMany.mockResolvedValue([
      {
        id: 'u1',
        email: 'sam@example.com',
        name: 'Sam',
        oidcSubject: null,
        password: 'hash',
        totpEnabledAt: factors.totp ? new Date() : null,
        _count: { passkeys: factors.passkeys, notes: 0, tags: 0 },
      },
    ]);

    const { users } = await service.findUsers(0, 50);

    expect(users[0]).toMatchObject({ twoFactor: expected, hasPassword: true });
    expect(users[0]).not.toHaveProperty('password');
    expect(users[0]._count).toEqual({ notes: 0, tags: 0 });
  });

  it('tells provider-only accounts apart by hasPassword', async () => {
    const { users } = await service.findUsers(0, 50);

    expect(users[0]).toMatchObject({ hasPassword: false, twoFactor: 'none' });
  });

  it('counts the notes and tags people still have, like the totals do', async () => {
    await service.findUsers(0, 50);

    expect(findMany.mock.calls[0][0]).toMatchObject({
      select: {
        _count: {
          select: {
            notes: { where: { state: { not: 'deleted' } } },
            tags: { where: { isDeleted: false } },
          },
        },
      },
    });
  });
});

describe('AdminService.getPendingUsers', () => {
  it('lists the people waiting, with their profile pictures', async () => {
    const findMany = vi.fn().mockResolvedValue([
      {
        id: 'u2',
        email: 'ana@example.com',
        name: 'Ana',
        profileImage: '/uploads/profiles/u2.png',
        oidcSubject: 'sub-2',
      },
    ]);
    const service = new AdminService(
      { user: { findMany } } as unknown as PrismaService,
      {} as SettingsService,
      {} as OidcConfigService,
      {} as TwoFactorService,
    );

    const waiting = await service.getPendingUsers();

    expect(findMany.mock.calls[0][0]).toMatchObject({
      where: { status: 'pending' },
      select: { profileImage: true },
    });
    expect(waiting).toEqual([
      {
        id: 'u2',
        email: 'ana@example.com',
        name: 'Ana',
        profileImage: '/uploads/profiles/u2.png',
        authMethod: 'oidc',
      },
    ]);
  });
});
