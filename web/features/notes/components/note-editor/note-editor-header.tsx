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
  ListRestart,
  ListX,
  LoaderCircle,
  LogOut,
  Palette,
  Pin,
  PinOff,
  Trash2,
  UserPlus,
} from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
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
import type { ChecklistActions } from "../../hooks/use-checklist-actions";
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
  /** Only for a note you can edit. */
  checklist?: ChecklistActions;
}

export function NoteEditorHeader(props: NoteEditorHeaderProps) {
  const t = useTranslations();
  const locale = useLocale();
  const [reminderOpen, setReminderOpen] = React.useState(false);
  const roving = useRovingFocus<HTMLDivElement>();
  const [startedUnsaved] = React.useState(!props.saved);
  const afterSave = startedUnsaved && "after-save";
  // Runs once the menu has closed and let go of focus.
  const afterMenu = React.useRef<(() => void) | null>(null);
  const late = !!props.reminder && isReminderPast(props.reminder);
  const bellLabel = !props.reminder
    ? t("noteAddReminder")
    : t(late ? "noteLateReminder" : "noteReminder", {
        reminder: reminderLabel(props.reminder, t, locale),
      });
  const pinLabel = props.isPinned ? t("noteUnpin") : t("notePin");
  const shareLabel = props.sharedWithCount ? t("noteSharing") : t("noteShare");

  return (
    <div
      ref={roving.ref}
      className="ed-head"
      role="toolbar"
      aria-label={t("noteLabel")}
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
    >
      <div className="ed-head-l">
        <Tip label={t("commonBack")}>
          <IconButton label={t("commonBack")} onClick={props.onBack}>
            <ArrowLeft />
          </IconButton>
        </Tip>
        <SaveStatus state={props.saveState} onRetry={props.onRetrySave} />
      </div>
      {props.trashed && props.canViewHistory && (
        <div className="ed-head-r">
          <Tip label={t("noteVersionHistory")}>
            <IconButton
              label={t("noteVersionHistory")}
              onClick={props.onHistory}
            >
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
              <Tip label={t("noteBackground")}>
                <PopoverTrigger asChild>
                  <IconButton label={t("noteBackground")}>
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
            <Tip label={pinLabel}>
              <IconButton
                label={pinLabel}
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
            <Tip label={shareLabel}>
              <IconButton
                label={shareLabel}
                onClick={props.onShare}
                className={cn("max-md:hidden", afterSave)}
              >
                <UserPlus />
              </IconButton>
            </Tip>
          )}
          {props.saved && (
            <DropdownMenu>
              <Tip label={t("noteMore")}>
                <DropdownMenuTrigger asChild>
                  <IconButton label={t("noteMore")} className={cn(afterSave)}>
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
                    {pinLabel}
                  </DropdownMenuItem>
                  {props.isOwner && (
                    <DropdownMenuItem onSelect={props.onShare}>
                      <UserPlus />
                      {t("noteShare")}
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
                    {t("noteVersionHistory")}
                  </DropdownMenuItem>
                )}
                {props.isArchived ? (
                  <DropdownMenuItem onSelect={props.onUnarchive}>
                    <ArchiveRestore />
                    {t("noteUnarchive")}
                  </DropdownMenuItem>
                ) : (
                  <DropdownMenuItem onSelect={props.onArchive}>
                    <Archive />
                    {t("noteArchive")}
                  </DropdownMenuItem>
                )}
                <DropdownMenuSeparator />
                {props.checklist && <ChecklistMenuItems {...props.checklist} />}
                <DropdownMenuItem tone="danger" onSelect={props.onTrash}>
                  {props.isOwner ? <Trash2 /> : <LogOut />}
                  {props.isOwner
                    ? t("noteMoveToTrash")
                    : t("noteRemoveFromMine")}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      )}
    </div>
  );
}

function ChecklistMenuItems({
  getCounts,
  uncheckAll,
  deleteChecked,
}: ChecklistActions) {
  const t = useTranslations();
  const [counts] = React.useState(getCounts);
  if (!counts?.items) return null;
  const isNoneChecked = counts.checked === 0;
  return (
    <>
      <DropdownMenuItem disabled={isNoneChecked} onSelect={uncheckAll}>
        <ListRestart />
        {t("noteUncheckAll")}
      </DropdownMenuItem>
      <DropdownMenuItem
        tone="danger"
        disabled={isNoneChecked}
        onSelect={deleteChecked}
      >
        <ListX />
        {t("noteDeleteCheckedItems")}
      </DropdownMenuItem>
      <DropdownMenuSeparator />
    </>
  );
}

function SaveStatus({
  state,
  onRetry,
}: {
  state: SaveState;
  onRetry: () => void;
}) {
  const t = useTranslations();
  const online = useSyncStatus((s) => s.online);
  if (state === "new") return null;
  const labelClass = "max-md:sr-only";
  const waitingHint = online ? t("noteWaitingServer") : t("noteWaitingOffline");
  return (
    <span className="save" aria-live="polite">
      {state === "saved" && (
        <span data-s>
          <Check aria-hidden />
          <span className={labelClass}>{t("noteSaved")}</span>
        </span>
      )}
      {state === "saving" && (
        <span data-s>
          <LoaderCircle aria-hidden className="animate-spin" />
          <span className={labelClass}>{t("noteSaving")}</span>
        </span>
      )}
      {state === "offline" && (
        <Tip label={waitingHint}>
          <span data-s>
            <CloudOff aria-hidden />
            <span className={labelClass}>{t("noteWaitingToSave")}</span>
            <span className="sr-only">. {waitingHint}</span>
          </span>
        </Tip>
      )}
      {state === "failed" && (
        <span data-s className="font-medium text-late">
          <CircleAlert aria-hidden />
          <span className={labelClass}>{t("noteSaveFailed")}</span>
          <button
            type="button"
            onClick={onRetry}
            className="ml-0.5 cursor-pointer border-0 bg-transparent p-0 font-semibold text-inherit underline decoration-current/35 underline-offset-3 hover:decoration-current"
          >
            {t("commonRetry")}
          </button>
        </span>
      )}
    </span>
  );
}
