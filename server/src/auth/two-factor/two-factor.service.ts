import * as bcrypt from 'bcrypt';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { AuthConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { OidcConfigService } from '../oidc/oidc-config.service';
import { ChallengeService, type OpenChallenge } from './challenge.service';
import { TwoFactorCryptoService } from './two-factor-crypto.service';
import {
  LOCKOUT_MS,
  MAX_FAILED_CODE_ATTEMPTS,
  TOTP_ISSUER,
  TWO_FACTOR_POLICIES,
  TWO_FACTOR_POLICY_SETTING_KEY,
  type TwoFactorPolicy,
} from './two-factor.constants';
import {
  base32Decode,
  base32Encode,
  buildOtpauthUri,
  generateTotpSecret,
  verifyTotp,
} from './totp.util';
import {
  generateRecoveryCodes,
  normalizeRecoveryCode,
} from './recovery-codes.util';

export interface Capabilities {
  totp: boolean;
  passkeys: boolean;
}

export interface CodeInput {
  code?: string;
  recoveryCode?: string;
}

const isNotFound = (error: unknown) =>
  typeof error === 'object' &&
  error !== null &&
  (error as { code?: string }).code === 'P2025';

@Injectable()
export class TwoFactorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly crypto: TwoFactorCryptoService,
    private readonly challenges: ChallengeService,
    private readonly oidcConfig: OidcConfigService,
    @Inject(AuthConfig.KEY)
    private readonly authConfig: ConfigType<typeof AuthConfig>,
  ) {}

  // ---- capabilities and policy -------------------------------------------

  async getCapabilities(): Promise<Capabilities> {
    const { disableInternalAuth } = await this.oidcConfig.getPublicConfig();
    if (disableInternalAuth) return { totp: false, passkeys: false };
    return {
      totp: this.crypto.isAvailable,
      passkeys: this.authConfig.passkeysConfigured,
    };
  }

  /** What an admin picked. */
  async getPolicy(): Promise<TwoFactorPolicy> {
    const row = await this.prisma.settings.findUnique({
      where: { key: TWO_FACTOR_POLICY_SETTING_KEY },
    });
    const value = row?.value as TwoFactorPolicy | undefined;
    return value && TWO_FACTOR_POLICIES.includes(value) ? value : 'optional';
  }

  /** What is enforced: nothing, when the server can't offer a factor. */
  async getEffectivePolicy(): Promise<TwoFactorPolicy> {
    const caps = await this.getCapabilities();
    if (!caps.totp && !caps.passkeys) return 'optional';
    return this.getPolicy();
  }

  async setPolicy(policy: TwoFactorPolicy, actingUserId: string) {
    const caps = await this.getCapabilities();
    if (policy !== 'optional') {
      if (!caps.totp && !caps.passkeys) {
        throw new ConflictException(
          'Two-factor is not available on this server',
        );
      }
      const admin = await this.prisma.user.findUnique({
        where: { id: actingUserId },
        select: {
          password: true,
          totpEnabledAt: true,
          _count: { select: { passkeys: true } },
        },
      });
      // An admin who signs in through a provider is outside the policy.
      if (admin?.password && !admin.totpEnabledAt && !admin._count.passkeys) {
        throw new ConflictException(
          'Set up two-factor for your own account first',
        );
      }
    }
    await this.prisma.settings.upsert({
      where: { key: TWO_FACTOR_POLICY_SETTING_KEY },
      update: { value: policy },
      create: { key: TWO_FACTOR_POLICY_SETTING_KEY, value: policy },
    });
    return this.getAdminSettings();
  }

  async getAdminSettings() {
    const [policy, available, coverage] = await Promise.all([
      this.getPolicy(),
      this.getCapabilities(),
      this.getCoverage(),
    ]);
    return { policy, isLocked: false, available, coverage };
  }

  /** Active people with a password, and how many already have a factor. */
  async getCoverage() {
    const base = { status: 'active' as const, password: { not: null } };
    const [total, covered] = await Promise.all([
      this.prisma.user.count({ where: base }),
      this.prisma.user.count({
        where: {
          ...base,
          OR: [{ totpEnabledAt: { not: null } }, { passkeys: { some: {} } }],
        },
      }),
    ]);
    return { covered, total };
  }

  private async policyAppliesTo(user: {
    isAdmin: boolean;
    hasPassword: boolean;
  }): Promise<boolean> {
    if (!user.hasPassword) return false;
    const policy = await this.getEffectivePolicy();
    return policy === 'everyone' || (policy === 'admins' && user.isAdmin);
  }

  // ---- sign-in -----------------------------------------------------------

  /**
   * Called once the password is right. Returns when a plain sign-in may go
   * ahead; otherwise throws the answer that tells the client what's next.
   */
  async gateForPasswordLogin(userId: string): Promise<void> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        isAdmin: true,
        password: true,
        totpEnabledAt: true,
        _count: { select: { passkeys: true } },
      },
    });

    if (user.totpEnabledAt) {
      if (!this.crypto.isAvailable) {
        // Letting the password through here would silently drop the factor.
        throw new ServiceUnavailableException(
          'Two-factor is on for this account, but TOTP_ENCRYPTION_KEY is missing on the server.',
        );
      }
      const challenge = await this.challenges.create('login_2fa', { userId });
      throw new UnauthorizedException({
        statusCode: 401,
        message: 'Two-factor code required',
        error: 'Unauthorized',
        twoFactorRequired: true,
        challenge,
      });
    }

    const applies = await this.policyAppliesTo({
      isAdmin: user.isAdmin,
      hasPassword: !!user.password,
    });
    if (!applies) return;

    const caps = await this.getCapabilities();
    if (user._count.passkeys > 0 && caps.passkeys) {
      throw new ForbiddenException({
        statusCode: 403,
        message: 'Sign in with your passkey',
        error: 'Forbidden',
        passkeyRequired: true,
      });
    }
    throw await this.setupRequired(userId);
  }

  /** The 403 that sends a person into the enrollment gate. */
  async setupRequired(userId: string): Promise<ForbiddenException> {
    return new ForbiddenException(await this.enrollmentGate(userId));
  }

  async enrollmentGate(userId: string) {
    const caps = await this.getCapabilities();
    const challenge = await this.challenges.create('enroll', { userId });
    return {
      statusCode: 403,
      message: 'Two-factor setup required',
      error: 'Forbidden',
      twoFactorSetupRequired: true,
      challenge,
      methods: { totp: caps.totp, passkey: caps.passkeys },
    };
  }

  /** Register: does a brand-new account have to enroll before it gets in? */
  async mustEnrollNewUser(user: { isAdmin: boolean; password: boolean }) {
    return this.policyAppliesTo({
      isAdmin: user.isAdmin,
      hasPassword: user.password,
    });
  }

  /** Step two of a password sign-in. Returns the user to sign in. */
  async completeLoginChallenge(
    token: string,
    input: CodeInput,
  ): Promise<string> {
    const challenge = await this.challenges.find(token, 'login_2fa');
    const userId = challenge.userId!;
    try {
      await this.verifySecondFactor(userId, input);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        await this.challenges.recordFailure(challenge);
      }
      throw error;
    }
    if (!(await this.challenges.consume(challenge.id))) {
      throw new UnauthorizedException('Challenge expired');
    }
    return userId;
  }

  async userForEnrollment(token: string): Promise<{
    challenge: OpenChallenge;
    userId: string;
  }> {
    const challenge = await this.challenges.find(token, 'enroll');
    const userId = challenge.userId!;
    // A second challenge handed out before the first enrollment finished must
    // not become a way around the factor that exists by now.
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { totpEnabledAt: true, _count: { select: { passkeys: true } } },
    });
    if (!user || user.totpEnabledAt || user._count.passkeys > 0) {
      await this.challenges.deleteForUser(userId, ['enroll']);
      throw new UnauthorizedException('Challenge expired');
    }
    return { challenge, userId };
  }

  /** Enrollment is done: this challenge and every sibling are used up. */
  async consumeEnrollment(userId: string, challengeId: string) {
    const consumed = await this.challenges.consume(challengeId);
    await this.challenges.deleteForUser(userId, ['enroll']);
    return consumed;
  }

  // ---- status ------------------------------------------------------------

  async getStatus(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        isAdmin: true,
        password: true,
        totpEnabledAt: true,
        totpLastUsedAt: true,
        passkeys: { orderBy: { createdAt: 'asc' } },
        _count: { select: { recoveryCodes: { where: { usedAt: null } } } },
      },
    });
    const [available, policy] = await Promise.all([
      this.getCapabilities(),
      this.getEffectivePolicy(),
    ]);
    const applies =
      !!user.password &&
      (policy === 'everyone' || (policy === 'admins' && user.isAdmin));
    return {
      available,
      policy,
      required: applies && !user.totpEnabledAt && user.passkeys.length === 0,
      totp: {
        enabled: !!user.totpEnabledAt,
        enabledAt: user.totpEnabledAt,
        lastUsedAt: user.totpLastUsedAt,
        recoveryCodesRemaining: user._count.recoveryCodes,
      },
      passkeys: user.passkeys.map((passkey) => ({
        id: passkey.id,
        name: passkey.name,
        createdAt: passkey.createdAt,
        lastUsedAt: passkey.lastUsedAt,
        deviceType: passkey.deviceType,
        backedUp: passkey.backedUp,
      })),
    };
  }

  // ---- enrollment --------------------------------------------------------

  /** Starts (or restarts) an authenticator; nothing counts until enable(). */
  async setupTotp(userId: string, current: CodeInput = {}) {
    await this.assertTotpUsable(userId);
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { email: true, totpEnabledAt: true },
    });
    if (user.totpEnabledAt) {
      if (!current.code && !current.recoveryCode) {
        throw new ForbiddenException('Current code required');
      }
      await this.verifyForSession(userId, current);
    }
    const secret = base32Encode(generateTotpSecret());
    await this.prisma.user.update({
      where: { id: userId },
      data: { totpPendingSecretEnc: this.crypto.encrypt(secret) },
    });
    return {
      secret,
      otpauthUri: buildOtpauthUri({
        secret,
        account: user.email,
        issuer: TOTP_ISSUER,
      }),
    };
  }

  /**
   * Turns the pending authenticator on. Every other session is signed out;
   * the caller hands the person a fresh token pair.
   */
  async enableTotp(userId: string, code: string): Promise<string[]> {
    await this.assertTotpUsable(userId);
    await this.reserveAttempt(userId);
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { totpPendingSecretEnc: true },
    });
    if (!user.totpPendingSecretEnc) {
      throw new BadRequestException('Start the setup first');
    }
    const secret = base32Decode(this.crypto.decrypt(user.totpPendingSecretEnc));
    const step = verifyTotp(secret, code);
    if (step === null) throw new BadRequestException('Invalid code');

    const codes = generateRecoveryCodes();
    const now = new Date();
    await this.prisma.$transaction(async (tx) => {
      // Only one of several simultaneous requests gets to claim the secret.
      const claimed = await tx.user.updateMany({
        where: { id: userId, totpPendingSecretEnc: user.totpPendingSecretEnc },
        data: {
          totpSecretEnc: user.totpPendingSecretEnc,
          totpPendingSecretEnc: null,
          totpEnabledAt: now,
          totpLastStep: step,
          totpLastUsedAt: now,
          sessionsRevokedAt: now,
        },
      });
      if (claimed.count !== 1) {
        throw new BadRequestException('Start the setup first');
      }
      await tx.recoveryCode.deleteMany({ where: { userId } });
      await tx.recoveryCode.createMany({
        data: codes.map((value) => ({
          userId,
          codeHash: this.crypto.mac(normalizeRecoveryCode(value)!),
        })),
      });
      await tx.refreshToken.deleteMany({ where: { userId } });
    });
    await this.resetAttempts(userId);
    return codes;
  }

  async disableTotp(
    userId: string,
    input: CodeInput & { password: string },
  ): Promise<void> {
    await this.assertPassword(userId, input.password);
    await this.verifyForSession(userId, input);
    await this.prisma.$transaction(async (tx) => {
      await this.lockUser(tx, userId);
      const user = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { isAdmin: true, _count: { select: { passkeys: true } } },
      });
      if (
        !user._count.passkeys &&
        (await this.policyAppliesTo({
          isAdmin: user.isAdmin,
          hasPassword: true,
        }))
      ) {
        throw new ForbiddenException('Two-factor is required by your admin');
      }
      await tx.user.update({
        where: { id: userId },
        data: {
          totpSecretEnc: null,
          totpPendingSecretEnc: null,
          totpEnabledAt: null,
          totpLastStep: null,
          totpLastUsedAt: null,
        },
      });
      await tx.recoveryCode.deleteMany({ where: { userId } });
    });
  }

  /**
   * Serialises changes to one person's factors, so two requests can't each
   * see "another factor is left" and remove both.
   */
  async lockUser(
    tx: { $queryRaw: PrismaService['$queryRaw'] },
    userId: string,
  ): Promise<void> {
    await tx.$queryRaw`SELECT id FROM "User" WHERE id = ${userId} FOR UPDATE`;
  }

  async regenerateRecoveryCodes(
    userId: string,
    input: { password: string; code: string },
  ): Promise<string[]> {
    await this.assertPassword(userId, input.password);
    await this.verifyForSession(userId, { code: input.code });
    const codes = generateRecoveryCodes();
    await this.prisma.$transaction([
      this.prisma.recoveryCode.deleteMany({ where: { userId } }),
      this.prisma.recoveryCode.createMany({
        data: codes.map((value) => ({
          userId,
          codeHash: this.crypto.mac(normalizeRecoveryCode(value)!),
        })),
      }),
    ]);
    return codes;
  }

  /** Admin: wipes the second factors and signs the person out everywhere. */
  async resetUser(userId: string): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: {
          totpSecretEnc: null,
          totpPendingSecretEnc: null,
          totpEnabledAt: null,
          totpLastStep: null,
          totpLastUsedAt: null,
          twoFactorFailedAttempts: 0,
          twoFactorLockedUntil: null,
          sessionsRevokedAt: new Date(),
        },
      }),
      this.prisma.recoveryCode.deleteMany({ where: { userId } }),
      this.prisma.passkey.deleteMany({ where: { userId } }),
      this.prisma.loginChallenge.deleteMany({ where: { userId } }),
      this.prisma.refreshToken.deleteMany({ where: { userId } }),
    ]);
  }

  /** Whether the policy lets this person drop their last factor. */
  async mayRemoveLastFactor(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { isAdmin: true, password: true },
    });
    return !(await this.policyAppliesTo({
      isAdmin: user.isAdmin,
      hasPassword: !!user.password,
    }));
  }

  // ---- checking codes ----------------------------------------------------

  /**
   * Checks a TOTP or recovery code, with the shared lockout. Throws 401
   * "Invalid code" or 429.
   */
  async verifySecondFactor(userId: string, input: CodeInput): Promise<void> {
    if (!!input.code === !!input.recoveryCode) {
      throw new BadRequestException('Send either a code or a recovery code');
    }
    await this.reserveAttempt(userId);

    const ok = input.code
      ? await this.claimTotp(userId, input.code)
      : await this.claimRecoveryCode(userId, input.recoveryCode!);
    if (!ok) throw new UnauthorizedException('Invalid code');
    await this.resetAttempts(userId);
  }

  /**
   * Same check for requests that already carry a session. A wrong code is a
   * 400 there: a 401 would make clients think the session itself has expired.
   */
  private async verifyForSession(
    userId: string,
    input: CodeInput,
  ): Promise<void> {
    try {
      await this.verifySecondFactor(userId, input);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw new BadRequestException('Invalid code');
      }
      throw error;
    }
  }

  private async claimTotp(userId: string, code: string): Promise<boolean> {
    if (!this.crypto.isAvailable) return false;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { totpSecretEnc: true, totpLastStep: true },
    });
    if (!user?.totpSecretEnc) return false;
    const step = verifyTotp(
      base32Decode(this.crypto.decrypt(user.totpSecretEnc)),
      code,
      { lastStep: user.totpLastStep },
    );
    if (step === null) return false;
    // The step is claimed in the database, so a code can't win two requests.
    const { count } = await this.prisma.user.updateMany({
      where: {
        id: userId,
        OR: [{ totpLastStep: null }, { totpLastStep: { lt: step } }],
      },
      data: { totpLastStep: step, totpLastUsedAt: new Date() },
    });
    return count === 1;
  }

  private async claimRecoveryCode(
    userId: string,
    input: string,
  ): Promise<boolean> {
    const normalized = normalizeRecoveryCode(input);
    if (!normalized || !this.crypto.isAvailable) return false;
    const { count } = await this.prisma.recoveryCode.updateMany({
      where: {
        userId,
        codeHash: this.crypto.mac(normalized),
        usedAt: null,
      },
      data: { usedAt: new Date() },
    });
    return count === 1;
  }

  /**
   * Spends one of the five tries before the code is looked at, so parallel
   * guesses can't all slip past a lockout that hasn't been written yet.
   */
  private async reserveAttempt(userId: string): Promise<void> {
    const now = new Date();
    await this.prisma.user.updateMany({
      where: { id: userId, twoFactorLockedUntil: { lte: now } },
      data: { twoFactorFailedAttempts: 0, twoFactorLockedUntil: null },
    });
    let attempts: number;
    try {
      const row = await this.prisma.user.update({
        where: {
          id: userId,
          twoFactorLockedUntil: null,
          twoFactorFailedAttempts: { lt: MAX_FAILED_CODE_ATTEMPTS },
        },
        data: { twoFactorFailedAttempts: { increment: 1 } },
        select: { twoFactorFailedAttempts: true },
      });
      attempts = row.twoFactorFailedAttempts;
    } catch (error) {
      if (isNotFound(error)) throw await this.lockedOut(userId);
      throw error;
    }
    if (attempts >= MAX_FAILED_CODE_ATTEMPTS) {
      await this.prisma.user.updateMany({
        where: { id: userId, twoFactorLockedUntil: null },
        data: { twoFactorLockedUntil: new Date(Date.now() + LOCKOUT_MS) },
      });
    }
  }

  private resetAttempts(userId: string) {
    return this.prisma.user.updateMany({
      where: { id: userId },
      data: { twoFactorFailedAttempts: 0, twoFactorLockedUntil: null },
    });
  }

  private async lockedOut(userId: string): Promise<HttpException> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { twoFactorLockedUntil: true },
    });
    const until =
      user?.twoFactorLockedUntil?.getTime() ?? Date.now() + LOCKOUT_MS;
    return new HttpException(
      {
        statusCode: 429,
        message: 'Too many attempts. Try again later.',
        error: 'Too Many Requests',
        retryAfterSeconds: Math.max(1, Math.ceil((until - Date.now()) / 1000)),
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  private async assertPassword(userId: string, password: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { password: true },
    });
    if (!user.password || !(await bcrypt.compare(password, user.password))) {
      throw new ForbiddenException('Current password is incorrect');
    }
  }

  private async assertTotpUsable(userId: string) {
    const caps = await this.getCapabilities();
    if (!caps.totp) {
      throw new BadRequestException(
        'Authenticator apps are not available on this server',
      );
    }
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { password: true },
    });
    if (!user.password) {
      throw new BadRequestException(
        'Two-factor is only for accounts that sign in with a password',
      );
    }
  }
}
