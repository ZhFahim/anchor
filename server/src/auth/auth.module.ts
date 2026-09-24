import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, type ConfigType } from '@nestjs/config';
import { AuthConfig } from '../config/configuration';
import { ACCESS_TOKEN_TTL } from './constants/auth.constants';
import { JwtStrategy } from './jwt.strategy';
import { TokenResolverService } from './token-resolver.service';
import { AuthGuard } from './auth.guard';
import { SettingsModule } from '../settings/settings.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OidcService } from './oidc/oidc.service';
import { OidcController } from './oidc/oidc.controller';
import { OidcConfigService } from './oidc/oidc-config.service';
import { OidcClientService } from './oidc/oidc-client.service';
import { OidcStateService } from './oidc/oidc-state.service';
import { OidcUserService } from './oidc/oidc-user.service';
import { OAuthController } from './oauth/oauth.controller';
import { OAuthMetadataService } from './oauth/oauth-metadata.service';
import { OAuthTokenService } from './oauth/oauth-token.service';
import { OAuthCodeStore } from './oauth/oauth-code.store';
import { OAuthClientService } from './oauth/oauth-client.service';
import { OAuthAuthorizeService } from './oauth/oauth-authorize.service';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (authConfig: ConfigType<typeof AuthConfig>) => ({
        secret: authConfig.jwtSecret,
        signOptions: { expiresIn: ACCESS_TOKEN_TTL },
      }),
      inject: [AuthConfig.KEY],
    }),
    SettingsModule,
    PrismaModule,
  ],
  controllers: [AuthController, OidcController, OAuthController],
  providers: [
    AuthService,
    JwtStrategy,
    TokenResolverService,
    AuthGuard,
    OidcService,
    OidcConfigService,
    OidcClientService,
    OidcStateService,
    OidcUserService,
    OAuthMetadataService,
    OAuthTokenService,
    OAuthCodeStore,
    OAuthClientService,
    OAuthAuthorizeService,
  ],
  exports: [
    AuthService,
    OidcConfigService,
    JwtModule,
    TokenResolverService,
    AuthGuard,
  ],
})
export class AuthModule {}
