"use client";

import { useRouter } from "next/navigation";
import { format } from "date-fns";
import { Pin } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { cn } from "@/lib/utils";
import type { Note } from "@/features/notes";
import { QuillPreview } from "@/features/notes";
import { NoteBackground } from "./backgrounds";
import { SharedNoteIndicator } from "./shared-note-indicator";

type ViewMode = "masonry" | "grid" | "list";

interface NoteCardProps {
  note: Note;
  index?: number;
  viewMode?: ViewMode;
  isSelectionMode?: boolean;
  isSelected?: boolean;
  onSelectChange?: (noteId: string, ctrlOrCmd: boolean, shift: boolean) => void;
}

export function NoteCard({
  note,
  index = 0,
  viewMode = "masonry",
  isSelectionMode = false,
  isSelected = false,
  onSelectChange,
}: NoteCardProps) {
  const router = useRouter();

  // Handle note click - store note in sessionStorage and navigate
  const handleNoteClick = (e: React.MouseEvent) => {
    const ctrlOrCmd = e.ctrlKey || e.metaKey;
    const shift = e.shiftKey;

    // If in selection mode or using keyboard modifiers, handle selection
    if (isSelectionMode || ctrlOrCmd || shift) {
      e.preventDefault();
      e.stopPropagation();
      // Prevent text selection
      if (window.getSelection) {
        window.getSelection()?.removeAllRanges();
      }
      onSelectChange?.(note.id, ctrlOrCmd, shift);
      return;
    }

    e.preventDefault();
    // Store note in sessionStorage for the editor page to use
    sessionStorage.setItem(`note-${note.id}`, JSON.stringify(note));
    router.push(`/notes/${note.id}`);
  };

  // Handle checkbox change
  const handleCheckboxChange = (checked: boolean) => {
    // Checkbox click is treated as a simple toggle (no modifiers, but in selection mode)
    onSelectChange?.(note.id, false, false);
  };

  const previewMaxLines =
    viewMode === "list" ? 2 : viewMode === "grid" ? 4 : 6;

  // Calculate stagger delay (max 500ms for first 10 items)
  const staggerDelay = Math.min(index * 50, 500);

  // List view layout
  if (viewMode === "list") {
    return (
      <div
        onClick={handleNoteClick}
        onMouseDown={(e) => {
          // Prevent text selection when using modifier keys
          if (e.ctrlKey || e.metaKey || e.shiftKey) {
            e.preventDefault();
          }
        }}
        className="block cursor-pointer select-none"
      >
        <Card
          className={cn(
            "group relative overflow-hidden cursor-pointer",
            "border border-border/40",
            "shadow-sm hover:shadow-md",
            "transition-all duration-200 ease-out",
            "hover:border-border",
            "animate-in fade-in-0 slide-in-from-left-4",
            isSelected && "ring-1 ring-primary/50 ring-offset-1"
          )}
          style={{
            animationDelay: `${staggerDelay}ms`,
            animationFillMode: "backwards",
          }}
        >
          <NoteBackground styleId={note.background} className="absolute inset-0" />
          <div className="relative">
            <CardContent>
              <div className="flex items-start gap-3">
                {/* Checkbox for selection mode */}
                {isSelectionMode && (
                  <div className="flex-shrink-0 mt-0.5" onClick={(e) => e.stopPropagation()}>
                    <Checkbox
                      checked={isSelected}
                      onCheckedChange={handleCheckboxChange}
                      className="h-4 w-4"
                    />
                  </div>
                )}

                {/* Pin indicator */}
                {note.isPinned && !isSelectionMode && (
                  <div className="flex-shrink-0 mt-0.5">
                    <Pin className="h-4 w-4 text-accent fill-accent" />
                  </div>
                )}

                <div className="flex-1 min-w-0">
                  {/* Title */}
                  <h3 className="font-semibold text-base leading-tight mb-1.5 line-clamp-1 group-hover:text-accent transition-colors duration-200">
                    {note.title || "Untitled"}
                  </h3>

                  {/* Content Preview */}
                  <QuillPreview
                    content={note.content}
                    maxLines={previewMaxLines}
                    className="mb-2"
                  />

                  {/* Tags, Shared Indicator, and Date */}
                  <div className="flex items-center gap-3 flex-wrap">
                    {note.tags && note.tags.length > 0 && (
                      <div className="flex flex-wrap gap-1.5">
                        {note.tags.slice(0, 3).map((tag) => (
                          <Badge
                            key={tag.id}
                            variant="secondary"
                            className="text-xs px-2 py-0.5 rounded-full font-medium"
                            style={{
                              backgroundColor: tag.color
                                ? `${tag.color}20`
                                : undefined,
                              color: tag.color || undefined,
                            }}
                          >
                            {tag.name}
                          </Badge>
                        ))}
                        {note.tags.length > 3 && (
                          <Badge
                            variant="secondary"
                            className="text-xs px-2 py-0.5 rounded-full"
                          >
                            +{note.tags.length - 3}
                          </Badge>
                        )}
                      </div>
                    )}
                    <SharedNoteIndicator note={note} />
                    <span className="text-xs text-muted-foreground font-medium">
                      {format(new Date(note.updatedAt), "MMM d, yyyy")}
                    </span>
                  </div>
                </div>
              </div>
            </CardContent>
          </div>
        </Card>
      </div>
    );
  }

  // Grid and Masonry view (similar layout, different sizing)
  return (
    <div
      onClick={handleNoteClick}
      onMouseDown={(e) => {
        // Prevent text selection when using modifier keys
        if (e.ctrlKey || e.metaKey || e.shiftKey) {
          e.preventDefault();
        }
      }}
      className="block cursor-pointer select-none"
    >
      <Card
        className={cn(
          "group relative overflow-hidden cursor-pointer",
          "border border-border/40",
          "shadow-sm hover:shadow-xl",
          "transition-all duration-300 ease-out",
          "hover:border-border hover:-translate-y-1",
          "animate-in fade-in-0 slide-in-from-bottom-4",
          viewMode === "grid" && "h-full",
          isSelected && "ring-1 ring-primary/50 ring-offset-1"
        )}
        style={{
          animationDelay: `${staggerDelay}ms`,
          animationFillMode: "backwards",
        }}
      >
        <NoteBackground styleId={note.background} className="absolute inset-0" />
        <div className="relative">
          <CardContent className={cn(viewMode === "grid" && "flex flex-col h-full")}>
            {/* Checkbox for selection mode */}
            {isSelectionMode && (
              <div className="absolute top-3 right-3 z-10" onClick={(e) => e.stopPropagation()}>
                <Checkbox
                  checked={isSelected}
                  onCheckedChange={handleCheckboxChange}
                  className="h-4 w-4 bg-background/90 backdrop-blur-sm shadow-sm"
                />
              </div>
            )}

            {/* Pin indicator */}
            {note.isPinned && !isSelectionMode && (
              <div className="absolute top-3 right-3 z-10">
                <div className="w-7 h-7 rounded-full bg-accent/10 backdrop-blur-sm flex items-center justify-center border border-accent/20">
                  <Pin className="h-3.5 w-3.5 text-accent fill-accent" />
                </div>
              </div>
            )}

            {/* Title */}
            <h3
              className={cn(
                "font-bold leading-tight mb-2 pr-8 line-clamp-2 group-hover:text-accent transition-colors duration-200",
                viewMode === "grid" ? "text-base" : "text-lg"
              )}
            >
              {note.title || "Untitled"}
            </h3>

            {/* Content Preview */}
            <QuillPreview
              content={note.content}
              maxLines={previewMaxLines}
              className={cn(
                "mb-3",
                viewMode === "grid" && "flex-1 min-h-0",
              )}
            />

            {/* Tags */}
            {note.tags && note.tags.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mb-3">
                {note.tags.slice(0, 3).map((tag) => (
                  <Badge
                    key={tag.id}
                    variant="secondary"
                    className="text-xs px-2 py-0.5 rounded-full font-medium"
                    style={{
                      backgroundColor: tag.color
                        ? `${tag.color}20`
                        : undefined,
                      color: tag.color || undefined,
                    }}
                  >
                    {tag.name}
                  </Badge>
                ))}
                {note.tags.length > 3 && (
                  <Badge
                    variant="secondary"
                    className="text-xs px-2 py-0.5 rounded-full"
                  >
                    +{note.tags.length - 3}
                  </Badge>
                )}
              </div>
            )}

            {/* Footer */}
            <div className="flex items-center justify-between text-xs text-muted-foreground mt-auto">
              <div className="flex items-center gap-2 flex-wrap">
                <SharedNoteIndicator note={note} />
                <span className="font-medium">
                  {format(new Date(note.updatedAt), "MMM d, yyyy")}
                </span>
              </div>
            </div>
          </CardContent>
        </div>
      </Card>
    </div>
  );
}
