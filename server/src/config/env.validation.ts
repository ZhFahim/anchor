import { plainToInstance, Type } from 'class-transformer';
import {
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
  validateSync,
} from 'class-validator';

export enum NodeEnv {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

export class EnvironmentVariables {
  @IsOptional()
  @IsEnum(NodeEnv)
  NODE_ENV: NodeEnv = NodeEnv.Development;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(65535)
  PORT: number = 3001;

  @IsString()
  @IsNotEmpty()
  DATABASE_URL: string;

  @IsString()
  @MinLength(16, {
    message:
      'JWT_SECRET must be at least 16 characters. Set a strong, random value.',
  })
  JWT_SECRET: string;

  @IsOptional()
  @IsString()
  APP_URL?: string;

  @IsOptional()
  @IsString()
  DATA_DIR?: string;

  @IsOptional()
  @IsString()
  CORS_ORIGINS?: string;

  @IsOptional()
  @IsIn(['disabled', 'enabled', 'review'])
  USER_SIGNUP?: string;

  @IsOptional()
  @IsString()
  OIDC_ENABLED?: string;

  @IsOptional()
  @IsString()
  OIDC_PROVIDER_NAME?: string;

  @IsOptional()
  @IsString()
  OIDC_ISSUER_URL?: string;

  @IsOptional()
  @IsString()
  OIDC_CLIENT_ID?: string;

  @IsOptional()
  @IsString()
  OIDC_CLIENT_SECRET?: string;

  @IsOptional()
  @IsString()
  DISABLE_INTERNAL_AUTH?: string;

  @IsOptional()
  @IsString()
  MCP_ENABLED?: string;

  @IsOptional()
  @IsString()
  MCP_PUBLIC_URL?: string;
}

export function validate(
  config: Record<string, unknown>,
): EnvironmentVariables {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validated, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const details = errors
      .map((error) => Object.values(error.constraints ?? {}).join(', '))
      .join('; ');
    throw new Error(`Invalid environment configuration: ${details}`);
  }

  return validated;
}
