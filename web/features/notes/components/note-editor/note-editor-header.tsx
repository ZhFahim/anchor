"use client";

import {
  Archive,
  ArchiveRestore,
  ArrowLeft,
  Bell,
  BellRing,
  Check,
  CircleAlert,
  CloudOff,
  Ellipsis,
  History,
  LoaderCircle,
  LogOut,
  Palette,
  Pin,
  PinOff,
  Trash2,
  UserPlus,
} from "lucide-react";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Tip } from "@/components/ui/tooltip";
import { useSyncStatus } from "@/features/sync";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";
import { isReminderPast, reminderLabel } from "../../reminder";
import type { NoteReminder, ReminderRecurrence } from "../../types";
import { BackgroundPicker } from "../background-picker";
import { ReminderPopoverContent } from "../reminder-picker";

export type SaveState = "new" | "saving" | "saved" | "offline" | "failed";

interface NoteEditorHeaderProps {
  saveState: SaveState;
  onRetrySave: () => void;
  onBack: () => void;
  trashed?: boolean;
  readOnly?: boolean;
  canSetReminder: boolean;
  saved: boolean;
  isOwner: boolean;
  canViewHistory: boolean;
  isPinned: boolean;
  isArchived: boolean;
  background: string | null;
  reminder: NoteReminder | null;
  sharedWithCount: number;
  onTogglePin: () => void;
  onBackground: (background: string | null) => void;
  onPreviewBackground: (background: string | null | false) => void;
  onReminder: (
    reminder: { remindAt: string; recurrence: ReminderRecurrence } | null,
  ) => void;
  onShare: () => void;
  onHistory: () => void;
  onArchive: () => void;
  onUnarchive: () => void;
  onTrash: () => void;
}

export function NoteEditorHeader(props: NoteEditorHeaderProps) {
  const [reminderOpen, setReminderOpen] = React.useState(false);
  const roving = useRovingFocus<HTMLDivElement>();
  const [startedUnsaved] = React.useState(!props.saved);
  const afterSave = startedUnsaved && "after-save";
  // Runs once the menu has closed and let go of focus.
  const afterMenu = React.useRef<(() => void) | null>(null);
  const late = !!props.reminder && isReminderPast(props.reminder);
  const bellLabel = props.reminder
    ? `${late ? "Late reminder" : "Reminder"}: ${reminderLabel(props.reminder)}`
    : "Add a reminder";

  return (
    <div
      ref={roving.ref}
      className="ed-head"
      role="toolbar"
      aria-label="Note"
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
    >
      <div className="ed-head-l">
        <Tip label="Back">
          <IconButton label="Back" onClick={props.onBack}>
            <ArrowLeft />
          </IconButton>
        </Tip>
        <SaveStatus state={props.saveState} onRetry={props.onRetrySave} />
      </div>
      {props.trashed && props.canViewHistory && (
        <div className="ed-head-r">
          <Tip label="Version history">
            <IconButton label="Version history" onClick={props.onHistory}>
              <History />
            </IconButton>
          </Tip>
        </div>
      )}
      {!props.trashed && (
        <div className="ed-head-r">
          {!props.readOnly && (
            <Popover
              onOpenChange={(open) => !open && props.onPreviewBackground(false)}
            >
              <Tip label="Background">
                <PopoverTrigger asChild>
                  <IconButton label="Background">
                    <Palette />
                  </IconButton>
                </PopoverTrigger>
              </Tip>
              <PopoverContent align="end" className="p-0">
                <BackgroundPicker
                  value={props.background}
                  onChange={props.onBackground}
                  onPreview={props.onPreviewBackground}
                />
              </PopoverContent>
            </Popover>
          )}
          {props.canSetReminder && (
            <Popover open={reminderOpen} onOpenChange={setReminderOpen}>
              <Tip label={bellLabel}>
                <PopoverTrigger asChild>
                  <IconButton
                    label={bellLabel}
                    className={cn(
                      props.reminder &&
                        (late ? "text-late" : "text-accent-strong"),
                    )}
                  >
                    {late ? <BellRing /> : <Bell />}
                  </IconButton>
                </PopoverTrigger>
              </Tip>
              <ReminderPopoverContent
                align="end"
                reminder={props.reminder}
                onReminder={props.onReminder}
                onClose={() => setReminderOpen(false)}
              />
            </Popover>
          )}
          {props.saved && (
            <Tip label={props.isPinned ? "Unpin" : "Pin"}>
              <IconButton
                label={props.isPinned ? "Unpin" : "Pin"}
                aria-pressed={props.isPinned}
                onClick={props.onTogglePin}
                className={cn(
                  "max-md:hidden aria-pressed:[&_svg]:fill-current",
                  afterSave,
                )}
              >
                <Pin />
              </IconButton>
            </Tip>
          )}
          {props.saved && props.isOwner && (
            <Tip label={props.sharedWithCount ? "Sharing" : "Share"}>
              <IconButton
                label={props.sharedWithCount ? "Sharing" : "Share"}
                onClick={props.onShare}
                className={cn("max-md:hidden", afterSave)}
              >
                <UserPlus />
              </IconButton>
            </Tip>
          )}
          {props.saved && (
            <DropdownMenu>
              <Tip label="More">
                <DropdownMenuTrigger asChild>
                  <IconButton label="More" className={cn(afterSave)}>
                    <Ellipsis />
                  </IconButton>
                </DropdownMenuTrigger>
              </Tip>
              <DropdownMenuContent
                align="end"
                className="min-w-55"
                onCloseAutoFocus={(e) => {
                  const next = afterMenu.current;
                  if (!next) return;
                  afterMenu.current = null;
                  e.preventDefault();
                  next();
                }}
              >
                <div className="contents md:hidden">
                  <DropdownMenuItem onSelect={props.onTogglePin}>
                    {props.isPinned ? <PinOff /> : <Pin />}
                    {props.isPinned ? "Unpin" : "Pin"}
                  </DropdownMenuItem>
                  {props.isOwner && (
                    <DropdownMenuItem onSelect={props.onShare}>
                      <UserPlus />
                      Share
                    </DropdownMenuItem>
                  )}
                  <DropdownMenuSeparator />
                </div>
                {props.canViewHistory && (
                  <DropdownMenuItem
                    onSelect={() => {
                      afterMenu.current = props.onHistory;
                    }}
                  >
                    <History />
                    Version history
                  </DropdownMenuItem>
                )}
                {props.isArchived ? (
                  <DropdownMenuItem onSelect={props.onUnarchive}>
                    <ArchiveRestore />
                    Unarchive
                  </DropdownMenuItem>
                ) : (
                  <DropdownMenuItem onSelect={props.onArchive}>
                    <Archive />
                    Archive
                  </DropdownMenuItem>
                )}
                <DropdownMenuSeparator />
                <DropdownMenuItem tone="danger" onSelect={props.onTrash}>
                  {props.isOwner ? <Trash2 /> : <LogOut />}
                  {props.isOwner ? "Move to trash" : "Remove from my notes"}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      )}
    </div>
  );
}

function SaveStatus({
  state,
  onRetry,
}: {
  state: SaveState;
  onRetry: () => void;
}) {
  const online = useSyncStatus((s) => s.online);
  if (state === "new") return null;
  const labelClass = "max-md:sr-only";
  const waitingHint = online
    ? "The server isn’t answering. Keep this tab open so your changes can be saved."
    : "You’re offline. Keep this tab open so your changes can be saved.";
  return (
    <span className="save" aria-live="polite">
      {state === "saved" && (
        <span data-s>
          <Check aria-hidden />
          <span className={labelClass}>Saved</span>
        </span>
      )}
      {state === "saving" && (
        <span data-s>
          <LoaderCircle aria-hidden className="animate-spin" />
          <span className={labelClass}>Saving…</span>
        </span>
      )}
      {state === "offline" && (
        <Tip label={waitingHint}>
          <span data-s>
            <CloudOff aria-hidden />
            <span className={labelClass}>Waiting to save</span>
            <span className="sr-only">. {waitingHint}</span>
          </span>
        </Tip>
      )}
      {state === "failed" && (
        <span data-s className="font-medium text-late">
          <CircleAlert aria-hidden />
          <span className={labelClass}>Couldn’t save</span>
          <button
            type="button"
            onClick={onRetry}
            className="ml-0.5 cursor-pointer border-0 bg-transparent p-0 font-semibold text-inherit underline decoration-current/35 underline-offset-3 hover:decoration-current"
          >
            Try again
          </button>
        </span>
      )}
    </span>
  );
}
