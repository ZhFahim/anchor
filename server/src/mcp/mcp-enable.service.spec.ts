import { McpEnableService } from './mcp-enable.service';

type PrismaLike = {
  settings: {
    findUnique: jest.Mock;
  };
};

describe('McpEnableService', () => {
  let prisma: PrismaLike;
  let service: McpEnableService;

  const build = (
    envEnabled: string | undefined,
    rawEnv: string | undefined,
  ) => {
    prisma = {
      settings: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    service = new McpEnableService(
      { settings: prisma.settings } as never,
      { enabled: envEnabled === 'true' } as never,
      rawEnv,
    );
  };

  it('is disabled by default (no env, no DB setting)', async () => {
    build(undefined, undefined);
    await expect(service.isEnabled()).resolves.toBe(false);
  });

  it('follows the MCP_ENABLED env var when set', async () => {
    build('true', 'true');
    await expect(service.isEnabled()).resolves.toBe(true);
  });

  it('falls back to the DB setting when no env var is set', async () => {
    build(undefined, undefined);
    prisma.settings.findUnique.mockResolvedValue({
      key: 'mcp_enabled',
      value: 'true',
    });
    await expect(service.isEnabled()).resolves.toBe(true);
  });

  it('env var overrides the DB setting', async () => {
    build('false', 'false');
    prisma.settings.findUnique.mockResolvedValue({
      key: 'mcp_enabled',
      value: 'true',
    });
    await expect(service.isEnabled()).resolves.toBe(false);
  });
});
