"use client";

import * as React from "react";
import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";

const columnOf = new WeakMap<Element, number>();
const GLIDE_WIDTH_CHANGE = 8;

function setVar(el: HTMLElement, name: string, value: number | string) {
  const text = typeof value === "number" ? `${value}px` : value;
  if (el.style.getPropertyValue(name) !== text)
    el.style.setProperty(name, text);
}

const lengthOf = (style: CSSStyleDeclaration, name: string) =>
  Number.parseFloat(style.getPropertyValue(name)) || 0;

export function columnCount(
  width: number,
  gap: number,
  min: number,
  max: number,
): number {
  const fewest = Math.ceil((width + gap) / (max + gap));
  const most = Math.floor((width + gap) / (min + gap));
  return Math.max(1, Math.min(fewest, most));
}

export function pickColumn(columnEnds: number[], tolerance: number): number {
  const lowest = Math.min(...columnEnds);
  return columnEnds.findIndex((end) => end <= lowest + tolerance);
}

const BOXES = ".cards.masonry, .cards.grid";

function layOutCards(box: HTMLElement, slide: boolean) {
  if (!box.isConnected || !box.matches(BOXES)) return;
  const width = box.clientWidth;
  if (!width) return;
  const style = getComputedStyle(box);
  const gap = lengthOf(style, "--gap");
  const count =
    Number.parseInt(style.getPropertyValue("--card-columns"), 10) ||
    columnCount(
      width,
      gap,
      lengthOf(style, "--card-min"),
      lengthOf(style, "--card-max"),
    );
  setVar(box, "--columns", String(count));
  if (!box.matches(".cards.masonry")) return;
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
export function useCardColumns(
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
            BOXES,
          ) ?? [])
            boxes.add(box);
        } else {
          const box = entry.target.closest<HTMLElement>(".cards.masonry");
          if (box) boxes.add(box);
        }
      }
      for (const box of boxes) layOutCards(box, true);
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
    for (const box of root.querySelectorAll<HTMLElement>(BOXES)) {
      layOutCards(box, false);
      if (box.matches(".cards.masonry"))
        for (const card of box.children) watch(card);
    }
  });
}
