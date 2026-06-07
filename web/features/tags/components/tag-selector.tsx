"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Hash, Loader2, Plus, Search, Tag as TagIcon, X } from "lucide-react";
import { useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { createTag, generateRandomTagColor, getTags } from "@/features/tags";

interface TagSelectorProps {
  selectedTagIds: string[];
  onTagsChange: (tagIds: string[]) => void;
  readOnly?: boolean;
}

export function TagSelector({
  selectedTagIds,
  onTagsChange,
  readOnly = false,
}: TagSelectorProps) {
  const [open, setOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const queryClient = useQueryClient();

  const { data: tags = [], isLoading } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  const createTagMutation = useMutation({
    mutationFn: createTag,
    onSuccess: (newTag) => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      onTagsChange([...selectedTagIds, newTag.id]);
      setSearchQuery("");
      inputRef.current?.focus();
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to create tag");
    },
  });

  const selectedTags = useMemo(
    () => tags.filter((tag) => selectedTagIds.includes(tag.id)),
    [tags, selectedTagIds],
  );

  const filteredTags = useMemo(
    () =>
      tags.filter(
        (tag) =>
          !selectedTagIds.includes(tag.id) &&
          tag.name.toLowerCase().includes(searchQuery.toLowerCase()),
      ),
    [tags, selectedTagIds, searchQuery],
  );

  const toggleTag = (tagId: string) => {
    if (selectedTagIds.includes(tagId)) {
      onTagsChange(selectedTagIds.filter((id) => id !== tagId));
    } else {
      onTagsChange([...selectedTagIds, tagId]);
    }
  };

  // Add a tag from the list and reset the query so the next one can be typed.
  // Refocus the input since a mouse click moves focus to the clicked item.
  const selectTag = (tagId: string) => {
    onTagsChange([...selectedTagIds, tagId]);
    setSearchQuery("");
    inputRef.current?.focus();
  };

  const handleCreateTag = () => {
    if (searchQuery.trim()) {
      createTagMutation.mutate({
        name: searchQuery.trim(),
        color: generateRandomTagColor(),
      });
    }
  };

  const handleSearchKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key !== "Enter") return;
    e.preventDefault();
    if (filteredTags.length > 0) {
      selectTag(filteredTags[0].id);
    } else if (searchQuery.trim() && !createTagMutation.isPending) {
      handleCreateTag();
    }
  };

  const handleOpenChange = (next: boolean) => {
    setOpen(next);
    if (!next) setSearchQuery("");
  };

  if (readOnly && selectedTags.length === 0) {
    return null;
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {selectedTags.map((tag) => (
        <Badge
          key={tag.id}
          variant="secondary"
          className="pl-2 pr-1.5 py-1 h-7 text-xs font-medium border border-transparent hover:border-border/40 transition-all duration-200"
          style={{
            backgroundColor: tag.color ? `${tag.color}15` : undefined,
            color: tag.color || undefined,
          }}
        >
          <Hash
            className="w-3 h-3 mr-1.5 opacity-70"
            style={{
              color: tag.color || "var(--accent)",
            }}
          />
          {tag.name}
          {!readOnly && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                toggleTag(tag.id);
              }}
              className="ml-1.5 rounded-full p-0.5 hover:bg-black/5 dark:hover:bg-white/10 transition-colors"
            >
              <X className="h-3 w-3" />
            </button>
          )}
        </Badge>
      ))}

      {!readOnly && (
        <Popover open={open} onOpenChange={handleOpenChange}>
          <PopoverTrigger asChild>
            <Button
              variant="ghost"
              size="sm"
              className="h-7 px-2.5 text-xs text-muted-foreground hover:text-foreground hover:bg-muted/50 border border-transparent hover:border-border/40 rounded-full transition-all duration-200"
            >
              <Plus className="h-3.5 w-3.5 mr-1.5" />
              Add tag
            </Button>
          </PopoverTrigger>
          <PopoverContent
            className="w-64 p-0 shadow-xl border-border/40 overflow-hidden"
            align="start"
            sideOffset={8}
            onOpenAutoFocus={(e) => e.preventDefault()}
          >
            <div className="flex flex-col">
              {/* Search Header */}
              <div className="flex items-center px-3 py-2 border-b border-border/40 bg-muted/20">
                <Search className="h-4 w-4 text-muted-foreground shrink-0 mr-2" />
                <input
                  ref={inputRef}
                  className="flex-1 bg-transparent border-none outline-none text-sm placeholder:text-muted-foreground/70"
                  placeholder="Search tags..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={handleSearchKeyDown}
                />
              </div>

              {/* Tag List */}
              <div className="max-h-70 overflow-y-auto p-1 scrollbar-none">
                {isLoading ? (
                  <div className="flex flex-col items-center justify-center py-8 gap-2 text-muted-foreground">
                    <Loader2 className="h-5 w-5 animate-spin" />
                    <span className="text-xs">Loading tags...</span>
                  </div>
                ) : (
                  <>
                    {filteredTags.length > 0 && (
                      <div className="space-y-0.5">
                        {filteredTags.map((tag) => (
                          <button
                            type="button"
                            key={tag.id}
                            onClick={() => selectTag(tag.id)}
                            className="w-full flex items-center gap-2.5 px-2.5 py-2 rounded-sm text-sm hover:bg-muted/50 transition-colors text-left group"
                          >
                            <Hash
                              className="w-3.5 h-3.5 shrink-0"
                              style={{ color: tag.color || "var(--accent)" }}
                            />
                            <span className="flex-1 text-foreground/90 truncate">
                              {tag.name}
                            </span>
                            <Plus className="h-3.5 w-3.5 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity" />
                          </button>
                        ))}
                      </div>
                    )}

                    {/* Empty State / Create New */}
                    {filteredTags.length === 0 && searchQuery.trim() && (
                      <div className="p-1">
                        <button
                          type="button"
                          onClick={handleCreateTag}
                          disabled={createTagMutation.isPending}
                          className="w-full flex items-center gap-2 px-2.5 py-2 rounded-sm text-sm hover:bg-accent/10 hover:text-accent transition-colors text-left"
                        >
                          <div className="flex items-center justify-center w-5 h-5 rounded-full bg-accent/10 text-accent">
                            {createTagMutation.isPending ? (
                              <Loader2 className="h-3 w-3 animate-spin" />
                            ) : (
                              <Plus className="h-3 w-3" />
                            )}
                          </div>
                          <span className="truncate">
                            Create "{searchQuery}"
                          </span>
                        </button>
                      </div>
                    )}

                    {filteredTags.length === 0 && !searchQuery.trim() && (
                      <div className="py-8 text-center px-4">
                        <TagIcon className="h-8 w-8 text-muted-foreground/20 mx-auto mb-2" />
                        <p className="text-xs text-muted-foreground">
                          {tags.length > 0
                            ? "All existing tags added"
                            : "No tags found"}
                        </p>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          </PopoverContent>
        </Popover>
      )}
    </div>
  );
}
