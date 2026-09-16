"use client";

import { CheckSquare, Square } from "lucide-react";
import {
  deltaToPreviewLines,
  orderedPreviewMarker,
} from "@/features/notes/quill";
import { cn } from "@/lib/utils";

export interface NoteViewerProps {
  title: string;
  content: string | null | undefined;
  state?: string;
  isArchived?: boolean;
  updatedAt?: string;
  tagIds?: string[];
  className?: string;
  /** Max lines to render; omit for the full note. */
  maxLines?: number;
}

/**
 * The canonical, faithful renderer for a note's Quill Delta. Shared by the
 * in-app note view and the embedded MCP App viewer so the markup lives in one
 * place (JSX + types), never duplicated as hand-written HTML.
 *
 * Renders the full note by default; pass `maxLines` for a truncated preview.
 */
export function NoteViewer({
  title,
  content,
  state,
  isArchived,
  updatedAt,
  tagIds,
  className,
  maxLines,
}: NoteViewerProps) {
  const lines = deltaToPreviewLines(
    content,
    maxLines ?? Number.MAX_SAFE_INTEGER,
  );
  const orderedCounters = new Map<number, number>();

  return (
    <div className={cn("flex flex-col gap-1", className)}>
      <h1 className="text-lg font-semibold">{title || "(untitled)"}</h1>
      {(state || updatedAt || isArchived) && (
        <div className="text-xs text-muted-foreground">
          {state ?? "active"}
          {isArchived ? ", archived" : ""}
          {updatedAt ? ` · ${updatedAt}` : ""}
        </div>
      )}
      <div className="flex flex-col gap-0.5">
        {lines.map((line, i) => {
          const text = line.text.trim();
          if (!text) return null;
          const indentStyle = line.indent
            ? { paddingLeft: line.indent * 16 }
            : undefined;
          if (line.listType === null) {
            orderedCounters.clear();
          } else {
            for (const level of [...orderedCounters.keys()]) {
              if (level > line.indent) orderedCounters.delete(level);
            }
          }

          if (line.listType === "checked" || line.listType === "unchecked") {
            const checked = line.listType === "checked";
            return (
              <div
                key={i}
                className="flex items-start gap-2"
                style={indentStyle}
              >
                <span className="mt-0.5 shrink-0 text-muted-foreground">
                  {checked ? (
                    <CheckSquare className="h-4 w-4 text-primary" />
                  ) : (
                    <Square className="h-4 w-4 opacity-60" />
                  )}
                </span>
                <span
                  className={cn(
                    "text-sm text-muted-foreground",
                    checked && "line-through opacity-70",
                  )}
                >
                  {text}
                </span>
              </div>
            );
          }

          if (line.listType === "ordered") {
            const count = (orderedCounters.get(line.indent) ?? 0) + 1;
            orderedCounters.set(line.indent, count);
            return (
              <div
                key={i}
                className="flex items-start gap-2"
                style={indentStyle}
              >
                <span className="w-3 text-center shrink-0 text-sm text-muted-foreground">
                  {orderedPreviewMarker(count, line.indent)}
                </span>
                <span className="text-sm">{text}</span>
              </div>
            );
          }

          if (line.listType === "bullet") {
            return (
              <div
                key={i}
                className="flex items-start gap-2"
                style={indentStyle}
              >
                <span className="w-3 text-center shrink-0 text-sm text-muted-foreground">
                  •
                </span>
                <span className="text-sm">{text}</span>
              </div>
            );
          }

          return (
            <span key={i} className="block text-sm" style={indentStyle}>
              {text}
            </span>
          );
        })}
      </div>
    </div>
  );
}
