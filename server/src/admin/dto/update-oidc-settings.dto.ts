import { IsBoolean, IsOptional, IsString, IsUrl } from 'class-validator';
import { RejectUnknownFields } from '../../common/decorators/reject-unknown-fields.decorator';

@RejectUnknownFields()
export class UpdateOidcSettingsDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsString()
  providerName?: string;

  @IsOptional()
  @IsUrl({
    protocols: ['http', 'https'],
    require_protocol: true,
    require_tld: false,
  })
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
