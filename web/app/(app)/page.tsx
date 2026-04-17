"use client";

import { useState, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Sparkles, Search } from "lucide-react";
import { getNotes, deltaToFullPlainText } from "@/features/notes";
import { getTags } from "@/features/tags";
import { Header } from "@/components/layout";
import { NoteCard, NoteGridLoading } from "@/features/notes";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";
import Link from "next/link";

export default function NotesPage() {
  const searchParams = useSearchParams();
  const tagIdParam = searchParams.get("tagId");
  const [searchQuery, setSearchQuery] = useState("");

  const { data: notes = [], isLoading: notesLoading } = useQuery({
    queryKey: ["notes", tagIdParam],
    queryFn: () => getNotes({ tagId: tagIdParam || undefined }),
  });

  const { data: tags = [] } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  // Filter notes by search query
  const filteredNotes = useMemo(() => {
    if (!searchQuery.trim()) return notes;

    const query = searchQuery.toLowerCase();
    return notes.filter((note) => {
      const titleMatch = note.title.toLowerCase().includes(query);
      const contentMatch = deltaToFullPlainText(note.content).toLowerCase().includes(query);
      return titleMatch || contentMatch;
    });
  }, [notes, searchQuery]);

  // Separate pinned and unpinned notes
  const pinnedNotes = filteredNotes.filter((note) => note.isPinned);
  const unpinnedNotes = filteredNotes.filter((note) => !note.isPinned);

  // Get selected tag
  const selectedTag = tagIdParam
    ? tags.find((tag) => tag.id === tagIdParam)
    : null;

  return (
    <div className="min-h-screen flex flex-col">
      <Header searchQuery={searchQuery} onSearchChange={setSearchQuery} />

      <div className="flex-1 p-4 lg:p-6">
        {/* Tag filter indicator */}
        {selectedTag && (
          <div className="mb-4">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-muted/50">
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
                className="h-5 w-5"
                asChild
              >
                <Link href="/">
                  <X className="h-3 w-3" />
                </Link>
              </Button>
            </div>
          </div>
        )}

        {notesLoading ? (
          <div className="max-w-7xl mx-auto">
            <NoteGridLoading />
          </div>
        ) : filteredNotes.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-center">
            {searchQuery ? (
              <>
                <Search className="h-16 w-16 text-muted-foreground/50 mb-4" />
                <h3 className="text-xl font-medium text-muted-foreground">
                  No matching notes found
                </h3>
                <p className="text-sm text-muted-foreground/70 mt-1">
                  Try a different search term
                </p>
              </>
            ) : (
              <>
                <Sparkles className="h-16 w-16 text-muted-foreground/50 mb-4" />
                <h3 className="text-xl font-medium text-muted-foreground">
                  Capture your ideas here
                </h3>
                <p className="text-sm text-muted-foreground/70 mt-1">
                  Create your first note to get started
                </p>
              </>
            )}
          </div>
        ) : (
          <div className="space-y-6">
            {/* Pinned Notes */}
            {pinnedNotes.length > 0 && (
              <div>
                <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
                  <span>Pinned</span>
                </h2>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                  {pinnedNotes.map((note) => (
                    <NoteCard key={note.id} note={note} />
                  ))}
                </div>
              </div>
            )}

            {/* Other Notes */}
            {unpinnedNotes.length > 0 && (
              <div>
                {pinnedNotes.length > 0 && (
                  <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">
                    Others
                  </h2>
                )}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                  {unpinnedNotes.map((note) => (
                    <NoteCard key={note.id} note={note} />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
