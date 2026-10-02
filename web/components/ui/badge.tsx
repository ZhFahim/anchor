import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex h-5.5 items-center gap-1 whitespace-nowrap rounded-pill bg-muted px-2 font-medium text-muted-foreground text-small [&_svg]:size-3",
  {
    variants: {
      tone: {
        default: "",
        ink: "font-semibold text-foreground",
        warn: "bg-warn font-semibold text-warn-foreground",
        ok: "bg-[color-mix(in_srgb,var(--added)_14%,var(--card))] font-semibold text-added-ink",
      },
    },
    defaultVariants: { tone: "default" },
  },
);

function Badge({
  className,
  tone,
  ...props
}: React.ComponentProps<"span"> & VariantProps<typeof badgeVariants>) {
  return (
    <span
      data-slot="badge"
      className={cn(badgeVariants({ tone }), className)}
      {...props}
    />
  );
}

export { Badge };
