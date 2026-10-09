import { Hash, X } from "lucide-react";
import type * as React from "react";
import { cn } from "@/lib/utils";
import { tagColorStyle } from "../utils";

interface TagChipProps {
  name: React.ReactNode;
  color?: string | null;
  size?: "default" | "sm";
  onRemove?: () => void;
  removeLabel?: string;
  className?: string;
}

export function TagChip({
  name,
  color,
  size = "default",
  onRemove,
  removeLabel,
  className,
}: TagChipProps) {
  const small = size === "sm";
  return (
    <span
      data-slot="tag-chip"
      style={tagColorStyle(color)}
      className={cn(
        "tag-color inline-flex max-w-full items-center whitespace-nowrap rounded-pill bg-note-surface font-medium text-foreground shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--note-border)_55%,transparent)] [&_svg]:flex-none",
        small
          ? "h-chip-card gap-1 pr-2 pl-1.75 text-caption"
          : "h-chip gap-1.25 pr-2 pl-2.25 text-chip max-md:h-7.5",
        className,
      )}
    >
      <span
        aria-hidden
        className={cn(
          "inline-grid flex-none place-items-center text-(--hash,var(--note-muted)) [&_svg]:stroke-[2.75]",
          small ? "[&_svg]:size-2.75" : "-mt-px [&_svg]:size-3",
        )}
      >
        <Hash />
      </span>
      <span className="min-w-0 truncate">{name}</span>
      {onRemove && (
        <button
          type="button"
          aria-label={removeLabel ?? "Remove tag"}
          onClick={onRemove}
          className="inline-grid cursor-pointer place-items-center rounded-pill bg-transparent p-0.5 text-note-muted hover:text-foreground [&_svg]:size-3"
        >
          <X />
        </button>
      )}
    </span>
  );
}

export function MoreChip({ count }: { count: number }) {
  return (
    <span className="inline-flex h-chip-card items-center rounded-pill bg-note-surface px-1.75 font-medium text-caption text-note-muted shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--note-border)_55%,transparent)]">
      +{count}
    </span>
  );
}
