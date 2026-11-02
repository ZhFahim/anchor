import {
  Inject,
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnApplicationShutdown,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { MonitoringConfig } from '../config/configuration';
import { HealthService } from './health.service';

const HEARTBEAT_TIMEOUT_MS = 10000;

/**
 * Calls HEARTBEAT_URL every HEARTBEAT_INTERVAL seconds while the server and
 * its database work: an Uptime Kuma push monitor, a Healthchecks.io check or
 * the like then reports the server down when the calls stop, also when it
 * can't reach the server itself, e.g. one at home behind a router.
 */
@Injectable()
export class HeartbeatService
  implements OnApplicationBootstrap, OnApplicationShutdown
{
  private readonly logger = new Logger(HeartbeatService.name);
  private timer?: NodeJS.Timeout;

  constructor(
    @Inject(MonitoringConfig.KEY)
    private readonly config: ConfigType<typeof MonitoringConfig>,
    private readonly health: HealthService,
  ) {}

  onApplicationBootstrap() {
    if (!this.config.heartbeatUrl) return;
    this.logger.log(
      `Sending a heartbeat every ${this.config.heartbeatInterval}s`,
    );
    void this.beat();
    this.timer = setInterval(
      () => void this.beat(),
      this.config.heartbeatInterval * 1000,
    );
  }

  onApplicationShutdown() {
    clearInterval(this.timer);
  }

  async beat(): Promise<void> {
    const url = this.config.heartbeatUrl;
    if (!url) return;
    if (!(await this.health.isDatabaseUp())) {
      this.logger.warn('No heartbeat sent: the database does not answer');
      return;
    }
    try {
      const res = await fetch(url, {
        signal: AbortSignal.timeout(HEARTBEAT_TIMEOUT_MS),
      });
      if (!res.ok) {
        this.logger.warn(`The heartbeat URL answered ${res.status}`);
      }
    } catch (error) {
      this.logger.warn(
        `Sending the heartbeat failed: ${(error as Error).message}`,
      );
    }
  }
}
