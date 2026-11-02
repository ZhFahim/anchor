import { Controller, Get, Res } from '@nestjs/common';
import type { Response } from 'express';
import * as path from 'path';
import * as fs from 'fs';
import { SUPPORTED_PROTOCOLS } from '../common/protocol/protocol.constants';
import { SkipProtocolGate } from '../common/protocol/skip-protocol-gate.decorator';
import { HealthService } from './health.service';

@Controller('api/health')
@SkipProtocolGate()
export class HealthController {
  constructor(private readonly health: HealthService) {}

  // Always 200 while the server runs: the apps take any other answer to mean
  // the address isn't an Anchor server. Monitors use /api/health/ready.
  @Get()
  check() {
    // Read version from package.json
    // Works in both npm scripts and direct node execution (Docker)
    let version: string | undefined;
    try {
      const packageJsonPath = path.join(process.cwd(), 'package.json');
      const packageJson = JSON.parse(
        fs.readFileSync(packageJsonPath, 'utf8'),
      ) as { version?: string };
      version = packageJson.version;
    } catch {
      // Fallback to npm_package_version if package.json read fails
      version = process.env.npm_package_version;
    }

    return {
      status: 'ok',
      app: 'anchor',
      version,
      protocols: SUPPORTED_PROTOCOLS,
      // The Docker image this runs from (see the Dockerfile), when it says.
      image: process.env.ANCHOR_IMAGE || undefined,
      timestamp: new Date().toISOString(),
    };
  }

  // For uptime monitors (Uptime Kuma, Docker, load balancers): 503 when the
  // database doesn't answer, so the server can't serve notes.
  @Get('ready')
  async ready(@Res({ passthrough: true }) res: Response) {
    const database = await this.health.isDatabaseUp();
    if (!database) res.status(503);
    return {
      status: database ? 'ok' : 'error',
      database: database ? 'ok' : 'down',
    };
  }
}
