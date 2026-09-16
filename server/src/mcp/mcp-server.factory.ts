import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z, type ZodTypeAny } from 'zod';
import { tools as registeredTools } from './tools/tools';
import type { McpServices } from './tools/tools';
import { getMcpUser, type McpUserContext } from './mcp-auth.context';
import { mcpResources } from './resources/resources';
import { mcpAppsResources } from './apps/note-viewer.resource';
import { mcpPrompts } from './prompts/prompts';
import type { McpAuditRecord } from './mcp-audit.service';

export type McpAuditSink = (rec: McpAuditRecord) => void;

export const MCP_SERVER_INSTRUCTIONS = `Anchor notes MCP.

Read operations are cheap and prefer narrow modes: use note_get summary unless you need full Delta content, and prefer note_search with filters to browsing resources.

Edits go through the notes revision/conflict net: note_edit with baseVersion is optimistic-concurrency safe. note_history restore is the undo path for any note_edit mistake.

Resources give you ids and metadata only; call tools for detail and for any action.`;

export function createMcpServer(
  services: McpServices,
  visibleTools?: string[],
  audit?: McpAuditSink,
  includeAppTools = false,
): McpServer {
  const server = new McpServer(
    {
      name: 'anchor-mcp-server',
      version: '1.0.0',
    },
    {
      instructions: MCP_SERVER_INSTRUCTIONS,
    },
  );

  // Resources (directory catalog + on-demand fetch). Every resource resolves
  // the current user from the auth storage so it stays scoped to the caller.
  const allResources = {
    ...mcpResources,
    // The embedded MCP-apps UI (ui://) is only advertised when the transport
    // opts in (?app=1); it returns a self-contained HTML viewer.
    ...(includeAppTools ? mcpAppsResources : {}),
  };
  for (const resource of Object.values(allResources)) {
    server.registerResource(
      resource.name,
      resource.uri,
      {
        description: resource.description,
        mimeType: resource.mimeType,
      },
      async (uri) => {
        const user = requireAuth();
        return resource.load(user, uri.toString(), services);
      },
    );
  }

  // Prompts: orchestration only (P9).
  for (const prompt of Object.values(mcpPrompts)) {
    server.registerPrompt(
      prompt.name,
      {
        title: prompt.title,
        description: prompt.description,
        argsSchema: {
          topic: z.string().optional(),
          focus: z.string().optional(),
        },
      },
      async (args) => {
        const text = await prompt.build(
          (args ?? {}) as Record<string, string>,
          services,
        );
        return {
          description: prompt.title,
          messages: [
            {
              role: 'user',
              content: {
                type: 'text',
                text,
              },
            },
          ],
        };
      },
    );
  }

  const names = visibleTools?.length ? new Set(visibleTools) : undefined;

  for (const tool of Object.values(registeredTools)) {
    if (names && !names.has(tool.name)) continue;
    // App-only tools feed the embedded rendering bundle; hide them from normal
    // LLM clients unless the transport explicitly opts in (plan P5/P10).
    if (tool.visibility === 'app' && !includeAppTools) continue;
    server.registerTool(
      tool.name,
      {
        title: tool.title,
        description: tool.description,
        inputSchema: toolSchema(tool.name),
        annotations: {
          readOnlyHint: tool.readOnlyHint,
          destructiveHint: false,
          idempotentHint: tool.name !== 'note_edit',
        },
        // MCP Apps extension: point hosts at the embedded UI resource so they
        // can render the app in a sandboxed iframe (plan P7/P10).
        ...(tool.visibility === 'app' && includeAppTools
          ? {
              _meta: {
                ui: { resourceUri: 'ui://anchor/note-viewer' },
              },
            }
          : {}),
      },
      async (params) => {
        const user = requireAuth();
        const paramsObject = params as Record<string, unknown>;
        const noteId = paramsObject.noteId;
        const action = paramsObject.action;
        const readOnly =
          tool.readOnlyHint ||
          (!!tool.readOnlyActions &&
            typeof action === 'string' &&
            tool.readOnlyActions.includes(action));
        const outcome = () => {
          if (refusedForReadOnly(readOnly, user.scope)) {
            return 'refused' as const;
          }
          return undefined;
        };

        if (audit) {
          audit({
            source: 'mcp',
            user: user.userId,
            tool: tool.name,
            opType: opTypeOf(tool.name),
            noteId: typeof noteId === 'string' ? noteId : undefined,
            outcome: outcome() ?? 'ok',
            authMethod: user.authMethod,
            scope: user.scope,
            timestamp: new Date().toISOString(),
          });
        }

        if (refusedForReadOnly(readOnly, user.scope)) {
          return {
            content: [
              {
                type: 'text',
                text: `Refused: your API token is read-only. Use a read-write token to run this ${tool.name} action.`,
              },
            ],
            isError: true,
          };
        }
        if (tool.confirmRequired && paramsObject.confirm !== true) {
          const name2 = tool.name;
          audit?.({
            source: 'mcp',
            user: user.userId,
            tool: name2,
            opType: opTypeOf(name2),
            noteId:
              typeof paramsObject.noteId === 'string'
                ? paramsObject.noteId
                : undefined,
            outcome: 'confirm_required',
            authMethod: user.authMethod,
            scope: user.scope,
            timestamp: new Date().toISOString(),
          });
          return {
            content: [
              {
                type: 'text',
                text: `${name2} is unrecoverable and requires explicit confirmation. Retry with "confirm": true to proceed.`,
              },
            ],
            isError: true,
          };
        }
        const result = await tool.run(
          user,
          params as Record<string, unknown>,
          services,
        );
        return {
          content: result.content,
          ...(result.structuredContent !== undefined
            ? { structuredContent: result.structuredContent }
            : {}),
          ...(result.isError ? { isError: true } : {}),
        };
      },
    );
  }

  return server;
}

function toolSchema(name: string): ZodTypeAny {
  const fields: Record<string, ZodTypeAny> = {};
  const def = registeredTools[name];
  const shape = def?.inputShape ?? {};
  for (const [key, desc] of Object.entries(shape)) {
    const optional = /\(optional\)/.test(desc);
    let field: ZodTypeAny = z.string().describe(desc.trim());
    if (key === 'limit' || key === 'baseVersion') {
      field = z.number().describe(desc.trim());
    }
    if (
      key === 'noteId' ||
      key === 'query' ||
      key === 'title' ||
      key === 'content'
    ) {
      field = z.string().describe(desc.trim());
    }
    if (key === 'mode') {
      field = z.enum(['summary', 'full']).describe(desc.trim());
    }
    if (key === 'confirm') {
      field = z
        .literal(true)
        .describe('Explicit confirmation for unrecoverable actions.');
    }
    if (key === 'edit_op') {
      field = z
        .object({
          op: z.enum([
            'append_line',
            'insert_after_line',
            'replace_line',
            'delete_line',
            'check_item',
          ]),
          line: z.number().int().min(1).optional(),
          text: z.string().optional(),
          checked: z.boolean().optional(),
        })
        .describe(desc.trim());
    }
    fields[key] = optional ? field.optional() : field;
  }
  return z.object(fields).strict();
}

function requireAuth(): McpUserContext {
  const user = getMcpUser();
  if (!user) {
    throw new Error('MCP request is not authenticated');
  }
  return user;
}

/**
 * True when a mutating tool must be refused for a read-only API token.
 */
export const refusedForReadOnly = (
  readOnlyHint: boolean,
  scope: string,
): boolean => !readOnlyHint && scope === 'readOnly';

const opTypeOf = (tool: string): McpAuditRecord['opType'] => {
  if (tool.startsWith('note_edit')) return 'edit';
  if (tool.startsWith('note_search')) return 'search';
  if (tool.startsWith('note_history')) return 'history';
  if (tool.startsWith('note_reminders')) return 'reminder';
  if (tool.startsWith('tag_')) return 'tag';
  return 'read';
};
