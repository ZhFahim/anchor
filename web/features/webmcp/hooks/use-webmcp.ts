"use client";

import { useEffect } from "react";
import { getNotes } from "@/features/notes/api";

/**
 * Registers Anchor's WebMCP tools with the browser's `document.modelContext`
 * once, when the authenticated app shell mounts, and unregisters them on
 * unmount (logout / navigation away).
 *
 * Requires WebMCP availability (Chrome origin-trial; `document.modelContext`,
 * since `navigator.modelContext` is deprecated in Chrome 150). No-ops when
 * WebMCP is unavailable, so it's safe on any page load.
 */
export function useWebMcp(): void {
  useEffect(() => {
    if (typeof document === "undefined") return;
    const mc = document.modelContext ?? navigator.modelContext;
    if (!mc) return;

    const controller = new AbortController();
    void mc
      .registerTool(
        {
          name: "note_search",
          title: "Search Notes",
          description:
            "Search the user's Anchor notes by title or content. Returns note ids and titles.",
          inputSchema: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "Search text for title/content.",
              },
            },
          },
          annotations: { readOnlyHint: true },
          execute: async ({ query }) => {
            const notes = await getNotes(
              typeof query === "string" && query
                ? { search: query }
                : undefined,
            );
            return {
              notes: notes.map((n) => ({
                id: n.id,
                title: n.title,
                isArchived: n.isArchived,
              })),
            };
          },
        },
        { signal: controller.signal },
      )
      .catch(() => {});

    return () => controller.abort();
  }, []);
}
