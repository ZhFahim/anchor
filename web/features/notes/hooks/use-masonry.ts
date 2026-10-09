"use client";

import * as React from "react";
import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";

const columnOf = new WeakMap<Element, number>();
const GLIDE_WIDTH_CHANGE = 8;

function setVar(el: HTMLElement, name: string, px: number) {
  const value = `${px}px`;
  if (el.style.getPropertyValue(name) !== value)
    el.style.setProperty(name, value);
}

export function pickColumn(columnEnds: number[], tolerance: number): number {
  const lowest = Math.min(...columnEnds);
  return columnEnds.findIndex((end) => end <= lowest + tolerance);
}

function placeCards(box: HTMLElement, slide: boolean) {
  if (!box.isConnected || !box.matches(".cards.masonry")) return;
  const width = box.clientWidth;
  if (!width) return;
  const style = getComputedStyle(box);
  const gap = Number.parseFloat(style.getPropertyValue("--gap")) || 0;
  const minWidth =
    Number.parseFloat(style.getPropertyValue("--masonry-min")) || 0;
  const maxColumns =
    Number.parseInt(style.getPropertyValue("--masonry-columns"), 10) || 1;
  const count = Math.max(
    1,
    Math.min(maxColumns, Math.floor((width + gap) / (minWidth + gap))),
  );
  const columnWidth = (width - gap * (count - 1)) / count;
  const hasJumped =
    Math.abs(
      columnWidth -
        Number.parseFloat(box.style.getPropertyValue("--masonry-width")),
    ) > GLIDE_WIDTH_CHANGE;
  const cards = Array.from(box.children) as HTMLElement[];
  const animate = slide && !prefersReducedMotion();
  const before = animate
    ? cards.map((card) => card.getBoundingClientRect())
    : [];
  const origin = box.getBoundingClientRect();

  setVar(box, "--masonry-width", columnWidth);
  const heights = cards.map((card) => card.offsetHeight);
  const columnEnds: number[] = Array(count).fill(0);
  let changedColumn = false;
  const spots = cards.map((card, index) => {
    const column = pickColumn(columnEnds, gap);
    const spot = { x: column * (columnWidth + gap), y: columnEnds[column] };
    columnEnds[column] += heights[index] + gap;
    if (columnOf.has(card) && columnOf.get(card) !== column)
      changedColumn = true;
    columnOf.set(card, column);
    return spot;
  });
  cards.forEach((card, index) => {
    setVar(card, "--masonry-x", spots[index].x);
    setVar(card, "--masonry-y", spots[index].y);
  });
  setVar(box, "--masonry-height", Math.max(0, Math.max(...columnEnds) - gap));

  if (!animate || !(changedColumn || hasJumped)) return;
  cards.forEach((card, index) => {
    const dx = before[index].left - origin.left - spots[index].x;
    const dy = before[index].top - origin.top - spots[index].y;
    if (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5)
      card.animate(
        [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: "none" }],
        { duration: DURATION.move, easing: EASE.standard },
      );
  });
}

/** [ruler] is a zero-height element beside the boxes that spans their width. */
export function useMasonry(
  container: React.RefObject<HTMLElement | null>,
  ruler: React.RefObject<HTMLElement | null>,
) {
  const observerRef = React.useRef<ResizeObserver | null>(null);
  const observedRef = React.useRef(new Set<Element>());

  React.useLayoutEffect(() => {
    const observed = observedRef.current;
    const observer = new ResizeObserver((entries) => {
      const boxes = new Set<HTMLElement>();
      for (const entry of entries) {
        if (entry.target === ruler.current) {
          for (const box of container.current?.querySelectorAll<HTMLElement>(
            ".cards.masonry",
          ) ?? [])
            boxes.add(box);
        } else {
          const box = entry.target.closest<HTMLElement>(".cards.masonry");
          if (box) boxes.add(box);
        }
      }
      for (const box of boxes) placeCards(box, true);
    });
    observerRef.current = observer;
    return () => {
      observer.disconnect();
      observerRef.current = null;
      observed.clear();
    };
  }, [container, ruler]);

  React.useLayoutEffect(() => {
    const root = container.current;
    const observer = observerRef.current;
    if (!root || !observer) return;
    const observed = observedRef.current;
    const watch = (el: Element) => {
      if (observed.has(el)) return;
      observed.add(el);
      observer.observe(el);
    };
    for (const el of observed) {
      if (el.isConnected) continue;
      observed.delete(el);
      observer.unobserve(el);
    }
    if (ruler.current) watch(ruler.current);
    for (const box of root.querySelectorAll<HTMLElement>(".cards.masonry")) {
      placeCards(box, false);
      for (const card of box.children) watch(card);
    }
  });
}
