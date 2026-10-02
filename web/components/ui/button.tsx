"use client";

import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { LoaderCircle } from "lucide-react";
import * as React from "react";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "relative inline-flex shrink-0 cursor-pointer select-none items-center justify-center gap-1.5 whitespace-nowrap rounded-button font-semibold transition-[background-color,box-shadow,color,transform] duration-(--duration-hover) active:translate-y-px disabled:pointer-events-none disabled:opacity-[.42] aria-busy:cursor-default [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-3.75",
  {
    variants: {
      variant: {
        primary:
          "bg-primary bg-[linear-gradient(180deg,rgb(255_255_255/.1),transparent)] text-note shadow-[inset_0_1px_0_rgb(255_255_255/.14),var(--sh-xs)] hover:bg-none hover:bg-[color-mix(in_srgb,var(--primary)_86%,var(--note))]",
        secondary:
          "bg-card text-foreground shadow-[inset_0_0_0_1px_var(--border),var(--sh-xs)] hover:bg-[color-mix(in_srgb,var(--foreground)_4%,var(--card))]",
        quiet: "bg-transparent text-foreground hover:bg-foreground/8",
        danger: "bg-transparent text-late hover:bg-late/10",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-[color-mix(in_srgb,var(--destructive)_88%,var(--foreground))]",
        link: "bg-transparent font-semibold text-accent-ink underline decoration-current/35 underline-offset-3 hover:decoration-current",
      },
      size: {
        default: "px-3.25 py-2 text-(length:--text-control)",
        sm: "rounded-pill px-2.5 py-1 font-medium text-(length:--text-meta)",
        lg: "h-field-large rounded-lg px-5 text-lead",
        inline: "p-0",
      },
    },
    compoundVariants: [
      {
        variant: "link",
        size: "default",
        className: "p-0 text-[length:inherit]",
      },
    ],
    defaultVariants: {
      variant: "primary",
      size: "default",
    },
  },
);

type ButtonProps = React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
    /** While a request runs: what the button is doing ("Deleting…"). */
    busy?: string | false | null;
  };

function Button({
  className,
  variant,
  size,
  asChild = false,
  busy,
  children,
  disabled,
  onClick,
  style,
  ...props
}: ButtonProps) {
  const Comp = asChild ? Slot : "button";
  const ref = React.useRef<HTMLButtonElement | null>(null);
  const idleWidth = React.useRef(0);
  const working = !!busy;
  const showBusy = useDelayedFlag(working);

  React.useLayoutEffect(() => {
    if (!working && ref.current) idleWidth.current = ref.current.offsetWidth;
  });

  return (
    <Comp
      ref={ref}
      data-slot="button"
      data-variant={variant ?? "primary"}
      className={cn(
        buttonVariants({ variant, size }),
        showBusy && variant !== "quiet" && "opacity-[.86]",
        className,
      )}
      style={
        showBusy
          ? { minWidth: idleWidth.current || undefined, ...style }
          : style
      }
      disabled={disabled}
      aria-busy={working || undefined}
      aria-disabled={working || undefined}
      onClick={
        working
          ? (e: React.MouseEvent<HTMLButtonElement>) => e.preventDefault()
          : onClick
      }
      {...props}
    >
      {showBusy ? (
        <>
          <LoaderCircle className="animate-spin" aria-hidden />
          {busy}
        </>
      ) : (
        children
      )}
    </Comp>
  );
}

const iconButtonVariants = cva(
  "inline-grid shrink-0 cursor-pointer place-items-center rounded-button bg-transparent p-0 text-note-muted transition-[background-color,color,box-shadow] duration-(--duration-hover) hover:bg-note-surface hover:text-foreground aria-expanded:bg-note-surface aria-expanded:text-foreground aria-pressed:bg-note-surface aria-pressed:text-foreground aria-pressed:shadow-[inset_0_0_0_1.5px_var(--note-muted)] disabled:cursor-default disabled:bg-transparent disabled:opacity-35 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4.25",
  {
    variants: {
      size: {
        default: "size-target-desktop max-md:size-target-phone",
        sm: "size-7 rounded-sm hover:bg-foreground/8 aria-pressed:bg-foreground/8 [&_svg:not([class*='size-'])]:size-3.75",
      },
      tone: {
        default: "",
        danger: "hover:text-destructive",
      },
    },
    defaultVariants: { size: "default", tone: "default" },
  },
);

type IconButtonProps = React.ComponentProps<"button"> &
  VariantProps<typeof iconButtonVariants> & {
    label: string;
    asChild?: boolean;
  };

function IconButton({
  className,
  size,
  tone,
  label,
  asChild = false,
  ...props
}: IconButtonProps) {
  const Comp = asChild ? Slot : "button";
  return (
    <Comp
      data-slot="icon-button"
      data-tone={tone ?? undefined}
      type="button"
      aria-label={label}
      className={cn(iconButtonVariants({ size, tone }), className)}
      {...props}
    />
  );
}

export { Button, IconButton };
