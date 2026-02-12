import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserStatus } from '../generated/prisma/enums';
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

@Injectable()
export class NotesAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractBearerToken(request?.headers?.authorization);

    if (!token) {
      throw new UnauthorizedException('Missing authentication token');
    }

    const user =
      (await this.resolveUserFromJwt(token)) ||
      (await this.resolveUserFromApiToken(token));

    if (!user) {
      throw new UnauthorizedException('Invalid authentication token');
    }

    if (user.status !== UserStatus.active) {
      throw new UnauthorizedException('Account pending approval');
    }

    request.user = user;
    return true;
  }

  private async resolveUserFromJwt(token: string) {
    try {
      const payload = this.jwtService.verify<{ sub?: string }>(token);

      if (typeof payload?.sub !== 'string' || !payload.sub) {
        return null;
      }

      return this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: AUTH_USER_SELECT,
      });
    } catch {
      return null;
    }
  }

  private async resolveUserFromApiToken(token: string) {
    return this.prisma.user.findUnique({
      where: { apiToken: token },
      select: AUTH_USER_SELECT,
    });
  }

  private extractBearerToken(header?: string | string[]): string | null {
    if (!header) {
      return null;
    }

    const value = Array.isArray(header) ? header[0] : header;
    if (!value) {
      return null;
    }

    const [scheme, token] = value.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      return null;
    }

    return token;
  }
}
