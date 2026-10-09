"use client";

import * as CheckboxPrimitive from "@radix-ui/react-checkbox";
import type * as React from "react";
import { cn } from "@/lib/utils";

function Checkbox({
  className,
  ...props
}: React.ComponentProps<typeof CheckboxPrimitive.Root>) {
  return (
    <CheckboxPrimitive.Root
      data-slot="checkbox"
      className={cn(
        "relative grid size-checkbox flex-none cursor-pointer place-items-center rounded-checkbox border-[1.5px] border-muted-foreground bg-transparent p-0 disabled:cursor-default disabled:opacity-50 data-[state=checked]:border-accent-strong data-[state=indeterminate]:border-accent-strong data-[state=checked]:bg-accent-strong data-[state=indeterminate]:bg-accent-strong",
        className,
      )}
      {...props}
    >
      <CheckboxPrimitive.Indicator className="grid place-items-center data-[state=indeterminate]:[&>i]:hidden data-[state=checked]:[&>b]:hidden">
        <i className="-mt-0.5 block h-1.25 w-2.25 -rotate-45 border-(--check-mark,var(--card)) border-b-2 border-l-2" />
        <b className="block h-0.5 w-2 rounded-full bg-(--check-mark,var(--card))" />
      </CheckboxPrimitive.Indicator>
    </CheckboxPrimitive.Root>
  );
}

export { Checkbox };
