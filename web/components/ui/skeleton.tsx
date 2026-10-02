import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import { cn } from "@/lib/utils";

const skeletonVariants = cva(
  "block animate-shimmer bg-size-[200%_100%] bg-[linear-gradient(90deg,var(--sk)_30%,var(--sk-hi)_50%,var(--sk)_70%)] [--sk-hi:color-mix(in_srgb,var(--foreground)_4%,transparent)] [--sk:color-mix(in_srgb,var(--foreground)_9%,transparent)]",
  {
    variants: {
      shape: {
        line: "h-2.5 w-full rounded-[5px]",
        title: "h-4 w-[55%] rounded-md",
        circle: "size-7 flex-none rounded-full",
        button: "h-8.5 w-23 flex-none rounded-button",
        block: "rounded-lg",
      },
    },
    defaultVariants: { shape: "line" },
  },
);

function Skeleton({
  className,
  shape,
  ...props
}: React.ComponentProps<"span"> & VariantProps<typeof skeletonVariants>) {
  return (
    <span
      data-slot="skeleton"
      aria-hidden
      className={cn(skeletonVariants({ shape }), className)}
      {...props}
    />
  );
}

function SkeletonRows({
  count = 3,
  className,
}: {
  count?: number;
  className?: string;
}) {
  const widths = ["62%", "48%", "56%", "40%", "52%"];
  return (
    <div className={cn("grid gap-3.5", className)} aria-busy="true">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="flex items-center gap-2.5">
          <Skeleton shape="circle" />
          <div className="grid flex-1 gap-1.5">
            <Skeleton style={{ width: widths[i % widths.length] }} />
            <Skeleton style={{ width: "38%" }} />
          </div>
        </div>
      ))}
    </div>
  );
}

export { Skeleton, SkeletonRows };
