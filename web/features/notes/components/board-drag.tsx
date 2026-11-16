"use client";

import {
  type Announcements,
  type CollisionDetection,
  closestCenter,
  type DragEndEvent,
  type DragMoveEvent,
  type DragOverEvent,
  type DragStartEvent,
  MeasuringStrategy,
  MouseSensor,
  pointerWithin,
  TouchSensor,
  type UniqueIdentifier,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import * as React from "react";
import { prefersReducedMotion } from "@/lib/motion";
import { suppressNextClick } from "@/lib/suppress-click";
import type { Note } from "../types";

/** A drop the page turns into a pin change and a new position. */
export interface BoardDrop {
  noteId: string;
  fromGroup: string;
  toGroup: string;
  /** The target group's notes, in their new order. */
  orderedIds: string[];
}

export interface BoardReorder {
  /** Groups whose cards can be dragged, and dropped into. */
  groups: string[];
  /** The board keeps the dropped order on screen until this settles. */
  onDrop: (drop: BoardDrop) => void | Promise<void>;
  /** A long press released without moving, on touch. */
  onHold?: (noteId: string) => void;
  /** Called just before the cards change place, so they glide. */
  prepareMotion: () => void;
}

interface DragState {
  activeId: string;
  fromGroup: string;
  order: Record<string, string[]>;
}

const GROUP_PREFIX = "group:";

// After cards change places, a different card can land under a still pointer.
// Wait for the pointer to move before the next change, and further still
// before undoing the last one, or two orders can take turns forever.
const SETTLE_DISTANCE = 6;
const SWAP_BACK_DISTANCE = 32;

const orderKey = (order: Record<string, string[]>) =>
  Object.values(order)
    .map((ids) => ids.join(","))
    .join("|");
export const groupDropId = (key: string) => `${GROUP_PREFIX}${key}`;

// Notes win over the group box they sit in; the gaps fall back to the nearest card.
const collide: CollisionDetection = (args) => {
  const hits = pointerWithin(args);
  if (hits.length) {
    const cards = hits.filter(
      (hit) => !String(hit.id).startsWith(GROUP_PREFIX),
    );
    return cards.length ? cards : hits;
  }
  return closestCenter(args);
};

// Scroll only right at the edges: the default fifth of the screen starts
// scrolling as soon as a card low on the page is picked up.
const AUTO_SCROLL = { threshold: { x: 0, y: 0.1 }, acceleration: 8 };

export const BOARD_MEASURING = {
  droppable: { strategy: MeasuringStrategy.Always },
};

export function useBoardDrag(
  groups: { key: string; notes: Note[] }[],
  reorder: BoardReorder | undefined,
) {
  const [drag, setDrag] = React.useState<DragState | null>(null);
  const [held, setHeld] = React.useState<Record<string, string[]> | null>(null);
  const dragRef = React.useRef(drag);
  dragRef.current = drag;
  const touchedRef = React.useRef(false);
  const lastMove = React.useRef<{
    delta: { x: number; y: number };
    before: string;
  } | null>(null);
  const startPoint = React.useRef<{ x: number; y: number } | null>(null);
  const lastDelta = React.useRef({ x: 0, y: 0 });
  // The lifted card is placed from where its note sat when the drag began, so
  // drop zones that push the notes around wait until that is measured.
  const [hasZones, setHasZones] = React.useState(false);
  const isDragging = !!drag;
  React.useEffect(() => {
    if (!isDragging) return setHasZones(false);
    let frame = requestAnimationFrame(() => {
      frame = requestAnimationFrame(() => {
        // The zones move the notes under a still pointer: only a real move
        // may change the order from here.
        const state = dragRef.current;
        if (state)
          lastMove.current = {
            delta: { ...lastDelta.current },
            before: orderKey(state.order),
          };
        setHasZones(true);
      });
    });
    return () => cancelAnimationFrame(frame);
  }, [isDragging]);

  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 6 } }),
    useSensor(TouchSensor, {
      activationConstraint: { delay: 250, tolerance: 8 },
    }),
  );

  const noteById = React.useMemo(() => {
    const map = new Map<string, Note>();
    for (const group of groups)
      for (const note of group.notes) map.set(note.id, note);
    return map;
  }, [groups]);

  const groupOf = (state: DragState, id: string) =>
    Object.keys(state.order).find((key) => state.order[key].includes(id));

  const notesOf = (group: { key: string; notes: Note[] }) => {
    const ids = (drag?.order ?? held)?.[group.key];
    if (!ids) return group.notes;
    return ids.flatMap((id) => noteById.get(id) ?? []);
  };

  const onDragStart = ({ active, activatorEvent }: DragStartEvent) => {
    if (!reorder) return;
    const id = String(active.id);
    const order: Record<string, string[]> = {};
    for (const group of groups)
      if (reorder.groups.includes(group.key))
        order[group.key] = group.notes.map((note) => note.id);
    const fromGroup = Object.keys(order).find((key) => order[key].includes(id));
    if (!fromGroup) return;
    touchedRef.current =
      typeof TouchEvent !== "undefined" && activatorEvent instanceof TouchEvent;
    const point =
      activatorEvent instanceof MouseEvent
        ? activatorEvent
        : touchedRef.current
          ? (activatorEvent as TouchEvent).touches[0]
          : null;
    startPoint.current = point ? { x: point.clientX, y: point.clientY } : null;
    navigator.vibrate?.(10);
    lastMove.current = null;
    lastDelta.current = { x: 0, y: 0 };
    setDrag({ activeId: id, fromGroup, order });
  };

  const onDragOver = ({
    active,
    over,
    delta,
  }: DragOverEvent | DragMoveEvent) => {
    lastDelta.current = delta;
    const state = dragRef.current;
    if (!state || !over || !reorder) return;
    const activeId = String(active.id);
    const overId = String(over.id);
    if (overId === activeId) return;
    const from = groupOf(state, activeId);
    const to = overId.startsWith(GROUP_PREFIX)
      ? overId.slice(GROUP_PREFIX.length)
      : groupOf(state, overId);
    if (!from || !to || !(to in state.order)) return;
    const target = state.order[to].filter((id) => id !== activeId);
    let index = overId.startsWith(GROUP_PREFIX)
      ? target.length
      : target.indexOf(overId);
    if (index < 0) return;
    // Over a card, take its place: after it when coming from before it.
    if (from === to && !overId.startsWith(GROUP_PREFIX)) {
      const was = state.order[to].indexOf(activeId);
      const at = state.order[to].indexOf(overId);
      if (was < at) index += 1;
    }
    const nextTarget = [
      ...target.slice(0, index),
      activeId,
      ...target.slice(index),
    ];
    if (from === to && nextTarget.every((id, i) => state.order[to][i] === id))
      return;
    const order = {
      ...state.order,
      [from]: state.order[from].filter((id) => id !== activeId),
      [to]: nextTarget,
    };
    const last = lastMove.current;
    if (last) {
      const moved = Math.hypot(delta.x - last.delta.x, delta.y - last.delta.y);
      const isSwapBack = orderKey(order) === last.before;
      if (moved < (isSwapBack ? SWAP_BACK_DISTANCE : SETTLE_DISTANCE)) return;
    }
    lastMove.current = { delta: { ...delta }, before: orderKey(state.order) };
    reorder.prepareMotion();
    setDrag({ ...state, order });
  };

  const finish = (event: DragEndEvent | null) => {
    const state = dragRef.current;
    if (!state || !reorder) return setDrag(null);
    const to = groupOf(state, state.activeId);
    const original = groups.find((g) => g.key === state.fromGroup)?.notes ?? [];
    const isUnmoved =
      to === state.fromGroup &&
      state.order[to].every((id, i) => original[i]?.id === id);
    const moved = event?.delta ? Math.hypot(event.delta.x, event.delta.y) : 0;
    if (event && isUnmoved && touchedRef.current && moved < 8)
      reorder.onHold?.(state.activeId);
    else if (event && to && !isUnmoved) {
      const saving = reorder.onDrop({
        noteId: state.activeId,
        fromGroup: state.fromGroup,
        toGroup: to,
        orderedIds: state.order[to],
      });
      if (saving) {
        setHeld(state.order);
        void saving.finally(() => setHeld(null));
      }
    } else reorder.prepareMotion();
    suppressNextClick();
    navigator.vibrate?.(event ? 10 : 0);
    setDrag(null);
  };

  return {
    drag,
    hasZones: !!drag && hasZones,
    activeNote: drag ? noteById.get(drag.activeId) : undefined,
    notesOf,
    contextProps: {
      sensors,
      collisionDetection: collide,
      measuring: BOARD_MEASURING,
      autoScroll: AUTO_SCROLL,
      onDragStart,
      onDragOver,
      // dnd-kit reports "over" only when it changes; a move the settle
      // distance held back is retried as the pointer keeps moving.
      onDragMove: onDragOver,
      onDragEnd: (event: DragEndEvent) => finish(event),
      onDragCancel: () => finish(null),
      accessibility: { announcements: noAnnouncements },
    },
    dropAnimation: prefersReducedMotion()
      ? null
      : { duration: 220, easing: "cubic-bezier(0.2,0.7,0.2,1)" },
  };
}

// Cards move by Alt+arrow keys, which announce themselves.
const noAnnouncements: Announcements = {
  onDragStart: () => undefined,
  onDragOver: () => undefined,
  onDragEnd: () => undefined,
  onDragCancel: () => undefined,
};

export type { UniqueIdentifier };
