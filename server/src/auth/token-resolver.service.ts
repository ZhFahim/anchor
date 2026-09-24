import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import type { ApiTokenScope } from '../generated/prisma/enums';

const AUTH_USER_SELECT = {
  id: true,
  email: true,
  name: true,
  profileImage: true,
  isAdmin: true,
  status: true,
  apiTokenScope: true,
  createdAt: true,
  updatedAt: true,
} as const;

export type AuthMethod = 'jwt' | 'apiToken';

export type AuthUser = {
  id: string;
  email: string;
  name: string;
  profileImage: string | null;
  isAdmin: boolean;
  status: string;
  apiTokenScope: ApiTokenScope;
  authMethod: AuthMethod;
  createdAt: Date;
  updatedAt: Date;
};

/** How this request was authenticated. `authMethod` is set by TokenResolverService. */
export type ApiTokenAuthUser = AuthUser & { authMethod: 'apiToken' };

/** True when the request authenticated via a static API token (PAT). */
export const isApiTokenAuth = (user: AuthUser): user is ApiTokenAuthUser =>
  user.authMethod === 'apiToken';

@Injectable()
export class TokenResolverService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async resolveUser(token: string): Promise<AuthUser | null> {
    const user = await this.resolveUserFromJwt(token);
    if (user) return user;
    return this.resolveUserFromApiToken(token);
  }

  private async resolveUserFromJwt(token: string): Promise<AuthUser | null> {
    try {
      const payload = this.jwtService.verify<{ sub?: string }>(token);

      if (typeof payload?.sub !== 'string' || !payload.sub) {
        return null;
      }

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: AUTH_USER_SELECT,
      });
      return user ? { ...user, authMethod: 'jwt' as const } : null;
    } catch {
      return null;
    }
  }

  private async resolveUserFromApiToken(
    token: string,
  ): Promise<AuthUser | null> {
    const user = await this.prisma.user.findUnique({
      where: { apiToken: token },
      select: AUTH_USER_SELECT,
    });
    return user ? { ...user, authMethod: 'apiToken' as const } : null;
  }
}
