import { McpAuditService, type McpAuditRecord } from './mcp-audit.service';

type Logger = {
  log: jest.MockedFunction<(message: string) => void>;
  error: jest.MockedFunction<(message: string) => void>;
  warn: jest.MockedFunction<(message: string) => void>;
};
type WithLogger = { logger: Logger };

describe('McpAuditService', () => {
  let service: McpAuditService;
  let logger: Logger;

  beforeEach(() => {
    service = new McpAuditService();
    logger = {
      log: jest.fn() as jest.MockedFunction<(message: string) => void>,
      error: jest.fn() as jest.MockedFunction<(message: string) => void>,
      warn: jest.fn() as jest.MockedFunction<(message: string) => void>,
    };
    (service as unknown as WithLogger).logger = logger;
  });

  it('emits a structured, metadata-only record through logger.log', () => {
    const rec: McpAuditRecord = {
      source: 'mcp',
      user: 'u1',
      tool: 'note_edit',
      opType: 'edit',
      noteId: 'n1',
      outcome: 'ok',
      authMethod: 'apiToken',
      scope: 'readWrite',
      timestamp: '2026-01-01T00:00:00.000Z',
    };
    service.record(rec);

    expect(logger.log).toHaveBeenCalled();
    const call = logger.log.mock.calls[0];
    const logged = call ? String(call[0]) : '';
    expect(logged).toContain('tool_call');
    const parsed = JSON.parse(logged.replace('tool_call ', '')) as Record<
      string,
      string
    >;
    expect(parsed.source).toBe('mcp');
    expect(parsed.tool).toBe('note_edit');
    expect(parsed.noteId).toBe('n1');
  });
});
