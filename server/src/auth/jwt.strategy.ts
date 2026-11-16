import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { PrismaService } from 'src/prisma/prisma.service';
import { AuthConfig } from '../config/configuration';
import { isSessionRevoked } from './utils/session-revocation';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @Inject(AuthConfig.KEY)
    authConfig: ConfigType<typeof AuthConfig>,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: authConfig.jwtSecret,
    });
  }

  async validate(payload: { sub: string; iat?: number }) {
    const row = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        name: true,
        profileImage: true,
        isAdmin: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        sessionsRevokedAt: true,
      },
    });

    if (!row) {
      throw new UnauthorizedException('User not found');
    }
    const { sessionsRevokedAt, ...user } = row;

    if (isSessionRevoked(payload.iat, sessionsRevokedAt)) {
      throw new UnauthorizedException('Session ended');
    }

    // Reject pending users
    if (user.status === 'pending') {
      throw new UnauthorizedException('Account pending approval');
    }

    return user;
  }
}
