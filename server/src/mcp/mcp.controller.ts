import {
  CanActivate,
  Controller,
  ExecutionContext,
  Injectable,
  Post,
  Req,
  Res,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { ExtractJwt } from 'passport-jwt';
import { TokenResolverService } from '../auth/token-resolver.service';
import { NotesService } from '../notes/services/notes.service';
import { NoteHistoryService } from '../notes/services/note-history.service';
import { NoteAttachmentsService } from '../notes/services/note-attachments.service';
import { TagsService } from '../tags/tags.service';
import { mcpAuthStorage } from './mcp-auth.context';
import type { McpUserContext } from './mcp-auth.context';
import { createMcpServer } from './mcp-server.factory';
import { McpAuditService } from './mcp-audit.service';
import { McpEnableService } from './mcp-enable.service';
import { AppConfig } from '../config/configuration';
import type { ConfigType } from '@nestjs/config';
import { Inject } from '@nestjs/common';
import { UserStatus } from '../generated/prisma/enums';

export const parseToolsParam = (
  raw: string | undefined | null,
): string[] | undefined => {
  if (!raw) return undefined;
  const names = raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return names.length ? [...new Set(names)] : undefined;
};

export const isMcpEnabled = (v: string | undefined): boolean => v === 'true';

const bearerToken = ExtractJwt.fromAuthHeaderAsBearerToken();

/**
 * MCP transport guard: authenticates the bearer session JWT or API token and
 * loads the per-request MCP auth context so tools resolve the current user.
 */
@Injectable()
export class McpAuthGuard implements CanActivate {
  constructor(private readonly tokenResolver: TokenResolverService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const token = bearerToken(req);
    if (!token) {
      throw new UnauthorizedException('Missing authentication token');
    }
    const user = await this.tokenResolver.resolveUser(token);
    if (!user) {
      throw new UnauthorizedException('Invalid authentication token');
    }
    if (user.status !== UserStatus.active) {
      throw new UnauthorizedException('Account pending approval');
    }
    (req as unknown as { mcpUser: unknown }).mcpUser = {
      userId: user.id,
      authMethod: user.authMethod,
      scope: user.apiTokenScope,
    };
    return true;
  }
}

@Controller('mcp')
@UseGuards(McpAuthGuard)
export class McpController {
  constructor(
    private readonly notes: NotesService,
    private readonly history: NoteHistoryService,
    private readonly attachments: NoteAttachmentsService,
    private readonly tags: TagsService,
    private readonly audit: McpAuditService,
    private readonly mcpEnable: McpEnableService,
    @Inject(AppConfig.KEY)
    private readonly appConfig: ConfigType<typeof AppConfig>,
  ) {}

  @Post()
  async handle(@Req() req: Request, @Res() res: Response): Promise<void> {
    const enabled = await this.mcpEnable.isEnabled();
    if (!enabled) {
      res.status(404).json({ message: 'MCP is not enabled' });
      return;
    }

    const user = (req as unknown as { mcpUser: McpUserContext }).mcpUser;
    if (!user) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const tools = parseToolsParam(
      Array.isArray(req.query.tools)
        ? undefined
        : (req.query.tools as string | undefined),
    );

    // The embedded MCP-apps bundle requests app-only tools via ?app=1 so note
    // content reaches the UI for faithful rendering, without leaking it to the
    // LLM unless it explicitly asks (plan P10).
    const includeAppTools = req.query.app === '1';

    const server = createMcpServer(
      {
        notes: this.notes,
        history: this.history,
        attachments: this.attachments,
        tags: this.tags,
        baseUrl: this.appConfig.appUrl,
      },
      tools,
      (rec) => this.audit.record(rec),
      includeAppTools,
    );

    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true,
    });

    res.on('close', () => {
      void transport.close();
    });

    await mcpAuthStorage.run(user, async () => {
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    });
  }
}
