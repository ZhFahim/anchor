import { getNote, getNotes } from "@/features/notes/api";
import type { ModelContextTool } from "./types";

/**
 * The WebMCP tools Anchor registers with the browser `document.modelContext`.
 * Tools run in-page as the signed-in user (the web session rides the existing
 * `api` client's bearer token — no extra tokens), matching the "same feature
 * parity via a shared bundle + browser adapter" plan (P7) and the WebMCP
 * in-page auth model.
 */

interface Tool {
  name: string;
  title: string;
  description: string;
  inputSchema: Record<string, unknown>;
  execute(input: Record<string, unknown>): Promise<unknown>;
  readOnly?: boolean;
}

const TOOLS: Tool[] = [
  {
    name: "note_search",
    title: "Search Notes",
    description:
      "Search the user's Anchor notes by title or content. Returns a list of note ids and titles. Use note_get for full detail.",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search text for title/content.",
        },
      },
    },
    async execute(input) {
      const query = typeof input.query === "string" ? input.query : undefined;
      const notes = await getNotes(query ? { search: query } : undefined);
      return {
        notes: notes.map((n) => ({
          id: n.id,
          title: n.title,
          isArchived: n.isArchived,
        })),
      };
    },
    readOnly: true,
  },
  {
    name: "note_get",
    title: "Get Note",
    description:
      "Get a single note by id. Returns the note's id, title, and full Quill-Delta content. Prefer search first to find the id.",
    inputSchema: {
      type: "object",
      properties: {
        noteId: { type: "string", description: "The id of the note to fetch." },
      },
      required: ["noteId"],
    },
    async execute(input) {
      const noteId = typeof input.noteId === "string" ? input.noteId : "";
      const note = await getNote(noteId);
      return {
        id: note.id,
        title: note.title,
        content: note.content ?? "",
        isArchived: note.isArchived,
      };
    },
    readOnly: true,
  },
];

/** The tool schema field names expected by WebMCP (see types.ts). */
export function toModelContextTool(t: Tool): ModelContextTool {
  return {
    name: t.name,
    title: t.title,
    description: t.description,
    inputSchema: t.inputSchema,
    annotations: { readOnlyHint: t.readOnly ?? false },
    execute: t.execute,
  };
}

export function webmcpAvailable(): boolean {
  if (typeof document !== "undefined") {
    const mc = document.modelContext ?? navigator.modelContext;
    return !!mc;
  }
  return false;
}

function register(tools: Tool[], signal: AbortSignal): void {
  const modelContext = document.modelContext ?? navigator.modelContext;
  if (!modelContext) return;
  for (const tool of tools) {
    void modelContext.registerTool(toModelContextTool(tool), { signal });
  }
}

/**
 * Register Anchor's WebMCP tools. Feature-detects `document.modelContext` (the
 * current API; `navigator.modelContext` is deprecated in Chrome 150) and does
 * nothing if WebMCP is unavailable, so it's safe to call on any page load.
 */
export function registerWebMcpTools(): () => void {
  if (!webmcpAvailable()) return () => {};
  const controller = new AbortController();
  register(TOOLS, controller.signal);
  // Aborting unregisters the tools (e.g. on unmount / logout).
  return () => controller.abort();
}

export { useWebMcp } from "./hooks/use-webmcp";
export type {
  ModelContext,
  ModelContextTool,
  ModelContextToolAnnotations,
} from "./types";
/** For tests: the tool catalogue (name -> schema) without registration. */
export { TOOLS as webmcpToolCatalog };
