"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { ChecklistDragPlan, QuillInstance } from "@/features/notes";
import {
  buildChecklistDropDelta,
  checklistLineIndexFromOrdinal,
  getChecklistDragPlan,
} from "@/features/notes";

const CHECKLIST_ITEM_SELECTOR =
  'li[data-list="checked"], li[data-list="unchecked"]';
const EDGE_EXTENT = 72;
const MAX_SCROLL_SPEED = 16;
/** How far left of a row the hover zone (and the handle) extends. */
const GUTTER_EXTENT = 48;
/** Vertical slack so the handle survives the small gaps between rows. */
const BAND_SLACK = 3;

export type ChecklistDragHandle = {
  top: number;
  left: number;
};

export type ChecklistDragState = {
  /** Null while the drop would put the item back where it started. */
  indicatorTop: number | null;
  ghostTop: number;
  ghostLeft: number;
  text: string;
  checked: boolean;
};

type ActiveDrag = {
  plan: ChecklistDragPlan;
  /**
   * The group's row geometry snapshotted at drag start, in document
   * coordinates so it stays valid across auto-scroll.
   */
  bands: { top: number; height: number }[];
  gap: number | null;
  pointer: { x: number; y: number };
  cleanup: () => void;
};

/**
 * Drag-to-reorder for checklist items: a grip handle appears next to the
 * hovered item; dragging it moves the line within its checklist group and
 * the drop is applied as a single move delta (one undo entry, selection
 * untouched).
 */
export function useChecklistDrag({
  containerEl,
  getQuill,
  enabled,
}: {
  containerEl: HTMLElement | null;
  getQuill: () => QuillInstance | null;
  enabled: boolean;
}) {
  const [handle, setHandle] = useState<ChecklistDragHandle | null>(null);
  const [drag, setDrag] = useState<ChecklistDragState | null>(null);

  const hoveredItemRef = useRef<HTMLElement | null>(null);
  const dragRef = useRef<ActiveDrag | null>(null);
  const scrollFrameRef = useRef<number | null>(null);

  // The hover zone is the row rect plus the gutter where the handle sits;
  // anything target-based loses the row en route to the handle.
  useEffect(() => {
    if (!enabled || !containerEl) {
      setHandle(null);
      return;
    }

    const hitTestRow = (x: number, y: number): HTMLElement | null => {
      const items = containerEl.querySelectorAll(CHECKLIST_ITEM_SELECTOR);
      for (const el of items) {
        const rect = el.getBoundingClientRect();
        if (
          y >= rect.top - BAND_SLACK &&
          y <= rect.bottom + BAND_SLACK &&
          x >= rect.left - GUTTER_EXTENT &&
          x <= rect.right
        ) {
          return el as HTMLElement;
        }
      }
      return null;
    };

    const onPointerMove = (e: PointerEvent) => {
      if (dragRef.current) return;
      const item = hitTestRow(e.clientX, e.clientY);
      if (!item) {
        hoveredItemRef.current = null;
        setHandle(null);
        return;
      }
      hoveredItemRef.current = item;
      const itemRect = item.getBoundingClientRect();
      const containerRect = containerEl.getBoundingClientRect();
      const next = {
        top: itemRect.top - containerRect.top + 1,
        left: itemRect.left - containerRect.left - 28,
      };
      setHandle((prev) =>
        prev && prev.top === next.top && prev.left === next.left ? prev : next,
      );
    };
    const onPointerLeave = (e: PointerEvent) => {
      if (dragRef.current) return;
      // Leaving toward the handle's gutter zone keeps the handle alive.
      if (hitTestRow(e.clientX, e.clientY)) return;
      hoveredItemRef.current = null;
      setHandle(null);
    };

    containerEl.addEventListener("pointermove", onPointerMove);
    containerEl.addEventListener("pointerleave", onPointerLeave);
    return () => {
      containerEl.removeEventListener("pointermove", onPointerMove);
      containerEl.removeEventListener("pointerleave", onPointerLeave);
    };
  }, [enabled, containerEl]);

  const updateDrag = useCallback(
    (x: number, y: number) => {
      const active = dragRef.current;
      if (!active || !containerEl) return;
      active.pointer = { x, y };
      const { plan, bands } = active;

      // Bands are in document coordinates, so they survive auto-scroll.
      const docY = y + window.scrollY;
      let gap = plan.groupEnd + 1;
      for (let i = 0; i < bands.length; i++) {
        if (docY < bands[i].top + bands[i].height / 2) {
          gap = plan.groupStart + i;
          break;
        }
      }
      gap = Math.min(Math.max(gap, plan.minGap), plan.maxGap);
      active.gap = gap;

      const containerRect = containerEl.getBoundingClientRect();
      let indicatorTop: number | null = null;
      if (gap !== plan.lineIndex && gap !== plan.lineIndex + 1) {
        const rel = gap - plan.groupStart;
        const edgeDocY =
          rel < bands.length
            ? bands[rel].top
            : bands[bands.length - 1].top + bands[bands.length - 1].height;
        indicatorTop = edgeDocY - window.scrollY - containerRect.top;
      }

      setDrag({
        indicatorTop,
        ghostTop: y - containerRect.top,
        ghostLeft: Math.min(
          x - containerRect.left + 14,
          containerRect.width - 200,
        ),
        text: plan.text,
        checked: plan.checked,
      });
    },
    [containerEl],
  );

  const finishDrag = useCallback(
    (commit: boolean) => {
      const active = dragRef.current;
      if (!active) return;
      active.cleanup();
      dragRef.current = null;
      setDrag(null);

      if (!commit || active.gap === null) return;
      const quill = getQuill();
      if (!quill) return;
      const moveDelta = buildChecklistDropDelta(
        quill.getContents(),
        active.plan.lineIndex,
        active.gap,
      );
      if (!moveDelta) return;
      // Cutoffs keep the move out of the surrounding typing's undo batches.
      quill.history.cutoff();
      quill.updateContents(moveDelta, "user");
      quill.history.cutoff();
    },
    [getQuill],
  );

  const startAutoScroll = useCallback(() => {
    const step = () => {
      const active = dragRef.current;
      if (!active) {
        scrollFrameRef.current = null;
        return;
      }
      const y = active.pointer.y;
      let dy = 0;
      if (y < EDGE_EXTENT) {
        dy = -MAX_SCROLL_SPEED * Math.min(1, (EDGE_EXTENT - y) / EDGE_EXTENT);
      } else if (y > window.innerHeight - EDGE_EXTENT) {
        dy =
          MAX_SCROLL_SPEED *
          Math.min(1, (y - (window.innerHeight - EDGE_EXTENT)) / EDGE_EXTENT);
      }
      if (dy !== 0) {
        const before = window.scrollY;
        window.scrollBy(0, dy);
        if (window.scrollY !== before) {
          updateDrag(active.pointer.x, active.pointer.y);
        }
      }
      scrollFrameRef.current = requestAnimationFrame(step);
    };
    scrollFrameRef.current = requestAnimationFrame(step);
  }, [updateDrag]);

  const startDrag = useCallback(
    (e: React.PointerEvent) => {
      if (!enabled || !containerEl || dragRef.current) return;
      const item = hoveredItemRef.current;
      const quill = getQuill();
      if (!item || !quill) return;
      e.preventDefault();
      e.stopPropagation();

      const allItems = Array.from(
        quill.root.querySelectorAll(CHECKLIST_ITEM_SELECTOR),
      ) as HTMLElement[];
      const ordinal = allItems.indexOf(item);
      if (ordinal === -1) return;

      const contents = quill.getContents();
      const lineIndex = checklistLineIndexFromOrdinal(contents, ordinal);
      if (lineIndex === -1) return;
      const plan = getChecklistDragPlan(contents, lineIndex);
      if (!plan) return;

      const groupSize = plan.groupEnd - plan.groupStart + 1;
      const items = allItems.slice(
        plan.groupOrdinal,
        plan.groupOrdinal + groupSize,
      );
      if (items.length !== groupSize) return;

      const bands = items.map((el) => {
        const rect = el.getBoundingClientRect();
        return { top: rect.top + window.scrollY, height: rect.height };
      });

      item.classList.add("anchor-checklist-dragging");
      document.body.style.userSelect = "none";
      document.body.style.cursor = "grabbing";

      const onMove = (ev: PointerEvent) => updateDrag(ev.clientX, ev.clientY);
      const onUp = () => finishDrag(true);
      const onCancel = () => finishDrag(false);
      window.addEventListener("pointermove", onMove);
      window.addEventListener("pointerup", onUp);
      window.addEventListener("pointercancel", onCancel);

      dragRef.current = {
        plan,
        bands,
        gap: null,
        pointer: { x: e.clientX, y: e.clientY },
        cleanup: () => {
          window.removeEventListener("pointermove", onMove);
          window.removeEventListener("pointerup", onUp);
          window.removeEventListener("pointercancel", onCancel);
          // Before updateContents: quill reuses li nodes across renders and
          // the class would stick to whichever line ends up in this one.
          item.classList.remove("anchor-checklist-dragging");
          document.body.style.userSelect = "";
          document.body.style.cursor = "";
          if (scrollFrameRef.current !== null) {
            cancelAnimationFrame(scrollFrameRef.current);
            scrollFrameRef.current = null;
          }
        },
      };
      setHandle(null);
      updateDrag(e.clientX, e.clientY);
      startAutoScroll();
    },
    [enabled, containerEl, getQuill, updateDrag, finishDrag, startAutoScroll],
  );

  useEffect(() => {
    return () => {
      dragRef.current?.cleanup();
      dragRef.current = null;
    };
  }, []);

  return { handle, drag, startDrag };
}
