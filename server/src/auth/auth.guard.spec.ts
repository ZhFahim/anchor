import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthGuard } from './auth.guard';
import { TokenResolverService } from './token-resolver.service';
import { UserStatus, ApiTokenScope } from '../generated/prisma/enums';
import type { AuthUser } from './token-resolver.service';

const baseUser: AuthUser = {
  id: 'u1',
  email: 'user@example.com',
  name: 'User',
  profileImage: null,
  isAdmin: false,
  status: UserStatus.active,
  apiTokenScope: ApiTokenScope.readOnly,
  authMethod: 'apiToken',
  createdAt: new Date(),
  updatedAt: new Date(),
};

const makeContext = (method: string, user?: AuthUser): ExecutionContext =>
  ({
    switchToHttp: () => ({
      getRequest: () => ({
        method,
        headers: { authorization: 'Bearer t' },
        user,
      }),
    }),
  }) as unknown as ExecutionContext;

describe('AuthGuard', () => {
  let guard: AuthGuard;
  let tokenResolver: { resolveUser: jest.Mock };

  beforeEach(async () => {
    tokenResolver = { resolveUser: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        AuthGuard,
        { provide: TokenResolverService, useValue: tokenResolver },
      ],
    }).compile();
    guard = module.get(AuthGuard);
  });

  it('allows read requests for a read-only API token', async () => {
    tokenResolver.resolveUser.mockResolvedValue(baseUser);
    await expect(guard.canActivate(makeContext('GET'))).resolves.toBe(true);
  });

  it('blocks write requests for a read-only API token', async () => {
    tokenResolver.resolveUser.mockResolvedValue(baseUser);
    await expect(guard.canActivate(makeContext('POST'))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('allows write requests for a read-write API token', async () => {
    tokenResolver.resolveUser.mockResolvedValue({
      ...baseUser,
      apiTokenScope: ApiTokenScope.readWrite,
    });
    await expect(guard.canActivate(makeContext('PATCH'))).resolves.toBe(true);
  });

  it('allows write requests for a session (JWT) auth regardless of scope', async () => {
    tokenResolver.resolveUser.mockResolvedValue({
      ...baseUser,
      authMethod: 'jwt',
    });
    await expect(guard.canActivate(makeContext('DELETE'))).resolves.toBe(true);
  });
});
