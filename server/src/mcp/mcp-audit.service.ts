import { Injectable, Logger } from '@nestjs/common';

export type McpOpType =
  | 'read'
  | 'search'
  | 'history'
  | 'edit'
  | 'create'
  | 'delete'
  | 'reminder'
  | 'tag'
  | 'attachment'
  | 'other';

export type McpOpOutcome = 'ok' | 'error' | 'refused' | 'confirm_required';

export interface McpAuditRecord {
  source: 'mcp';
  user: string;
  tool: string;
  opType: McpOpType;
  noteId?: string;
  outcome: McpOpOutcome;
  authMethod: string;
  scope: string;
  timestamp: string;
}

/**
 * Metadata-only audit log for MCP tool invocations. Records who ran which
 * tool, on which note, with what outcome — never note content. Emits through
 * the same Nest Logger pipeline, tagged `source:"mcp"` so admin log filters
 * can isolate MCP activity. No DB surface (plan P-2026: log-filter only).
 */
@Injectable()
export class McpAuditService {
  private readonly logger = new Logger('mcp');

  record(rec: McpAuditRecord): void {
    // Metadata only — never include note content or tokens.
    this.logger.log(`tool_call ${JSON.stringify(rec)}`);
  }
}
