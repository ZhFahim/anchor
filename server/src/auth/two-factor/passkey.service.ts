import {
  generateAuthenticationOptions,
  generateRegistrationOptions,
  verifyAuthenticationResponse,
  verifyRegistrationResponse,
  type AuthenticationResponseJSON,
  type RegistrationResponseJSON,
} from '@simplewebauthn/server';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { UserStatus } from '../../generated/prisma/enums';
import { ChallengeService } from './challenge.service';
import { MAX_PASSKEYS_PER_USER } from './two-factor.constants';
import { TwoFactorService } from './two-factor.service';

const RP_NAME = 'Anchor';

type PasskeyRow = {
  id: string;
  name: string;
  createdAt: Date;
  lastUsedAt: Date | null;
  deviceType: string;
  backedUp: boolean;
};

const summary = (passkey: PasskeyRow) => ({
  id: passkey.id,
  name: passkey.name,
  createdAt: passkey.createdAt,
  lastUsedAt: passkey.lastUsedAt,
  deviceType: passkey.deviceType,
  backedUp: passkey.backedUp,
});

@Injectable()
export class PasskeyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly challenges: ChallengeService,
    private readonly twoFactor: TwoFactorService,
    @Inject(AppConfig.KEY)
    private readonly appConfig: ConfigType<typeof AppConfig>,
  ) {}

  /** The relying party is the public URL; nothing else is accepted. */
  private get relyingParty() {
    const url = new URL(this.appConfig.appUrl);
    return { rpID: url.hostname, origin: url.origin };
  }

  private async assertAvailable() {
    const caps = await this.twoFactor.getCapabilities();
    if (!caps.passkeys) {
      throw new ForbiddenException('Passkeys are not available on this server');
    }
  }

  // ---- registration ------------------------------------------------------

  async registrationOptions(userId: string) {
    const options = await this.buildRegistrationOptions(userId);
    const challenge = await this.challenges.create('webauthn_register', {
      userId,
      data: options.challenge,
    });
    return { options, challenge };
  }

  private async buildRegistrationOptions(userId: string) {
    await this.assertAvailable();
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        password: true,
        passkeys: { select: { credentialId: true, transports: true } },
      },
    });
    // A passkey on a provider-only account would outlive its provider login.
    if (!user.password) {
      throw new BadRequestException(
        'Passkeys are only for accounts that sign in with a password',
      );
    }
    if (user.passkeys.length >= MAX_PASSKEYS_PER_USER) {
      throw new ConflictException(
        `You can have up to ${MAX_PASSKEYS_PER_USER} passkeys`,
      );
    }
    return generateRegistrationOptions({
      rpName: RP_NAME,
      rpID: this.relyingParty.rpID,
      userName: user.email,
      userDisplayName: user.name,
      userID: new TextEncoder().encode(user.id),
      attestationType: 'none',
      excludeCredentials: user.passkeys.map((passkey) => ({
        id: passkey.credentialId,
        transports: passkey.transports,
      })),
      authenticatorSelection: {
        residentKey: 'required',
        userVerification: 'required',
      },
    });
  }

  async verifyRegistration(
    userId: string,
    token: string,
    response: RegistrationResponseJSON,
    name: string,
  ) {
    await this.assertAvailable();
    const challenge = await this.challenges.find(token, 'webauthn_register');
    if (challenge.userId !== userId) {
      throw new UnauthorizedException('Challenge expired');
    }
    // One try per challenge: a failed ceremony starts over.
    if (!(await this.challenges.consume(challenge.id))) {
      throw new UnauthorizedException('Challenge expired');
    }
    return this.storePasskey(userId, challenge.data!, response, name);
  }

  private async storePasskey(
    userId: string,
    expectedChallenge: string,
    response: RegistrationResponseJSON,
    name: string,
  ) {
    const { origin, rpID } = this.relyingParty;
    let verification: Awaited<ReturnType<typeof verifyRegistrationResponse>>;
    try {
      verification = await verifyRegistrationResponse({
        response,
        expectedChallenge,
        expectedOrigin: origin,
        expectedRPID: rpID,
        requireUserVerification: true,
      });
    } catch {
      throw new BadRequestException('Passkey could not be verified');
    }
    if (!verification.verified) {
      throw new BadRequestException('Passkey could not be verified');
    }
    const { credential, credentialDeviceType, credentialBackedUp } =
      verification.registrationInfo;
    const taken = await this.prisma.passkey.findUnique({
      where: { credentialId: credential.id },
      select: { id: true },
    });
    if (taken) throw new ConflictException('That passkey is already added');

    const created = await this.prisma.passkey.create({
      data: {
        userId,
        credentialId: credential.id,
        publicKey: Buffer.from(credential.publicKey),
        counter: BigInt(credential.counter),
        transports: credential.transports ?? response.response.transports ?? [],
        name: name.trim(),
        deviceType: credentialDeviceType,
        backedUp: credentialBackedUp,
      },
    });
    return summary(created);
  }

  // ---- sign-in -----------------------------------------------------------

  async loginOptions() {
    await this.assertAvailable();
    const options = await generateAuthenticationOptions({
      rpID: this.relyingParty.rpID,
      userVerification: 'required',
    });
    const challenge = await this.challenges.create('webauthn_login', {
      data: options.challenge,
    });
    return { options, challenge };
  }

  /** Returns the user a verified passkey belongs to. */
  async verifyLogin(
    token: string,
    response: AuthenticationResponseJSON,
  ): Promise<string> {
    const failed = new UnauthorizedException('Passkey sign-in failed');
    const challenge = await this.challenges.find(token, 'webauthn_login');
    if (!(await this.challenges.consume(challenge.id))) throw failed;
    await this.assertAvailable();

    const passkey = await this.prisma.passkey.findUnique({
      where: { credentialId: response.id },
      include: { user: { select: { id: true, status: true } } },
    });
    if (!passkey || passkey.user.status !== UserStatus.active) throw failed;

    const { origin, rpID } = this.relyingParty;
    let verification: Awaited<ReturnType<typeof verifyAuthenticationResponse>>;
    try {
      verification = await verifyAuthenticationResponse({
        response,
        expectedChallenge: challenge.data!,
        expectedOrigin: origin,
        expectedRPID: rpID,
        requireUserVerification: true,
        credential: {
          id: passkey.credentialId,
          publicKey: new Uint8Array(passkey.publicKey),
          counter: Number(passkey.counter),
          transports: passkey.transports,
        },
      });
    } catch {
      throw failed;
    }
    if (!verification.verified) throw failed;

    // The stored counter only ever moves forward, even when two sign-ins with
    // the same passkey finish out of order. Authenticators that always report
    // zero keep it at zero.
    const newCounter = BigInt(verification.authenticationInfo.newCounter);
    const { count } = await this.prisma.passkey.updateMany({
      where: {
        id: passkey.id,
        counter: newCounter > 0n ? { lt: newCounter } : 0n,
      },
      data: {
        counter: newCounter,
        backedUp: verification.authenticationInfo.credentialBackedUp,
        lastUsedAt: new Date(),
      },
    });
    if (count === 0) {
      // Either a sign-in that finished a moment earlier moved the counter on,
      // or the passkey was removed (an admin reset) while this one was checked.
      const stillThere = await this.prisma.passkey.count({
        where: { id: passkey.id },
      });
      if (!stillThere) throw failed;
    }
    return passkey.userId;
  }

  // ---- managing ----------------------------------------------------------

  async rename(userId: string, id: string, name: string) {
    const { count } = await this.prisma.passkey.updateMany({
      where: { id, userId },
      data: { name: name.trim() },
    });
    if (count === 0) throw new NotFoundException('Passkey not found');
    return summary(
      await this.prisma.passkey.findUniqueOrThrow({ where: { id } }),
    );
  }

  async remove(userId: string, id: string) {
    await this.prisma.$transaction(async (tx) => {
      await this.twoFactor.lockUser(tx, userId);
      const user = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: {
          totpEnabledAt: true,
          passkeys: { select: { id: true } },
        },
      });
      const owned = user.passkeys.some((passkey) => passkey.id === id);
      if (!owned) throw new NotFoundException('Passkey not found');
      const isLastFactor = !user.totpEnabledAt && user.passkeys.length === 1;
      if (isLastFactor && !(await this.twoFactor.mayRemoveLastFactor(userId))) {
        throw new ForbiddenException('Two-factor is required by your admin');
      }
      await tx.passkey.deleteMany({ where: { id, userId } });
    });
    return { message: 'Passkey removed' };
  }

  // ---- enrollment gate ---------------------------------------------------

  /** Options for a person who isn't signed in yet; the enroll challenge keeps the ceremony. */
  async enrollmentOptions(token: string) {
    const { challenge, userId } = await this.twoFactor.userForEnrollment(token);
    const options = await this.buildRegistrationOptions(userId);
    await this.prisma.loginChallenge.update({
      where: { id: challenge.id },
      data: { data: options.challenge },
    });
    return options;
  }

  async verifyEnrollment(
    token: string,
    response: RegistrationResponseJSON,
    name: string,
  ): Promise<string> {
    const { challenge, userId } = await this.twoFactor.userForEnrollment(token);
    if (!challenge.data) {
      throw new BadRequestException('Start the passkey setup first');
    }
    // Each ceremony gets exactly one try.
    await this.prisma.loginChallenge.update({
      where: { id: challenge.id },
      data: { data: null },
    });
    const created = await this.storePasskey(
      userId,
      challenge.data,
      response,
      name,
    );
    // Whoever finished enrolling first wins; a second ceremony from a sibling
    // challenge leaves nothing behind.
    if (!(await this.twoFactor.consumeEnrollment(userId, challenge.id))) {
      await this.prisma.passkey.deleteMany({ where: { id: created.id } });
      throw new UnauthorizedException('Challenge expired');
    }
    return userId;
  }
}
