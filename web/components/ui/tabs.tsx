"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

interface TabsProps<T extends string> {
  value: T;
  onValueChange: (value: T) => void;
  tabs: readonly { value: T; label: React.ReactNode }[];
  panelId: string;
  "aria-label": string;
  className?: string;
}

function Tabs<T extends string>({
  value,
  onValueChange,
  tabs,
  panelId,
  className,
  ...props
}: TabsProps<T>) {
  const listRef = React.useRef<HTMLDivElement>(null);
  const tabId = (tabValue: string) => `${panelId}-tab-${tabValue}`;
  const onKeyDown = (e: React.KeyboardEvent) => {
    const currentIndex = tabs.findIndex((tab) => tab.value === value);
    const targetIndex = {
      ArrowRight: currentIndex + 1,
      ArrowLeft: currentIndex - 1,
      Home: 0,
      End: tabs.length - 1,
    }[e.key];
    if (targetIndex === undefined) return;
    e.preventDefault();
    const next = tabs[(targetIndex + tabs.length) % tabs.length];
    onValueChange(next.value);
    listRef.current
      ?.querySelector<HTMLElement>(`#${CSS.escape(tabId(next.value))}`)
      ?.focus();
  };
  return (
    <div
      ref={listRef}
      role="tablist"
      aria-label={props["aria-label"]}
      onKeyDown={onKeyDown}
      className={cn("mt-0.5 mb-1 flex gap-1", className)}
    >
      {tabs.map((tab) => {
        const selected = tab.value === value;
        return (
          <button
            key={tab.value}
            type="button"
            role="tab"
            id={tabId(tab.value)}
            aria-selected={selected}
            aria-controls={panelId}
            tabIndex={selected ? 0 : -1}
            onClick={() => onValueChange(tab.value)}
            className="relative inline-flex h-9 cursor-pointer items-center gap-2 rounded-md bg-transparent px-3 font-medium text-muted-foreground text-ui hover:bg-foreground/5 hover:text-foreground aria-selected:font-semibold aria-selected:text-foreground aria-selected:after:absolute aria-selected:after:inset-x-3 aria-selected:after:-bottom-0.5 aria-selected:after:h-0.5 aria-selected:after:rounded-xs aria-selected:after:bg-accent-strong aria-selected:after:content-['']"
          >
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}

function TabPanel({
  id,
  labelledBy,
  className,
  ...props
}: React.ComponentProps<"div"> & { labelledBy: string }) {
  return (
    <div
      role="tabpanel"
      id={id}
      aria-labelledby={labelledBy}
      tabIndex={-1}
      className={cn("outline-none", className)}
      {...props}
    />
  );
}

export { TabPanel, Tabs };
