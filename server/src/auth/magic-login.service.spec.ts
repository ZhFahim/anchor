import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { UnauthorizedException } from '@nestjs/common';
import { MagicLoginService } from './magic-login.service';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { MAGIC_LOGIN_VALIDITY_MS } from './constants/auth.constants';

describe('MagicLoginService', () => {
  let status: 'active' | 'pending';
  let service: MagicLoginService;
  const createTokenPair = vi.fn();

  beforeEach(() => {
    status = 'active';
    createTokenPair.mockReset().mockResolvedValue({
      access_token: 'access',
      refresh_token: 'refresh',
    });
    const prisma = {
      user: {
        findUnique: vi.fn(({ where }: { where: { id: string } }) =>
          Promise.resolve({
            id: where.id,
            email: `${where.id}@example.com`,
            password: 'hash',
            name: 'Test User',
            profileImage: null,
            isAdmin: false,
            status,
            createdAt: new Date(),
            updatedAt: new Date(),
          }),
        ),
      },
    };
    service = new MagicLoginService(
      prisma as unknown as PrismaService,
      { createTokenPair } as unknown as AuthService,
    );
  });

  afterEach(() => {
    service.onModuleDestroy();
    vi.useRealTimers();
  });

  it('signs in as the person who made the code, without the password hash', async () => {
    const { code } = service.create('u1');
    const result = await service.redeem(code);
    expect(createTokenPair).toHaveBeenCalledWith('u1', 'u1@example.com');
    expect(result.access_token).toBe('access');
    expect(result.user.id).toBe('u1');
    expect(result.user.hasPassword).toBe(true);
    expect(result.user).not.toHaveProperty('password');
  });

  it('works only once', async () => {
    const { code } = service.create('u1');
    await service.redeem(code);
    await expect(service.redeem(code)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects an unknown code', async () => {
    await expect(service.redeem('nope')).rejects.toThrow(UnauthorizedException);
  });

  it('expires', async () => {
    vi.useFakeTimers();
    const { code } = service.create('u1');
    vi.advanceTimersByTime(MAGIC_LOGIN_VALIDITY_MS + 1);
    await expect(service.redeem(code)).rejects.toThrow(UnauthorizedException);
  });

  it('replaces the earlier code of the same person', async () => {
    const first = service.create('u1');
    const other = service.create('u2');
    service.create('u1');
    await expect(service.redeem(first.code)).rejects.toThrow(
      UnauthorizedException,
    );
    await expect(service.redeem(other.code)).resolves.toBeDefined();
  });

  it('rejects an account that is no longer active', async () => {
    const { code } = service.create('u1');
    status = 'pending';
    await expect(service.redeem(code)).rejects.toThrow(UnauthorizedException);
  });
});
