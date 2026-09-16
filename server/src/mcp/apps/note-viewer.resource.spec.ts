import {
  noteViewerResource,
  mcpAppsResources,
  buildNoteViewerHtml,
  UI_VIEWER_URI,
} from './note-viewer.resource';
import type { McpUserContext } from '../mcp-auth.context';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readOnly',
};

describe('MCP Apps note-viewer resource', () => {
  it('is registered under the ui:// scheme and text/html mime', () => {
    expect(Object.keys(mcpAppsResources)).toContain('anchor-note-viewer');
    expect(noteViewerResource.uri).toBe(UI_VIEWER_URI);
    expect(noteViewerResource.uri.startsWith('ui://')).toBe(true);
    expect(noteViewerResource.mimeType).toBe('text/html');
  });

  it('returns a self-contained HTML page with the postMessage app script', async () => {
    const result = await noteViewerResource.load(
      user,
      UI_VIEWER_URI,
      {} as never,
    );
    const html = (result.contents[0] as { text: string }).text;
    expect(html).toContain('<!doctype html>');
    expect(html).toContain('ui/initialize');
    expect(html).toContain(`tools/call`);
    expect(html).toContain('note_render');
  });

  it('builds valid, escapable note rendering markup', () => {
    const html = buildNoteViewerHtml();
    expect(html).toContain('&lt;');
  });
});
