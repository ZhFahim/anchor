"use client";

import { Check, Hash, Plus, Search } from "lucide-react";
import * as React from "react";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { PopoverTitle } from "@/components/ui/popover";
import { ShortcutHints } from "@/components/ui/shortcut-hints";
import { SkeletonRows } from "@/components/ui/skeleton";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { cn } from "@/lib/utils";
import type { Tag } from "../types";
import { nextTagColor, tagColorStyle } from "../utils";

export type TagCheckState = boolean | "mixed";

interface TagPickerProps {
  tags: Tag[];
  loading?: boolean;
  loadFailed?: boolean;
  isRetrying?: boolean;
  onRetry?: () => void;
  state: (tagId: string) => TagCheckState;
  onToggle: (tag: Tag) => void;
  onCreate: (name: string) => Promise<Tag | undefined> | undefined;
  /** How many notes are being tagged, when more than one. */
  bulk?: number;
}

export function TagPicker({
  tags,
  loading = false,
  loadFailed = false,
  isRetrying,
  onRetry,
  state,
  onToggle,
  onCreate,
  bulk,
}: TagPickerProps) {
  const [query, setQuery] = React.useState("");
  const [active, setActive] = React.useState(0);
  const [creating, setCreating] = React.useState(false);
  const listRef = React.useRef<HTMLDivElement>(null);
  const listId = React.useId();
  const term = query.trim();
  const lowerTerm = term.toLowerCase();
  const sorted = React.useMemo(
    () => [...tags].sort((a, b) => a.name.localeCompare(b.name)),
    [tags],
  );
  const matches = sorted.filter((t) =>
    t.name.toLowerCase().includes(lowerTerm),
  );
  const exactMatch = matches.find((t) => t.name.toLowerCase() === lowerTerm);
  const shown = exactMatch
    ? [exactMatch, ...matches.filter((t) => t !== exactMatch)]
    : matches;
  const canCreate = !!term && !exactMatch && !loading && !loadFailed;
  const optionCount = shown.length + (canCreate ? 1 : 0);
  const activeIndex = Math.min(active, Math.max(0, optionCount - 1));

  const choose = async (index: number) => {
    if (index < shown.length) return onToggle(shown[index]);
    if (!canCreate || creating) return;
    setCreating(true);
    const created = await onCreate(term);
    setCreating(false);
    setQuery("");
    if (created)
      setActive(
        Math.max(
          0,
          sorted.findIndex((t) => t.name.localeCompare(created.name) >= 0),
        ),
      );
  };

  const highlightMatch = (name: string) => {
    if (!term) return name;
    const i = name.toLowerCase().indexOf(lowerTerm);
    if (i < 0) return name;
    return (
      <>
        {name.slice(0, i)}
        <mark className="bg-transparent font-bold text-inherit">
          {name.slice(i, i + term.length)}
        </mark>
        {name.slice(i + term.length)}
      </>
    );
  };

  const rowClass =
    "relative flex h-9 w-full cursor-pointer items-center gap-2.5 rounded-md border-0 bg-transparent px-2.5 text-left text-ui hover:bg-foreground/6 aria-selected:bg-foreground/6";
  const barClass =
    "data-kbd:after:absolute data-kbd:after:top-1/2 data-kbd:after:left-0.75 data-kbd:after:-mt-2 data-kbd:after:h-4 data-kbd:after:w-0.75 data-kbd:after:rounded-xs data-kbd:after:bg-accent-strong data-kbd:after:content-['']";
  const [usingKeyboard, setUsingKeyboard] = React.useState(false);
  const showLoadingShapes = useDelayedFlag(loading);
  const keepFocus = (e: React.MouseEvent) => e.preventDefault();

  return (
    <div className="grid w-72.5 max-w-full p-1.5 max-md:w-auto">
      <PopoverTitle className="sr-only">
        {bulk ? "Add tags" : "Tags"}
      </PopoverTitle>
      <Input
        autoFocus
        icon={<Search aria-hidden />}
        role="combobox"
        aria-expanded
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={
          optionCount ? `${listId}-${activeIndex}` : undefined
        }
        aria-label="Find or create a tag"
        placeholder="Find or create a tag"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setActive(0);
        }}
        onKeyDown={(e) => {
          if (e.key === "ArrowDown" || e.key === "ArrowUp") {
            e.preventDefault();
            setUsingKeyboard(true);
            const next =
              (activeIndex + (e.key === "ArrowDown" ? 1 : -1) + optionCount) %
              Math.max(optionCount, 1);
            setActive(next);
            listRef.current?.children[next]?.scrollIntoView({
              block: "nearest",
            });
          } else if (e.key === "Enter") {
            e.preventDefault();
            void choose(activeIndex);
          }
        }}
        boxClassName="m-0.5 mb-1.5 h-9.5 bg-muted shadow-none focus-within:bg-(--field-bg)"
      />
      {loading ? (
        <SkeletonRows
          count={3}
          className={cn("px-2.5 py-2", !showLoadingShapes && "invisible")}
        />
      ) : loadFailed ? (
        <LoadFailedRow
          message="Couldn’t load tags."
          onRetry={() => onRetry?.()}
          isRetrying={isRetrying}
          className="m-0.5"
        />
      ) : (
        <div
          ref={listRef}
          role="listbox"
          id={listId}
          aria-label="Tags"
          className="grid max-h-66 grid-cols-[minmax(0,1fr)] gap-px overflow-auto"
        >
          {shown.map((tag, i) => {
            const checked = state(tag.id);
            return (
              <div
                key={tag.id}
                id={`${listId}-${i}`}
                role="option"
                tabIndex={-1}
                aria-selected={i === activeIndex}
                aria-checked={checked}
                data-kbd={(usingKeyboard && i === activeIndex) || undefined}
                onPointerMove={() => {
                  setUsingKeyboard(false);
                  setActive(i);
                }}
                onMouseDown={keepFocus}
                onClick={() => void choose(i)}
                style={tagColorStyle(tag.color)}
                className={cn(rowClass, barClass, "tag-color")}
              >
                <span
                  aria-hidden
                  className="inline-grid text-(--hash) [&_svg]:size-3.75 [&_svg]:stroke-[2.75]"
                >
                  <Hash />
                </span>
                <span className="min-w-0 flex-1 truncate">
                  {highlightMatch(tag.name)}
                </span>
                <span className="text-muted-foreground text-small tabular-nums">
                  {tag._count?.notes ?? 0}
                </span>
                <span
                  aria-hidden
                  className={cn(
                    "grid size-checkbox place-items-center rounded-xs shadow-[inset_0_0_0_1.5px_var(--muted-foreground)] [&_svg]:size-3 [&_svg]:stroke-[3.2]",
                    checked === true &&
                      "bg-accent-strong text-(--check-mark,var(--card)) shadow-none",
                    checked === "mixed" &&
                      "shadow-[inset_0_0_0_1.5px_var(--ring)] after:h-0.5 after:w-2 after:rounded-xs after:bg-accent-strong after:content-['']",
                  )}
                >
                  {checked === true && <Check />}
                </span>
              </div>
            );
          })}
          {canCreate && (
            <div
              id={`${listId}-${shown.length}`}
              role="option"
              tabIndex={-1}
              aria-selected={activeIndex === shown.length}
              data-kbd={
                (usingKeyboard && activeIndex === shown.length) || undefined
              }
              onPointerMove={() => {
                setUsingKeyboard(false);
                setActive(shown.length);
              }}
              onMouseDown={keepFocus}
              onClick={() => void choose(shown.length)}
              style={tagColorStyle(nextTagColor(tags.length))}
              className={cn(
                rowClass,
                barClass,
                "tag-color text-foreground [&>svg]:size-3.75",
              )}
            >
              <Plus aria-hidden />
              <span className="min-w-0 flex-1 truncate">
                Create <b className="font-semibold">“{term}”</b>
              </span>
              <span
                aria-hidden
                className="inline-grid text-(--hash) [&_svg]:size-3.75 [&_svg]:stroke-[2.75]"
              >
                <Hash />
              </span>
            </div>
          )}
          {!optionCount && (
            <div className="px-2.5 py-3.5 text-center text-control text-muted-foreground">
              No tags yet. Type a name to create one.
            </div>
          )}
        </div>
      )}
      <div className="mt-1 flex items-center justify-between gap-2 border-border/55 border-t px-1.5 pt-2 pb-0.5 text-caption text-muted-foreground max-md:hidden">
        <ShortcutHints
          groups={[
            [["↑", "↓"], "move"],
            [["↵"], "pick"],
          ]}
          screenReaderText="Up and down arrows move, Enter picks"
        />
        <span>{bulk ? `${bulk} ${bulk === 1 ? "note" : "notes"}` : ""}</span>
      </div>
    </div>
  );
}
