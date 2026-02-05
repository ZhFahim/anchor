"use client";

import { useState, useMemo, useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import Masonry from "react-masonry-css";
import {
  Sparkles,
  Search,
  Loader2,
  X,
  Plus,
  Pin,
  Archive,
  Trash2,
  CheckCircle2,
  Circle,
  CircleCheck
} from "lucide-react";
import {
  getNotes,
  deltaToFullPlainText,
  bulkDeleteNotes,
  bulkArchiveNotes,
  useSelectionMode
} from "@/features/notes";
import { getTags } from "@/features/tags";
import { Header } from "@/components/layout";
import { NoteCard } from "@/features/notes";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { BulkDeleteDialog, BulkArchiveDialog, ViewSettings } from "@/features/notes";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import Link from "next/link";
import { usePreferencesStore } from "@/features/preferences";

const masonryBreakpoints = {
  default: 4,
  1536: 4,
  1280: 3,
  1024: 3,
  768: 2,
  640: 1,
};

export default function NotesPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const tagIdParam = searchParams.get("tagId");
  const [searchQuery, setSearchQuery] = useState("");
  const { notes: notesPrefs, setNotesPreference } = usePreferencesStore();
  const { viewMode, sortBy, sortOrder } = notesPrefs;
  const setViewMode = (value: typeof viewMode) => setNotesPreference("viewMode", value);
  const setSortBy = (value: typeof sortBy) => setNotesPreference("sortBy", value);
  const setSortOrder = (value: typeof sortOrder) => setNotesPreference("sortOrder", value);
  const [isSelectionMode, setIsSelectionMode] = useState(false);
  const [selectedNoteIds, setSelectedNoteIds] = useState<Set<string>>(new Set());
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [archiveDialogOpen, setArchiveDialogOpen] = useState(false);
  const [lastSelectedIndex, setLastSelectedIndex] = useState<number | null>(null);

  // Clear selection when exiting selection mode
  useEffect(() => {
    if (!isSelectionMode) {
      setSelectedNoteIds(new Set());
      setLastSelectedIndex(null);
    }
  }, [isSelectionMode]);

  // Handle keyboard shortcuts for selection mode
  useSelectionMode({
    isSelectionMode,
    onExit: () => {
      setIsSelectionMode(false);
      setSelectedNoteIds(new Set());
      setLastSelectedIndex(null);
    },
  });

  const { data: notes = [], isLoading: notesLoading } = useQuery({
    queryKey: ["notes", tagIdParam],
    queryFn: () => getNotes({ tagId: tagIdParam || undefined }),
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

  // Filter notes by search query
  const filteredNotes = useMemo(() => {
    if (!searchQuery.trim()) return notesWithTags;

    const query = searchQuery.toLowerCase();
    return notesWithTags.filter((note) => {
      const titleMatch = note.title.toLowerCase().includes(query);
      const contentMatch = deltaToFullPlainText(note.content).toLowerCase().includes(query);
      return titleMatch || contentMatch;
    });
  }, [notesWithTags, searchQuery]);

  // Separate pinned and unpinned notes (pinned always first, then sorted)
  const pinnedNotes = filteredNotes.filter((note) => note.isPinned);
  const unpinnedNotes = filteredNotes.filter((note) => !note.isPinned);

  // Sort pinned and unpinned separately
  const sortedPinnedNotes = useMemo(() => {
    return [...pinnedNotes].sort((a, b) => {
      let comparison = 0;
      if (sortBy === "title") {
        comparison = a.title.localeCompare(b.title);
      } else if (sortBy === "updatedAt") {
        comparison = new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime();
      } else if (sortBy === "createdAt") {
        comparison = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      }
      return sortOrder === "asc" ? comparison : -comparison;
    });
  }, [pinnedNotes, sortBy, sortOrder]);

  const sortedUnpinnedNotes = useMemo(() => {
    return [...unpinnedNotes].sort((a, b) => {
      let comparison = 0;
      if (sortBy === "title") {
        comparison = a.title.localeCompare(b.title);
      } else if (sortBy === "updatedAt") {
        comparison = new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime();
      } else if (sortBy === "createdAt") {
        comparison = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      }
      return sortOrder === "asc" ? comparison : -comparison;
    });
  }, [unpinnedNotes, sortBy, sortOrder]);

  // Get selected tag
  const selectedTag = tagIdParam
    ? tags.find((tag) => tag.id === tagIdParam)
    : null;

  // Handle note selection with keyboard modifiers
  const handleNoteSelect = (
    noteId: string,
    index: number,
    ctrlOrCmd: boolean,
    shift: boolean
  ) => {
    if (shift && lastSelectedIndex !== null) {
      // Range selection
      const start = Math.min(lastSelectedIndex, index);
      const end = Math.max(lastSelectedIndex, index);
      const notesToSelect = filteredNotes.slice(start, end + 1);

      setSelectedNoteIds((prev) => {
        const next = new Set(prev);
        notesToSelect.forEach((note) => {
          next.add(note.id);
        });
        return next;
      });
    } else if (ctrlOrCmd || isSelectionMode) {
      // Toggle individual selection (with CTRL/CMD or in selection mode)
      setSelectedNoteIds((prev) => {
        const next = new Set(prev);
        if (next.has(noteId)) {
          next.delete(noteId);
        } else {
          next.add(noteId);
        }
        return next;
      });
      setLastSelectedIndex(index);
    } else {
      // Single selection (replace all) - only when not in selection mode and no modifiers
      setSelectedNoteIds(new Set([noteId]));
      setLastSelectedIndex(index);
    }
  };

  // Combined sorted notes for selection
  const allSortedNotes = useMemo(() => {
    return [...sortedPinnedNotes, ...sortedUnpinnedNotes];
  }, [sortedPinnedNotes, sortedUnpinnedNotes]);

  // Select all / deselect all
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedNoteIds(new Set(allSortedNotes.map((note) => note.id)));
    } else {
      setSelectedNoteIds(new Set());
    }
  };

  const allSelected = allSortedNotes.length > 0 && selectedNoteIds.size === allSortedNotes.length;
  const someSelected = selectedNoteIds.size > 0 && selectedNoteIds.size < allSortedNotes.length;

  // Bulk delete mutation
  const bulkDeleteMutation = useMutation({
    mutationFn: (noteIds: string[]) => bulkDeleteNotes(noteIds),
    onSuccess: (_, noteIds) => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      toast.success(`${noteIds.length} note${noteIds.length > 1 ? "s" : ""} moved to trash`);
      setSelectedNoteIds(new Set());
      setIsSelectionMode(false);
      setDeleteDialogOpen(false);
    },
    onError: () => {
      toast.error("Failed to delete notes");
    },
  });

  // Bulk archive mutation
  const bulkArchiveMutation = useMutation({
    mutationFn: (noteIds: string[]) => bulkArchiveNotes(noteIds),
    onSuccess: (_, noteIds) => {
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      toast.success(`${noteIds.length} note${noteIds.length > 1 ? "s" : ""} archived`);
      setSelectedNoteIds(new Set());
      setIsSelectionMode(false);
      setArchiveDialogOpen(false);
    },
    onError: () => {
      toast.error("Failed to archive notes");
    },
  });


  const renderNotesGrid = (notesToRender: typeof filteredNotes, startIndex = 0) => {
    if (viewMode === "list") {
      return (
        <div className="space-y-2">
          {notesToRender.map((note, index) => {
            const globalIndex = startIndex + index;
            return (
              <NoteCard
                key={note.id}
                note={note}
                index={globalIndex}
                viewMode="list"
                isSelectionMode={isSelectionMode}
                isSelected={selectedNoteIds.has(note.id)}
                onSelectChange={(noteId, ctrlOrCmd, shift) => {
                  handleNoteSelect(noteId, globalIndex, ctrlOrCmd, shift);
                  if (!isSelectionMode && (ctrlOrCmd || shift)) {
                    setIsSelectionMode(true);
                  }
                }}
              />
            );
          })}
        </div>
      );
    }

    if (viewMode === "grid") {
      return (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {notesToRender.map((note, index) => {
            const globalIndex = startIndex + index;
            return (
              <NoteCard
                key={note.id}
                note={note}
                index={globalIndex}
                viewMode="grid"
                isSelectionMode={isSelectionMode}
                isSelected={selectedNoteIds.has(note.id)}
                onSelectChange={(noteId, ctrlOrCmd, shift) => {
                  handleNoteSelect(noteId, globalIndex, ctrlOrCmd, shift);
                  if (!isSelectionMode && (ctrlOrCmd || shift)) {
                    setIsSelectionMode(true);
                  }
                }}
              />
            );
          })}
        </div>
      );
    }

    // Masonry view
    return (
      <Masonry
        breakpointCols={masonryBreakpoints}
        className="masonry-grid"
        columnClassName="masonry-grid-column"
      >
        {notesToRender.map((note, index) => {
          const globalIndex = startIndex + index;
          return (
            <NoteCard
              key={note.id}
              note={note}
              index={globalIndex}
              viewMode="masonry"
              isSelectionMode={isSelectionMode}
              isSelected={selectedNoteIds.has(note.id)}
              onSelectChange={(noteId, ctrlOrCmd, shift) => {
                handleNoteSelect(noteId, globalIndex, ctrlOrCmd, shift);
                if (!isSelectionMode && (ctrlOrCmd || shift)) {
                  setIsSelectionMode(true);
                }
              }}
            />
          );
        })}
      </Masonry>
    );
  };

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Header searchQuery={searchQuery} onSearchChange={setSearchQuery} />

      <div className="flex-1">
        <div className="p-4 lg:p-8">
          {/* Bulk Action Toolbar */}
          {isSelectionMode && (
            <div className="max-w-7xl mx-auto mb-4">
              <div className="flex items-center justify-between gap-4 px-4 h-12 rounded-lg bg-muted/30 border border-border/40 backdrop-blur-sm">
                <button
                  type="button"
                  onClick={() => handleSelectAll(!allSelected)}
                  className="flex items-center gap-2.5 text-sm font-medium transition-colors hover:text-foreground"
                >
                  {allSelected ? (
                    <CircleCheck className="h-5 w-5 text-primary" />
                  ) : someSelected ? (
                    <div className="relative">
                      <Circle className="h-5 w-5 text-primary/70" strokeWidth={2} />
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="h-2 w-2 rounded-full bg-primary" />
                      </div>
                    </div>
                  ) : (
                    <Circle className="h-5 w-5 text-muted-foreground" strokeWidth={2} />
                  )}
                  <span className={cn(
                    "transition-colors",
                    allSelected && "text-primary",
                    someSelected && "text-foreground",
                    !allSelected && !someSelected && "text-muted-foreground"
                  )}>
                    {selectedNoteIds.size > 0 ? (
                      <>
                        <span className="font-semibold">{selectedNoteIds.size}</span>{" "}
                        <span className="text-muted-foreground">selected</span>
                      </>
                    ) : (
                      "Select all"
                    )}
                  </span>
                </button>
                <div className="flex items-center gap-0.5">
                  <TooltipProvider delayDuration={0}>
                    {selectedNoteIds.size > 0 && (
                      <>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button
                              variant="ghost"
                              size="icon-sm"
                              onClick={() => setArchiveDialogOpen(true)}
                              disabled={bulkArchiveMutation.isPending}
                              className="h-8 w-8 rounded-md hover:bg-accent"
                            >
                              <Archive className="h-4 w-4" />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>Archive selected</TooltipContent>
                        </Tooltip>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button
                              variant="ghost"
                              size="icon-sm"
                              onClick={() => setDeleteDialogOpen(true)}
                              disabled={bulkDeleteMutation.isPending}
                              className="h-8 w-8 rounded-md text-destructive hover:text-destructive hover:bg-destructive/10"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>Delete selected</TooltipContent>
                        </Tooltip>
                      </>
                    )}
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          onClick={() => {
                            setIsSelectionMode(false);
                            setSelectedNoteIds(new Set());
                          }}
                          className="h-8 w-8 rounded-md"
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </TooltipTrigger>
                      <TooltipContent>Cancel selection</TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
              </div>
            </div>
          )}

          {/* Controls Bar */}
          {(filteredNotes.length > 0 || searchQuery || selectedTag) && !isSelectionMode && (
            <div className="max-w-7xl mx-auto mb-6 flex flex-col gap-4">
              {/* Tag filter indicator */}
              {selectedTag && (
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-muted/50 border border-border/40 w-fit">
                  <span className="text-sm text-muted-foreground">Filtering by</span>
                  <Badge
                    variant="secondary"
                    className="gap-1.5"
                    style={{
                      backgroundColor: selectedTag.color
                        ? `${selectedTag.color}20`
                        : undefined,
                      color: selectedTag.color || undefined,
                    }}
                  >
                    {selectedTag.name}
                  </Badge>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-6 w-6"
                    asChild
                  >
                    <Link href="/notes">
                      <X className="h-3.5 w-3.5" />
                    </Link>
                  </Button>
                </div>
              )}

              {/* View Settings and Selection Mode Toggle */}
              {filteredNotes.length > 0 && (
                <div className="flex items-center justify-end gap-2">
                  <ViewSettings
                    viewMode={viewMode}
                    onViewModeChange={setViewMode}
                    sortBy={sortBy}
                    onSortByChange={setSortBy}
                    sortOrder={sortOrder}
                    onSortOrderChange={setSortOrder}
                  />

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setIsSelectionMode(true)}
                    className="h-8 px-3 gap-2 border-border/60 hover:border-primary/50 hover:bg-primary/5 hover:text-primary transition-all shadow-none rounded-full"
                  >
                    <CheckCircle2 className="h-4 w-4" />
                    <span className="text-xs font-medium">Select</span>
                  </Button>
                </div>
              )}
            </div>
          )}

          {/* Content */}
          {notesLoading ? (
            <div className="flex items-center justify-center h-64">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : filteredNotes.length === 0 ? (
            <div className="flex flex-col items-center justify-center min-h-[60vh] text-center max-w-md mx-auto">
              {searchQuery ? (
                <>
                  <div className="relative mb-6">
                    <div className="w-24 h-24 rounded-full bg-muted/50 flex items-center justify-center">
                      <Search className="h-12 w-12 text-muted-foreground/50" />
                    </div>
                    <div className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-accent/20 border-2 border-background flex items-center justify-center">
                      <X className="h-3 w-3 text-accent" />
                    </div>
                  </div>
                  <h3 className="text-2xl font-semibold text-foreground mb-2">
                    No matching notes found
                  </h3>
                  <p className="text-sm text-muted-foreground mb-6">
                    Try adjusting your search terms or{" "}
                    <button
                      onClick={() => setSearchQuery("")}
                      className="text-accent hover:underline"
                    >
                      clear the search
                    </button>
                  </p>
                </>
              ) : (
                <>
                  <div className="relative mb-6">
                    <div className="w-24 h-24 rounded-full bg-muted/50 flex items-center justify-center">
                      <Sparkles className="h-12 w-12 text-accent" />
                    </div>
                    <div className="absolute -top-1 -right-1 w-8 h-8 rounded-full bg-accent/30 border-2 border-background flex items-center justify-center animate-pulse">
                      <Plus className="h-4 w-4 text-accent" />
                    </div>
                  </div>
                  <h3 className="text-2xl font-semibold text-foreground mb-2">
                    Start capturing your ideas
                  </h3>
                  <p className="text-sm text-muted-foreground mb-6">
                    Create your first note to begin organizing your thoughts
                  </p>
                  <Button
                    onClick={() => {
                      const url = tagIdParam
                        ? `/notes/new?tagId=${tagIdParam}`
                        : "/notes/new";
                      router.push(url);
                    }}
                    size="lg"
                    className="gap-2"
                  >
                    <Plus className="h-4 w-4" />
                    Create Your First Note
                  </Button>
                </>
              )}
            </div>
          ) : (
            <div className="max-w-7xl mx-auto space-y-10">
              {/* Pinned Notes */}
              {sortedPinnedNotes.length > 0 && (
                <section className="space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="h-px flex-1 bg-gradient-to-r from-transparent via-border to-transparent" />
                    <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-2 px-3 py-1.5 rounded-full bg-muted/30 border border-border/40">
                      <Pin className="h-3 w-3" />
                      <span>Pinned</span>
                      <span className="text-muted-foreground/60">
                        ({sortedPinnedNotes.length})
                      </span>
                    </h2>
                    <div className="h-px flex-1 bg-gradient-to-r from-transparent via-border to-transparent" />
                  </div>
                  {renderNotesGrid(sortedPinnedNotes, 0)}
                </section>
              )}

              {/* Other Notes */}
              {sortedUnpinnedNotes.length > 0 && (
                <section className="space-y-4">
                  {sortedPinnedNotes.length > 0 && (
                    <div className="flex items-center gap-3">
                      <div className="h-px flex-1 bg-gradient-to-r from-transparent via-border to-transparent" />
                      <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-2 px-3 py-1.5 rounded-full bg-muted/30 border border-border/40">
                        <span>All Notes</span>
                        <span className="text-muted-foreground/60">
                          ({sortedUnpinnedNotes.length})
                        </span>
                      </h2>
                      <div className="h-px flex-1 bg-gradient-to-r from-transparent via-border to-transparent" />
                    </div>
                  )}
                  {renderNotesGrid(sortedUnpinnedNotes, sortedPinnedNotes.length)}
                </section>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Delete Confirmation Dialog */}
      <BulkDeleteDialog
        open={deleteDialogOpen}
        onOpenChange={setDeleteDialogOpen}
        onConfirm={() => {
          const noteIds = Array.from(selectedNoteIds);
          bulkDeleteMutation.mutate(noteIds);
        }}
        count={selectedNoteIds.size}
        isPending={bulkDeleteMutation.isPending}
      />

      {/* Archive Confirmation Dialog */}
      <BulkArchiveDialog
        open={archiveDialogOpen}
        onOpenChange={setArchiveDialogOpen}
        onConfirm={() => {
          const noteIds = Array.from(selectedNoteIds);
          bulkArchiveMutation.mutate(noteIds);
        }}
        count={selectedNoteIds.size}
        isPending={bulkArchiveMutation.isPending}
      />
    </div>
  );
}
