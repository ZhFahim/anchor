import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PrismaModule } from '../prisma/prisma.module';
import { SettingsModule } from '../settings/settings.module';
import { AuthModule } from '../auth/auth.module';
import { McpEnableService } from '../mcp/mcp-enable.service';

@Module({
  imports: [PrismaModule, SettingsModule, AuthModule],
  controllers: [AdminController],
  providers: [AdminService, McpEnableService],
})
export class AdminModule {}
