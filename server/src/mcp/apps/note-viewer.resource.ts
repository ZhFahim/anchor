import type { ReadResourceResult } from '@modelcontextprotocol/sdk/types.js';
import type { McpServices } from '../tools/tools';
import type { McpUserContext } from '../mcp-auth.context';

/**
 * MCP Apps `ui://` resource (plan P7/P10 / MCP Apps extension).
 *
 * Instead of hand-written inline HTML, the viewer page is rendered by the web
 * app (Next.js) at `${baseUrl}/mcp-app/note-viewer` from the shared React
 * components — one source of truth for presentation (JSX + type safety). This
 * resource SSR-fetches that page and serves it to the host, caching briefly so
 * a burst of reads doesn't hammer the web app.
 */

export const UI_VIEWER_URI = 'ui://anchor/note-viewer';
const VIEWER_PATH = '/mcp-app/note-viewer';
const CACHE_TTL_MS = 60_000;

let cached: { html: string; at: number } | null = null;

/** Clear the viewer HTML cache (tests / manual refresh). */
export function clearViewerCache(): void {
  cached = null;
}

/** Fetch (and cache) the SSR viewer HTML from the web app. */
export async function fetchViewerHtml(baseUrl: string): Promise<string> {
  const now = Date.now();
  if (cached && now - cached.at < CACHE_TTL_MS) {
    return cached.html;
  }
  const base = (baseUrl || '').replace(/\/+$/, '');
  const res = await fetch(`${base}${VIEWER_PATH}`, {
    headers: { accept: 'text/html' },
  });
  if (!res.ok) {
    throw new Error(`viewer route returned ${res.status}`);
  }
  const html = await res.text();
  cached = { html, at: now };
  return html;
}

export const noteViewerResource: McpResource_ = {
  name: 'anchor-note-viewer',
  uri: UI_VIEWER_URI,
  description:
    'Interactive note viewer UI (MCP App). Rendered by the Anchor web app; fetches note content via note_render.',
  mimeType: 'text/html',
  async load(_user, _uri, services): Promise<ReadResourceResult> {
    const html = await fetchViewerHtml(services.baseUrl);
    return {
      contents: [{ uri: UI_VIEWER_URI, mimeType: 'text/html', text: html }],
    };
  },
};

// Local structural type to avoid a circular import with the shared McpResource.
type McpResource_ = {
  name: string;
  uri: string;
  description: string;
  mimeType?: string;
  load: (
    user: McpUserContext,
    uri: string,
    services: McpServices,
  ) => Promise<ReadResourceResult>;
};

export const mcpAppsResources: Record<string, McpResource_> = {
  [noteViewerResource.name]: noteViewerResource,
};
