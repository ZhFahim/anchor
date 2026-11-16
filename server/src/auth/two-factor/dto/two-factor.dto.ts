import {
  IsIn,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';
import {
  TWO_FACTOR_POLICIES,
  type TwoFactorPolicy,
} from '../two-factor.constants';

export class ChallengeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  challenge: string;
}

export class LoginTwoFactorDto extends ChallengeDto {
  @IsOptional()
  @IsString()
  @MaxLength(32)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  recoveryCode?: string;
}

export class EnrollEnableDto extends ChallengeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  code: string;
}

export class EnrollPasskeyVerifyDto extends ChallengeDto {
  @IsObject()
  response: Record<string, unknown>;

  @IsOptional()
  @IsString()
  @Length(1, 60)
  name?: string;
}

export class SetupTotpDto {
  @IsOptional()
  @IsString()
  @MaxLength(32)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  recoveryCode?: string;
}

export class EnableTotpDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  code: string;
}

export class DisableTotpDto {
  @IsString()
  @IsNotEmpty()
  password: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  recoveryCode?: string;
}

export class RegenerateRecoveryCodesDto {
  @IsString()
  @IsNotEmpty()
  password: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  code: string;
}

export class PasskeyRegisterVerifyDto extends ChallengeDto {
  @IsObject()
  response: Record<string, unknown>;

  @IsString()
  @Length(1, 60)
  name: string;
}

export class RenamePasskeyDto {
  @IsString()
  @Length(1, 60)
  name: string;
}

export class PasskeyLoginVerifyDto extends ChallengeDto {
  @IsObject()
  response: Record<string, unknown>;
}

export class UpdateTwoFactorPolicyDto {
  @IsIn(TWO_FACTOR_POLICIES)
  policy: TwoFactorPolicy;
}
