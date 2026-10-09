"use client";

import * as ToggleGroupPrimitive from "@radix-ui/react-toggle-group";
import * as React from "react";
import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";
import { cn } from "@/lib/utils";

interface SegmentedControlOption<T extends string> {
  value: T;
  label?: React.ReactNode;
  icon?: React.ReactNode;
  ariaLabel?: string;
  disabled?: boolean;
}

interface SegmentedControlProps<T extends string> {
  value: T;
  onValueChange: (value: T) => void;
  options: readonly SegmentedControlOption<T>[];
  "aria-label": string;
  size?: "default" | "sm";
  variant?: "segments" | "tiles";
  full?: boolean;
  className?: string;
}

const segmentClass =
  "inline-flex flex-1 cursor-pointer items-center justify-center gap-1.5 whitespace-nowrap rounded-md border-0 px-3 font-medium text-control [&_svg]:size-3.75";
const tileClass =
  "grid cursor-pointer justify-items-center gap-1.5 rounded-md border-0 px-1 pt-2.5 pb-2 font-medium text-small [&_svg]:size-5";

/** The root must be positioned. */
function useGlidingFill(
  root: React.RefObject<HTMLElement | null>,
  value: string,
) {
  const [shape, setShape] = React.useState<{
    clip: string;
    value: string;
  } | null>(null);
  const fillRef = React.useRef<HTMLDivElement>(null);
  const shownShape = React.useRef(shape);

  React.useLayoutEffect(() => {
    const el = root.current;
    if (!el) return;
    const measure = () => {
      const chosen = el.querySelector<HTMLElement>(
        `[data-seg="${CSS.escape(value)}"]`,
      );
      if (!chosen) return setShape(null);
      const right = el.clientWidth - chosen.offsetLeft - chosen.offsetWidth;
      const bottom = el.clientHeight - chosen.offsetTop - chosen.offsetHeight;
      const radius = getComputedStyle(chosen).borderTopLeftRadius;
      setShape({
        clip: `inset(${chosen.offsetTop}px ${right}px ${bottom}px ${chosen.offsetLeft}px round ${radius})`,
        value,
      });
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(el);
    return () => observer.disconnect();
  }, [root, value]);

  React.useLayoutEffect(() => {
    const from = shownShape.current;
    shownShape.current = shape;
    const fill = fillRef.current;
    if (
      !fill ||
      !from ||
      !shape ||
      from.value === shape.value ||
      prefersReducedMotion()
    )
      return;
    const moving = fill.getAnimations();
    const start = moving.length ? getComputedStyle(fill).clipPath : from.clip;
    for (const animation of moving) animation.cancel();
    fill.animate([{ clipPath: start }, { clipPath: shape.clip }], {
      duration: DURATION.move,
      easing: EASE.standard,
    });
  }, [shape]);

  return { clip: shape?.clip ?? null, fillRef };
}

function SegmentedControl<T extends string>({
  value,
  onValueChange,
  options,
  size = "default",
  variant = "segments",
  full,
  className,
  ...props
}: SegmentedControlProps<T>) {
  const isTiles = variant === "tiles";
  const root = React.useRef<HTMLDivElement>(null);
  const fill = useGlidingFill(root, value);

  const sizeClass = isTiles ? "" : size === "sm" ? "h-7 px-2" : "h-7.5";
  const shapeClass = isTiles ? tileClass : segmentClass;
  return (
    <ToggleGroupPrimitive.Root
      ref={root}
      data-slot="segmented-control"
      data-variant={variant}
      type="single"
      value={value}
      onValueChange={(selected) => selected && onValueChange(selected as T)}
      aria-label={props["aria-label"]}
      className={cn(
        isTiles
          ? "relative grid grid-cols-[repeat(auto-fit,minmax(0,1fr))] gap-1.5"
          : "relative inline-flex max-w-full gap-0.5 overflow-x-auto rounded-lg bg-muted p-0.75 scrollbar-none",
        full && !isTiles && "flex",
        className,
      )}
    >
      {options.map((option) => (
        <ToggleGroupPrimitive.Item
          key={option.value}
          value={option.value}
          data-seg={option.value}
          disabled={option.disabled}
          aria-label={option.ariaLabel}
          className={cn(
            shapeClass,
            sizeClass,
            isTiles
              ? "bg-muted text-muted-foreground transition-colors duration-(--duration-hover) hover:text-foreground data-[state=on]:font-semibold"
              : "bg-transparent text-muted-foreground transition-colors duration-(--duration-hover) hover:bg-foreground/5 hover:text-foreground disabled:cursor-default disabled:opacity-50 data-[state=on]:font-semibold data-[state=on]:hover:bg-transparent",
          )}
        >
          {option.icon}
          {option.label}
        </ToggleGroupPrimitive.Item>
      ))}
      {fill.clip && (
        <div
          ref={fill.fillRef}
          aria-hidden
          data-slot="segmented-fill"
          className={cn(
            "pointer-events-none absolute inset-0",
            isTiles
              ? "grid grid-cols-[repeat(auto-fit,minmax(0,1fr))] gap-1.5"
              : "flex gap-0.5 bg-primary p-0.75",
          )}
          style={{ clipPath: fill.clip }}
        >
          {options.map((option) => (
            <span
              key={option.value}
              className={cn(
                shapeClass,
                sizeClass,
                "text-card",
                isTiles && "bg-primary",
                option.value === value && "font-semibold",
              )}
            >
              {option.icon}
              {option.label}
            </span>
          ))}
        </div>
      )}
    </ToggleGroupPrimitive.Root>
  );
}

export { SegmentedControl, useGlidingFill };
