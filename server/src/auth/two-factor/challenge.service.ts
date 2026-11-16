import { createHash, randomBytes } from 'crypto';
import {
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { ChallengeKind } from '../../generated/prisma/enums';
import {
  ENROLL_CHALLENGE_TTL_MS,
  LOGIN_CHALLENGE_TTL_MS,
  MAX_CHALLENGE_ATTEMPTS,
  MAX_OPEN_WEBAUTHN_LOGIN_CHALLENGES,
  WEBAUTHN_CHALLENGE_TTL_MS,
} from './two-factor.constants';

const TTL: Record<ChallengeKind, number> = {
  login_2fa: LOGIN_CHALLENGE_TTL_MS,
  enroll: ENROLL_CHALLENGE_TTL_MS,
  webauthn_login: WEBAUTHN_CHALLENGE_TTL_MS,
  webauthn_register: WEBAUTHN_CHALLENGE_TTL_MS,
};

export interface OpenChallenge {
  id: string;
  kind: ChallengeKind;
  userId: string | null;
  data: string | null;
  attempts: number;
}

const hashToken = (token: string) =>
  createHash('sha256').update(token).digest('hex');

/**
 * One-time tokens for the steps between "password ok" and "signed in".
 * Only a hash is stored; the token itself is never persisted.
 */
@Injectable()
export class ChallengeService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    kind: ChallengeKind,
    options: { userId?: string; data?: string } = {},
  ): Promise<string> {
    await this.prisma.loginChallenge.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });
    if (kind === 'webauthn_login') {
      const open = await this.prisma.loginChallenge.count({
        where: { kind },
      });
      if (open >= MAX_OPEN_WEBAUTHN_LOGIN_CHALLENGES) {
        throw new HttpException(
          'Too many sign-in attempts. Try again in a few minutes.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }
    const token = randomBytes(32).toString('base64url');
    await this.prisma.loginChallenge.create({
      data: {
        tokenHash: hashToken(token),
        kind,
        userId: options.userId ?? null,
        data: options.data ?? null,
        expiresAt: new Date(Date.now() + TTL[kind]),
      },
    });
    return token;
  }

  /** The open challenge of that kind, or 401 "Challenge expired". */
  async find(token: string, kind: ChallengeKind): Promise<OpenChallenge> {
    const row = await this.prisma.loginChallenge.findUnique({
      where: { tokenHash: hashToken(token) },
    });
    if (!row || row.kind !== kind || row.expiresAt <= new Date()) {
      throw new UnauthorizedException('Challenge expired');
    }
    return row;
  }

  /** Uses the challenge up. False when someone else got there first. */
  async consume(id: string): Promise<boolean> {
    const { count } = await this.prisma.loginChallenge.deleteMany({
      where: { id },
    });
    return count === 1;
  }

  /** Counts a wrong code; the challenge dies after too many. */
  async recordFailure(challenge: OpenChallenge): Promise<void> {
    await this.prisma.loginChallenge.updateMany({
      where: { id: challenge.id },
      data: { attempts: { increment: 1 } },
    });
    await this.prisma.loginChallenge.deleteMany({
      where: { id: challenge.id, attempts: { gte: MAX_CHALLENGE_ATTEMPTS } },
    });
  }

  deleteForUser(userId: string, kinds?: ChallengeKind[]) {
    return this.prisma.loginChallenge.deleteMany({
      where: { userId, ...(kinds ? { kind: { in: kinds } } : {}) },
    });
  }
}
