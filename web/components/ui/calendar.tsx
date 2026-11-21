"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const isSameDay = (a: Date, b: Date) => a.toDateString() === b.toDateString();
const addDays = (d: Date, n: number) => {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
};
const endOfDay = (d: Date) =>
  new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59);

type WeekInfo = { firstDay: number };
type LocaleWithWeek = Intl.Locale & {
  getWeekInfo?: () => WeekInfo;
  weekInfo?: WeekInfo;
};

// CLDR regions whose weeks start on Sunday or Saturday; the rest start on Monday.
const SUNDAY_FIRST = new Set(
  "AG AS BD BR BS BT BW BZ CA CN CO DM DO ET GT GU HK HN ID IL IN JM JP KE KH KR LA MH MM MO MT MX MZ NI NP PA PE PH PK PR PT PY SA SG SV TH TT TW UM US VE VI WS YE ZA ZW".split(
    " ",
  ),
);
const SATURDAY_FIRST = new Set(
  "AE AF BH DJ DZ EG IQ IR JO KW LY OM QA SD SY".split(" "),
);

/** The day a locale's weeks start on, counted like Date.getDay: 0 is Sunday. */
function firstDayOfWeek(locale: string) {
  try {
    const info = new Intl.Locale(locale) as LocaleWithWeek;
    const firstDay = (info.getWeekInfo?.() ?? info.weekInfo)?.firstDay;
    if (firstDay) return firstDay % 7;
    const region = info.maximize().region;
    if (region)
      return SUNDAY_FIRST.has(region) ? 0 : SATURDAY_FIRST.has(region) ? 6 : 1;
  } catch {}
  return 0;
}

/** January 4, 1970 was a Sunday. */
const weekdayDate = (day: number) => new Date(1970, 0, 4 + day);

interface CalendarProps {
  value: Date | null;
  onChange: (day: Date) => void;
  now?: Date;
  noPast?: boolean;
}

export function Calendar({
  value,
  onChange,
  now = new Date(),
  noPast = true,
}: CalendarProps) {
  const t = useTranslations();
  const locale = useLocale();
  const firstDay = React.useMemo(() => firstDayOfWeek(locale), [locale]);
  const weekdays = React.useMemo(() => {
    const narrow = new Intl.DateTimeFormat(locale, { weekday: "narrow" });
    return Array.from({ length: 7 }, (_, i) =>
      narrow.format(weekdayDate((firstDay + i) % 7)),
    );
  }, [locale, firstDay]);
  const daysIntoWeek = (d: Date) => (d.getDay() - firstDay + 7) % 7;
  const [month, setMonth] = React.useState(
    () => new Date((value ?? now).getFullYear(), (value ?? now).getMonth(), 1),
  );
  const gridRef = React.useRef<HTMLDivElement>(null);
  const [focusDay, setFocusDay] = React.useState<Date | null>(null);
  const monthLabel = month.toLocaleDateString(locale, {
    month: "long",
    year: "numeric",
  });
  const firstOfMonth = new Date(month.getFullYear(), month.getMonth(), 1);
  const gridStart = addDays(firstOfMonth, -daysIntoWeek(firstOfMonth));
  const days = Array.from({ length: 42 }, (_, i) => addDays(gridStart, i));
  const tabStopDay =
    value && days.some((d) => isSameDay(d, value)) ? value : now;

  React.useEffect(() => {
    if (!focusDay) return;
    gridRef.current
      ?.querySelector<HTMLElement>(`[data-day="${focusDay.toDateString()}"]`)
      ?.focus();
  }, [focusDay]);

  const onDayKeyDown = (e: React.KeyboardEvent, day: Date) => {
    const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[
      e.key
    ];
    let to: Date | null = null;
    if (step) to = addDays(day, step);
    else if (e.key === "PageUp" || e.key === "PageDown") {
      to = new Date(day);
      to.setMonth(day.getMonth() + (e.key === "PageUp" ? -1 : 1));
    } else if (e.key === "Home") to = addDays(day, -daysIntoWeek(day));
    else if (e.key === "End") to = addDays(day, 6 - daysIntoWeek(day));
    if (!to) return;
    e.preventDefault();
    if (noPast && endOfDay(to) < now) return;
    if (
      to.getMonth() !== month.getMonth() ||
      to.getFullYear() !== month.getFullYear()
    )
      setMonth(new Date(to.getFullYear(), to.getMonth(), 1));
    setFocusDay(to);
  };

  return (
    <div className="grid gap-1">
      <div className="flex items-center justify-between pb-1">
        <IconButton
          size="sm"
          label={t("uiCalendarPreviousMonth")}
          onClick={() =>
            setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))
          }
        >
          <ChevronLeft />
        </IconButton>
        <b className="font-semibold text-ui">{monthLabel}</b>
        <IconButton
          size="sm"
          label={t("uiCalendarNextMonth")}
          onClick={() =>
            setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))
          }
        >
          <ChevronRight />
        </IconButton>
      </div>
      {/* biome-ignore lint/a11y/useSemanticElements: a grid of day buttons, not a form fieldset */}
      <div
        ref={gridRef}
        role="group"
        aria-label={monthLabel}
        className="grid grid-cols-7 gap-0.5 text-center"
      >
        {weekdays.map((weekday, i) => (
          <span
            key={i}
            aria-hidden
            className="pt-0.5 pb-1 font-semibold text-caption text-muted-foreground uppercase tracking-[.04em]"
          >
            {weekday}
          </span>
        ))}
        {days.map((day) => {
          const isPast = noPast && endOfDay(day) < now;
          const selected = !!value && isSameDay(day, value);
          const isToday = isSameDay(day, now);
          return (
            <button
              key={day.toDateString()}
              type="button"
              data-day={day.toDateString()}
              tabIndex={isSameDay(day, tabStopDay) ? 0 : -1}
              aria-pressed={selected}
              aria-current={isToday ? "date" : undefined}
              aria-label={day.toLocaleDateString(locale, {
                weekday: "long",
                month: "long",
                day: "numeric",
              })}
              disabled={isPast}
              onClick={() => onChange(day)}
              onKeyDown={(e) => onDayKeyDown(e, day)}
              className={cn(
                "aspect-square h-8.25 max-w-full cursor-pointer justify-self-center rounded-full border-0 bg-transparent font-medium text-meta tabular-nums hover:bg-foreground/7",
                day.getMonth() !== month.getMonth() && "text-muted-foreground",
                isPast &&
                  "cursor-default text-muted-foreground line-through decoration-muted-foreground/40 hover:bg-transparent",
                isToday &&
                  !selected &&
                  "font-bold text-accent-ink shadow-[inset_0_0_0_1.5px_var(--ring)]",
                selected &&
                  "bg-primary font-bold text-card shadow-none hover:bg-primary",
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
