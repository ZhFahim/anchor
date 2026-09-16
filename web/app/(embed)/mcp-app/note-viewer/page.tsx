import type { Metadata } from "next";
import { McpAppBootstrap } from "./mcp-app-bootstrap";

export const metadata: Metadata = {
  title: "Anchor note viewer",
  robots: { index: false, follow: false },
};

/**
 * Embedded MCP App route (SSR). Rendered server-side by Next from the shared
 * web components; the MCP `ui://anchor/note-viewer` resource serves this page's
 * HTML. The client adapter then fetches note content over the MCP Apps channel.
 */
export default function NoteViewerPage() {
  return (
    <main className="mx-auto max-w-2xl p-4">
      <McpAppBootstrap />
    </main>
  );
}
