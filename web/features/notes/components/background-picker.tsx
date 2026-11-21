"use client";

import { useTranslations } from "next-intl";
import * as React from "react";
import { PopoverTitle } from "@/components/ui/popover";
import type { Messages } from "@/i18n/messages";
import { BACKGROUNDS } from "@/lib/design/tokens";
import { cn } from "@/lib/utils";

type Background = { id: string | null; name: string; kind?: string };
type BackgroundId = Exclude<
  (typeof BACKGROUNDS)[keyof typeof BACKGROUNDS][number]["id"],
  null
>;

const NAME_KEYS = {
  color_yellow: "colorYellow",
  color_orange: "colorOrange",
  color_brown: "colorBrown",
  color_red: "colorRed",
  color_pink: "colorPink",
  color_purple: "colorPurple",
  color_dark_blue: "colorIndigo",
  color_blue: "colorBlue",
  color_teal: "colorTeal",
  color_green: "colorGreen",
  pattern_dots: "colorPatternDots",
  pattern_grid: "colorPatternGrid",
  pattern_lines: "colorPatternLines",
  pattern_waves: "colorPatternWaves",
  pattern_groceries: "colorPatternGroceries",
  pattern_music: "colorPatternMusic",
  pattern_travel: "colorPatternTravel",
  pattern_code: "colorPatternCode",
} as const satisfies Record<BackgroundId, keyof Messages>;

const nameKeyOf = (id: string | null) =>
  id === null ? "colorDefault" : NAME_KEYS[id as BackgroundId];

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
  const t = useTranslations();
  const isPattern = !!value?.startsWith("pattern_");
  const chosenName = (list: readonly Background[]) => {
    const chosen = list.find((b) => b.id === value);
    return chosen ? t(nameKeyOf(chosen.id)) : "";
  };
  return (
    <div
      className="grid w-75 max-w-full gap-3.5 p-3.5 max-md:w-auto"
      onPointerLeave={() => onPreview?.(false)}
    >
      <PopoverTitle className="sr-only">{t("notesBackground")}</PopoverTitle>
      <Section
        label={t("notesBackgroundColor")}
        chosen={isPattern ? "" : chosenName(BACKGROUNDS.colors)}
        items={BACKGROUNDS.colors}
        value={value}
        onChange={onChange}
        onPreview={onPreview}
        color
      />
      <Section
        label={t("notesBackgroundPattern")}
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
  const t = useTranslations();
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
          const name = t(nameKeyOf(background.id));
          return (
            // biome-ignore lint/a11y/useSemanticElements: tiles in a radio group
            <button
              key={background.id ?? "default"}
              type="button"
              role="radio"
              aria-checked={isChosen}
              aria-label={name}
              title={name}
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
              {color ? t("notesBackgroundSample") : ""}
            </button>
          );
        })}
      </div>
    </div>
  );
}
