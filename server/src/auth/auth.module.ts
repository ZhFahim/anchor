import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
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

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
      inject: [ConfigService],
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
    OidcService,
    OidcConfigService,
    OidcClientService,
    OidcStateService,
    OidcUserService,
  ],
  exports: [AuthService, OidcConfigService, JwtModule, TokenResolverService, AuthGuard],
})
export class AuthModule { }
