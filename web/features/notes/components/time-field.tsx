"use client";

import { Clock } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { formatTime, parseTimeInput } from "@/features/notes/reminder";
import { cn } from "@/lib/utils";

interface TimeFieldProps {
  /** "HH:mm", 24-hour, matching the stored wall clock. */
  value: string;
  onChange: (value: string) => void;
  id?: string;
}

const pad = (value: number) => String(value).padStart(2, "0");

const hour12 =
  typeof Intl === "undefined" ||
  Intl.DateTimeFormat().resolvedOptions().hour12 !== false;

const HOURS = hour12
  ? Array.from({ length: 12 }, (_, index) => index + 1)
  : Array.from({ length: 24 }, (_, index) => index);
const MINUTES = Array.from({ length: 12 }, (_, index) => index * 5);

export function TimeField({ value, onChange, id }: TimeFieldProps) {
  const [open, setOpen] = useState(false);
  /** What the user is typing, until it is committed or abandoned. */
  const [draft, setDraft] = useState<string | null>(null);
  const rootRef = useRef<HTMLDivElement>(null);
  const [hours, minutes] = value.split(":").map(Number);

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };

    document.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  const commit = (nextHours: number, nextMinutes: number) => {
    setDraft(null);
    onChange(`${pad(nextHours)}:${pad(nextMinutes)}`);
  };

  /** Commits a typed time if it reads as one, and reverts otherwise. */
  const commitDraft = () => {
    if (draft === null) return;
    const parsed = parseTimeInput(draft);
    setDraft(null);
    if (parsed) onChange(parsed);
  };

  const minuteValues = MINUTES.includes(minutes)
    ? MINUTES
    : [...MINUTES, minutes].sort((a, b) => a - b);

  const isPm = hours >= 12;
  const displayHour = hour12 ? hours % 12 || 12 : hours;
  const toStoredHour = (shown: number) =>
    hour12 ? (shown % 12) + (isPm ? 12 : 0) : shown;

  return (
    <div ref={rootRef} className="relative">
      <div
        className={cn(
          "border-input dark:bg-input/30 flex h-9 w-32 items-center gap-1 rounded-md border bg-transparent pr-2 pl-3 text-sm shadow-xs transition-[color,box-shadow]",
          "focus-within:border-ring focus-within:ring-ring/50 focus-within:ring-[3px]",
          open && "border-ring ring-ring/50 ring-[3px]",
        )}
      >
        <input
          id={id}
          type="text"
          inputMode="numeric"
          autoComplete="off"
          spellCheck={false}
          value={draft ?? formatTime(new Date(2000, 0, 1, hours, minutes))}
          onChange={(event) => setDraft(event.target.value)}
          onFocus={(event) => {
            event.target.select();
            setOpen(true);
          }}
          onClick={() => setOpen(true)}
          onBlur={commitDraft}
          onKeyDown={(event) => {
            if (event.key === "Enter") {
              event.preventDefault();
              commitDraft();
              setOpen(false);
            }
            if (event.key === "Escape") setDraft(null);
          }}
          className="w-full min-w-0 bg-transparent outline-none"
        />
        <button
          type="button"
          onClick={() => setOpen((previous) => !previous)}
          aria-expanded={open}
          aria-label="Choose a time"
          className="text-muted-foreground hover:text-foreground shrink-0 transition-colors"
        >
          <Clock className="h-3.5 w-3.5" />
        </button>
      </div>

      {open && (
        <div className="bg-popover border-border/40 absolute right-0 z-50 mt-1 flex gap-1 rounded-xl border p-1.5 shadow-lg">
          <Column
            values={HOURS}
            label={(hour) => (hour12 ? String(hour) : pad(hour))}
            isActive={(hour) => hour === displayHour}
            onSelect={(hour) => commit(toStoredHour(hour), minutes)}
          />
          <Column
            values={minuteValues}
            label={pad}
            isActive={(minute) => minute === minutes}
            onSelect={(minute) => commit(hours, minute)}
          />
          {hour12 && (
            <div className="flex w-11 flex-col gap-0.5">
              {[false, true].map((pm) => (
                <button
                  key={pm ? "PM" : "AM"}
                  type="button"
                  onClick={() => commit((hours % 12) + (pm ? 12 : 0), minutes)}
                  className={cn(
                    "hover:bg-muted rounded-md py-1.5 text-xs transition-colors",
                    pm === isPm &&
                      "bg-accent text-accent-foreground hover:bg-accent font-medium",
                  )}
                >
                  {pm ? "PM" : "AM"}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Column({
  values,
  label,
  isActive,
  onSelect,
}: {
  values: number[];
  label: (value: number) => string;
  isActive: (value: number) => boolean;
  onSelect: (value: number) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const list = ref.current;
    const active = list?.querySelector<HTMLElement>('[data-active="true"]');
    if (list && active)
      list.scrollTop = active.offsetTop - list.clientHeight / 2;
  }, []);

  return (
    <div
      ref={ref}
      className="scrollbar-none flex max-h-40 w-11 flex-col gap-0.5 overflow-y-auto scroll-smooth"
    >
      {values.map((entry) => (
        <button
          key={entry}
          type="button"
          data-active={isActive(entry)}
          onClick={() => onSelect(entry)}
          className={cn(
            "hover:bg-muted shrink-0 rounded-md py-1.5 text-xs transition-colors",
            isActive(entry) &&
              "bg-accent text-accent-foreground hover:bg-accent font-medium",
          )}
        >
          {label(entry)}
        </button>
      ))}
    </div>
  );
}
