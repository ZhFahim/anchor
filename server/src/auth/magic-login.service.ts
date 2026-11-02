import {
  Injectable,
  OnModuleDestroy,
  UnauthorizedException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UserStatus } from '../generated/prisma/enums';
import { AuthService } from './auth.service';
import {
  MAGIC_LOGIN_CODE_BYTES,
  MAGIC_LOGIN_VALIDITY_MS,
} from './constants/auth.constants';

/**
 * One-time codes that sign another device in as someone already signed in
 * (a QR code or a link from Settings). Kept in memory only: a restart ends
 * them, as it should for something this short-lived.
 */
@Injectable()
export class MagicLoginService implements OnModuleDestroy {
  private readonly codes = new Map<
    string,
    { userId: string; expiresAt: number }
  >();
  private readonly cleanupInterval = setInterval(
    () => this.dropExpired(),
    MAGIC_LOGIN_VALIDITY_MS,
  );

  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
  ) {
    this.cleanupInterval.unref?.();
  }

  create(userId: string) {
    // A new code replaces the person's earlier ones.
    for (const [code, entry] of this.codes) {
      if (entry.userId === userId) this.codes.delete(code);
    }
    const code = crypto
      .randomBytes(MAGIC_LOGIN_CODE_BYTES)
      .toString('base64url');
    const expiresAt = Date.now() + MAGIC_LOGIN_VALIDITY_MS;
    this.codes.set(code, { userId, expiresAt });
    return { code, expiresAt: new Date(expiresAt).toISOString() };
  }

  async redeem(code: string) {
    const entry = this.codes.get(code);
    this.codes.delete(code);
    if (!entry || Date.now() > entry.expiresAt) {
      throw new UnauthorizedException(
        'This sign-in code has expired or was already used',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: entry.userId },
      select: {
        id: true,
        email: true,
        password: true,
        name: true,
        profileImage: true,
        isAdmin: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!user || user.status !== UserStatus.active) {
      throw new UnauthorizedException(
        'This sign-in code has expired or was already used',
      );
    }

    const { password, ...userWithoutPassword } = user;
    const tokens = await this.authService.createTokenPair(user.id, user.email);
    return {
      ...tokens,
      user: { ...userWithoutPassword, hasPassword: !!password },
    };
  }

  private dropExpired(): void {
    const now = Date.now();
    for (const [code, entry] of this.codes) {
      if (now > entry.expiresAt) this.codes.delete(code);
    }
  }

  onModuleDestroy(): void {
    clearInterval(this.cleanupInterval);
  }
}
