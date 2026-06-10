"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Check,
  Hash,
  Loader2,
  Plus,
  Search,
  Tag as TagIcon,
  X,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { createTag, generateRandomTagColor, getTags } from "@/features/tags";
import { cn } from "@/lib/utils";

interface BulkTagDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (tagIds: string[]) => void;
  count: number;
  isPending?: boolean;
}

export function BulkTagDialog({
  open,
  onOpenChange,
  onConfirm,
  count,
  isPending = false,
}: BulkTagDialogProps) {
  const [selectedTagIds, setSelectedTagIds] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const queryClient = useQueryClient();

  const { data: tags = [], isLoading } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  // Reset the picker and focus the search each time the dialog is opened.
  useEffect(() => {
    if (open) {
      setSelectedTagIds(new Set());
      setSearchQuery("");
      // Defer until the dialog content has mounted.
      requestAnimationFrame(() => inputRef.current?.focus());
    }
  }, [open]);

  const createTagMutation = useMutation({
    mutationFn: createTag,
    onSuccess: (newTag) => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setSelectedTagIds((prev) => new Set(prev).add(newTag.id));
      setSearchQuery("");
      inputRef.current?.focus();
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to create tag");
    },
  });

  const query = searchQuery.trim().toLowerCase();

  const filteredTags = useMemo(
    () => tags.filter((tag) => tag.name.toLowerCase().includes(query)),
    [tags, query],
  );

  const selectedTags = useMemo(
    () => tags.filter((tag) => selectedTagIds.has(tag.id)),
    [tags, selectedTagIds],
  );

  const exactMatch = useMemo(
    () => tags.some((tag) => tag.name.toLowerCase() === query),
    [tags, query],
  );

  const canCreate = query.length > 0 && !exactMatch;

  const toggleTag = (tagId: string) => {
    setSelectedTagIds((prev) => {
      const next = new Set(prev);
      if (next.has(tagId)) {
        next.delete(tagId);
      } else {
        next.add(tagId);
      }
      return next;
    });
  };

  const handleCreateTag = () => {
    if (!searchQuery.trim() || createTagMutation.isPending) return;
    createTagMutation.mutate({
      name: searchQuery.trim(),
      color: generateRandomTagColor(),
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key !== "Enter") return;
    e.preventDefault();
    if (filteredTags.length > 0) {
      toggleTag(filteredTags[0].id);
      setSearchQuery("");
    } else if (canCreate) {
      handleCreateTag();
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md gap-0 overflow-hidden p-0">
        <DialogHeader className="px-6 pt-6">
          <DialogTitle className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
              <TagIcon className="h-5 w-5 text-primary" />
            </div>
            Add Tags
          </DialogTitle>
          <DialogDescription className="pt-2">
            Add tags to {count} note{count > 1 ? "s" : ""}. Existing tags on
            those notes are kept.
          </DialogDescription>
        </DialogHeader>

        {/* Search / create input */}
        <div className="px-6 pt-4">
          <div className="flex items-center px-3 h-11 rounded-xl border border-border/60 bg-muted/30 focus-within:border-primary/50 focus-within:bg-background transition-colors">
            <Search className="h-4 w-4 text-muted-foreground shrink-0 mr-2.5" />
            <input
              ref={inputRef}
              className="flex-1 bg-transparent border-none outline-none text-sm placeholder:text-muted-foreground/70"
              placeholder="Search or create a tag..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={handleKeyDown}
            />
          </div>
        </div>

        {/* Selected tags — at-a-glance review of the current selection */}
        {selectedTags.length > 0 && (
          <div className="px-6 pt-3 flex flex-wrap gap-1.5">
            {selectedTags.map((tag) => (
              <span
                key={tag.id}
                className="inline-flex items-center gap-1 pl-2 pr-1 py-1 rounded-full text-xs font-medium border border-transparent"
                style={{
                  backgroundColor: tag.color ? `${tag.color}1a` : undefined,
                  color: tag.color || undefined,
                }}
              >
                <Hash className="h-3 w-3 opacity-70" />
                {tag.name}
                <button
                  type="button"
                  onClick={() => toggleTag(tag.id)}
                  className="rounded-full p-0.5 hover:bg-black/10 dark:hover:bg-white/15 transition-colors"
                  aria-label={`Remove ${tag.name}`}
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))}
          </div>
        )}

        {/* Tag list */}
        <div className="mt-3 max-h-72 overflow-y-auto px-3 pb-1">
          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-12 gap-2 text-muted-foreground">
              <Loader2 className="h-5 w-5 animate-spin" />
              <span className="text-xs">Loading tags...</span>
            </div>
          ) : (
            <>
              <div className="space-y-0.5">
                {filteredTags.map((tag) => {
                  const isSelected = selectedTagIds.has(tag.id);
                  const color = tag.color || undefined;
                  return (
                    <button
                      type="button"
                      key={tag.id}
                      onClick={() => toggleTag(tag.id)}
                      className={cn(
                        "w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-left transition-colors",
                        isSelected
                          ? !color && "bg-primary/10"
                          : "hover:bg-muted/50",
                      )}
                      style={
                        isSelected && color
                          ? { backgroundColor: `${color}14` }
                          : undefined
                      }
                    >
                      <span
                        className="flex items-center justify-center w-7 h-7 rounded-lg shrink-0 bg-accent/10"
                        style={
                          color ? { backgroundColor: `${color}24` } : undefined
                        }
                      >
                        <Hash
                          className="w-3.5 h-3.5"
                          style={{ color: color || "var(--accent)" }}
                        />
                      </span>
                      <span
                        className="flex-1 truncate font-medium text-foreground/90"
                        style={isSelected && color ? { color } : undefined}
                      >
                        {tag.name}
                      </span>
                      <span
                        className={cn(
                          "flex items-center justify-center w-5 h-5 rounded-full shrink-0 transition-colors",
                          isSelected ? "text-white" : "border border-border/70",
                        )}
                        style={
                          isSelected
                            ? { backgroundColor: color || "var(--primary)" }
                            : undefined
                        }
                      >
                        {isSelected && <Check className="h-3 w-3" />}
                      </span>
                    </button>
                  );
                })}
              </div>

              {/* Create new tag */}
              {canCreate && (
                <button
                  type="button"
                  onClick={handleCreateTag}
                  disabled={createTagMutation.isPending}
                  className="w-full flex items-center gap-3 px-3 py-2.5 mt-0.5 rounded-xl text-sm hover:bg-accent/10 hover:text-accent transition-colors text-left"
                >
                  <span className="flex items-center justify-center w-7 h-7 rounded-lg bg-accent/10 text-accent shrink-0">
                    {createTagMutation.isPending ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    ) : (
                      <Plus className="h-3.5 w-3.5" />
                    )}
                  </span>
                  <span className="truncate">
                    Create{" "}
                    <span className="font-medium">"{searchQuery.trim()}"</span>
                  </span>
                </button>
              )}

              {filteredTags.length === 0 && !canCreate && (
                <div className="py-12 text-center px-4">
                  <TagIcon className="h-8 w-8 text-muted-foreground/20 mx-auto mb-2" />
                  <p className="text-xs text-muted-foreground">
                    {tags.length > 0
                      ? "No matching tags"
                      : "No tags yet — type to create one"}
                  </p>
                </div>
              )}
            </>
          )}
        </div>

        <DialogFooter className="px-6 py-4 border-t border-border/40 bg-muted/20">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={() => onConfirm(Array.from(selectedTagIds))}
            disabled={selectedTagIds.size === 0 || isPending}
          >
            {isPending && <Loader2 className="h-4 w-4 animate-spin" />}
            Add {selectedTagIds.size > 0 ? selectedTagIds.size : ""} tag
            {selectedTagIds.size === 1 ? "" : "s"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
