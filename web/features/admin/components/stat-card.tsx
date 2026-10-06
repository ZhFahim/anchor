import type * as React from "react";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { cardClass } from "./admin-parts";

export function StatCard({
  icon,
  label,
  value,
  failed,
  caption,
}: {
  icon: React.ReactNode;
  label: string;
  value?: number;
  failed?: boolean;
  caption: string;
}) {
  return (
    <div
      data-slot="card"
      className={cn(cardClass, "grid gap-1.5 px-5 py-4 max-md:p-3")}
    >
      <span className="flex items-center gap-2 font-medium text-meta text-muted-foreground [&_svg]:size-3.75">
        {icon}
        {label}
      </span>
      {value === undefined && failed ? (
        <b className="text-display text-muted-foreground leading-[1.1] max-md:text-page">
          —<span className="sr-only">Not loaded</span>
        </b>
      ) : value === undefined ? (
        <Skeleton className="my-1.5 h-7 w-16" />
      ) : (
        <b className="text-display leading-[1.1] tabular-nums max-md:text-page">
          {value.toLocaleString()}
        </b>
      )}
      <small className="text-muted-foreground text-small max-md:hidden">
        {caption}
      </small>
    </div>
  );
}
