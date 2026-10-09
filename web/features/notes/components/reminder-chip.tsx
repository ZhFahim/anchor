"use client";

import { Bell, BellRing } from "lucide-react";
import * as React from "react";
import { cn } from "@/lib/utils";
import { isReminderPast, reminderLabel } from "../reminder";
import type { NoteReminder } from "../types";

const alreadyRung = new Set<string>();

export function useRingOnce(noteId: string, late: boolean) {
  const [ringingNoteId, setRingingNoteId] = React.useState<string | null>(null);
  // Set while rendering: the ring must be there on the first late frame.
  if (late && ringingNoteId !== noteId && !alreadyRung.has(noteId)) {
    setRingingNoteId(noteId);
  } else if (!late && ringingNoteId !== null) {
    setRingingNoteId(null);
  }
  React.useEffect(() => {
    if (late) alreadyRung.add(noteId);
  }, [late, noteId]);
  return late && ringingNoteId === noteId;
}

interface ReminderChipProps {
  noteId: string;
  reminder: NoteReminder;
  size?: "default" | "sm";
  className?: string;
}

export function ReminderChip({
  noteId,
  reminder,
  size = "default",
  className,
}: ReminderChipProps) {
  const late = isReminderPast(reminder);
  const ringBell = useRingOnce(noteId, late);
  const small = size === "sm";
  return (
    <span
      data-slot="reminder-chip"
      title={late ? "Reminder time has passed" : "Reminder"}
      className={cn(
        "inline-flex min-w-0 items-center whitespace-nowrap rounded-pill font-medium [&_svg]:flex-none",
        small
          ? "h-chip-card gap-1 pr-2 pl-1.75 text-caption [&_svg]:size-3"
          : "h-chip gap-1.25 pr-2 pl-2.25 text-chip [&_svg]:size-3",
        late
          ? "bg-[color-mix(in_srgb,var(--late)_var(--mix-late),var(--note-surface))] text-late"
          : "bg-note-surface text-foreground shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--note-border)_55%,transparent)] [&_svg]:text-note-muted",
        ringBell && "[&_svg]:origin-[50%_15%] [&_svg]:animate-bell-ring",
        className,
      )}
    >
      {late ? <BellRing aria-hidden /> : <Bell aria-hidden />}
      <span className="truncate">
        {late && <span className="sr-only">Late: </span>}
        {reminderLabel(reminder)}
      </span>
    </span>
  );
}
