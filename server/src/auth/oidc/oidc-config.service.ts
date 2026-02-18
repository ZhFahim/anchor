import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import type { OidcConfig } from './oidc.types';

@Injectable()
export class OidcConfigService {
  private readonly logger = new Logger(OidcConfigService.name);

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) { }

  /**
   * Check if OIDC is locked by environment variables.
   */
  private isLockedByEnv(): boolean {
    const oidcEnabled = this.configService.get<string>('OIDC_ENABLED');
    const issuerUrl = this.configService.get<string>('OIDC_ISSUER_URL');
    const clientId = this.configService.get<string>('OIDC_CLIENT_ID');
    return oidcEnabled !== undefined && !!issuerUrl && !!clientId;
  }

  /**
   * Get OIDC configuration.
   */
  async getConfig(): Promise<OidcConfig> {
    if (this.isLockedByEnv()) {
      return this.getConfigFromEnv();
    }
    return this.getConfigFromDb();
  }

  private getConfigFromEnv(): OidcConfig {
    const enabled = this.getBooleanEnv('OIDC_ENABLED', false) ?? false;

    if (!enabled) {
      return {
        enabled: false,
        providerName: 'OIDC Provider',
        disableInternalAuth: false,
      };
    }

    const issuerUrl = this.configService.get<string>('OIDC_ISSUER_URL')!;
    const clientId = this.configService.get<string>('OIDC_CLIENT_ID')!;
    const clientSecret = this.configService.get<string>('OIDC_CLIENT_SECRET');
    const providerName =
      this.configService.get<string>('OIDC_PROVIDER_NAME') || 'OIDC Provider';
    const disableInternalAuth =
      this.getBooleanEnv('DISABLE_INTERNAL_AUTH', false) ?? false;

    return {
      enabled: true,
      providerName,
      issuerUrl,
      clientId,
      clientSecret,
      disableInternalAuth,
    };
  }

  private async getConfigFromDb(): Promise<OidcConfig> {
    const dbSettings = await this.getDbSettings([
      'oidc_enabled',
      'oidc_provider_name',
      'oidc_issuer_url',
      'oidc_client_id',
      'oidc_client_secret',
      'oidc_disable_internal_auth',
    ]);

    const enabled =
      dbSettings.get('oidc_enabled')?.toLowerCase() === 'true' || false;

    if (!enabled) {
      return {
        enabled: false,
        providerName: 'OIDC Provider',
        disableInternalAuth: false,
      };
    }

    const issuerUrl = dbSettings.get('oidc_issuer_url');
    const clientId = dbSettings.get('oidc_client_id');

    if (!issuerUrl || !clientId) {
      this.logger.warn(
        'OIDC is enabled in database but missing issuer URL or client ID',
      );
    }

    const providerName =
      dbSettings.get('oidc_provider_name') || 'OIDC Provider';
    const clientSecret = dbSettings.get('oidc_client_secret');
    const disableInternalAuth =
      dbSettings.get('oidc_disable_internal_auth')?.toLowerCase() === 'true' ||
      false;

    return {
      enabled: true,
      providerName,
      issuerUrl,
      clientId,
      clientSecret,
      disableInternalAuth,
    };
  }

  /**
   * Get application base URL (for redirects and callback URL).
   * Used by OIDC callback URL, frontend redirects, and redirect validation.
   */
  getAppUrl(): string {
    return this.configService.get<string>('APP_URL') || 'http://localhost:3000';
  }

  /**
   * Check if OIDC is enabled
   */
  async isEnabled(): Promise<boolean> {
    const config = await this.getConfig();
    return config.enabled && !!config.issuerUrl && !!config.clientId;
  }

  /**
   * Get public OIDC config
   */
  async getPublicConfig(): Promise<{
    enabled: boolean;
    providerName: string;
    issuerUrl?: string;
    clientId?: string;
    disableInternalAuth: boolean;
  }> {
    const config = await this.getConfig();
    return {
      enabled: config.enabled && !!config.issuerUrl && !!config.clientId,
      providerName: config.providerName,
      issuerUrl: config.issuerUrl,
      clientId: config.clientId,
      disableInternalAuth: config.disableInternalAuth,
    };
  }

  /**
   * Get OIDC settings for admin UI
   */
  async getOidcSettings(): Promise<{
    enabled: boolean;
    providerName: string;
    issuerUrl?: string;
    clientId?: string;
    hasClientSecret: boolean;
    disableInternalAuth: boolean;
    isLocked: boolean;
    source: 'env' | 'database' | 'default';
  }> {
    const config = await this.getConfig();
    const locked = this.isLockedByEnv();

    return {
      enabled: config.enabled,
      providerName: config.providerName,
      issuerUrl: config.issuerUrl,
      clientId: config.clientId,
      hasClientSecret: !!config.clientSecret,
      disableInternalAuth: config.disableInternalAuth,
      isLocked: locked,
      source: locked ? 'env' : 'database',
    };
  }

  /**
   * Set OIDC settings (only if not locked by env mode)
   */
  async setOidcSettings(settings: {
    enabled?: boolean;
    providerName?: string;
    issuerUrl?: string;
    clientId?: string;
    clientSecret?: string;
    disableInternalAuth?: boolean;
  }): Promise<void> {
    if (this.isLockedByEnv()) {
      throw new Error(
        'OIDC settings are locked by environment variables. Remove OIDC_ENABLED, OIDC_ISSUER_URL and OIDC_CLIENT_ID to manage from UI.',
      );
    }

    // Update database settings
    if (settings.enabled !== undefined) {
      await this.setDbSetting('oidc_enabled', settings.enabled.toString());
    }
    if (settings.providerName !== undefined) {
      await this.setDbSetting('oidc_provider_name', settings.providerName);
    }
    if (settings.issuerUrl !== undefined) {
      await this.setDbSetting('oidc_issuer_url', settings.issuerUrl);
    }
    if (settings.clientId !== undefined) {
      await this.setDbSetting('oidc_client_id', settings.clientId);
    }
    if (settings.clientSecret !== undefined) {
      await this.setDbSetting('oidc_client_secret', settings.clientSecret);
    }
    if (settings.disableInternalAuth !== undefined) {
      await this.setDbSetting(
        'oidc_disable_internal_auth',
        String(settings.disableInternalAuth),
      );
    }
  }

  private getBooleanEnv(
    key: string,
    defaultValue?: boolean,
  ): boolean | undefined {
    const value = this.configService.get<string>(key);
    if (value === undefined) {
      return defaultValue;
    }
    return value.toLowerCase() === 'true';
  }

  /**
   * Fetch multiple settings from database in a single query
   */
  private async getDbSettings(keys: string[]): Promise<Map<string, string>> {
    try {
      const settings = await this.prisma.settings.findMany({
        where: {
          key: {
            in: keys,
          },
        },
      });

      const settingsMap = new Map<string, string>();
      for (const setting of settings) {
        settingsMap.set(setting.key, setting.value);
      }

      return settingsMap;
    } catch (error) {
      this.logger.warn(`Failed to get DB settings:`, error);
      return new Map();
    }
  }

  private async setDbSetting(key: string, value: string): Promise<void> {
    await this.prisma.settings.upsert({
      where: { key },
      update: { value },
      create: { key, value },
    });
  }
}
