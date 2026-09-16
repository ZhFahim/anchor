import { isMcpEnabled, parseToolsParam } from './mcp.controller';

describe('MCP controller helpers', () => {
  it('parses the ?tools= limiting param', () => {
    expect(parseToolsParam('note_get,note_search')).toEqual([
      'note_get',
      'note_search',
    ]);
    expect(parseToolsParam('')).toBeUndefined();
    expect(parseToolsParam(undefined)).toBeUndefined();
    const names = parseToolsParam('note_get,note_search,note_get');
    expect(names && names.sort()).toEqual(['note_get', 'note_search']);
  });

  it('treats the transport as enabled when MCP_ENABLED is true', () => {
    expect(isMcpEnabled('true')).toBe(true);
    expect(isMcpEnabled('false')).toBe(false);
    expect(isMcpEnabled(undefined)).toBe(false);
  });
});
