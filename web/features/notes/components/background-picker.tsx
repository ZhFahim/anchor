"use client";

import * as React from "react";
import { PopoverTitle } from "@/components/ui/popover";
import { BACKGROUNDS } from "@/lib/design/tokens";
import { cn } from "@/lib/utils";

type Background = { id: string | null; name: string; kind?: string };

interface BackgroundPickerProps {
  value: string | null;
  onChange: (background: string | null) => void;
  /** false when the pointer leaves. */
  onPreview?: (background: string | null | false) => void;
}

const tileSize = (kind?: string) =>
  !kind
    ? undefined
    : kind.startsWith("icon")
      ? "30px 60px"
      : kind === "waves"
        ? "20px 20px"
        : kind === "dots"
          ? "20px 20px"
          : "24px 24px";

export function BackgroundPicker({
  value,
  onChange,
  onPreview,
}: BackgroundPickerProps) {
  const isPattern = !!value?.startsWith("pattern_");
  const chosenName = (list: readonly Background[]) =>
    list.find((b) => b.id === value)?.name ?? "";
  return (
    <div
      className="grid w-75 max-w-full gap-3.5 p-3.5 max-md:w-auto"
      onPointerLeave={() => onPreview?.(false)}
    >
      <PopoverTitle className="sr-only">Background</PopoverTitle>
      <Section
        label="Color"
        chosen={isPattern ? "" : chosenName(BACKGROUNDS.colors)}
        items={BACKGROUNDS.colors}
        value={value}
        onChange={onChange}
        onPreview={onPreview}
        color
      />
      <Section
        label="Pattern"
        chosen={isPattern ? chosenName(BACKGROUNDS.patterns) : ""}
        items={BACKGROUNDS.patterns}
        value={value}
        onChange={onChange}
        onPreview={onPreview}
      />
    </div>
  );
}

function Section({
  label,
  chosen,
  items,
  value,
  onChange,
  onPreview,
  color,
}: {
  label: string;
  chosen: string;
  items: readonly Background[];
  value: string | null;
  onChange: (id: string | null) => void;
  onPreview?: (id: string | null | false) => void;
  color?: boolean;
}) {
  const gridRef = React.useRef<HTMLDivElement>(null);
  const chooseByKeyboard = (id: string | null) => {
    onChange(id);
    onPreview?.(false);
  };
  const move = (e: React.KeyboardEvent, index: number) => {
    const step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: 6, ArrowUp: -6 }[
      e.key
    ];
    if (!step) return;
    e.preventDefault();
    const next = Math.min(items.length - 1, Math.max(0, index + step));
    chooseByKeyboard(items[next].id);
    gridRef.current?.querySelectorAll<HTMLElement>("button")[next]?.focus();
  };
  const chosenIndex = items.findIndex((b) => b.id === value);
  return (
    <div>
      <div className="mb-2.5 flex items-baseline justify-between">
        <span className="text-label text-muted-foreground uppercase">
          {label}
        </span>
        <span className="text-(length:--text-meta) text-muted-foreground">
          {chosen}
        </span>
      </div>
      <div
        ref={gridRef}
        role="radiogroup"
        aria-label={label}
        className="grid grid-cols-6 gap-2"
      >
        {items.map((background, index) => {
          const isChosen = background.id === value;
          return (
            // biome-ignore lint/a11y/useSemanticElements: tiles in a radio group
            <button
              key={background.id ?? "default"}
              type="button"
              role="radio"
              aria-checked={isChosen}
              aria-label={background.name}
              title={background.name}
              tabIndex={isChosen || (chosenIndex < 0 && index === 0) ? 0 : -1}
              data-note={background.id ?? ""}
              onClick={(e) =>
                // A click count of 0 means Enter or Space.
                e.detail === 0
                  ? chooseByKeyboard(background.id)
                  : onChange(background.id)
              }
              onKeyDown={(e) => move(e, index)}
              onPointerEnter={() => onPreview?.(background.id)}
              style={{ backgroundSize: tileSize(background.kind) }}
              className={cn(
                "grid aspect-square max-w-full cursor-pointer place-items-center rounded-lg border border-note-border bg-note bg-(image:--note-image) p-0 font-semibold text-meta text-foreground transition-[transform,box-shadow] duration-(--duration-hover) ease-standard hover:-translate-y-px",
                isChosen &&
                  "shadow-[0_0_0_2px_var(--card),0_0_0_4px_var(--ring)]",
              )}
            >
              {color ? "Aa" : ""}
            </button>
          );
        })}
      </div>
    </div>
  );
}
