"use client";

import { useEffect, useRef, useState } from "react";
import { NoteViewer } from "@/features/notes/components";

interface NotePayload {
  id: string;
  title: string;
  content?: string;
  state?: string;
  isArchived?: boolean;
  updatedAt?: string;
  version?: number;
}

/**
 * Client adapter that lets the shared NoteViewer run as an MCP App inside the
 * host's sandboxed iframe. It speaks the MCP Apps postMessage JSON-RPC dialect:
 * it answers `ui/initialize`, reacts to `ui/context/update`, and calls the
 * app-only `note_render` tool for content. All rendering is delegated to the
 * shared NoteViewer component — no hand-written HTML.
 */
export function McpAppBootstrap() {
  const [note, setNote] = useState<NotePayload | null>(null);
  const noteIdRef = useRef<string>("");
  const versionRef = useRef<number | null>(null);

  useEffect(() => {
    const send = (msg: unknown) => window.parent.postMessage(msg, "*");
    const call = (method: string, params: unknown) => {
      send({
        jsonrpc: "2.0",
        id: `r${Math.random().toString(36).slice(2)}`,
        method,
        params,
      });
    };
    const refresh = () => {
      if (noteIdRef.current) {
        call("tools/call", {
          name: "note_render",
          arguments: { noteId: noteIdRef.current },
        });
      }
    };

    const onMessage = (ev: MessageEvent) => {
      if (ev.source !== window.parent) return;
      const data = ev.data;
      if (!data || data.jsonrpc !== "2.0") return;

      if (data.method === "ui/initialize" && data.id !== undefined) {
        send({
          jsonrpc: "2.0",
          id: data.id,
          result: { ready: true, name: "anchor-note-viewer" },
        });
        refresh();
        return;
      }
      if (data.method === "ui/context/update" && data.params?.context) {
        const pushed = data.params.context;
        if (typeof pushed?.noteId === "string") {
          noteIdRef.current = pushed.noteId;
          versionRef.current = null;
          refresh();
        }
        return;
      }
      if (data.id && data.method === undefined && data.result) {
        const structured = data.result?.structuredContent;
        if (structured && (structured.content || structured.id)) {
          // Live updates (P8): repaint only when the server version moved.
          if (
            typeof structured.version !== "undefined" &&
            structured.version === versionRef.current
          ) {
            return;
          }
          versionRef.current = structured.version ?? null;
          setNote(structured as NotePayload);
        }
      }
    };

    window.addEventListener("message", onMessage);
    call("ui/initialize", { version: "1" });
    // Poll so the viewer tracks server-side changes without a manual refresh.
    const timer = setInterval(refresh, 4000);
    return () => {
      window.removeEventListener("message", onMessage);
      clearInterval(timer);
    };
  }, []);

  if (!note) {
    return <div className="text-sm text-muted-foreground">Loading note…</div>;
  }
  return (
    <NoteViewer
      title={note.title}
      content={note.content}
      state={note.state}
      isArchived={note.isArchived}
      updatedAt={note.updatedAt}
    />
  );
}
