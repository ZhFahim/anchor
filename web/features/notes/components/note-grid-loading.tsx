"use client";

import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

interface NoteGridLoadingProps {
  count?: number;
  className?: string;
}

export function NoteGridLoading({ count = 8, className }: NoteGridLoadingProps) {
  return (
    <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4", className)}>
      {Array.from({ length: count }).map((_, index) => (
        <div
          key={`note-loading-${index}`}
          className="rounded-3xl border border-border/65 bg-card/95 p-5 shadow-[0_6px_18px_hsl(var(--shadow)/0.09)]"
        >
          <Skeleton className="mb-4 h-6 w-2/3" />
          <Skeleton className="mb-2 h-4 w-full" />
          <Skeleton className="mb-2 h-4 w-[88%]" />
          <Skeleton className="mb-6 h-4 w-[72%]" />

          <div className="mb-4 flex items-center gap-2">
            <Skeleton className="h-6 w-16 rounded-full" />
            <Skeleton className="h-6 w-14 rounded-full" />
          </div>

          <Skeleton className="h-4 w-24" />
        </div>
      ))}
    </div>
  );
}
