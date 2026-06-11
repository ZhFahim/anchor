"use client";

import { Users } from "lucide-react";
import { useState } from "react";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";
import type { Note } from "../types";
import { ShareDialog } from "./share-dialog";

interface SharedByMeIndicatorProps {
  note: Note;
  className?: string;
}

export function SharedByMeIndicator({
  note,
  className,
}: SharedByMeIndicatorProps) {
  const [shareOpen, setShareOpen] = useState(false);

  // Only show for notes the current user owns and has shared with others
  if (
    note.permission !== "owner" ||
    !note.shareIds ||
    note.shareIds.length === 0
  ) {
    return null;
  }

  const count = note.shareIds.length;

  return (
    <span className="contents" onClick={(e) => e.stopPropagation()}>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setShareOpen(true);
            }}
            className={cn(
              "inline-flex items-center gap-1 rounded-full px-1.5 py-0.5 -mx-1.5 -my-0.5 text-muted-foreground cursor-pointer transition-all hover:bg-primary/10 hover:text-primary",
              className,
            )}
          >
            <Users className="h-3.5 w-3.5" />
            <span className="font-medium">{count}</span>
          </button>
        </TooltipTrigger>
        <TooltipContent side="top">
          Shared with {count} {count === 1 ? "person" : "people"}
        </TooltipContent>
      </Tooltip>
      <ShareDialog
        open={shareOpen}
        onOpenChange={setShareOpen}
        noteId={note.id}
      />
    </span>
  );
}
