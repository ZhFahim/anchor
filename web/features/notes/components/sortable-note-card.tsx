"use client";

import { useRef } from "react";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { NoteCard } from "./note-card";
import type { Note } from "@/features/notes";

type ViewMode = "masonry" | "grid" | "list";

interface SortableNoteCardProps {
  note: Note;
  index?: number;
  viewMode?: ViewMode;
  isSelectionMode?: boolean;
  isSelected?: boolean;
  onSelectChange?: (noteId: string, ctrlOrCmd: boolean, shift: boolean) => void;
}

export function SortableNoteCard({
  note,
  index = 0,
  viewMode = "grid",
  isSelectionMode = false,
  isSelected = false,
  onSelectChange,
}: SortableNoteCardProps) {
  const wasDragged = useRef(false);

  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: note.id });

  // Wrap the onPointerDown listener to track drag activation
  const wrappedListeners = {
    ...listeners,
    onPointerDown: (e: React.PointerEvent) => {
      wasDragged.current = false;
      listeners?.onPointerDown?.(e);
    },
  };

  // If isDragging becomes true, mark that a drag occurred
  if (isDragging) {
    wasDragged.current = true;
  }

  const handleClickCapture = (e: React.MouseEvent) => {
    if (wasDragged.current) {
      e.stopPropagation();
      e.preventDefault();
      wasDragged.current = false;
    }
  };

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    zIndex: isDragging ? 50 : undefined,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...wrappedListeners}
      onClickCapture={handleClickCapture}
    >
      <NoteCard
        note={note}
        index={index}
        viewMode={viewMode}
        isSelectionMode={isSelectionMode}
        isSelected={isSelected}
        onSelectChange={onSelectChange}
      />
    </div>
  );
}
