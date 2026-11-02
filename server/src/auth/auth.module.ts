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
import { MagicLoginService } from './magic-login.service';
import { SettingsModule } from '../settings/settings.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OidcService } from './oidc/oidc.service';
import { OidcController } from './oidc/oidc.controller';
import { OidcConfigService } from './oidc/oidc-config.service';
import { OidcClientService } from './oidc/oidc-client.service';
import { OidcStateService } from './oidc/oidc-state.service';
import { OidcUserService } from './oidc/oidc-user.service';

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
  controllers: [AuthController, OidcController],
  providers: [
    AuthService,
    JwtStrategy,
    TokenResolverService,
    AuthGuard,
    MagicLoginService,
    OidcService,
    OidcConfigService,
    OidcClientService,
    OidcStateService,
    OidcUserService,
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
