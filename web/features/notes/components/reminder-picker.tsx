"use client";

import { isSameDay, startOfDay, startOfMonth } from "date-fns";
import {
  ArrowLeft,
  Bell,
  BellOff,
  BellRing,
  CalendarDays,
  Repeat,
} from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  formatOccurrence,
  formatTime,
  isReminderPast,
  nextOccurrence,
  nextRoundTime,
  parseWallClock,
  presetReminders,
  recurrenceLabels,
  recurrenceShortLabels,
  reminderLabel,
  toWallClock,
} from "@/features/notes/reminder";
import type { NoteReminder, ReminderRecurrence } from "@/features/notes/types";
import { cn } from "@/lib/utils";
import { ReminderCalendar } from "./reminder-calendar";
import { TimeField } from "./time-field";

interface ReminderPickerProps {
  reminder: NoteReminder | null;
  onReminderChange: (reminder: NoteReminder | null) => void;
  disabled?: boolean;
}

const DEFAULT_TIME = "09:00";

const pad = (value: number) => String(value).padStart(2, "0");

const clockOf = (at: Date) => `${pad(at.getHours())}:${pad(at.getMinutes())}`;

export function ReminderPicker({
  reminder,
  onReminderChange,
  disabled = false,
}: ReminderPickerProps) {
  const [open, setOpen] = useState(false);
  const [custom, setCustom] = useState(false);
  const [date, setDate] = useState<Date | null>(null);
  const [time, setTime] = useState(DEFAULT_TIME);
  const [recurrence, setRecurrence] = useState<ReminderRecurrence>("none");
  const [month, setMonth] = useState(() => startOfMonth(new Date()));
  const [presets, setPresets] = useState(presetReminders);

  const openWith = (next: boolean) => {
    if (next) {
      const at = reminder ? parseWallClock(reminder.remindAt) : null;
      setPresets(presetReminders());
      setDate(at ? startOfDay(at) : null);
      setTime(at ? clockOf(at) : DEFAULT_TIME);
      setRecurrence(reminder?.recurrence ?? "none");
      setMonth(startOfMonth(at ?? new Date()));
      setCustom(at !== null);
    }
    setOpen(next);
  };

  const applyPreset = (remindAt: string) => {
    const at = parseWallClock(remindAt);
    if (!at) return;
    setDate(startOfDay(at));
    setTime(clockOf(at));
    setMonth(startOfMonth(at));
  };

  const draftAt = date
    ? toWallClock(
        new Date(
          date.getFullYear(),
          date.getMonth(),
          date.getDate(),
          ...(time.split(":").map(Number) as [number, number]),
        ),
      )
    : null;
  const draft: NoteReminder | null = draftAt
    ? { remindAt: draftAt, recurrence, version: 0 }
    : null;
  const upcoming = draft ? nextOccurrence(draft) : null;
  const draftIsPast = draft !== null && isReminderPast(draft);

  const isSet = !!reminder;
  const overdue = isSet && isReminderPast(reminder);

  return (
    <Popover open={open && !disabled} onOpenChange={openWith}>
      <Tooltip>
        <TooltipTrigger asChild>
          <PopoverTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              disabled={disabled}
              aria-label={isSet ? "Edit reminder" : "Add reminder"}
              className={cn(
                "h-9 w-9 rounded-xl",
                isSet && "text-accent",
                overdue && "text-destructive",
              )}
            >
              {isSet ? (
                <BellRing className="h-4 w-4" />
              ) : (
                <Bell className="h-4 w-4" />
              )}
            </Button>
          </PopoverTrigger>
        </TooltipTrigger>
        <TooltipContent side="bottom">
          {isSet ? reminderLabel(reminder) : "Add reminder"}
        </TooltipContent>
      </Tooltip>

      <PopoverContent
        className="border-border/40 w-[320px] p-0 shadow-lg"
        align="end"
      >
        <div className="border-border/40 bg-muted/30 flex items-center gap-3 rounded-t-md border-b px-4 py-3">
          <div className="bg-accent/10 flex h-8 w-8 items-center justify-center rounded-lg">
            <Bell className="text-accent h-4 w-4" />
          </div>
          <div className="min-w-0">
            <h3 className="text-foreground text-sm font-medium">Reminder</h3>
            <p className="text-muted-foreground truncate text-xs">
              Only rings on the Anchor mobile app
            </p>
          </div>
        </div>

        <div className="space-y-4 p-4">
          {custom ? (
            <div className="space-y-3">
              <Button
                variant="ghost"
                size="sm"
                className="-ml-2 h-7 px-2 text-xs"
                onClick={() => setCustom(false)}
              >
                <ArrowLeft className="mr-1 h-3.5 w-3.5" />
                Quick options
              </Button>

              <ReminderCalendar
                selected={date}
                month={month}
                onMonthChange={setMonth}
                onSelect={(day) => {
                  setDate(day);
                  setMonth(startOfMonth(day));
                  const now = new Date();
                  if (isSameDay(day, now) && time <= clockOf(now)) {
                    setTime(nextRoundTime(now));
                  }
                }}
              />

              <div className="flex items-center justify-between gap-3">
                <Label htmlFor="reminder-time" className="text-xs">
                  Time
                </Label>
                <TimeField id="reminder-time" value={time} onChange={setTime} />
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              {presets.map((preset) => {
                const at = parseWallClock(preset.remindAt);
                return (
                  <button
                    key={preset.label}
                    type="button"
                    aria-pressed={draftAt === preset.remindAt}
                    onClick={() => applyPreset(preset.remindAt)}
                    className={cn(
                      "border-border/40 hover:border-accent/60 hover:bg-accent/5 focus-visible:ring-ring/50 rounded-xl border px-3 py-2 text-left transition-colors outline-none focus-visible:ring-2",
                      draftAt === preset.remindAt &&
                        "border-accent bg-accent/10",
                    )}
                  >
                    <span className="block text-xs font-medium">
                      {preset.label}
                    </span>
                    <span className="text-muted-foreground block text-[11px]">
                      {at ? formatTime(at) : preset.remindAt}
                    </span>
                  </button>
                );
              })}

              <button
                type="button"
                onClick={() => setCustom(true)}
                className="border-border/40 text-muted-foreground hover:border-accent/60 hover:text-foreground focus-visible:ring-ring/50 col-span-2 flex items-center justify-center gap-2 rounded-xl border border-dashed px-3 py-2 text-xs transition-colors outline-none focus-visible:ring-2"
              >
                <CalendarDays className="h-3.5 w-3.5" />
                Pick a date and time
              </button>
            </div>
          )}

          <div>
            <h4 className="text-muted-foreground mb-2 flex items-center gap-1.5 text-xs font-semibold tracking-wider uppercase">
              <Repeat className="h-3 w-3" />
              Repeat
            </h4>
            <ToggleGroup
              type="single"
              variant="outline"
              spacing={1}
              value={recurrence}
              onValueChange={(value) =>
                value && setRecurrence(value as ReminderRecurrence)
              }
              className="w-full"
            >
              {Object.entries(recurrenceShortLabels).map(([value, label]) => (
                <ToggleGroupItem
                  key={value}
                  value={value}
                  aria-label={recurrenceLabels[value as ReminderRecurrence]}
                  className="h-8 flex-1 rounded-lg px-1 text-[11px]"
                >
                  {label}
                </ToggleGroupItem>
              ))}
            </ToggleGroup>
          </div>
        </div>

        <div className="border-border/40 space-y-2 border-t px-4 py-3">
          <p
            className={cn(
              "text-xs",
              draftIsPast
                ? "text-amber-600 dark:text-amber-400"
                : "text-muted-foreground",
            )}
          >
            {!draft
              ? "Choose when to be reminded."
              : draftIsPast
                ? "That time has already passed."
                : upcoming
                  ? `Rings ${formatOccurrence(upcoming)}`
                  : ""}
          </p>
          <div className="flex items-center justify-between gap-2">
            {isSet ? (
              <Button
                variant="ghost"
                size="sm"
                className="text-destructive"
                onClick={() => {
                  onReminderChange(null);
                  setOpen(false);
                }}
              >
                <BellOff className="mr-1.5 h-3.5 w-3.5" />
                Remove
              </Button>
            ) : (
              <span />
            )}
            <Button
              size="sm"
              disabled={!draftAt}
              onClick={() => {
                if (!draftAt) return;
                onReminderChange({ remindAt: draftAt, recurrence, version: 0 });
                setOpen(false);
              }}
            >
              Save
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
