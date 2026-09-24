import { Module } from '@nestjs/common';
import { McpController } from './mcp.controller';
import { McpAuthGuard } from './mcp.controller';
import { McpAuditService } from './mcp-audit.service';
import { McpEnableService } from './mcp-enable.service';
import { NotesModule } from '../notes/notes.module';
import { AuthModule } from '../auth/auth.module';
import { TagsModule } from '../tags/tags.module';
import { PrismaModule } from '../prisma/prisma.module';

/** Advertise the MCP transport as the io.modelcontextprotocol/ui app. */
export const MCP_APPS_UI = 'io.modelcontextprotocol/ui';

@Module({
  imports: [NotesModule, AuthModule, TagsModule, PrismaModule],
  controllers: [McpController],
  providers: [McpAuthGuard, McpAuditService, McpEnableService],
})
export class McpModule {}
