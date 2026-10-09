"use client";

import * as PopoverPrimitive from "@radix-ui/react-popover";
import type * as React from "react";
import { menuSurface } from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

const Popover = PopoverPrimitive.Root;
const PopoverTrigger = PopoverPrimitive.Trigger;
const PopoverAnchor = PopoverPrimitive.Anchor;
const PopoverTitle = PopoverPrimitive.Title;
const PopoverDescription = PopoverPrimitive.Description;

function PopoverContent({
  className,
  align = "start",
  sideOffset = 6,
  collisionPadding = 8,
  sheetOnPhone = true,
  ...props
}: React.ComponentProps<typeof PopoverPrimitive.Content> & {
  sheetOnPhone?: boolean;
}) {
  return (
    <PopoverPrimitive.Portal>
      <PopoverPrimitive.Content
        data-slot="popover"
        data-phone-sheet={sheetOnPhone || undefined}
        align={align}
        sideOffset={sideOffset}
        collisionPadding={collisionPadding}
        className={cn(
          menuSurface,
          "z-(--z-popover) max-h-(--radix-popover-content-available-height) origin-(--radix-popover-content-transform-origin) overflow-auto rounded-popover outline-none animate-pop-in data-[side=top]:animate-pop-up data-[state=closed]:pointer-events-none! data-[state=closed]:animate-pop-out data-[side=top]:data-[state=closed]:animate-pop-down-out",
          sheetOnPhone &&
            "max-md:max-h-[calc(100dvh-60px)] max-md:w-auto! max-md:origin-bottom max-md:rounded-3xl max-md:animate-pop-up max-md:data-[state=closed]:animate-pop-down-out",
          className,
        )}
        {...props}
      />
    </PopoverPrimitive.Portal>
  );
}

export {
  Popover,
  PopoverAnchor,
  PopoverContent,
  PopoverDescription,
  PopoverTitle,
  PopoverTrigger,
};
