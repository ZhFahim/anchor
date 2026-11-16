import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type {
  AuthenticationResponseJSON,
  RegistrationResponseJSON,
} from '@simplewebauthn/server';
import type { User } from 'src/generated/prisma/client';
import { AuthService } from '../auth.service';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../jwt-auth.guard';
import {
  ChallengeDto,
  DisableTotpDto,
  EnableTotpDto,
  EnrollEnableDto,
  EnrollPasskeyVerifyDto,
  LoginTwoFactorDto,
  PasskeyLoginVerifyDto,
  PasskeyRegisterVerifyDto,
  RegenerateRecoveryCodesDto,
  RenamePasskeyDto,
  SetupTotpDto,
} from './dto/two-factor.dto';
import { PasskeyService } from './passkey.service';
import { TwoFactorService } from './two-factor.service';

@Controller('api/auth')
export class TwoFactorController {
  constructor(
    private readonly authService: AuthService,
    private readonly twoFactor: TwoFactorService,
    private readonly passkeys: PasskeyService,
  ) {}

  @Get('capabilities')
  capabilities() {
    return this.twoFactor.getCapabilities();
  }

  // ---- sign-in -----------------------------------------------------------

  @HttpCode(HttpStatus.OK)
  @Post('login/2fa')
  async loginTwoFactor(@Body() dto: LoginTwoFactorDto) {
    const userId = await this.twoFactor.completeLoginChallenge(dto.challenge, {
      code: dto.code,
      recoveryCode: dto.recoveryCode,
    });
    return this.authService.issueSession(userId);
  }

  @HttpCode(HttpStatus.OK)
  @Post('passkeys/login/options')
  passkeyLoginOptions() {
    return this.passkeys.loginOptions();
  }

  @HttpCode(HttpStatus.OK)
  @Post('passkeys/login/verify')
  async passkeyLoginVerify(@Body() dto: PasskeyLoginVerifyDto) {
    const userId = await this.passkeys.verifyLogin(
      dto.challenge,
      dto.response as unknown as AuthenticationResponseJSON,
    );
    return this.authService.issueSession(userId);
  }

  // ---- enrollment gate (authenticated by the enroll challenge) -----------

  @HttpCode(HttpStatus.OK)
  @Post('enroll/totp/setup')
  async enrollTotpSetup(@Body() dto: ChallengeDto) {
    const { userId } = await this.twoFactor.userForEnrollment(dto.challenge);
    return this.twoFactor.setupTotp(userId);
  }

  @HttpCode(HttpStatus.OK)
  @Post('enroll/totp/enable')
  async enrollTotpEnable(@Body() dto: EnrollEnableDto) {
    const { challenge, userId } = await this.twoFactor.userForEnrollment(
      dto.challenge,
    );
    const recoveryCodes = await this.twoFactor.enableTotp(userId, dto.code);
    if (!(await this.twoFactor.consumeEnrollment(userId, challenge.id))) {
      throw new UnauthorizedException('Challenge expired');
    }
    return { recoveryCodes, ...(await this.authService.issueSession(userId)) };
  }

  @HttpCode(HttpStatus.OK)
  @Post('enroll/passkey/options')
  async enrollPasskeyOptions(@Body() dto: ChallengeDto) {
    return { options: await this.passkeys.enrollmentOptions(dto.challenge) };
  }

  @HttpCode(HttpStatus.OK)
  @Post('enroll/passkey/verify')
  async enrollPasskeyVerify(@Body() dto: EnrollPasskeyVerifyDto) {
    const userId = await this.passkeys.verifyEnrollment(
      dto.challenge,
      dto.response as unknown as RegistrationResponseJSON,
      dto.name?.trim() || 'Passkey',
    );
    return this.authService.issueSession(userId);
  }

  // ---- settings (signed in) ----------------------------------------------

  @UseGuards(JwtAuthGuard)
  @Get('2fa')
  status(@CurrentUser() user: User) {
    return this.twoFactor.getStatus(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('2fa/setup')
  setup(@CurrentUser() user: User, @Body() dto: SetupTotpDto) {
    return this.twoFactor.setupTotp(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('2fa/enable')
  async enable(@CurrentUser() user: User, @Body() dto: EnableTotpDto) {
    const recoveryCodes = await this.twoFactor.enableTotp(user.id, dto.code);
    const tokens = await this.authService.createTokenPair(user.id, user.email);
    return { recoveryCodes, ...tokens };
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('2fa/disable')
  async disable(@CurrentUser() user: User, @Body() dto: DisableTotpDto) {
    await this.twoFactor.disableTotp(user.id, dto);
    return { message: 'Two-factor turned off' };
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('2fa/recovery-codes')
  async recoveryCodes(
    @CurrentUser() user: User,
    @Body() dto: RegenerateRecoveryCodesDto,
  ) {
    return {
      recoveryCodes: await this.twoFactor.regenerateRecoveryCodes(user.id, dto),
    };
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('passkeys/register/options')
  passkeyRegisterOptions(@CurrentUser() user: User) {
    return this.passkeys.registrationOptions(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('passkeys/register/verify')
  async passkeyRegisterVerify(
    @CurrentUser() user: User,
    @Body() dto: PasskeyRegisterVerifyDto,
  ) {
    return {
      passkey: await this.passkeys.verifyRegistration(
        user.id,
        dto.challenge,
        dto.response as unknown as RegistrationResponseJSON,
        dto.name,
      ),
    };
  }

  @UseGuards(JwtAuthGuard)
  @Patch('passkeys/:id')
  async renamePasskey(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() dto: RenamePasskeyDto,
  ) {
    return { passkey: await this.passkeys.rename(user.id, id, dto.name) };
  }

  @UseGuards(JwtAuthGuard)
  @Delete('passkeys/:id')
  deletePasskey(@CurrentUser() user: User, @Param('id') id: string) {
    return this.passkeys.remove(user.id, id);
  }
}
