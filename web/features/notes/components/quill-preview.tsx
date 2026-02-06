"use client";

import { CheckSquare, Square } from "lucide-react";
import { cn } from "@/lib/utils";
import { deltaToPreviewLines } from "@/features/notes/quill";

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

  let orderedIndex = 0;

  return (
    <div className={cn("flex flex-col gap-0.5", className)}>
      {lines.map((line, i) => {
        const text = line.text.trim();
        if (!text) return null;

        if (line.listType === "checked" || line.listType === "unchecked") {
          const checked = line.listType === "checked";
          return (
            <div key={i} className="flex items-start gap-2">
              <span className="mt-0.5 flex-shrink-0 text-muted-foreground">
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
          orderedIndex += 1;
          return (
            <div key={i} className="flex items-start gap-2">
              <span className="w-3 text-center flex-shrink-0 text-sm text-muted-foreground">
                {orderedIndex}.
              </span>
              <span className="truncate text-sm text-muted-foreground">
                {text}
              </span>
            </div>
          );
        }

        if (line.listType === "bullet") {
          orderedIndex = 0;
          return (
            <div key={i} className="flex items-start gap-2">
              <span className="w-3 text-center flex-shrink-0 text-sm text-muted-foreground">
                •
              </span>
              <span className="truncate text-sm text-muted-foreground">
                {text}
              </span>
            </div>
          );
        }

        orderedIndex = 0;
        return (
          <span
            key={i}
            className="block truncate text-sm text-muted-foreground"
          >
            {text}
          </span>
        );
      })}
    </div>
  );
}
