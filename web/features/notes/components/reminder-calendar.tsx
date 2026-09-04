"use client";

import {
  addDays,
  addMonths,
  eachDayOfInterval,
  endOfWeek,
  isSameDay,
  isSameMonth,
  startOfDay,
  startOfMonth,
  startOfWeek,
} from "date-fns";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface ReminderCalendarProps {
  selected: Date | null;
  month: Date;
  onMonthChange: (month: Date) => void;
  onSelect: (day: Date) => void;
  today?: Date;
}

/** A month grid with roving focus: one day is tabbable, arrow keys walk the rest. */
export function ReminderCalendar({
  selected,
  month,
  onMonthChange,
  onSelect,
  today = new Date(),
}: ReminderCalendarProps) {
  const startOfToday = startOfDay(today);
  const [focused, setFocused] = useState(() => selected ?? startOfToday);
  const gridRef = useRef<HTMLDivElement>(null);
  const steering = useRef(false);

  useEffect(() => {
    if (selected) setFocused(startOfDay(selected));
  }, [selected]);

  useEffect(() => {
    if (!steering.current) return;
    steering.current = false;
    gridRef.current
      ?.querySelector<HTMLButtonElement>(`[data-day="${focused.getTime()}"]`)
      ?.focus();
  }, [focused]);

  const moveTo = (day: Date) => {
    steering.current = true;
    setFocused(day);
    if (!isSameMonth(day, month)) onMonthChange(startOfMonth(day));
  };

  const handleKeyDown = (event: React.KeyboardEvent) => {
    const target = {
      ArrowLeft: () => addDays(focused, -1),
      ArrowRight: () => addDays(focused, 1),
      ArrowUp: () => addDays(focused, -7),
      ArrowDown: () => addDays(focused, 7),
      Home: () => startOfWeek(focused),
      End: () => endOfWeek(focused),
      PageUp: () => addMonths(focused, -1),
      PageDown: () => addMonths(focused, 1),
    }[event.key];

    if (!target) return;
    event.preventDefault();
    moveTo(target());
  };

  // Always six rows, so the popover height does not change between months.
  const gridStart = startOfWeek(startOfMonth(month));
  const days = eachDayOfInterval({
    start: gridStart,
    end: addDays(gridStart, 41),
  });

  return (
    <div>
      <div className="mb-2 flex items-center justify-between">
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7 rounded-lg"
          aria-label="Previous month"
          onClick={() => onMonthChange(addMonths(month, -1))}
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <span aria-live="polite" className="text-sm font-medium">
          {month.toLocaleDateString(undefined, {
            month: "long",
            year: "numeric",
          })}
        </span>
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7 rounded-lg"
          aria-label="Next month"
          onClick={() => onMonthChange(addMonths(month, 1))}
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>

      <div className="text-muted-foreground grid grid-cols-7 gap-0.5 pb-1 text-center text-[10px] font-semibold uppercase">
        {days.slice(0, 7).map((day) => (
          <div key={day.getDay()}>
            {day.toLocaleDateString(undefined, { weekday: "narrow" })}
          </div>
        ))}
      </div>

      <div
        ref={gridRef}
        onKeyDown={handleKeyDown}
        className="grid grid-cols-7 gap-0.5"
      >
        {days.map((day) => {
          const isSelected = selected !== null && isSameDay(day, selected);
          const isToday = isSameDay(day, startOfToday);
          const hasCaret = isSameDay(day, focused);

          return (
            <button
              key={day.getTime()}
              type="button"
              data-day={day.getTime()}
              tabIndex={hasCaret ? 0 : -1}
              aria-label={day.toDateString()}
              aria-pressed={isSelected}
              onClick={() => onSelect(day)}
              onFocus={() => setFocused(day)}
              className={cn(
                "mx-auto flex h-9 w-9 items-center justify-center rounded-full text-sm transition-colors",
                "hover:bg-muted focus-visible:ring-ring/50 outline-none focus-visible:ring-2",
                !isSameMonth(day, month) && "text-muted-foreground/50",
                isToday && !isSelected && "ring-accent/50 text-accent ring-1",
                isSelected &&
                  "bg-accent text-accent-foreground hover:bg-accent font-semibold",
              )}
            >
              {day.getDate()}
            </button>
          );
        })}
      </div>
    </div>
  );
}
