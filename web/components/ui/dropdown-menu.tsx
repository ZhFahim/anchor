"use client";

import * as DropdownMenuPrimitive from "@radix-ui/react-dropdown-menu";
import type * as React from "react";
import { cn } from "@/lib/utils";

/** Radix's modal menu hides the page from screen readers. */
function DropdownMenu({
  modal = false,
  ...props
}: React.ComponentProps<typeof DropdownMenuPrimitive.Root>) {
  return <DropdownMenuPrimitive.Root modal={modal} {...props} />;
}
const DropdownMenuTrigger = DropdownMenuPrimitive.Trigger;

export const menuSurface =
  "bg-card text-foreground shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_70%,transparent),var(--sh-menu)]";

function DropdownMenuContent({
  className,
  sideOffset = 6,
  align = "start",
  collisionPadding = 8,
  ...props
}: React.ComponentProps<typeof DropdownMenuPrimitive.Content>) {
  return (
    <DropdownMenuPrimitive.Portal>
      <DropdownMenuPrimitive.Content
        data-slot="menu"
        sideOffset={sideOffset}
        align={align}
        collisionPadding={collisionPadding}
        className={cn(
          menuSurface,
          "z-(--z-popover) grid min-w-50 origin-(--radix-dropdown-menu-content-transform-origin) gap-px rounded-menu p-1.5 outline-none animate-pop-in data-[side=top]:animate-pop-up data-[state=closed]:pointer-events-none! data-[state=closed]:animate-pop-out data-[side=top]:data-[state=closed]:animate-pop-down-out",
          className,
        )}
        {...props}
      />
    </DropdownMenuPrimitive.Portal>
  );
}

const menuItem =
  "relative flex min-h-8.5 cursor-pointer select-none items-center gap-2.5 whitespace-nowrap rounded-menu-item px-2.5 py-1.5 text-left text-ui transition-[color,background-color] focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-transparent duration-(--duration-hover) data-disabled:pointer-events-none data-disabled:opacity-50 data-highlighted:bg-foreground/6 [&>svg]:size-3.75 [&>svg]:flex-none [&>svg]:text-muted-foreground [&>svg]:transition-colors data-highlighted:[&>svg:first-child]:text-foreground focus-visible:after:absolute focus-visible:after:top-1/2 focus-visible:after:left-0.75 focus-visible:after:-mt-2 focus-visible:after:h-4 focus-visible:after:w-0.75 focus-visible:after:rounded-xs focus-visible:after:bg-accent-strong focus-visible:after:content-['']";

function DropdownMenuItem({
  className,
  tone,
  ...props
}: React.ComponentProps<typeof DropdownMenuPrimitive.Item> & {
  tone?: "default" | "danger";
}) {
  return (
    <DropdownMenuPrimitive.Item
      className={cn(
        menuItem,
        tone === "danger" &&
          "text-destructive [&>svg]:text-destructive data-highlighted:[&>svg:first-child]:text-destructive",
        className,
      )}
      {...props}
    />
  );
}

function DropdownMenuSeparator({
  className,
  ...props
}: React.ComponentProps<typeof DropdownMenuPrimitive.Separator>) {
  return (
    <DropdownMenuPrimitive.Separator
      className={cn("mx-2 my-1 h-px bg-border/60", className)}
      {...props}
    />
  );
}

function DropdownMenuLabel({
  className,
  ...props
}: React.ComponentProps<typeof DropdownMenuPrimitive.Label>) {
  return (
    <DropdownMenuPrimitive.Label
      className={cn(
        "px-2.5 pt-2 pb-1 text-label text-muted-foreground uppercase",
        className,
      )}
      {...props}
    />
  );
}

export {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  menuItem,
};
