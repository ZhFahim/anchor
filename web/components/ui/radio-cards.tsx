"use client";

import * as ToggleGroupPrimitive from "@radix-ui/react-toggle-group";
import { Check } from "lucide-react";
import type * as React from "react";
import { cn } from "@/lib/utils";

interface RadioCardOption<T extends string> {
  value: T;
  label: React.ReactNode;
  description?: React.ReactNode;
  icon?: React.ReactNode;
  picture?: React.ReactNode;
  disabled?: boolean;
}

interface RadioCardsProps<T extends string> {
  value: T;
  onValueChange: (value: T) => void;
  options: readonly RadioCardOption<T>[];
  "aria-label": string;
  className?: string;
}

function RadioCards<T extends string>({
  value,
  onValueChange,
  options,
  className,
  ...props
}: RadioCardsProps<T>) {
  return (
    <ToggleGroupPrimitive.Root
      data-slot="radio-cards"
      type="single"
      value={value}
      onValueChange={(selected) => selected && onValueChange(selected as T)}
      aria-label={props["aria-label"]}
      className={cn(
        "grid grid-cols-[repeat(auto-fit,minmax(150px,1fr))] gap-2.5",
        className,
      )}
    >
      {options.map((option) => (
        <ToggleGroupPrimitive.Item
          key={option.value}
          value={option.value}
          disabled={option.disabled}
          data-slot="radio-card"
          className="group/rc relative grid cursor-pointer content-start gap-1 rounded-xl bg-card px-3.5 pt-3.5 pb-3 text-left shadow-[inset_0_0_0_1px_var(--border)] transition-shadow duration-(--duration-hover) hover:shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--muted-foreground)_55%,var(--border))] disabled:cursor-default disabled:opacity-55 data-[state=on]:shadow-[inset_0_0_0_2px_var(--ring)]"
        >
          {option.picture}
          <b
            className={cn(
              "flex items-center gap-2 font-semibold text-ui [&>svg]:size-4 [&>svg]:text-muted-foreground",
              !option.picture && "pr-6",
            )}
          >
            {option.icon}
            {option.label}
          </b>
          {option.description && (
            <span className="text-muted-foreground text-small leading-[1.45]">
              {option.description}
            </span>
          )}
          <span
            aria-hidden
            data-slot="radio-card-check"
            className="absolute top-3 right-3 hidden size-5 place-items-center rounded-full bg-accent-strong text-(--check-mark,var(--card)) group-data-[state=on]/rc:grid [&>svg]:size-3 [&>svg]:stroke-[3.4]"
          >
            <Check />
          </span>
        </ToggleGroupPrimitive.Item>
      ))}
    </ToggleGroupPrimitive.Root>
  );
}

export { RadioCards };
