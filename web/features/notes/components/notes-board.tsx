"use client";

import { ChevronRight } from "lucide-react";
import * as React from "react";
import { Skeleton } from "@/components/ui/skeleton";
import { useTagMap } from "@/features/tags/hooks";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { hasOverlay, useShortcuts } from "@/lib/hooks/use-shortcuts";
import { cn } from "@/lib/utils";
import {
  CARD_KEYS,
  focusEdgeCard,
  moveCardFocus,
  refocusLeftCard,
} from "../card-focus";
import { type DragPreview, useCardDrag } from "../hooks/use-card-drag";
import { useMasonry } from "../hooks/use-masonry";
import type { Note } from "../types";
import { type CardLayout, NoteCard } from "./note-card";

const focusLastCard = () => focusEdgeCard("last");

interface NotesBoardGroup {
  key: string;
  label?: string;
  icon?: React.ReactNode;
  notes: Note[];
  fold?: { isOpen: boolean; onToggle: () => void };
  fallback?: React.ReactNode;
  /** Its notes keep their places when others are dragged. */
  isFixed?: boolean;
}

interface NotesBoardProps {
  groups: NotesBoardGroup[];
  layout: CardLayout;
  picking: boolean;
  picked: Set<string>;
  /** Leave out for cards that can't be picked. */
  onPick?: (noteId: string, range: boolean) => void;
  onShare?: (note: Note) => void;
  /** Pins or unpins a note from its card. Keep it stable. */
  onTogglePin?: (note: Note) => void;
  /** Keep it stable, or every card redraws. */
  renderActions?: (note: Note) => React.ReactNode;
  dateLabel?: (note: Note) => string;
  /** The search the notes were found by. */
  searchTerm?: string;
  /**
   * Lets cards be dragged to new places within their group, as in Google
   * Keep; called with the group's new order when one is let go.
   */
  onReorder?: (draggedId: string, ids: string[]) => void;
}

export const NotesBoard = React.forwardRef<HTMLDivElement, NotesBoardProps>(
  (
    {
      groups,
      layout,
      picking,
      picked,
      onPick,
      onShare,
      onTogglePin,
      renderActions,
      dateLabel,
      searchTerm,
      onReorder,
    },
    ref,
  ) => {
    const isList = layout === "list";
    const tagMap = useTagMap();
    const boardRef = React.useRef<HTMLDivElement>(null);
    const rulerRef = React.useRef<HTMLDivElement>(null);
    const boardId = React.useId();
    React.useImperativeHandle(ref, () => boardRef.current as HTMLDivElement);
    useMasonry(boardRef, rulerRef);
    const drag = useCardDrag({
      enabled: !!onReorder && !picking,
      onDrop: (draggedId, ids) => onReorder?.(draggedId, ids),
    });
    // A let-go order is held until the notes arrive in it.
    const { preview, settled } = drag;
    React.useEffect(() => {
      if (!preview?.settling) return;
      const group = groups.find((g) => g.key === preview.group);
      if (group)
        settled(
          group.key,
          group.notes.map((n) => n.id),
        );
    }, [preview, groups, settled]);
    React.useLayoutEffect(() => {
      if (groups.some((g) => g.notes.length)) refocusLeftCard();
    }, [groups]);
    // With no card focused, J and K start at the first card, as do the
    // arrows with nothing focused at all (L is the notes page's new list);
    // G goes to the last. The first of two boards takes the key.
    useShortcuts({
      j: () => focusEdgeCard("first"),
      k: () => focusEdgeCard("first"),
      G: focusLastCard,
    });
    React.useEffect(() => {
      const onKey = (e: KeyboardEvent) => {
        if (e.defaultPrevented || e.target !== document.body) return;
        if (e.ctrlKey || e.metaKey || e.altKey || e.shiftKey) return;
        if (!e.key.startsWith("Arrow") || hasOverlay()) return;
        if (focusEdgeCard("first")) e.preventDefault();
      };
      document.addEventListener("keydown", onKey);
      return () => document.removeEventListener("keydown", onKey);
    }, []);
    const onKeyDown = (e: React.KeyboardEvent) => {
      const link = e.target as HTMLElement;
      if (!link.classList.contains("nc-link")) return;
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      const direction = CARD_KEYS[e.key];
      if (direction) {
        e.preventDefault();
        moveCardFocus(link, direction);
      } else if (e.key === "Home" || e.key === "End") {
        e.preventDefault();
        focusEdgeCard(e.key === "Home" ? "first" : "last");
      } else if (e.key === "o") {
        e.preventDefault();
        link.click();
      }
    };
    return (
      <div
        ref={boardRef}
        data-hold-width
        className="relative grid min-w-0 gap-3.5"
        onKeyDown={onKeyDown}
      >
        <div
          ref={rulerRef}
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 h-0"
        />
        {groups.map((group) => {
          const heading = (
            <>
              {group.icon}
              {group.label}
              <span className="ml-0.5 font-medium tracking-normal tabular-nums">
                {group.notes.length}
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
                <div
                  id={cardsId}
                  className={cn("cards", layout, picking && "picking")}
                  // A card is a link; the browser's own link dragging would
                  // take the pointer away from ours.
                  onDragStart={
                    drag.enabled ? (e) => e.preventDefault() : undefined
                  }
                  onPointerDown={
                    group.isFixed
                      ? undefined
                      : (e) =>
                          drag.onPointerDown(
                            e,
                            group.key,
                            group.notes.map((n) => n.id),
                          )
                  }
                >
                  {inPreviewOrder(group, drag.preview).map((note) => (
                    <NoteCard
                      key={note.id}
                      note={note}
                      tagMap={tagMap}
                      layout={layout}
                      picking={picking}
                      picked={picked.has(note.id)}
                      onPick={onPick}
                      onShare={onShare}
                      onTogglePin={onTogglePin}
                      renderActions={renderActions}
                      dateLabel={dateLabel?.(note)}
                      searchTerm={searchTerm}
                    />
                  ))}
                </div>
              )}
            </React.Fragment>
          );
        })}
      </div>
    );
  },
);
NotesBoard.displayName = "NotesBoard";

/** A group's notes in the order a drag is showing, if one is under way. */
function inPreviewOrder(
  group: NotesBoardGroup,
  preview: DragPreview | null,
): Note[] {
  if (!preview || preview.group !== group.key) return group.notes;
  const byId = new Map(group.notes.map((n) => [n.id, n]));
  const shown = preview.ids.flatMap((id) => byId.get(id) ?? []);
  // A note that arrived during the drag goes at the end.
  for (const note of group.notes)
    if (!preview.ids.includes(note.id)) shown.push(note);
  return shown;
}

export function NotesBoardSkeleton({ loading }: { loading: boolean }) {
  const shown = useDelayedFlag(loading);
  if (!shown) return null;
  return (
    <div
      role="status"
      aria-label="Loading notes"
      className="columns-[4_200px] gap-x-4"
    >
      {[5, 3, 4, 2, 4, 3, 5, 2].map((lines, index) => (
        <div
          key={index}
          className="mb-4 grid break-inside-avoid gap-2 rounded-card bg-card p-4 shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent)]"
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
  );
}
