"use client";

import { CheckSquare, Square } from "lucide-react";
import {
  deltaToPreviewLines,
  orderedPreviewMarker,
} from "@/features/notes/quill";
import { cn } from "@/lib/utils";

interface QuillPreviewProps {
  content: string | null | undefined;
  maxLines?: number;
  className?: string;
}

export function QuillPreview({
  content,
  maxLines = 6,
  className,
}: QuillPreviewProps) {
  const lines = deltaToPreviewLines(content, maxLines);
  if (lines.length === 0) return null;

  // Ordered counters per nesting level: deeper levels reset when the list
  // returns to a shallower one; a level's own count continues across
  // nested runs, matching the editor's numbering.
  const orderedCounters = new Map<number, number>();

  return (
    <div className={cn("flex flex-col gap-0.5", className)}>
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
            <div key={i} className="flex items-start gap-2" style={indentStyle}>
              <span className="mt-0.5 shrink-0 text-muted-foreground">
                {checked ? (
                  <CheckSquare className="h-4 w-4 text-primary" />
                ) : (
                  <Square className="h-4 w-4 opacity-60" />
                )}
              </span>
              <span
                className={cn(
                  "truncate text-sm text-muted-foreground",
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
            <div key={i} className="flex items-start gap-2" style={indentStyle}>
              <span className="w-3 text-center shrink-0 text-sm text-muted-foreground">
                {orderedPreviewMarker(count, line.indent)}
              </span>
              <span className="truncate text-sm text-muted-foreground">
                {text}
              </span>
            </div>
          );
        }

        if (line.listType === "bullet") {
          return (
            <div key={i} className="flex items-start gap-2" style={indentStyle}>
              <span className="w-3 text-center shrink-0 text-sm text-muted-foreground">
                •
              </span>
              <span className="truncate text-sm text-muted-foreground">
                {text}
              </span>
            </div>
          );
        }

        return (
          <span
            key={i}
            className="block truncate text-sm text-muted-foreground"
            style={indentStyle}
          >
            {text}
          </span>
        );
      })}
    </div>
  );
}
