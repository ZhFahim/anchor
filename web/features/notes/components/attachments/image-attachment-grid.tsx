"use client";

import {
  closestCenter,
  DndContext,
  type DragEndEvent,
  DragOverlay,
  type DragStartEvent,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  arrayMove,
  rectSortingStrategy,
  SortableContext,
  sortableKeyboardCoordinates,
} from "@dnd-kit/sortable";
import { useState } from "react";
import { cn } from "@/lib/utils";
import type { NoteAttachment } from "../../types";
import { ImageAttachmentItem } from "./image-attachment-item";
import { SortableImageItem } from "./sortable-image-item";

interface ImageAttachmentGridProps {
  noteId: string;
  attachments: NoteAttachment[];
  getCanDelete: (attachment: NoteAttachment) => boolean;
  canReorder: boolean;
  onDelete: (id: string) => void;
  onReorder: (orderedIds: string[]) => void;
}

export function ImageAttachmentGrid({
  noteId,
  attachments,
  getCanDelete,
  canReorder,
  onDelete,
  onReorder,
}: ImageAttachmentGridProps) {
  const [activeId, setActiveId] = useState<string | null>(null);
  const count = attachments.length;

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);

    if (over && active.id !== over.id) {
      const oldIndex = attachments.findIndex((a) => a.id === active.id);
      const newIndex = attachments.findIndex((a) => a.id === over.id);
      const newOrder = arrayMove(attachments, oldIndex, newIndex);
      onReorder(newOrder.map((a) => a.id));
    }
  };

  const activeAttachment = activeId
    ? attachments.find((a) => a.id === activeId)
    : null;

  // Adaptive grid classes based on image count
  const gridClasses = cn(
    "grid gap-2",
    count === 1 && "grid-cols-1 max-w-sm",
    count === 2 && "grid-cols-2 max-w-lg",
    count >= 3 && "grid-cols-2 md:grid-cols-3",
  );

  const content = (
    <div className={gridClasses}>
      {attachments.map((attachment) => (
        <SortableImageItem
          key={attachment.id}
          noteId={noteId}
          attachment={attachment}
          canDelete={getCanDelete(attachment)}
          canReorder={canReorder}
          onDelete={onDelete}
        />
      ))}
    </div>
  );

  if (!canReorder) {
    return (
      <div className="mb-4">
        <p className="text-xs text-muted-foreground font-medium mb-2 uppercase tracking-wide">
          Images
        </p>
        {content}
      </div>
    );
  }

  return (
    <div className="mb-4">
      <p className="text-xs text-muted-foreground font-medium mb-2 uppercase tracking-wide">
        Images
      </p>
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={attachments.map((a) => a.id)}
          strategy={rectSortingStrategy}
        >
          {content}
        </SortableContext>
        <DragOverlay>
          {activeAttachment && (
            <div className="aspect-square rounded-lg overflow-hidden shadow-xl opacity-90">
              <ImageAttachmentItem
                noteId={noteId}
                attachment={activeAttachment}
                canDelete={getCanDelete(activeAttachment)}
                onDelete={() => {}}
              />
            </div>
          )}
        </DragOverlay>
      </DndContext>
    </div>
  );
}
