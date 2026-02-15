import { IsBoolean, IsOptional, IsString, IsUrl } from 'class-validator';

export class UpdateOidcSettingsDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsString()
  providerName?: string;

  @IsOptional()
  @IsUrl()
  issuerUrl?: string;

  @IsOptional()
  @IsString()
  clientId?: string;

  @IsOptional()
  @IsString()
  clientSecret?: string;

  @IsOptional()
  @IsBoolean()
  clearClientSecret?: boolean;

  @IsOptional()
  @IsBoolean()
  disableInternalAuth?: boolean;
}
