import type { ReadResourceResult } from '@modelcontextprotocol/sdk/types.js';
import type { McpServices } from '../tools/tools';
import type { McpUserContext } from '../mcp-auth.context';

/**
 * MCP Apps `ui://` resource (plan P7/P10 / MCP Apps extension).
 *
 * Returns a self-contained HTML page (CSS + vanilla JS inlined, no bundler)
 * that renders a note's Quill Delta faithfully and talks to the host over the
 * MCP Apps postMessage JSON-RPC dialect. The host renders this in a sandboxed
 * iframe; the app calls the app-only `note_render` tool (via the `?app=1`
 * transport) to get raw content, then displays it.
 */

export const UI_VIEWER_URI = 'ui://anchor/note-viewer';

export function buildNoteViewerHtml(): string {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<title>Anchor note viewer</title>
<style>
  :root { color-scheme: light dark; }
  body { margin: 0; font-family: system-ui, -apple-system, sans-serif; }
  .wrap { padding: 16px; }
  h1 { margin: 0 0 8px; font-size: 18px; }
  .meta { font-size: 12px; opacity: .6; margin-bottom: 12px; }
  .ql { white-space: pre-wrap; line-height: 1.5; }
  .empty { opacity: .5; font-style: italic; }
  ul[data-list], .ql ul { padding-left: 22px; }
  li[data-list="checked"]::after { content: " ✔"; color: #16a34a; }
  li[data-list="unchecked"]::after { content: " ⬜"; }
</style>
</head>
<body>
<div class="wrap" id="root"><div class="missing">Connecting to host…</div></div>
<script>
(function () {
  var root = document.getElementById('root');
  var pending = [];
  function send(msg) {
    var target = window.origin;
    // The host posts back to us via event.origin; we post to 'parent' as the
    // postMessage targetWindow. Use '*' target; host validates origin.
    window.parent.postMessage(msg, '*');
  }
  function call(method, params, id) {
    params = params || {};
    var rid = id || ('r' + Math.random().toString(36).slice(2));
    send({ jsonrpc: '2.0', id: rid, method: method, params: params });
    return rid;
  }
  function render(note) {
    if (!note) { root.innerHTML = '<div class="empty">No note loaded.</div>'; return; }
    var title = (note.title || '(untitled)').replace(/</g, '&lt;');
    var txt = '';
    try {
      var ops = JSON.parse(note.content || '[]').ops || [];
      for (var i = 0; i < ops.length; i++) {
        var op = ops[i];
        txt += (op.insert || '').toString();
      }
    } catch (e) { txt = note.content || ''; }
    var esc = txt.replace(/</g, '&lt;');
    root.innerHTML =
      '<h1>' + title + '</h1>' +
      '<div class="meta">id ' + note.id + ' · ' + (note.state || 'active') + '</div>' +
      '<div class="ql">' + esc + '</div>';
  }
  // ui/initialize handshake with the host.
  var currentNoteId = '';
  window.addEventListener('message', function (ev) {
    if (ev.source !== window.parent) return;
    var data = ev.data;
    if (!data || data.jsonrpc !== '2.0') return;
    if (data.method === 'ui/initialize' && data.id !== undefined) {
      send({ jsonrpc: '2.0', id: data.id, result: { ready: true, name: 'anchor-note-viewer' } });
      // Request the raw content through the app channel.
      if (currentNoteId) {
        call('tools/call', { name: 'note_render', arguments: { noteId: currentNoteId } });
      }
      return;
    }
    if (data.method === 'ui/context/update' && data.params && data.params.context) {
      // Host pushes a fresh note id to render (e.g. the user opened a note).
      var pushed = data.params.context;
      if (pushed && typeof pushed.noteId === 'string') {
        currentNoteId = pushed.noteId;
        call('tools/call', { name: 'note_render', arguments: { noteId: currentNoteId } });
      }
      return;
    }
    if (data.id && data.method === undefined && data.result) {
      // tool result (tools/call response) -> render it
      var result = data.result;
      var structured = result && result.structuredContent;
      if (structured && (structured.content || structured.id)) {
        render(structured);
        return;
      }
    }
  });
  call('ui/initialize', { version: '1' });
})();
</script>
</body>
</html>`;
}

/** `ui://anchor/note-viewer` resource: returns the embedded note-viewer HTML. */
export const noteViewerResource: McpResource_ = {
  name: 'anchor-note-viewer',
  uri: UI_VIEWER_URI,
  description:
    'Interactive note viewer UI (MCP App). Renders a note faithfully in a sandboxed iframe; calls note_render.',
  mimeType: 'text/html',
  load(): Promise<ReadResourceResult> {
    return Promise.resolve({
      contents: [
        {
          uri: UI_VIEWER_URI,
          mimeType: 'text/html',
          text: buildNoteViewerHtml(),
        },
      ],
    });
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
