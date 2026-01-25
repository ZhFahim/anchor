"use client";

import { Input } from "@/components/ui/input";
import { RichTextEditor } from "@/features/notes";
import { TagSelector } from "@/features/tags";
import { cn } from "@/lib/utils";

interface NoteEditorContentProps {
  title: string;
  content: string;
  selectedTagIds: string[];
  isReadOnly: boolean;
  isTrashed?: boolean;
  onTitleChange: (title: string) => void;
  onContentChange: (content: string) => void;
  onTagsChange: (tagIds: string[]) => void;
}

export function NoteEditorContent({
  title,
  content,
  selectedTagIds,
  isReadOnly,
  isTrashed = false,
  onTitleChange,
  onContentChange,
  onTagsChange,
}: NoteEditorContentProps) {
  return (
    <div className="flex-1 relative">
      <div className="relative max-w-3xl mx-auto w-full px-4 lg:px-6 py-8">
        {/* Title */}
        <Input
          value={title}
          onChange={(e) => !isReadOnly && onTitleChange(e.target.value)}
          placeholder="Title"
          disabled={isTrashed}
          readOnly={isReadOnly}
          className={cn(
            "!bg-transparent border-0 shadow-none rounded-none",
            "px-0 h-auto py-2 mb-4",
            "text-3xl lg:text-4xl font-bold",
            "placeholder:text-muted-foreground/40",
            "focus-visible:ring-0 focus-visible:ring-offset-0 focus-visible:border-0",
            isReadOnly && "cursor-default",
            !isTrashed && isReadOnly && "text-foreground"
          )}
        />

        {/* Tags */}
        <div className="py-3 border-b border-border/30 mb-6">
          <TagSelector
            selectedTagIds={selectedTagIds}
            onTagsChange={onTagsChange}
            readOnly={isReadOnly}
          />
        </div>

        {/* Content */}
        <RichTextEditor
          value={content}
          onChange={onContentChange}
          placeholder="Start typing your thoughts..."
          readOnly={isReadOnly}
          className={cn("w-full", "min-h-[calc(100vh-320px)]")}
        />
      </div>
    </div>
  );
}

