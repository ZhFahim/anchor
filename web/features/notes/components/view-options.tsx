"use client";

import {
  ALargeSmall,
  CalendarPlus,
  Check,
  GripVertical,
  Hand,
  LayoutDashboard,
  LayoutGrid,
  PencilLine,
  Rows3,
  SlidersHorizontal,
} from "lucide-react";
import { TopBarButton } from "@/components/layout/app-page";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { SegmentedControl } from "@/components/ui/segmented-control";
import type { SortBy, SortOrder, ViewMode } from "@/features/preferences";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";

interface ViewOptionsProps {
  layout: ViewMode;
  sortBy: SortBy;
  sortOrder: SortOrder;
  onLayout: (layout: ViewMode) => void;
  onSort: (sortBy: SortBy, sortOrder: SortOrder) => void;
}

const ORDER_OPTIONS: Record<SortBy, [SortOrder, string][]> = {
  updatedAt: [
    ["desc", "Newest first"],
    ["asc", "Oldest first"],
  ],
  createdAt: [
    ["desc", "Newest first"],
    ["asc", "Oldest first"],
  ],
  title: [
    ["asc", "A to Z"],
    ["desc", "Z to A"],
  ],
  custom: [],
};

const headingClass = "m-0 mb-2 text-label text-muted-foreground uppercase";

export function ViewOptions({
  layout,
  sortBy,
  sortOrder,
  onLayout,
  onSort,
}: ViewOptionsProps) {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <TopBarButton icon={<SlidersHorizontal aria-hidden />}>
          View
          {sortBy === "custom" && (
            <span className="ml-1.5 rounded-pill bg-accent/15 px-1.75 py-0.25 font-semibold text-accent-ink text-caption dark:text-accent">
              Custom
            </span>
          )}
        </TopBarButton>
      </PopoverTrigger>
      <PopoverContent
        align="end"
        aria-label="View options"
        className="grid w-68 gap-3 p-3"
      >
        <div>
          <h2 className={headingClass}>Layout</h2>
          <SegmentedControl
            variant="tiles"
            aria-label="Layout"
            value={layout}
            onValueChange={onLayout}
            options={[
              {
                value: "masonry",
                label: "Masonry",
                icon: <LayoutDashboard aria-hidden />,
              },
              {
                value: "grid",
                label: "Grid",
                icon: <LayoutGrid aria-hidden />,
              },
              { value: "list", label: "List", icon: <Rows3 aria-hidden /> },
            ]}
          />
        </div>
        <div>
          <h2 className={headingClass} id="sort-by">
            Sort by
          </h2>
          <SortChoices sortBy={sortBy} onSort={onSort} />
        </div>
        {sortBy === "custom" ? (
          <p className="m-0 flex gap-2.5 rounded-md bg-muted px-3 py-2.5 text-muted-foreground text-small [&>svg]:mt-0.5 [&>svg]:size-4 [&>svg]:flex-none">
            <Hand aria-hidden />
            Drag notes to arrange them. New notes appear at the top.
          </p>
        ) : (
          <SegmentedControl
            full
            aria-label="Order"
            value={sortOrder}
            onValueChange={(order) => onSort(sortBy, order)}
            options={ORDER_OPTIONS[sortBy].map(([value, label]) => ({
              value,
              label,
            }))}
          />
        )}
      </PopoverContent>
    </Popover>
  );
}

const SORT_CHOICES = [
  ["updatedAt", "Last edited", PencilLine],
  ["createdAt", "Date created", CalendarPlus],
  ["title", "Title", ALargeSmall],
  ["custom", "Custom order", GripVertical],
] as const;

function SortChoices({
  sortBy,
  onSort,
}: Pick<ViewOptionsProps, "sortBy" | "onSort">) {
  const roving = useRovingFocus<HTMLDivElement>({
    orientation: "both",
    selectsOnMove: true,
  });
  return (
    <div
      ref={roving.ref}
      role="radiogroup"
      aria-labelledby="sort-by"
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
      className="grid gap-px"
    >
      {SORT_CHOICES.map(([value, label, Icon]) => {
        const selected = sortBy === value;
        return (
          // biome-ignore lint/a11y/useSemanticElements: menu-style rows in a radio group
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() =>
              !selected && onSort(value, value === "title" ? "asc" : "desc")
            }
            className={cn(
              "relative flex h-8.5 cursor-pointer items-center gap-2.5 rounded-menu-item border-0 bg-transparent px-2.5 text-left text-ui hover:bg-foreground/6 focus-visible:bg-foreground/6 focus-visible:outline-transparent focus-visible:after:absolute focus-visible:after:top-1/2 focus-visible:after:left-0.75 focus-visible:after:-mt-2 focus-visible:after:h-4 focus-visible:after:w-0.75 focus-visible:after:rounded-xs focus-visible:after:bg-accent-strong focus-visible:after:content-[''] [&>svg]:size-4 [&>svg]:text-muted-foreground",
              selected && "font-semibold",
            )}
          >
            <Icon aria-hidden />
            {label}
            {selected && (
              <Check aria-hidden className="ml-auto text-accent-strong!" />
            )}
          </button>
        );
      })}
    </div>
  );
}
