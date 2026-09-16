import {
  noteViewerResource,
  mcpAppsResources,
  fetchViewerHtml,
  clearViewerCache,
  UI_VIEWER_URI,
} from './note-viewer.resource';
import type { McpUserContext } from '../mcp-auth.context';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readOnly',
};

describe('MCP Apps note-viewer resource', () => {
  beforeEach(() => clearViewerCache());
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('is registered under the ui:// scheme and text/html mime', () => {
    expect(Object.keys(mcpAppsResources)).toContain('anchor-note-viewer');
    expect(noteViewerResource.uri).toBe(UI_VIEWER_URI);
    expect(noteViewerResource.uri.startsWith('ui://')).toBe(true);
    expect(noteViewerResource.mimeType).toBe('text/html');
  });

  it('serves the SSR viewer HTML fetched from the web app', async () => {
    const html = '<!doctype html><html><body>SSR viewer</body></html>';
    const fetchSpy = jest
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(new Response(html, { status: 200 }));

    const result = await noteViewerResource.load(user, UI_VIEWER_URI, {
      baseUrl: 'https://notes.example.com',
    } as never);
    const text = (result.contents[0] as { text: string }).text;
    expect(text).toContain('SSR viewer');
    expect(fetchSpy).toHaveBeenCalledWith(
      'https://notes.example.com/mcp-app/note-viewer',
      expect.anything(),
    );
  });

  it('throws when the viewer route is unavailable', async () => {
    jest
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(new Response('nope', { status: 500 }));
    await expect(
      fetchViewerHtml('https://notes.example.com'),
    ).rejects.toThrow();
  });
});
