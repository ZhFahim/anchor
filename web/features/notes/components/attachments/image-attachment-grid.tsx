"use client";

import { useState } from "react";
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragEndEvent,
  DragStartEvent,
  DragOverlay,
} from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  rectSortingStrategy,
} from "@dnd-kit/sortable";
import { cn } from "@/lib/utils";
import type { NoteAttachment } from "../../types";
import { SortableImageItem } from "./sortable-image-item";
import { ImageAttachmentItem } from "./image-attachment-item";

interface ImageAttachmentGridProps {
  noteId: string;
  attachments: NoteAttachment[];
  canDelete: boolean;
  canReorder: boolean;
  onDelete: (id: string) => void;
  onReorder: (orderedIds: string[]) => void;
}

export function ImageAttachmentGrid({
  noteId,
  attachments,
  canDelete,
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
    })
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
    count >= 3 && "grid-cols-2 md:grid-cols-3"
  );

  const content = (
    <div className={gridClasses}>
      {attachments.map((attachment) => (
        <SortableImageItem
          key={attachment.id}
          noteId={noteId}
          attachment={attachment}
          canDelete={canDelete}
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
                canDelete={false}
                onDelete={() => {}}
              />
            </div>
          )}
        </DragOverlay>
      </DndContext>
    </div>
  );
}
