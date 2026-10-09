"use client";

import * as TooltipPrimitive from "@radix-ui/react-tooltip";
import * as React from "react";
import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";
import { cn } from "@/lib/utils";

function TooltipProvider({
  delayDuration = 450,
  skipDelayDuration = 300,
  ...props
}: React.ComponentProps<typeof TooltipPrimitive.Provider>) {
  return (
    <TooltipPrimitive.Provider
      data-slot="tooltip-provider"
      delayDuration={delayDuration}
      skipDelayDuration={skipDelayDuration}
      {...props}
    />
  );
}

function Tooltip(props: React.ComponentProps<typeof TooltipPrimitive.Root>) {
  return <TooltipPrimitive.Root data-slot="tooltip" {...props} />;
}

function TooltipTrigger({
  onFocus,
  ...props
}: React.ComponentProps<typeof TooltipPrimitive.Trigger>) {
  return (
    <TooltipPrimitive.Trigger
      data-slot="tooltip-trigger"
      onFocus={(e) => {
        onFocus?.(e);
        // Skips Radix's handler that opens the tooltip.
        if (!e.currentTarget.matches(":focus-visible")) e.preventDefault();
      }}
      {...props}
    />
  );
}

function TooltipContent({
  className,
  side = "bottom",
  sideOffset = 8,
  collisionPadding = 8,
  children,
  ...props
}: React.ComponentProps<typeof TooltipPrimitive.Content>) {
  return (
    <TooltipPrimitive.Portal>
      <TooltipPrimitive.Content
        data-slot="tooltip-content"
        side={side}
        sideOffset={sideOffset}
        collisionPadding={collisionPadding}
        className={cn(
          "z-(--z-tooltip) max-w-65 origin-(--radix-tooltip-content-transform-origin) rounded-sm bg-inverse px-2 py-1.25 font-medium text-inverse-foreground text-small leading-[1.35] shadow-floating animate-fade-in",
          className,
        )}
        {...props}
      >
        {children}
      </TooltipPrimitive.Content>
    </TooltipPrimitive.Portal>
  );
}

/** Fades a copy in place of a closed tooltip, so no closing tooltip is left to catch Esc. */
function fadeOutCopy(content: HTMLElement | null) {
  const wrapper = content?.parentElement;
  if (!content || !wrapper?.isConnected || prefersReducedMotion()) return;
  const opacity = Number(getComputedStyle(content).opacity);
  const copy = wrapper.cloneNode(true) as HTMLElement;
  copy.querySelector("[role=tooltip]")?.remove();
  copy.inert = true;
  copy.setAttribute("aria-hidden", "true");
  copy.style.pointerEvents = "none";
  (copy.firstElementChild as HTMLElement | null)?.style.setProperty(
    "animation",
    "none",
  );
  wrapper.after(copy);
  const remove = () => copy.remove();
  copy
    .animate([{ opacity }, { opacity: 0 }], {
      duration: DURATION.exit,
      easing: EASE.exit,
      fill: "forwards",
    })
    .finished.then(remove, remove);
}

function Tip({
  label,
  side,
  isDisabled = false,
  isFocusOnly = false,
  children,
  ...props
}: Omit<React.ComponentProps<typeof TooltipPrimitive.Root>, "children"> & {
  label?: React.ReactNode;
  side?: React.ComponentProps<typeof TooltipPrimitive.Content>["side"];
  /** Switches the tooltip off without remounting the child. */
  isDisabled?: boolean;
  isFocusOnly?: boolean;
  children: React.ReactElement;
}) {
  const [isOpen, setIsOpen] = React.useState(false);
  const content = React.useRef<HTMLDivElement>(null);
  if (!label) return children;
  const isShown = isOpen && !isDisabled;
  return (
    <Tooltip
      {...props}
      open={isShown}
      onOpenChange={(open) => {
        if (isShown && !open) fadeOutCopy(content.current);
        setIsOpen(open && !isDisabled);
      }}
    >
      <TooltipTrigger
        asChild
        // Skips Radix's handler that opens the tooltip on hover.
        onPointerMove={isFocusOnly ? (e) => e.preventDefault() : undefined}
      >
        {children}
      </TooltipTrigger>
      <TooltipContent ref={content} side={side}>
        {label}
      </TooltipContent>
    </Tooltip>
  );
}

export { Tip, TooltipProvider };
