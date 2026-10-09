"use client";

import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { Menu, Search, X } from "lucide-react";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import { Tip } from "@/components/ui/tooltip";
import { hasShortcutKey, isMac } from "@/lib/platform";
import { cn } from "@/lib/utils";
import { useShellStore } from "./shell-store";

const scrollMemory = new Map<string, number>();

interface AppPageProps {
  title: React.ReactNode;
  actions?: React.ReactNode;
  scrollKey?: string;
  className?: string;
  children: React.ReactNode;
}

export function AppPage({
  title,
  actions,
  scrollKey,
  className,
  children,
}: AppPageProps) {
  const scrollRef = React.useRef<HTMLDivElement>(null);
  const [scrolled, setScrolled] = React.useState(false);

  React.useLayoutEffect(() => {
    const el = scrollRef.current;
    if (!el || !scrollKey) return;
    const savedTop = scrollMemory.get(scrollKey);
    if (savedTop) el.scrollTop = savedTop;
    return () => {
      scrollMemory.set(scrollKey, el.scrollTop);
    };
  }, [scrollKey]);

  return (
    <div
      ref={scrollRef}
      data-slot="page-scroll"
      onScroll={(e) => setScrolled(e.currentTarget.scrollTop > 0)}
      className="min-h-0 flex-1 scroll-pt-16 overflow-auto scrollbar-slim scrollbar-gutter-stable"
    >
      <header
        data-scrolled={scrolled || undefined}
        className="sticky top-0 z-(--z-sticky) flex min-h-16 items-center gap-2.5 px-gutter pt-3 pb-2.5 transition-[background-color,box-shadow] duration-(--duration-fade) data-scrolled:bg-background/84 data-scrolled:shadow-[0_1px_0_color-mix(in_srgb,var(--border)_55%,transparent)] data-scrolled:backdrop-blur-[14px] data-scrolled:backdrop-saturate-130 max-md:min-h-14 max-md:gap-1 max-md:px-gutter-phone max-md:pt-2.5 max-md:pb-2"
      >
        <MenuButton />
        {title}
        {actions && (
          <div className="ml-auto flex min-w-0 items-center gap-1.5">
            {actions}
          </div>
        )}
      </header>
      <div
        className={cn(
          "grid min-w-0 content-start gap-3.5 px-gutter pt-1.5 pb-10 max-md:px-gutter-phone max-md:pt-1 max-md:pb-24 *:min-w-0",
          className,
        )}
      >
        {children}
      </div>
    </div>
  );
}

function MenuButton() {
  const setDrawer = useShellStore((s) => s.setDrawer);
  return (
    <IconButton
      label="Open menu"
      onClick={() => setDrawer(true)}
      className="-ml-1.5 lg:hidden"
    >
      <Menu />
    </IconButton>
  );
}

export function PageTitle({
  count,
  icon,
  className,
  children,
}: {
  count?: number;
  icon?: React.ReactNode;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <h1
      className={cn(
        "m-0 flex min-w-0 items-center gap-2 whitespace-nowrap text-page max-md:text-page-phone",
        className,
      )}
    >
      {icon}
      <span className="truncate">{children}</span>
      {count !== undefined && (
        <span className="ml-0.5 font-medium text-muted-foreground text-ui tracking-normal tabular-nums">
          {count}
        </span>
      )}
    </h1>
  );
}

const topButtonVariants = cva(
  "inline-flex h-9.5 cursor-pointer items-center justify-center gap-2 whitespace-nowrap rounded-md border-0 px-3 font-medium text-control transition-colors duration-(--duration-hover) max-md:h-10 max-md:min-w-10 max-md:px-2.5 [&_svg]:size-4.25",
  {
    variants: {
      variant: {
        default:
          "bg-transparent text-muted-foreground hover:bg-foreground/6 hover:text-foreground aria-expanded:bg-foreground/6 aria-expanded:text-foreground aria-pressed:bg-foreground aria-pressed:text-card aria-pressed:shadow-xs",
        primary:
          "bg-foreground font-semibold text-card hover:bg-[color-mix(in_srgb,var(--foreground)_88%,var(--card))]",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

export function TopBarButton({
  icon,
  className,
  variant,
  asChild,
  children,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof topButtonVariants> & {
    icon?: React.ReactNode;
    asChild?: boolean;
  }) {
  const Comp = asChild ? Slot : "button";
  return (
    <Comp
      data-slot="top-bar-button"
      type={asChild ? undefined : "button"}
      className={cn(topButtonVariants({ variant }), className)}
      {...props}
    >
      {icon}
      {children && <span className="max-md:sr-only">{children}</span>}
    </Comp>
  );
}

export const SearchField = React.forwardRef<
  HTMLInputElement,
  {
    value: string;
    onChange: (value: string) => void;
    placeholder: string;
    className?: string;
    autoFocus?: boolean;
  }
>(({ value, onChange, placeholder, className, autoFocus }, forwardedRef) => {
  const input = React.useRef<HTMLInputElement>(null);
  React.useImperativeHandle(
    forwardedRef,
    () => input.current as HTMLInputElement,
  );
  const [open, setOpen] = React.useState(false);

  React.useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented) return;
      if (hasShortcutKey(e) && e.key.toLowerCase() === "k") {
        if (
          document.querySelector(
            "[role=dialog], [role=alertdialog], [role=menu]",
          )
        )
          return;
        e.preventDefault();
        setOpen(true);
        requestAnimationFrame(() => {
          input.current?.focus();
          input.current?.select();
        });
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, []);

  React.useEffect(() => {
    if (!autoFocus) return;
    setOpen(true);
    requestAnimationFrame(() => input.current?.focus());
  }, [autoFocus]);

  return (
    <>
      <label
        data-search-field
        data-open={open || undefined}
        className={cn(
          "group/search flex h-9.5 w-75 max-w-full items-center gap-2 rounded-md bg-card pr-2 pl-3 shadow-[inset_0_0_0_1px_var(--input),var(--sh-xs)] transition-[box-shadow,width] duration-(--duration-header) ease-standard focus-within:w-90 focus-within:shadow-[inset_0_0_0_2px_var(--ring)] max-md:hidden max-md:data-open:absolute max-md:data-open:inset-x-3 max-md:data-open:top-2 max-md:data-open:z-(--z-raised) max-md:data-open:flex max-md:data-open:w-auto [&>svg]:size-4 [&>svg]:text-muted-foreground",
          className,
        )}
      >
        <Search aria-hidden />
        <input
          ref={input}
          type="search"
          value={value}
          placeholder={placeholder}
          aria-label={placeholder}
          onChange={(e) => onChange(e.target.value)}
          onBlur={() => !value && setOpen(false)}
          onKeyDown={(e) => {
            if (e.key !== "Escape") return;
            if (value) {
              e.preventDefault();
              e.stopPropagation();
              onChange("");
            } else e.currentTarget.blur();
          }}
          className="h-full min-w-0 flex-1 border-0 bg-transparent p-0 text-foreground text-ui outline-none placeholder:text-muted-foreground focus-visible:outline-none [&::-webkit-search-cancel-button]:hidden"
        />
        {value ? (
          <Tip label="Clear search">
            <button
              type="button"
              aria-label="Clear search"
              onClick={() => {
                onChange("");
                input.current?.focus();
              }}
              className="grid size-6 flex-none cursor-pointer place-items-center rounded-sm bg-transparent p-0 text-muted-foreground hover:bg-muted hover:text-foreground [&>svg]:size-3.5"
            >
              <X />
            </button>
          </Tip>
        ) : (
          <kbd aria-hidden className="group-focus-within/search:hidden">
            {isMac() ? "⌘K" : "Ctrl K"}
          </kbd>
        )}
      </label>
      <IconButton
        label="Search"
        className="hidden max-md:inline-grid"
        onClick={() => {
          setOpen(true);
          requestAnimationFrame(() => input.current?.focus());
        }}
      >
        <Search />
      </IconButton>
    </>
  );
});
SearchField.displayName = "SearchField";

export function Fab({
  label,
  asChild,
  className,
  children,
  ...rest
}: React.ComponentProps<"button"> & { label: string; asChild?: boolean }) {
  const Comp = asChild ? Slot : "button";
  return (
    <Comp
      aria-label={label}
      className={cn(
        "absolute right-5 bottom-6 z-(--z-float) hidden size-14 cursor-pointer place-items-center rounded-fab border-0 bg-foreground text-card shadow-fab max-md:grid [&_svg]:size-6",
        className,
      )}
      {...rest}
    >
      {children}
    </Comp>
  );
}
