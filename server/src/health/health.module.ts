import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';
import { HeartbeatService } from './heartbeat.service';

@Module({
  controllers: [HealthController],
  providers: [HealthService, HeartbeatService],
})
export class HealthModule {}
