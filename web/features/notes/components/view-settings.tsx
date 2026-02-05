"use client";

import { useState } from "react";
import {
  LayoutGrid,
  Grid3x3,
  List,
  Settings2,
  Calendar,
  FileText,
  ArrowUp,
  ArrowDown,
  Check,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Separator } from "@/components/ui/separator";
import { cn } from "@/lib/utils";
import { ViewMode, SortBy, SortOrder } from "@/features/preferences";

interface ViewSettingsProps {
  viewMode: ViewMode;
  onViewModeChange: (mode: ViewMode) => void;
  sortBy: SortBy;
  onSortByChange: (sortBy: SortBy) => void;
  sortOrder: SortOrder;
  onSortOrderChange: (order: SortOrder) => void;
}

const viewModes: { value: ViewMode; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { value: "masonry", label: "Masonry", icon: LayoutGrid },
  { value: "grid", label: "Grid", icon: Grid3x3 },
  { value: "list", label: "List", icon: List },
];

const sortOptions: { value: SortBy; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { value: "updatedAt", label: "Last Modified", icon: Calendar },
  { value: "createdAt", label: "Date Created", icon: Calendar },
  { value: "title", label: "Title", icon: FileText },
];

export function ViewSettings({
  viewMode,
  onViewModeChange,
  sortBy,
  onSortByChange,
  sortOrder,
  onSortOrderChange,
}: ViewSettingsProps) {
  const [open, setOpen] = useState(false);

  const SortIcon = sortOrder === "asc" ? ArrowUp : ArrowDown;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          size="sm"
          className="h-8 px-3 gap-2 border-border/60 hover:border-primary/50 hover:bg-primary/5 hover:text-primary transition-all shadow-none rounded-full"
        >
          <Settings2 className="h-4 w-4" />
          <span className="text-xs font-medium">View</span>
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-56 p-2" align="end">
        <div className="space-y-1.5">
          {/* Sort By Section */}
          <div className="space-y-0.5">
            <div className="px-2 py-1.5">
              <span className="text-[10px] font-medium text-muted-foreground/70 uppercase tracking-wider">
                Sort
              </span>
            </div>
            <div className="space-y-0.5">
              {sortOptions.map((option) => {
                const Icon = option.icon;
                const isSelected = sortBy === option.value;
                return (
                  <div key={option.value} className="flex items-center gap-1">
                    <button
                      onClick={() => onSortByChange(option.value)}
                      className={cn(
                        "flex-1 flex items-center gap-2.5 px-2 py-1.5 rounded-sm text-sm transition-colors",
                        "hover:bg-primary/5",
                        isSelected
                          ? "bg-primary/10 text-primary font-medium"
                          : "text-muted-foreground"
                      )}
                    >
                      <Icon className={cn(
                        "h-3.5 w-3.5 transition-colors",
                        isSelected ? "text-primary" : "text-muted-foreground/60"
                      )} />
                      <span className="flex-1 text-left">{option.label}</span>
                      {isSelected && (
                        <Check className="h-3 w-3 text-primary" />
                      )}
                    </button>
                    {isSelected && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          onSortOrderChange(sortOrder === "asc" ? "desc" : "asc");
                        }}
                        className={cn(
                          "flex items-center justify-center px-2 py-1.5 rounded-sm text-xs font-medium transition-colors",
                          "bg-primary/10 text-primary",
                          "hover:bg-primary/15",
                          "border border-primary/20"
                        )}
                        title={`Sort ${sortOrder === "asc" ? "descending" : "ascending"}`}
                      >
                        <SortIcon className="h-4 w-3.5" />
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          <Separator className="my-1.5" />

          {/* View Mode Section */}
          <div className="space-y-0.5">
            <div className="px-2 py-1.5">
              <span className="text-[10px] font-medium text-muted-foreground/70 uppercase tracking-wider">
                View
              </span>
            </div>
            <div className="grid grid-cols-3 gap-1">
              {viewModes.map((mode) => {
                const Icon = mode.icon;
                const isSelected = viewMode === mode.value;
                return (
                  <button
                    key={mode.value}
                    onClick={() => {
                      onViewModeChange(mode.value);
                      setOpen(false);
                    }}
                    className={cn(
                      "flex flex-col items-center justify-center gap-1.5 px-2 py-2 rounded-sm text-xs transition-colors",
                      "hover:bg-primary/5",
                      isSelected
                        ? "bg-primary/10 text-primary font-medium border border-primary/20"
                        : "text-muted-foreground"
                    )}
                  >
                    <Icon className={cn(
                      "h-3.5 w-3.5 transition-colors",
                      isSelected ? "text-primary" : "text-muted-foreground/60"
                    )} />
                    <span>{mode.label}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}

