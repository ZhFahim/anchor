import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
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
  // The embedded MCP-apps UI (ui://) is always advertised; it is a static
  // viewer shell and leaks no note content on its own. The app fetches content
  // through the app-only note_render tool.
  const allResources = {
    ...mcpResources,
    ...mcpAppsResources,
  };
  for (const resource of Object.values(allResources)) {
    const metadata = {
      description: resource.description,
      mimeType: resource.mimeType,
    };
    // A URI with `{var}` placeholders must be registered as a ResourceTemplate
    // so templated reads (anchor://notes/<id>) resolve; a literal string is
    // registered as a fixed resource and would 404 on any concrete id.
    if (resource.uri.includes('{')) {
      server.registerResource(
        resource.name,
        new ResourceTemplate(resource.uri, { list: undefined }),
        metadata,
        async (uri) => {
          const user = requireAuth();
          return resource.load(user, uri.toString(), services);
        },
      );
    } else {
      server.registerResource(
        resource.name,
        resource.uri,
        metadata,
        async (uri) => {
          const user = requireAuth();
          return resource.load(user, uri.toString(), services);
        },
      );
    }
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
    server.registerTool(
      tool.name,
      {
        title: tool.title,
        description: tool.description,
        inputSchema: toolSchema(tool.name),
        annotations: {
          readOnlyHint: tool.readOnlyHint,
          destructiveHint: tool.destructive ?? false,
          idempotentHint: tool.name !== 'note_edit',
        },
        // MCP Apps extension: the embedded viewer is discovered via a DEFAULT
        // tool (note_get) so normal hosts see it. App-only tools (note_render)
        // carry `ui.visibility: ['app']` so they are hidden from the model but
        // remain callable from inside the app iframe.
        ...(tool.name === 'note_get'
          ? { _meta: { ui: { resourceUri: 'ui://anchor/note-viewer' } } }
          : {}),
        ...(tool.visibility === 'app'
          ? { _meta: { ui: { visibility: ['app'] } } }
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

        const record = (outcome: McpAuditRecord['outcome']) => {
          audit?.({
            source: 'mcp',
            user: user.userId,
            tool: tool.name,
            opType: opTypeOf(tool.name),
            noteId: typeof noteId === 'string' ? noteId : undefined,
            outcome,
            authMethod: user.authMethod,
            scope: user.scope,
            timestamp: new Date().toISOString(),
          });
        };

        if (refusedForReadOnly(readOnly, user.scope)) {
          record('refused');
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
          record('confirm_required');
          return {
            content: [
              {
                type: 'text',
                text: `${tool.name} is unrecoverable and requires explicit confirmation. Retry with "confirm": true to proceed.`,
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
        // Audit after execution so refusals/errors raised inside the tool are
        // classified correctly (the tool owns the confirm contract).
        record(result.isError ? 'error' : 'ok');
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
  if (tool === 'note_edit') return 'edit';
  if (tool === 'note_search') return 'search';
  if (tool === 'note_history') return 'history';
  if (tool === 'note_reminders') return 'reminder';
  if (tool === 'note_attachments') return 'attachment';
  if (tool === 'tag_manage') return 'tag';
  return 'read';
};
