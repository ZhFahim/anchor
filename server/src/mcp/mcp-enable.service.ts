import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { McpConfig } from '../config/configuration';
import type { ConfigType } from '@nestjs/config';

/**
 * Resolves whether the MCP transport is enabled, with a 3-way priority:
 *  1. `MCP_ENABLED` env var (kill switch / hard gate) — always wins.
 *  2. `mcp_enabled` row in the Settings table (admin toggle).
 *  3. default: off.
 * Mirrors the SettingsService registration-mode pattern (env > DB > default).
 */
@Injectable()
export class McpEnableService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mcpConfig: ConfigType<typeof McpConfig>,
    /** Raw MCP_ENABLED env string; undefined means "not set". Test seam. */
    private readonly rawEnv: string | undefined = process.env.MCP_ENABLED,
  ) {}

  async isEnabled(): Promise<boolean> {
    // 1. Environment kill switch.
    if (this.rawEnv !== undefined && this.rawEnv !== '') {
      return this.mcpConfig.enabled;
    }

    // 2. DB admin toggle.
    const setting = await this.prisma.settings.findUnique({
      where: { key: 'mcp_enabled' },
    });
    if (setting) {
      return setting.value === 'true';
    }

    // 3. Default off.
    return false;
  }

  async setEnabled(enabled: boolean): Promise<void> {
    await this.prisma.settings.upsert({
      where: { key: 'mcp_enabled' },
      update: { value: String(enabled) },
      create: { key: 'mcp_enabled', value: String(enabled) },
    });
  }
}
