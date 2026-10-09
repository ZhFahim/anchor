"use client";

import * as SwitchPrimitives from "@radix-ui/react-switch";
import type * as React from "react";
import { cn } from "@/lib/utils";

function Switch({
  className,
  ...props
}: React.ComponentProps<typeof SwitchPrimitives.Root>) {
  return (
    <SwitchPrimitives.Root
      data-slot="switch"
      className={cn(
        "relative h-6 w-10 flex-none cursor-pointer rounded-pill bg-[color-mix(in_srgb,var(--muted-foreground)_75%,var(--card))] p-0 transition-colors duration-(--duration-fade) disabled:cursor-default disabled:opacity-45 data-[state=checked]:bg-accent-strong",
        className,
      )}
      {...props}
    >
      <SwitchPrimitives.Thumb className="pointer-events-none absolute top-0.5 left-0.5 block size-5 rounded-full bg-knob shadow-knob transition-transform duration-(--duration-move) ease-standard data-[state=checked]:translate-x-4" />
    </SwitchPrimitives.Root>
  );
}

export { Switch };
