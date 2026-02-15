import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

const AUTH_USER_SELECT = {
  id: true,
  email: true,
  name: true,
  profileImage: true,
  isAdmin: true,
  status: true,
  createdAt: true,
  updatedAt: true,
} as const;

export type AuthUser = {
  id: string;
  email: string;
  name: string;
  profileImage: string | null;
  isAdmin: boolean;
  status: string;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class TokenResolverService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async resolveUser(token: string): Promise<AuthUser | null> {
    const user =
      (await this.resolveUserFromJwt(token)) ||
      (await this.resolveUserFromApiToken(token));
    return user;
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
      return user as AuthUser | null;
    } catch {
      return null;
    }
  }

  private async resolveUserFromApiToken(token: string): Promise<AuthUser | null> {
    const user = await this.prisma.user.findUnique({
      where: { apiToken: token },
      select: AUTH_USER_SELECT,
    });
    return user as AuthUser | null;
  }
}
