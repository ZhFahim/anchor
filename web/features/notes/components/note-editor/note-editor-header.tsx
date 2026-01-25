"use client";

import {
  ArrowLeft,
  Trash2,
  Pin,
  PinOff,
  Loader2,
  Check,
  Archive,
  ArchiveRestore,
  Eye,
  RotateCcw,
  UserPlus,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
  TooltipProvider,
} from "@/components/ui/tooltip";
import {
  NoteBackgroundPicker,
} from "@/features/notes";
import { cn } from "@/lib/utils";

interface NoteEditorHeaderProps {
  isNew: boolean;
  isReadOnly: boolean;
  isPinned: boolean;
  isArchived: boolean;
  background: string | null;
  isSaving: boolean;
  hasUnsavedChanges: boolean;
  isSaved: boolean;
  isOwner?: boolean;
  permission?: "owner" | "viewer" | "editor";
  isTrashed?: boolean;
  hasShares?: boolean;
  onBack: () => void;
  onTogglePin: () => void;
  onBackgroundChange: (background: string | null) => void;
  onArchiveClick: () => void;
  onDeleteClick: () => void;
  onRestoreClick: () => void;
  onPermanentDeleteClick: () => void;
  onShareClick?: () => void;
  restorePending?: boolean;
  permanentDeletePending?: boolean;
}

export function NoteEditorHeader({
  isNew,
  isReadOnly,
  isPinned,
  isArchived,
  background,
  isSaving,
  hasUnsavedChanges,
  isSaved,
  isOwner = true,
  permission = "owner",
  isTrashed = false,
  hasShares = false,
  onBack,
  onTogglePin,
  onBackgroundChange,
  onArchiveClick,
  onDeleteClick,
  onRestoreClick,
  onPermanentDeleteClick,
  onShareClick,
  restorePending = false,
  permanentDeletePending = false,
}: NoteEditorHeaderProps) {
  return (
    <TooltipProvider delayDuration={0}>
      <header
        className={cn(
          "sticky top-0 z-40 flex h-16 items-center justify-between",
          "border-b border-border/30 backdrop-blur-sm px-4 lg:px-6",
          "bg-background/60 dark:bg-background/40"
        )}
      >
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="h-9 w-9 rounded-xl"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="bottom">Back to notes</TooltipContent>
        </Tooltip>

        <div className="flex items-center gap-2">
          {/* Save status indicator (hidden when read-only) */}
          {!isReadOnly && (
            <div
              className={cn(
                "flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all duration-300",
                "backdrop-blur-sm",
                isSaving && "bg-muted/80 text-muted-foreground",
                hasUnsavedChanges &&
                !isSaving &&
                "bg-amber-500/20 text-amber-600 dark:text-amber-400",
                isSaved && "bg-emerald-500/20 text-emerald-600 dark:text-emerald-400"
              )}
            >
              {isSaving ? (
                <>
                  <Loader2 className="h-3 w-3 animate-spin" />
                  <span>Saving...</span>
                </>
              ) : hasUnsavedChanges ? (
                <>
                  <div className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                  <span>Unsaved</span>
                </>
              ) : isSaved ? (
                <>
                  <Check className="h-3 w-3" />
                  <span>Saved</span>
                </>
              ) : null}
            </div>
          )}

          {/* Read-only indicator or permission badge */}
          {(isReadOnly || permission === "viewer") && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium backdrop-blur-sm bg-muted/80 text-muted-foreground">
              <Eye className="h-3 w-3" />
              <span>
                {isReadOnly ? "Read-only" : permission === "viewer" ? "Viewer" : "Read-only"}
              </span>
            </div>
          )}

          {(isTrashed || (isOwner && !isTrashed)) && (
            <div className="h-6 w-px bg-border/50 mx-1" />
          )}

          {!isReadOnly && (
            <>
              <NoteBackgroundPicker
                selectedBackground={background}
                onBackgroundChange={onBackgroundChange}
                disabled={isReadOnly}
              />

              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={onTogglePin}
                    disabled={isReadOnly}
                    className={cn(
                      "h-9 w-9 rounded-xl transition-colors",
                      isPinned && "text-accent bg-accent/10"
                    )}
                  >
                    {isPinned ? (
                      <Pin className="h-4 w-4 fill-current" />
                    ) : (
                      <PinOff className="h-4 w-4" />
                    )}
                  </Button>
                </TooltipTrigger>
                <TooltipContent side="bottom">
                  {isPinned ? "Unpin note" : "Pin note"}
                </TooltipContent>
              </Tooltip>
            </>
          )}

          {!isNew && isOwner && !isTrashed && onShareClick && (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={onShareClick}
                  className={cn(
                    "h-9 w-9 rounded-xl transition-colors",
                    hasShares && "text-primary bg-primary/10"
                  )}
                >
                  <UserPlus className="h-4 w-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="bottom">
                {hasShares ? "Manage shares" : "Share note"}
              </TooltipContent>
            </Tooltip>
          )}

          {!isNew && (
            <>
              {isTrashed ? (
                <>
                  {/* Restore button (only for trashed notes) */}
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={onRestoreClick}
                        disabled={restorePending}
                        className={cn(
                          "h-9 w-9 rounded-xl transition-colors",
                          "text-primary bg-primary/10"
                        )}
                      >
                        <RotateCcw className="h-4 w-4" />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent side="bottom">Restore note</TooltipContent>
                  </Tooltip>

                  {/* Permanent Delete button (only for trashed notes) */}
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={onPermanentDeleteClick}
                        disabled={permanentDeletePending}
                        className="h-9 w-9 rounded-xl text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                      >
                        {permanentDeletePending ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent side="bottom">Delete forever</TooltipContent>
                  </Tooltip>
                </>
              ) : (
                <>
                  {/* Archive and Delete only for owners */}
                  {isOwner && (
                    <>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={onArchiveClick}
                            className={cn(
                              "h-9 w-9 rounded-xl transition-colors",
                              isArchived && "text-primary bg-primary/10"
                            )}
                          >
                            {isArchived ? (
                              <ArchiveRestore className="h-4 w-4" />
                            ) : (
                              <Archive className="h-4 w-4" />
                            )}
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent side="bottom">
                          {isArchived ? "Unarchive note" : "Archive note"}
                        </TooltipContent>
                      </Tooltip>

                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={onDeleteClick}
                            className="h-9 w-9 rounded-xl text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent side="bottom">Move to trash</TooltipContent>
                      </Tooltip>
                    </>
                  )}
                </>
              )}
            </>
          )}
        </div>
      </header>
    </TooltipProvider>
  );
}

