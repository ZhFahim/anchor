"use client";

import { Check, X } from "lucide-react";
import * as React from "react";
import { useShellStore } from "@/components/layout/shell-store";
import { Tip } from "@/components/ui/tooltip";
import { usePresence } from "@/lib/hooks/use-presence";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";

interface SelectionBarAction {
  key: string;
  label: string;
  icon: React.ReactNode;
  onClick: (button: HTMLButtonElement) => void;
}

interface SelectionBarProps {
  open: boolean;
  count: number;
  total: number;
  onToggleAll: () => void;
  actions: SelectionBarAction[];
  onClose: () => void;
  "aria-label"?: string;
}

export function SelectionBar({
  open,
  count,
  total,
  onToggleAll,
  actions,
  onClose,
  ...props
}: SelectionBarProps) {
  const { mounted, leaving, done } = usePresence(open);
  const setBarShown = useShellStore((s) => s.setBarShown);
  const roving = useRovingFocus<HTMLDivElement>();
  React.useEffect(() => {
    setBarShown(open);
    return () => setBarShown(false);
  }, [open, setBarShown]);
  if (!mounted) return null;

  const allSelected = count > 0 && count === total;
  const barButtonClass =
    "inline-flex h-9 cursor-pointer items-center gap-2 rounded-md border-0 bg-transparent px-3 font-medium text-control text-inherit hover:bg-inverse-foreground/10 aria-disabled:cursor-default aria-disabled:hover:bg-transparent aria-disabled:*:opacity-40 max-md:w-10 max-md:justify-center max-md:px-0 [&_svg]:size-4";
  const divider = (
    <span
      aria-hidden
      className="mx-1 h-5 w-px flex-none bg-inverse-foreground/16"
    />
  );
  return (
    <div
      ref={roving.ref}
      data-slot="selection-bar"
      role="toolbar"
      aria-label={props["aria-label"] ?? "Selected notes"}
      inert={leaving || undefined}
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
      onAnimationEnd={(e) => e.target === e.currentTarget && leaving && done()}
      className={cn(
        "absolute bottom-6 left-1/2 z-(--z-float) flex max-w-[calc(100%-24px)] -translate-x-1/2 items-center gap-0.5 whitespace-nowrap rounded-xl bg-inverse p-1.5 text-inverse-foreground shadow-[var(--sh-bar),0_0_0_1px_color-mix(in_srgb,var(--inverse-foreground)_8%,transparent)] **:[:focus-visible]:outline-accent",
        "max-md:right-2.5 max-md:bottom-4 max-md:left-2.5 max-md:translate-x-0 max-md:justify-between",
        leaving ? "pointer-events-none animate-rise-out" : "animate-rise-in",
      )}
    >
      <span className="flex items-center gap-2 pr-3 pl-2 font-semibold text-ui tabular-nums">
        {/* biome-ignore lint/a11y/useSemanticElements: a three-state Select all (some, all, none) */}
        <button
          type="button"
          role="checkbox"
          aria-checked={allSelected ? true : count ? "mixed" : false}
          aria-label="Select all"
          onClick={onToggleAll}
          className={cn(
            "grid size-5 cursor-pointer place-items-center rounded-full border-[1.5px] border-current bg-transparent p-0 opacity-90 [&_svg]:size-3 [&_svg]:stroke-3",
            allSelected &&
              "border-inverse-foreground bg-inverse-foreground text-inverse opacity-100",
            count > 0 &&
              !allSelected &&
              "after:h-0.5 after:w-2 after:rounded-xs after:bg-current after:content-['']",
          )}
        >
          {allSelected && <Check aria-hidden />}
        </button>
        <span aria-live="polite">
          {count ? `${count} selected` : "Select notes"}
        </span>
      </span>
      {divider}
      {actions.map((action) => (
        <Tip key={action.key} label={action.label} side="top">
          <button
            type="button"
            className={barButtonClass}
            aria-disabled={!count || undefined}
            aria-label={action.label}
            onClick={(e) => {
              if (count) action.onClick(e.currentTarget);
            }}
          >
            {action.icon}
            <span className="max-md:hidden">{action.label}</span>
          </button>
        </Tip>
      ))}
      {divider}
      <Tip label="Stop selecting (Esc)" side="top">
        <button
          type="button"
          className={cn(barButtonClass, "w-9 justify-center px-0")}
          aria-label="Stop selecting"
          aria-keyshortcuts="Escape"
          onClick={onClose}
        >
          <X aria-hidden />
        </button>
      </Tip>
    </div>
  );
}
