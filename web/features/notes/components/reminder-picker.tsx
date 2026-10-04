"use client";

import {
  BellOff,
  CalendarDays,
  Calendar as CalendarIcon,
  CalendarRange,
  Check,
  Clock,
  Repeat,
  Sun,
  X,
} from "lucide-react";
import * as React from "react";
import { Button, IconButton } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Input } from "@/components/ui/input";
import { PopoverContent } from "@/components/ui/popover";
import { RollingText } from "@/components/ui/rolling-text";
import { SegmentedControl } from "@/components/ui/segmented-control";
import { Switch } from "@/components/ui/switch";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";
import {
  parseTimeInput,
  parseWallClock,
  presetReminders,
  reminderSummary,
  toWallClock,
} from "../reminder";
import type { NoteReminder, ReminderRecurrence } from "../types";

type Choice = "later" | "tomorrow" | "week" | "custom";
type Repeating = Exclude<ReminderRecurrence, "none">;

interface ReminderPickerProps {
  reminder: NoteReminder | null;
  onSave: (reminder: {
    remindAt: string;
    recurrence: ReminderRecurrence;
  }) => void;
  onRemove?: () => void;
  onClose?: () => void;
  now?: Date;
}

const ICONS = { later: Clock, tomorrow: Sun, week: CalendarRange } as const;
const REPEAT_OPTIONS: { value: Repeating; label: string }[] = [
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "yearly", label: "Yearly" },
];
const formatTime = (d: Date) =>
  d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
const formatDay = (d: Date) =>
  d.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
const withTime = (d: Date, hours: number, minutes: number) => {
  const result = new Date(d);
  result.setHours(hours, minutes, 0, 0);
  return result;
};

function ReminderPicker({
  reminder,
  onSave,
  onRemove,
  onClose,
  now: fixedNow,
}: ReminderPickerProps) {
  const [now] = React.useState(() => fixedNow ?? new Date());
  const presets = React.useMemo(() => presetReminders(now), [now]);
  const [when, setWhen] = React.useState<Date | null>(() =>
    reminder ? parseWallClock(reminder.remindAt) : null,
  );
  const [repeat, setRepeat] = React.useState<ReminderRecurrence>(
    reminder?.recurrence ?? "none",
  );
  const [lastRepeat, setLastRepeat] = React.useState<Repeating>(
    reminder && reminder.recurrence !== "none" ? reminder.recurrence : "weekly",
  );
  const [choice, setChoice] = React.useState<Choice | null>(() => {
    if (!reminder) return null;
    return (
      presets.find((p) => p.remindAt === reminder.remindAt)?.key ?? "custom"
    );
  });
  const [openField, setOpenField] = React.useState<"date" | "time" | null>(
    null,
  );
  const [typedTime, setTypedTime] = React.useState("");
  const summary = reminderSummary(when, repeat, now);
  const repeatId = React.useId();
  const timePillRef = React.useRef<HTMLButtonElement>(null);
  const whenChoices = useRovingFocus<HTMLDivElement>({
    orientation: "both",
    selectsOnMove: true,
    itemSelector: ':scope > [role="radio"]',
  });

  const pickPreset = (key: Exclude<Choice, "custom">) => {
    const preset = presets.find((p) => p.key === key);
    if (!preset) return;
    setWhen(parseWallClock(preset.remindAt));
    setChoice(key);
    setOpenField(null);
  };
  const pickCustom = () => {
    if (choice !== "custom" && !when)
      setWhen(
        withTime(
          new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1),
          9,
          0,
        ),
      );
    setChoice("custom");
    setOpenField((prev) => prev ?? "date");
  };

  const rowClass =
    "flex min-h-10.5 w-full cursor-pointer items-center gap-3 border-0 bg-transparent px-3 text-left text-ui hover:bg-foreground/4 focus-visible:-outline-offset-2 aria-checked:font-semibold [&>svg:first-child]:size-4.25 [&>svg:first-child]:text-muted-foreground";
  const groupClass =
    "overflow-hidden rounded-xl bg-card shadow-[0_0_0_1px_color-mix(in_srgb,var(--border)_55%,transparent)] [&>*+*]:border-border/55 [&>*+*]:border-t";

  return (
    <div
      role="dialog"
      aria-label="Reminder"
      className="grid w-87 max-w-full gap-2 bg-background px-3.5 pt-3 pb-3.5 max-md:w-auto"
    >
      <div className="flex items-start gap-2.5 p-0.5 pl-1">
        <div className="grid flex-1 gap-px">
          <b className="font-semibold text-lead">Reminder</b>
          <small className="text-muted-foreground text-small">
            Sent to the Anchor app on your phone
          </small>
        </div>
        {onClose && (
          <IconButton size="sm" label="Close" onClick={onClose}>
            <X />
          </IconButton>
        )}
      </div>

      <div
        data-slot="picker-group"
        className={cn(
          groupClass,
          "grid gap-0.5 px-3 pt-3.5 pb-3 text-center [&>*+*]:border-t-0",
        )}
        aria-live="polite"
      >
        <RollingText
          text={summary.headline}
          className={cn("text-heading", summary.past && "text-destructive")}
        />
        <RollingText
          text={summary.caption}
          className="text-meta text-muted-foreground"
        />
      </div>

      <div
        ref={whenChoices.ref}
        data-slot="picker-group"
        className={groupClass}
        role="radiogroup"
        aria-label="When"
        onFocus={whenChoices.onFocus}
        onKeyDown={whenChoices.onKeyDown}
      >
        {presets.map((preset) => {
          const Icon = ICONS[preset.key];
          const date = parseWallClock(preset.remindAt) as Date;
          return (
            // biome-ignore lint/a11y/useSemanticElements: a radio group of full-width rows
            <button
              key={preset.key}
              type="button"
              role="radio"
              aria-checked={choice === preset.key}
              className={rowClass}
              onClick={() => pickPreset(preset.key)}
            >
              <Icon aria-hidden />
              <span>{preset.label}</span>
              <span
                className={cn(
                  "ml-auto text-control tabular-nums",
                  choice === preset.key
                    ? "text-foreground"
                    : "text-muted-foreground",
                )}
              >
                {preset.key === "week"
                  ? `${formatDay(date).split(",")[0]}, ${formatTime(date)}`
                  : formatTime(date)}
              </span>
              <Tick checked={choice === preset.key} />
            </button>
          );
        })}
        {/* biome-ignore lint/a11y/useSemanticElements: one of the rows above */}
        <button
          type="button"
          role="radio"
          aria-checked={choice === "custom"}
          className={rowClass}
          onClick={pickCustom}
        >
          <CalendarDays aria-hidden />
          <span>Pick a date</span>
          <span className="ml-auto" />
          <Tick checked={choice === "custom"} />
        </button>
        {choice === "custom" && when && (
          <div className="grid animate-open gap-2 border-t-0! px-3 pt-1 pb-2.5">
            <div className="flex gap-2">
              <PillButton
                icon={<CalendarIcon aria-hidden />}
                expanded={openField === "date"}
                onClick={() =>
                  setOpenField(openField === "date" ? null : "date")
                }
              >
                {formatDay(when)}
              </PillButton>
              <PillButton
                ref={timePillRef}
                icon={<Clock aria-hidden />}
                expanded={openField === "time"}
                onClick={() =>
                  setOpenField(openField === "time" ? null : "time")
                }
              >
                {formatTime(when)}
              </PillButton>
            </div>
            {openField === "date" && (
              <Calendar
                value={when}
                now={now}
                onChange={(date) => {
                  setWhen(withTime(date, when.getHours(), when.getMinutes()));
                  setOpenField("time");
                  timePillRef.current?.focus();
                }}
              />
            )}
            {openField === "time" && (
              <>
                <Input
                  size="sm"
                  icon={<Clock aria-hidden />}
                  aria-label="Time"
                  placeholder="Type a time, like 4 PM"
                  value={typedTime}
                  onChange={(e) => setTypedTime(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key !== "Enter") return;
                    e.preventDefault();
                    const parsed = parseTimeInput(typedTime);
                    if (!parsed) return e.currentTarget.select();
                    const [hours, minutes] = parsed.split(":").map(Number);
                    setWhen(withTime(when, hours, minutes));
                    setTypedTime("");
                    setOpenField(null);
                    timePillRef.current?.focus();
                  }}
                />
                <TimeList
                  value={when}
                  onChange={(hours, minutes) => {
                    setWhen(withTime(when, hours, minutes));
                    setOpenField(null);
                    timePillRef.current?.focus();
                  }}
                />
              </>
            )}
          </div>
        )}
      </div>

      <div data-slot="picker-group" className={cn(groupClass, "px-3")}>
        <div className="flex min-h-10.5 items-center gap-3 text-ui [&>svg]:size-4.25 [&>svg]:text-muted-foreground">
          <Repeat aria-hidden />
          <label htmlFor={repeatId} className="flex-1 cursor-pointer">
            Repeat
          </label>
          <Switch
            id={repeatId}
            checked={repeat !== "none"}
            onCheckedChange={(checked) =>
              setRepeat(checked ? lastRepeat : "none")
            }
          />
        </div>
        {repeat !== "none" && (
          <div className="border-t-0! pb-3">
            <SegmentedControl
              full
              aria-label="How often"
              value={repeat}
              onValueChange={(value) => {
                setRepeat(value);
                setLastRepeat(value);
              }}
              options={REPEAT_OPTIONS}
              className="[&_button]:px-1.5 [&_button]:text-meta [&_span]:px-1.5 [&_span]:text-meta"
            />
          </div>
        )}
      </div>

      <div className="flex items-center gap-2 pt-0.5 max-md:sticky max-md:bottom-0 max-md:z-1 max-md:-mx-3.5 max-md:-mb-3.5 max-md:bg-background max-md:px-3.5 max-md:pt-2.5 max-md:pb-3.5">
        {reminder && onRemove && (
          <Button variant="danger" size="sm" onClick={onRemove}>
            <BellOff aria-hidden />
            Remove
          </Button>
        )}
        <Button
          className="ml-auto min-w-21 justify-center"
          disabled={!summary.ok}
          onClick={() =>
            when && onSave({ remindAt: toWallClock(when), recurrence: repeat })
          }
        >
          Save
        </Button>
      </div>
    </div>
  );
}

function Tick({ checked }: { checked: boolean }) {
  return (
    <Check
      aria-hidden
      className={cn(
        "size-4.25 text-accent-strong transition-[opacity,transform] duration-(--duration-fade) ease-standard",
        checked ? "scale-100 opacity-100" : "scale-60 opacity-0",
      )}
    />
  );
}

function PillButton({
  ref,
  icon,
  expanded,
  onClick,
  children,
}: {
  ref?: React.Ref<HTMLButtonElement>;
  icon: React.ReactNode;
  expanded: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      ref={ref}
      type="button"
      data-slot="pill-button"
      aria-expanded={expanded}
      onClick={onClick}
      className="inline-flex h-8.5 cursor-pointer items-center gap-2 rounded-md border-0 bg-muted px-3 font-semibold text-control tabular-nums aria-expanded:bg-primary aria-expanded:text-card aria-expanded:shadow-xs [&>svg]:size-3.75 [&>svg]:text-muted-foreground aria-expanded:[&>svg]:text-inherit"
    >
      {icon}
      {children}
    </button>
  );
}

function TimeList({
  value,
  onChange,
}: {
  value: Date;
  onChange: (hours: number, minutes: number) => void;
}) {
  const listRef = React.useRef<HTMLDivElement>(null);
  React.useLayoutEffect(() => {
    const chosen = listRef.current?.querySelector<HTMLElement>(
      '[aria-pressed="true"]',
    );
    if (chosen && listRef.current)
      listRef.current.scrollTop = chosen.offsetTop - 60;
  }, []);
  const slots: number[] = [];
  for (let minutes = 7 * 60; minutes <= 22 * 60 + 30; minutes += 30)
    slots.push(minutes);
  return (
    // biome-ignore lint/a11y/useSemanticElements: a grid of time buttons, not a form fieldset
    <div
      ref={listRef}
      role="group"
      aria-label="Times"
      data-slot="time-list"
      className="relative grid max-h-46 grid-cols-3 gap-1.5 overflow-auto p-0.5"
    >
      {slots.map((minutes) => {
        const selected = value.getHours() * 60 + value.getMinutes() === minutes;
        return (
          <button
            key={minutes}
            type="button"
            aria-pressed={selected}
            onClick={() => onChange(Math.floor(minutes / 60), minutes % 60)}
            className={cn(
              "h-8.5 cursor-pointer rounded-md border-0 bg-muted font-medium text-meta tabular-nums hover:bg-[color-mix(in_srgb,var(--foreground)_10%,var(--muted))] focus-visible:-outline-offset-2",
              selected && "bg-primary font-bold text-card hover:bg-primary",
            )}
          >
            {formatTime(
              withTime(value, Math.floor(minutes / 60), minutes % 60),
            )}
          </button>
        );
      })}
    </div>
  );
}

export function ReminderPopoverContent({
  align,
  reminder,
  onReminder,
  onClose,
}: {
  align: "start" | "end";
  reminder: NoteReminder | null;
  onReminder: (
    reminder: { remindAt: string; recurrence: ReminderRecurrence } | null,
  ) => void;
  onClose: () => void;
}) {
  return (
    <PopoverContent align={align} className="overflow-hidden bg-background p-0">
      <ReminderPicker
        reminder={reminder}
        onClose={onClose}
        onSave={(next) => {
          onClose();
          onReminder(next);
        }}
        onRemove={() => {
          onClose();
          onReminder(null);
        }}
      />
    </PopoverContent>
  );
}
