"use client";

import { Input } from "@/components/ui/input";
import { RichTextEditor } from "@/features/notes";
import { TagSelector } from "@/features/tags";
import { cn } from "@/lib/utils";
import { AttachmentsCollapsible } from "../attachments";

interface NoteEditorContentProps {
  noteId?: string;
  canUpload?: boolean;
  canDelete?: boolean;
  attachmentCount?: number;
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
  noteId,
  canUpload = false,
  canDelete = false,
  attachmentCount,
  title,
  content,
  selectedTagIds,
  isReadOnly,
  isTrashed = false,
  onTitleChange,
  onContentChange,
  onTagsChange,
}: NoteEditorContentProps) {
  const showTags = !isReadOnly || selectedTagIds.length > 0;
  const showAttachments =
    !!noteId && (canUpload || (attachmentCount ?? 0) > 0);

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
            "px-0 h-auto py-2 mb-2",
            "text-3xl lg:text-4xl font-bold",
            "placeholder:text-muted-foreground/40",
            "focus-visible:ring-0 focus-visible:ring-offset-0 focus-visible:border-0",
            isReadOnly && "cursor-default",
            !isTrashed && isReadOnly && "text-foreground"
          )}
        />

        {/* Tags */}
        {showTags && (
          <div className="py-3 border-b border-border/30">
            <TagSelector
              selectedTagIds={selectedTagIds}
              onTagsChange={onTagsChange}
              readOnly={isReadOnly}
            />
          </div>
        )}

        {/* Attachments */}
        {showAttachments && (
          <div className="py-3 border-b border-border/30">
            <AttachmentsCollapsible
              noteId={noteId!}
              canUpload={!isTrashed && canUpload}
              canDelete={canDelete}
            />
          </div>
        )}

        {/* Content */}
        <div className="mt-2">
          <RichTextEditor
            value={content}
            onChange={onContentChange}
            placeholder="Start typing your thoughts..."
            readOnly={isReadOnly}
            className={cn("w-full", "min-h-[calc(100vh-380px)]")}
          />
        </div>
      </div>
    </div>
  );
}
