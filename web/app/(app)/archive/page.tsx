"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Archive, ArchiveRestore, Loader2 } from "lucide-react";
import {
  getArchivedNotes,
  unarchiveNote,
  deltaToFullPlainText,
  NoteBackground,
} from "@/features/notes";
import type { Note } from "@/features/notes";
import { getTags } from "@/features/tags";
import { Header } from "@/components/layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Pin } from "lucide-react";
import { useMemo } from "react";
import { cn } from "@/lib/utils";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { format } from "date-fns";
import { toast } from "sonner";
import { useState } from "react";
import * as React from "react";
import { useRouter } from "next/navigation";
import Masonry from "react-masonry-css";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
  TooltipProvider,
} from "@/components/ui/tooltip";

const masonryBreakpoints = {
  default: 4,
  1536: 4,
  1280: 3,
  1024: 3,
  768: 2,
  640: 1,
};

export default function ArchivePage() {
  const [searchQuery, setSearchQuery] = useState("");
  const queryClient = useQueryClient();
  const router = useRouter();

  const { data: notes = [], isLoading } = useQuery({
    queryKey: ["notes", "archive"],
    queryFn: getArchivedNotes,
  });

  const { data: tags = [] } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  // Join tags with notes based on tagIds
  const notesWithTags = useMemo(() => {
    return notes.map((note) => ({
      ...note,
      tags: note.tagIds
        ? note.tagIds
          .map((tagId) => tags.find((tag) => tag.id === tagId))
          .filter((tag): tag is NonNullable<typeof tag> => tag !== undefined)
        : [],
    }));
  }, [notes, tags]);

  const unarchiveMutation = useMutation({
    mutationFn: unarchiveNote,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["notes", "archive"] });
      toast.success("Note unarchived");
    },
    onError: () => {
      toast.error("Failed to unarchive note");
    },
  });

  const filteredNotes = notesWithTags.filter((note) => {
    if (!searchQuery.trim()) return true;
    const query = searchQuery.toLowerCase();
    return (
      note.title.toLowerCase().includes(query) ||
      deltaToFullPlainText(note.content).toLowerCase().includes(query)
    );
  });

  const handleNoteClick = (note: Note) => {
    // Store note in sessionStorage for quick access
    if (typeof window !== "undefined") {
      sessionStorage.setItem(`note-${note.id}`, JSON.stringify(note));
    }
    router.push(`/notes/${note.id}`);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Header searchQuery={searchQuery} onSearchChange={setSearchQuery} />

      <div className="flex-1 p-4 lg:p-6">
        <div className="mb-6">
          <h1 className="font-serif text-2xl font-bold">Archive</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Archived notes are hidden from your main notes list
          </p>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        ) : filteredNotes.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-center">
            <div className="w-20 h-20 rounded-full bg-muted/50 flex items-center justify-center mb-4">
              <Archive className="h-10 w-10 text-muted-foreground/50" />
            </div>
            <h3 className="text-xl font-medium text-foreground">
              Archive is empty
            </h3>
            <p className="text-sm text-muted-foreground mt-1">
              Archived notes will appear here
            </p>
          </div>
        ) : (
          <Masonry
            breakpointCols={masonryBreakpoints}
            className="flex w-auto -ml-4"
            columnClassName="pl-4 bg-clip-padding"
          >
            {filteredNotes.map((note) => (
              <div key={note.id} className="mb-4">
                <ArchiveNoteCard
                  note={note}
                  onUnarchive={() => unarchiveMutation.mutate(note.id)}
                  onClick={() => handleNoteClick(note)}
                  isUnarchiving={unarchiveMutation.isPending}
                />
              </div>
            ))}
          </Masonry>
        )}
      </div>
    </div>
  );
}

interface ArchiveNoteCardProps {
  note: Note;
  onUnarchive: () => void;
  onClick: () => void;
  isUnarchiving: boolean;
}

function ArchiveNoteCard({
  note,
  onUnarchive,
  onClick,
  isUnarchiving,
}: ArchiveNoteCardProps) {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [tooltipOpen, setTooltipOpen] = useState(false);
  const dialogJustClosedRef = React.useRef(false);

  const handleButtonClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setTooltipOpen(false);
    setDialogOpen(true);
  };

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open);
    if (!open) {
      setTooltipOpen(false);
      dialogJustClosedRef.current = true;
      setTimeout(() => {
        dialogJustClosedRef.current = false;
      }, 100);
    }
  };

  const handleCardClick = (e: React.MouseEvent) => {
    if (
      (e.target as HTMLElement).closest("button") ||
      (e.target as HTMLElement).closest("[data-slot='dialog-content']") ||
      (e.target as HTMLElement).closest("[data-slot='dialog-overlay']") ||
      dialogOpen ||
      dialogJustClosedRef.current
    ) {
      return;
    }
    onClick();
  };

  return (
    <Card
      className={cn(
        "group relative overflow-hidden cursor-pointer",
        "border border-border/40",
        "shadow-sm hover:shadow-xl",
        "transition-all duration-300 ease-out",
        "hover:border-border hover:-translate-y-1"
      )}
      onClick={handleCardClick}
    >
      <NoteBackground styleId={note.background} className="absolute inset-0" />
      <div className="relative">
        <CardContent>
          {/* Pin indicator */}
          {note.isPinned && (
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
              "text-lg"
            )}
          >
            {note.title || "Untitled"}
          </h3>

          {/* Content Preview */}
          {note.content && (
            <p className="text-sm text-muted-foreground mb-3 leading-relaxed whitespace-pre-line line-clamp-6">
              {deltaToFullPlainText(note.content)}
            </p>
          )}

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
          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <span className="font-medium">
              Archived {format(new Date(note.updatedAt), "MMM d, yyyy")}
            </span>
            <TooltipProvider>
              <Tooltip open={tooltipOpen && !dialogOpen} onOpenChange={setTooltipOpen}>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 hover:bg-accent hover:text-accent-foreground opacity-0 group-hover:opacity-100 transition-all duration-200 bg-background/80 backdrop-blur-sm border border-border/50"
                    onClick={handleButtonClick}
                  >
                    <ArchiveRestore className="h-3.5 w-3.5" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent side="top">Unarchive</TooltipContent>
              </Tooltip>
            </TooltipProvider>
            <Dialog open={dialogOpen} onOpenChange={handleDialogClose}>
              <DialogContent className="sm:max-w-md">
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                      <ArchiveRestore className="h-5 w-5 text-primary" />
                    </div>
                    Unarchive Note?
                  </DialogTitle>
                  <DialogDescription className="pt-2">
                    This note will be moved back to your notes.
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter className="gap-2 sm:gap-0">
                  <Button
                    variant="ghost"
                    onClick={() => setDialogOpen(false)}
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={() => {
                      onUnarchive();
                      setDialogOpen(false);
                    }}
                    disabled={isUnarchiving}
                  >
                    {isUnarchiving ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      "Unarchive"
                    )}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </div>
    </Card>
  );
}