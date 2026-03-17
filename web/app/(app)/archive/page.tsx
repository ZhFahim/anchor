"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Archive, ArchiveRestore, Loader2 } from "lucide-react";
import {
  getArchivedNotes,
  unarchiveNote,
  deltaToFullPlainText,
  ArchiveDialog,
  NoteCard,
} from "@/features/notes";
import type { Note } from "@/features/notes";
import { getTags } from "@/features/tags";
import { Header } from "@/components/layout";
import { Button } from "@/components/ui/button";
import { useMemo } from "react";
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
      queryClient.invalidateQueries({ queryKey: ["tags"] });
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
  const dialogJustClosedRef = React.useRef(false);

  const handleDialogClose = (open: boolean) => {
    if (!open) {
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
    <NoteCard
      note={note}
      viewMode="masonry"
      footerLeft={
        <span className="font-medium">
          Archived {format(new Date(note.updatedAt), "MMM d, yyyy")}
        </span>
      }
      footerRight={
        <div onClick={(e) => e.stopPropagation()} className="flex items-center">
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7 hover:bg-accent hover:text-accent-foreground opacity-0 group-hover:opacity-100 transition-all duration-200 bg-background/80 backdrop-blur-sm border border-border/50"
                  onClick={(e) => {
                    e.stopPropagation();
                    setDialogOpen(true);
                  }}
                >
                  <ArchiveRestore className="h-3.5 w-3.5" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="top">Unarchive</TooltipContent>
            </Tooltip>
          </TooltipProvider>
          <ArchiveDialog
            open={dialogOpen}
            onOpenChange={handleDialogClose}
            isArchived={true}
            onConfirm={() => {
              onUnarchive();
              setDialogOpen(false);
            }}
            isPending={isUnarchiving}
          />
        </div>
      }
      onClick={handleCardClick}
    />
  );
}