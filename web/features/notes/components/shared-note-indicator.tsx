"use client";

import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";
import type { Note } from "../types";

interface SharedNoteIndicatorProps {
  note: Note;
  className?: string;
}

export function SharedNoteIndicator({
  note,
  className,
}: SharedNoteIndicatorProps) {
  // Only show for notes shared with current user
  if (!note.sharedBy) {
    return null;
  }

  const { sharedBy } = note;

  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <div className={cn("inline-flex", className)}>
          <Avatar className="size-6 cursor-pointer ring-2 ring-background hover:ring-primary/20 transition-all">
            {sharedBy.profileImage && (
              <AvatarImage src={sharedBy.profileImage} alt={sharedBy.name} />
            )}
            <AvatarFallback className="bg-primary/10 text-primary text-xs font-medium">
              {sharedBy.name.charAt(0).toUpperCase()}
            </AvatarFallback>
          </Avatar>
        </div>
      </TooltipTrigger>
      <TooltipContent side="top">
        {sharedBy.name}
      </TooltipContent>
    </Tooltip>
  );
}
