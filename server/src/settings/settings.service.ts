import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';

export type RegistrationMode = 'disabled' | 'enabled' | 'review';

@Injectable()
export class SettingsService {
  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {}

  /**
   * Get the current registration mode.
   * Priority: env var > DB setting > default "enabled"
   */
  async getRegistrationMode(): Promise<RegistrationMode> {
    // Check environment variable first
    const envMode = this.configService.get<string>('USER_SIGNUP');
    if (envMode && ['disabled', 'enabled', 'review'].includes(envMode)) {
      return envMode as RegistrationMode;
    }

    // Check database setting
    const setting = await this.prisma.settings.findUnique({
      where: { key: 'user_signup' },
    });

    if (setting) {
      return setting.value as RegistrationMode;
    }

    // Default to enabled
    return 'enabled';
  }

  /**
   * Check if registration mode is locked by environment variable
   */
  isRegistrationModeLocked(): boolean {
    const envMode = this.configService.get<string>('USER_SIGNUP');
    return !!envMode && ['disabled', 'enabled', 'review'].includes(envMode);
  }

  /**
   * Get registration settings including lock status and source
   */
  async getRegistrationSettings(): Promise<{
    mode: RegistrationMode;
    isLocked: boolean;
    source: 'env' | 'database' | 'default';
  }> {
    const envMode = this.configService.get<string>('USER_SIGNUP');
    const isLocked =
      !!envMode && ['disabled', 'enabled', 'review'].includes(envMode);

    if (isLocked) {
      return {
        mode: envMode as RegistrationMode,
        isLocked: true,
        source: 'env',
      };
    }

    const setting = await this.prisma.settings.findUnique({
      where: { key: 'user_signup' },
    });

    if (setting) {
      return {
        mode: setting.value as RegistrationMode,
        isLocked: false,
        source: 'database',
      };
    }

    return {
      mode: 'enabled',
      isLocked: false,
      source: 'default',
    };
  }

  /**
   * Set registration mode (only works if not locked by env)
   */
  async setRegistrationMode(mode: RegistrationMode): Promise<void> {
    if (this.isRegistrationModeLocked()) {
      throw new ForbiddenException(
        'Registration mode is locked by USER_SIGNUP environment variable',
      );
    }

    if (!['disabled', 'enabled', 'review'].includes(mode)) {
      throw new Error('Invalid registration mode');
    }

    // Upsert the setting
    await this.prisma.settings.upsert({
      where: { key: 'user_signup' },
      update: { value: mode },
      create: {
        key: 'user_signup',
        value: mode,
      },
    });
  }
}
