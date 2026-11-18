"use client";

import { DndContext, DragOverlay, useDroppable } from "@dnd-kit/core";
import { SortableContext, useSortable } from "@dnd-kit/sortable";
import { ChevronRight } from "lucide-react";
import * as React from "react";
import { Skeleton } from "@/components/ui/skeleton";
import { useTagMap } from "@/features/tags/hooks";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { useHoldRing } from "@/lib/use-hold-ring";
import { cn } from "@/lib/utils";
import type { DropTarget } from "../columns";
import { useCardColumns } from "../hooks/use-card-columns";
import type { Note } from "../types";
import { type BoardReorder, groupDropId, useBoardDrag } from "./board-drag";
import { type CardDrag, type CardLayout, NoteCard } from "./note-card";

interface NotesBoardGroup {
  key: string;
  label?: string;
  icon?: React.ReactNode;
  notes: Note[];
  fold?: { isOpen: boolean; onToggle: () => void };
  fallback?: React.ReactNode;
  /** Shown only while a card is dragged, as a place to drop it. */
  isDropOnly?: boolean;
  dropHint?: string;
}

interface NotesBoardProps {
  groups: NotesBoardGroup[];
  layout: CardLayout;
  picking: boolean;
  picked: Set<string>;
  onPick: (noteId: string, range: boolean) => void;
  onShare?: (note: Note) => void;
  /** Keep it stable, or every card redraws. */
  renderActions?: (note: Note) => React.ReactNode;
  dateLabel?: (note: Note) => string;
  /** Lets cards be dragged into a new order. */
  reorder?: BoardReorder;
  /** Columns: where a card opens, and which note is open beside the list. */
  noteHref?: (noteId: string) => string;
  openId?: string | null;
  /** Columns: cards, or all picked ones, can be dropped on the sidebar. */
  onDropOut?: (noteIds: string[], target: DropTarget) => void;
  onMoveByKey?: CardDrag["onMoveByKey"];
}

// Sortable's own shifting is unused: cards change places in the list itself.
const noShift = () => null;
const LIFTED: CardDrag = { isLifted: true };

export const NotesBoard = React.forwardRef<HTMLDivElement, NotesBoardProps>(
  (
    {
      groups,
      layout,
      picking,
      picked,
      onPick,
      onShare,
      renderActions,
      dateLabel,
      reorder,
      onMoveByKey,
      noteHref,
      openId,
      onDropOut,
    },
    ref,
  ) => {
    const isList = layout === "list";
    const tagMap = useTagMap();
    const boardRef = React.useRef<HTMLDivElement>(null);
    const rulerRef = React.useRef<HTMLDivElement>(null);
    const boardId = React.useId();
    React.useImperativeHandle(ref, () => boardRef.current as HTMLDivElement);
    useCardColumns(boardRef, rulerRef);
    const {
      drag,
      hasZones,
      activeNote,
      draggedCount,
      notesOf,
      contextProps,
      dropAnimation,
    } = useBoardDrag(
      groups,
      reorder,
      React.useMemo(
        () => (onDropOut ? { picked, onDrop: onDropOut } : undefined),
        [onDropOut, picked],
      ),
    );
    useHoldRing(".nc-draggable", !!reorder);
    const board = (
      <div
        ref={boardRef}
        data-hold-width
        className="relative grid min-w-0 gap-3.5"
      >
        <div
          ref={rulerRef}
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 h-0"
        />
        {groups.map((group) => {
          if (group.isDropOnly && !hasZones) return null;
          const notes = notesOf(group);
          const isSortable = !!reorder?.groups.includes(group.key);
          const heading = (
            <>
              {group.icon}
              {group.label}
              <span className="ml-0.5 font-medium tracking-normal tabular-nums">
                {notes.length}
              </span>
            </>
          );
          const cardsId = `${boardId}-${group.key}`;
          const isShown = !group.fold || group.fold.isOpen;
          return (
            <React.Fragment key={group.key}>
              {group.label && (
                <h2
                  data-flip={`grp:${group.key}`}
                  className={cn(
                    "m-0 mt-1.5 flex items-center gap-1.5 px-0.5 text-label text-muted-foreground uppercase [&+div]:-mt-1 [&_svg]:size-3.25",
                    isList && "w-full max-w-195 justify-self-center",
                  )}
                >
                  {group.fold ? (
                    <button
                      type="button"
                      aria-expanded={group.fold.isOpen}
                      aria-controls={group.fold.isOpen ? cardsId : undefined}
                      onClick={group.fold.onToggle}
                      className="-mx-0.5 -my-1.5 flex cursor-pointer items-center gap-1.5 rounded-sm border-0 bg-transparent px-0.5 py-1.5 text-inherit uppercase transition-colors duration-(--duration-hover) hover:text-foreground max-md:flex-1 pointer-coarse:-my-3.5 pointer-coarse:py-3.5"
                    >
                      {heading}
                      <ChevronRight
                        aria-hidden
                        className={cn(
                          "transition-transform duration-(--duration-move) ease-standard max-md:ml-auto",
                          group.fold.isOpen && "rotate-90",
                        )}
                      />
                    </button>
                  ) : (
                    heading
                  )}
                </h2>
              )}
              {isShown && group.fallback}
              {isShown && !group.fallback && (
                <SortableGroup
                  id={group.key}
                  ids={
                    isSortable || onDropOut
                      ? notes.map((note) => note.id)
                      : NO_IDS
                  }
                  disabled={{
                    draggable: !isSortable && !onDropOut,
                    droppable: !isSortable,
                  }}
                >
                  <CardsBox
                    id={cardsId}
                    groupKey={isSortable ? group.key : null}
                    className={cn(
                      "cards",
                      layout,
                      picking && "picking",
                      drag && "dragging",
                      group.isDropOnly && "drop-only",
                    )}
                    dropHint={notes.length ? undefined : group.dropHint}
                  >
                    {notes.map((note) => {
                      const card = {
                        note,
                        tagMap,
                        layout,
                        picking,
                        picked: picked.has(note.id),
                        onPick,
                        onShare,
                        renderActions,
                        dateLabel: dateLabel?.(note),
                        href: noteHref?.(note.id),
                        isOpen: note.id === openId,
                      };
                      // One card type throughout, so searching or picking
                      // doesn't remount every card.
                      return (
                        <SortableNoteCard
                          key={note.id}
                          {...card}
                          isSortable={isSortable}
                          canLeave={!!onDropOut}
                          onMoveByKey={isSortable ? onMoveByKey : undefined}
                        />
                      );
                    })}
                  </CardsBox>
                </SortableGroup>
              )}
            </React.Fragment>
          );
        })}
      </div>
    );
    return (
      <DndContext id={boardId} {...contextProps}>
        {board}
        <DragOverlay dropAnimation={dropAnimation} zIndex={60}>
          {activeNote && (
            <div className={cn("cards drag-overlay", layout)}>
              <NoteCard
                note={activeNote}
                tagMap={tagMap}
                layout={layout}
                drag={LIFTED}
              />
              {draggedCount > 1 && (
                <span className="drag-count">{draggedCount}</span>
              )}
            </div>
          )}
        </DragOverlay>
      </DndContext>
    );
  },
);
NotesBoard.displayName = "NotesBoard";

const NO_IDS: string[] = [];

/** Sortable re-measures whenever its item list is a new array, even an equal one. */
function SortableGroup({
  id,
  ids,
  disabled,
  children,
}: {
  id: string;
  ids: string[];
  disabled: { draggable: boolean; droppable: boolean };
  children: React.ReactNode;
}) {
  const stable = React.useRef(ids);
  if (
    stable.current.length !== ids.length ||
    stable.current.some((value, i) => value !== ids[i])
  )
    stable.current = ids;
  return (
    <SortableContext
      id={id}
      items={stable.current}
      strategy={noShift}
      disabled={disabled}
    >
      {children}
    </SortableContext>
  );
}

function CardsBox({
  groupKey,
  dropHint,
  children,
  ...props
}: React.ComponentProps<"div"> & {
  groupKey: string | null;
  dropHint?: string;
}) {
  const { setNodeRef } = useDroppable({
    id: groupDropId(groupKey ?? ""),
    disabled: !groupKey,
  });
  return (
    <div ref={groupKey ? setNodeRef : undefined} {...props}>
      {children}
      {dropHint && <p className="cards-drop-hint">{dropHint}</p>}
    </div>
  );
}

function SortableNoteCard({
  isSortable,
  canLeave,
  onMoveByKey,
  ...props
}: React.ComponentProps<typeof NoteCard> & {
  isSortable: boolean;
  /** Can be dropped outside the board, even while picking. */
  canLeave: boolean;
  onMoveByKey?: CardDrag["onMoveByKey"];
}) {
  const canSort = isSortable && !props.picking;
  const isOn = canSort || canLeave;
  const { setNodeRef, listeners, isDragging } = useSortable({
    id: props.note.id,
    disabled: { draggable: !isOn, droppable: !canSort },
  });
  const drag = React.useMemo<CardDrag | undefined>(
    () =>
      isOn
        ? {
            ref: setNodeRef,
            listeners,
            isPlaceholder: isDragging,
            onMoveByKey,
          }
        : undefined,
    [isOn, setNodeRef, listeners, isDragging, onMoveByKey],
  );
  return <NoteCard {...props} drag={drag} />;
}

export function NotesBoardSkeleton({ loading }: { loading: boolean }) {
  const shown = useDelayedFlag(loading);
  const boardRef = React.useRef<HTMLDivElement>(null);
  const rulerRef = React.useRef<HTMLDivElement>(null);
  useCardColumns(boardRef, rulerRef);
  if (!shown) return null;
  return (
    <div
      ref={boardRef}
      role="status"
      aria-label="Loading notes"
      className="relative"
    >
      <div
        ref={rulerRef}
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 top-0 h-0"
      />
      <div className="cards masonry">
        {[5, 3, 4, 2, 4, 3, 5, 2].map((lines, index) => (
          <div
            key={index}
            className="grid gap-2 rounded-card bg-card p-4 shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent)]"
          >
            <Skeleton className="h-3.5 w-[62%] bg-[linear-gradient(90deg,var(--muted)_30%,color-mix(in_srgb,var(--muted)_40%,var(--card))_50%,var(--muted)_70%)]" />
            {Array.from({ length: lines }, (_, i) => (
              <Skeleton
                key={i}
                className="bg-[linear-gradient(90deg,var(--muted)_30%,color-mix(in_srgb,var(--muted)_40%,var(--card))_50%,var(--muted)_70%)]"
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
