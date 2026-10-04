"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { QuillInstance } from "../../quill";
import { setUndoCaret } from "../../quill";
import type { ChecklistDragPlan } from "../../quill-checklist";
import {
  buildChecklistDropDelta,
  checklistLineIndexFromOrdinal,
  getChecklistDragPlan,
} from "../../quill-checklist";
import {
  deltaToLines,
  getLineLength,
  getLineStartPosition,
} from "../../quill-lines";

const CHECKLIST_ITEM_SELECTOR =
  'li[data-list="checked"], li[data-list="unchecked"]';
const EDGE_EXTENT = 72;
const MAX_SCROLL_SPEED = 16;
/** How far left of a row the hover zone (and the handle) extends. */
const GUTTER_EXTENT = 48;
/** Vertical slack so the handle survives the small gaps between rows. */
const BAND_SLACK = 3;
/** Horizontal pointer travel per nesting level, matching the editor CSS. */
const INDENT_STEP = 24;

export type ChecklistDragHandle = {
  top: number;
  left: number;
};

export type ChecklistDragState = {
  /** Null while the drop would change nothing. */
  indicatorTop: number | null;
  /** Left edge of the block's row at the indent the drop would give it. */
  indicatorLeft: number;
  ghostTop: number;
  ghostLeft: number;
  text: string;
  checked: boolean;
  /** Indented children travelling with the dragged line. */
  childCount: number;
};

export function scrollerOf(el: HTMLElement): HTMLElement {
  for (let parent = el.parentElement; parent; parent = parent.parentElement) {
    const { overflowY } = getComputedStyle(parent);
    if (
      (overflowY === "auto" || overflowY === "scroll") &&
      parent.scrollHeight > parent.clientHeight
    )
      return parent;
  }
  return (document.scrollingElement ?? document.documentElement) as HTMLElement;
}

function hitTestRow(
  containerEl: HTMLElement,
  x: number,
  y: number,
): HTMLElement | null {
  for (const el of containerEl.querySelectorAll<HTMLElement>(
    CHECKLIST_ITEM_SELECTOR,
  )) {
    const rect = el.getBoundingClientRect();
    if (
      y >= rect.top - BAND_SLACK &&
      y <= rect.bottom + BAND_SLACK &&
      x >= rect.left - GUTTER_EXTENT &&
      x <= rect.right
    )
      return el;
  }
  return null;
}

function visibleSpan(scroller: HTMLElement) {
  if (scroller === document.scrollingElement)
    return { top: 0, bottom: window.innerHeight };
  const rect = scroller.getBoundingClientRect();
  return {
    top: Math.max(0, rect.top),
    bottom: Math.min(window.innerHeight, rect.bottom),
  };
}

type ActiveDrag = {
  plan: ChecklistDragPlan;
  /** The rows at drag start, in the scroller's content coordinates. */
  bands: { top: number; height: number }[];
  scroller: HTMLElement;
  /** Left of the dragged block's row relative to the container. */
  blockLeft: number;
  /** Pointer X at drag start; horizontal travel from here picks the indent. */
  startX: number;
  gap: number | null;
  /** Indent the head line takes on drop, picked by horizontal travel. */
  indent: number;
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
  const pointerRef = useRef<{ x: number; y: number } | null>(null);
  const isHandlePausedRef = useRef(false);
  const dragRef = useRef<ActiveDrag | null>(null);
  const scrollFrameRef = useRef<number | null>(null);

  // The hover zone is the row rect plus the gutter where the handle sits;
  // anything target-based loses the row en route to the handle.
  const showHandleAt = useCallback(
    (x: number, y: number) => {
      if (!containerEl) return;
      const item = hitTestRow(containerEl, x, y);
      hoveredItemRef.current = item;
      if (!item) {
        setHandle(null);
        return;
      }
      const itemRect = item.getBoundingClientRect();
      const containerRect = containerEl.getBoundingClientRect();
      const next = {
        top: itemRect.top - containerRect.top + 1,
        left: itemRect.left - containerRect.left - 28,
      };
      setHandle((prev) =>
        prev && prev.top === next.top && prev.left === next.left ? prev : next,
      );
    },
    [containerEl],
  );

  useEffect(() => {
    if (!enabled || !containerEl) {
      setHandle(null);
      return;
    }

    const onPointerMove = (e: PointerEvent) => {
      pointerRef.current = { x: e.clientX, y: e.clientY };
      if (dragRef.current || isHandlePausedRef.current) return;
      showHandleAt(e.clientX, e.clientY);
    };
    const onPointerLeave = (e: PointerEvent) => {
      if (dragRef.current) return;
      // Leaving toward the handle's gutter zone keeps the handle alive.
      if (hitTestRow(containerEl, e.clientX, e.clientY)) return;
      pointerRef.current = null;
      hoveredItemRef.current = null;
      setHandle(null);
    };

    containerEl.addEventListener("pointermove", onPointerMove);
    containerEl.addEventListener("pointerleave", onPointerLeave);
    return () => {
      containerEl.removeEventListener("pointermove", onPointerMove);
      containerEl.removeEventListener("pointerleave", onPointerLeave);
    };
  }, [enabled, containerEl, showHandleAt]);

  const pauseHandle = useCallback(() => {
    isHandlePausedRef.current = true;
    hoveredItemRef.current = null;
    setHandle(null);
  }, []);

  const resumeHandle = useCallback(() => {
    isHandlePausedRef.current = false;
    const pointer = pointerRef.current;
    if (enabled && pointer && !dragRef.current)
      showHandleAt(pointer.x, pointer.y);
  }, [enabled, showHandleAt]);

  const updateDrag = useCallback(
    (x: number, y: number) => {
      const active = dragRef.current;
      if (!active || !containerEl) return;
      active.pointer = { x, y };
      const { plan, bands } = active;

      const scrolled = active.scroller.scrollTop;
      const contentY = y + scrolled;
      // Y of a gap, centered in the visual seam between the two rows.
      const gapEdge = (g: number) => {
        const rel = g - plan.groupStart;
        if (rel <= 0) return bands[0].top;
        if (rel >= bands.length) {
          const last = bands[bands.length - 1];
          return last.top + last.height;
        }
        const prev = bands[rel - 1];
        return (prev.top + prev.height + bands[rel].top) / 2;
      };
      // Snap to the nearest structurally valid gap.
      let entry = plan.gaps[0];
      let bestDistance = Number.POSITIVE_INFINITY;
      for (const g of plan.gaps) {
        const distance = Math.abs(contentY - gapEdge(g.gap));
        if (distance < bestDistance) {
          bestDistance = distance;
          entry = g;
        }
      }
      // Horizontal travel from the grab point picks the indent at this gap.
      const desired =
        plan.indent + Math.round((x - active.startX) / INDENT_STEP);
      const indent = Math.min(
        entry.maxIndent,
        Math.max(entry.minIndent, desired),
      );
      active.gap = entry.gap;
      active.indent = indent;

      const containerRect = containerEl.getBoundingClientRect();
      const moves = entry.gap < plan.lineIndex || entry.gap > plan.blockEnd + 1;
      let indicatorTop: number | null = null;
      if (moves || indent !== plan.indent) {
        indicatorTop = gapEdge(entry.gap) - scrolled - containerRect.top;
      }

      setDrag({
        indicatorTop,
        indicatorLeft: active.blockLeft + (indent - plan.indent) * INDENT_STEP,
        ghostTop: y - containerRect.top,
        ghostLeft: Math.min(
          x - containerRect.left + 14,
          containerRect.width - 200,
        ),
        text: plan.text,
        checked: plan.checked,
        childCount: plan.blockEnd - plan.lineIndex,
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
      const contents = quill.getContents();
      const moveDelta = buildChecklistDropDelta(
        contents,
        active.plan.lineIndex,
        active.gap,
        active.indent,
      );
      if (!moveDelta) return;
      const lines = deltaToLines(contents.ops);
      const line = active.plan.lineIndex;
      const restoreCaret = setUndoCaret(
        quill,
        getLineStartPosition(lines, line) + getLineLength(lines[line]) - 1,
      );
      // Cutoffs keep the move out of the surrounding typing's undo batches.
      quill.history.cutoff();
      quill.updateContents(moveDelta, "user");
      quill.history.cutoff();
      restoreCaret();
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
      const { top, bottom } = visibleSpan(active.scroller);
      let dy = 0;
      if (y < top + EDGE_EXTENT) {
        dy =
          -MAX_SCROLL_SPEED *
          Math.min(1, (top + EDGE_EXTENT - y) / EDGE_EXTENT);
      } else if (y > bottom - EDGE_EXTENT) {
        dy =
          MAX_SCROLL_SPEED *
          Math.min(1, (y - (bottom - EDGE_EXTENT)) / EDGE_EXTENT);
      }
      if (dy !== 0) {
        const before = active.scroller.scrollTop;
        active.scroller.scrollBy(0, dy);
        if (active.scroller.scrollTop !== before) {
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

      const scroller = scrollerOf(containerEl);
      const bands = items.map((el) => {
        const rect = el.getBoundingClientRect();
        return { top: rect.top + scroller.scrollTop, height: rect.height };
      });
      const blockEls = items.slice(
        plan.lineIndex - plan.groupStart,
        plan.blockEnd - plan.groupStart + 1,
      );

      for (const el of blockEls) {
        el.classList.add("anchor-checklist-dragging");
      }
      document.body.style.userSelect = "none";
      document.body.style.cursor = "grabbing";

      const onMove = (ev: PointerEvent) => updateDrag(ev.clientX, ev.clientY);
      const onUp = () => finishDrag(true);
      const onCancel = () => finishDrag(false);
      const onKeyDown = (ev: KeyboardEvent) => {
        if (ev.key !== "Escape") return;
        ev.preventDefault();
        ev.stopPropagation();
        finishDrag(false);
      };
      window.addEventListener("pointermove", onMove);
      window.addEventListener("pointerup", onUp);
      window.addEventListener("pointercancel", onCancel);
      window.addEventListener("keydown", onKeyDown, true);

      dragRef.current = {
        plan,
        bands,
        scroller,
        blockLeft:
          blockEls[0].getBoundingClientRect().left -
          containerEl.getBoundingClientRect().left,
        startX: e.clientX,
        gap: null,
        indent: plan.indent,
        pointer: { x: e.clientX, y: e.clientY },
        cleanup: () => {
          window.removeEventListener("pointermove", onMove);
          window.removeEventListener("pointerup", onUp);
          window.removeEventListener("pointercancel", onCancel);
          window.removeEventListener("keydown", onKeyDown, true);
          // Before updateContents: quill reuses li nodes across renders and
          // the class would stick to whichever line ends up in this one.
          for (const el of blockEls) {
            el.classList.remove("anchor-checklist-dragging");
          }
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

  return { handle, drag, startDrag, pauseHandle, resumeHandle };
}
