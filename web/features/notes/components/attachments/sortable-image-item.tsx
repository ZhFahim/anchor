"use client";

import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { GripVertical } from "lucide-react";
import { cn } from "@/lib/utils";
import { ImageAttachmentItem } from "./image-attachment-item";
import type { NoteAttachment } from "../../types";

interface SortableImageItemProps {
  noteId: string;
  attachment: NoteAttachment;
  canDelete: boolean;
  canReorder: boolean;
  onDelete: (id: string) => void;
}

export function SortableImageItem({
  noteId,
  attachment,
  canDelete,
  canReorder,
  onDelete,
}: SortableImageItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: attachment.id, disabled: !canReorder });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        "relative group/sortable",
        isDragging && "z-50"
      )}
    >
      {isDragging ? (
        // Placeholder shown in the original position while dragging
        <div className="aspect-square rounded-lg bg-muted border-2 border-dashed border-muted-foreground/30" />
      ) : (
        <>
          <ImageAttachmentItem
            noteId={noteId}
            attachment={attachment}
            canDelete={canDelete}
            onDelete={onDelete}
          />

          {/* Drag handle - visible on hover when reordering is enabled */}
          {canReorder && (
            <button
              {...attributes}
              {...listeners}
              className={cn(
                "absolute top-2 left-2 p-1 rounded-full cursor-grab active:cursor-grabbing",
                "bg-black/50 text-white",
                "opacity-0 group-hover/sortable:opacity-100 transition-opacity duration-200"
              )}
            >
              <GripVertical className="h-3.5 w-3.5" />
            </button>
          )}
        </>
      )}
    </div>
  );
}
