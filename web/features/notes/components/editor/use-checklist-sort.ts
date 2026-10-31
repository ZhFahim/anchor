"use client";

import { useCallback, useEffect, useMemo, useRef } from "react";
import { DURATION, EASE } from "@/lib/design/tokens";
import { paintHighlights } from "@/lib/highlight-paint";
import { isNearScreen, prefersReducedMotion } from "@/lib/motion";
import type { QuillDelta, QuillInstance, QuillLine } from "../../quill";
import { findTickedLines, LIST_FORMATS } from "../../quill";
import {
  didChangeChecklistItemState,
  getToggledLinePosition,
  isChecklistLineAt,
} from "../../quill-checklist";
import {
  type DeltaLine,
  deltaToLines,
  findLineIndexAtPosition,
  getLineLength,
} from "../../quill-lines";
import { planChecklistSort } from "./checklist-sort";
import {
  isFoldedAway,
  nearestShownIndex,
  rollLines,
} from "./use-checked-folds";

const TICKED = "ticked";
const SORTING = "sorting";

function lineStarts(lines: DeltaLine[]) {
  const starts: number[] = [];
  let position = 0;
  for (const line of lines) {
    starts.push(position);
    position += getLineLength(line);
  }
  return starts;
}

function lineElement(quill: QuillInstance, position: number) {
  return quill.getLine(position)[0]?.domNode ?? null;
}

type Slide = { animations: Animation[]; frame: number };

export function useChecklistSort({
  containerEl,
  getQuill,
  isEnabled,
  onSlideStart,
  onSlideEnd,
  isFoldActive,
}: {
  containerEl: HTMLElement | null;
  getQuill: () => QuillInstance | null;
  /** The "Move checked items to the bottom" setting. */
  isEnabled: boolean;
  onSlideStart: () => void;
  onSlideEnd: () => void;
  isFoldActive: () => boolean;
}) {
  const live = useRef({
    containerEl,
    isEnabled,
    onSlideStart,
    onSlideEnd,
    isFoldActive,
  });
  live.current = {
    containerEl,
    isEnabled,
    onSlideStart,
    onSlideEnd,
    isFoldActive,
  };
  /** Each toggled line, with its state before the first toggle. */
  const pendingRef = useRef(new Map<QuillLine, unknown>());
  const timerRef = useRef(0);
  const slideRef = useRef<Slide | null>(null);
  const isSortingRef = useRef(false);
  const popTimers = useRef(new WeakMap<Element, number>());

  const stopSlide = useCallback(() => {
    const slide = slideRef.current;
    if (!slide) return false;
    slideRef.current = null;
    cancelAnimationFrame(slide.frame);
    for (const animation of slide.animations) animation.cancel();
    return true;
  }, []);

  const startSlide = useCallback(
    (quill: QuillInstance, moves: { element: HTMLElement; from: number }[]) => {
      const offsets = moves
        .map(({ element, from }) => ({
          element,
          offset: from - element.getBoundingClientRect().top,
        }))
        .filter(({ offset }) => Math.abs(offset) >= 0.5);
      if (!offsets.length) return false;
      const slide: Slide = {
        animations: offsets.map(({ element, offset }) =>
          element.animate(
            [{ transform: `translateY(${offset}px)` }, { transform: "none" }],
            { duration: DURATION.sink, easing: EASE.standard },
          ),
        ),
        frame: 0,
      };
      slideRef.current = slide;
      // The highlight strokes are drawn in their own layer.
      const host = live.current.containerEl;
      const hasHighlights =
        !!host &&
        offsets.some(({ element }) => element.querySelector("mark.hl"));
      const repaint = () => {
        if (host && hasHighlights) paintHighlights(host, quill.root);
      };
      const follow = () => {
        repaint();
        slide.frame = requestAnimationFrame(follow);
      };
      if (hasHighlights) slide.frame = requestAnimationFrame(follow);
      Promise.allSettled(slide.animations.map((a) => a.finished)).then(() => {
        cancelAnimationFrame(slide.frame);
        if (slideRef.current !== slide) return;
        slideRef.current = null;
        repaint();
        live.current.onSlideEnd();
      });
      return true;
    },
    [],
  );

  const sort = useCallback(() => {
    const quill = getQuill();
    const toggles = [...pendingRef.current];
    if (!quill || !live.current.isEnabled) {
      pendingRef.current.clear();
      return;
    }
    // Rewriting lines mid-composition would break the word being composed.
    if (quill.composition.isComposing) {
      timerRef.current = window.setTimeout(sort, DURATION.sinkDelay);
      return;
    }
    pendingRef.current.clear();
    const contents = quill.getContents();
    const lines = deltaToLines(contents.ops);
    const toggledLines: number[] = [];
    for (const [line, stateBefore] of toggles) {
      if (quill.scroll.find(line.domNode) !== line) continue;
      const state = line.formats().list;
      if (
        state === stateBefore ||
        (state !== LIST_FORMATS.CHECKED && state !== LIST_FORMATS.UNCHECKED)
      )
        continue;
      toggledLines.push(findLineIndexAtPosition(lines, quill.getIndex(line)));
    }
    const plan = planChecklistSort(contents, toggledLines);
    if (!plan) return;

    const starts = lineStarts(lines);
    const moved = plan.origins.flatMap((origin, index) =>
      origin === index ? [] : [index],
    );
    const tops = new Map<number, number>();
    const copies = new Map<number, [HTMLElement, DOMRect]>();
    const hasFoldedItems = live.current.isFoldActive();
    starts.forEach((start, index) => {
      const element = lineElement(quill, start);
      if (!element) return;
      const rect = element.getBoundingClientRect();
      if (rect.height === 0 || !isNearScreen(rect)) return;
      tops.set(index, rect.top);
      if (hasFoldedItems && moved.includes(index))
        copies.set(index, [element.cloneNode(true) as HTMLElement, rect]);
    });
    stopSlide();
    live.current.onSlideStart();
    // Quill can reuse a row's element for another line.
    for (const element of quill.root.querySelectorAll(`li.${TICKED}`))
      element.classList.remove(TICKED);

    const selection =
      document.activeElement === quill.root ? quill.getSelection() : null;
    const caretLine = selection
      ? findLineIndexAtPosition(lines, selection.index)
      : -1;
    const isInOneLine =
      !!selection &&
      selection.index + selection.length <
        starts[caretLine] + getLineLength(lines[caretLine]);

    // Quill may rewrite a row into another line.
    const host = live.current.containerEl;
    host?.classList.add(SORTING);
    isSortingRef.current = true;
    try {
      quill.updateContents(plan.delta, "user");
    } finally {
      isSortingRef.current = false;
      void quill.root.offsetHeight;
      host?.classList.remove(SORTING);
    }
    quill.history.cutoff();

    const sortedStarts = lineStarts(deltaToLines(quill.getContents().ops));
    if (selection && isInOneLine) {
      const index =
        sortedStarts[plan.origins.indexOf(caretLine)] +
        selection.index -
        starts[caretLine];
      const now = quill.getSelection();
      if (now?.index !== index || now.length !== selection.length)
        quill.setSelection(index, selection.length, "silent");
    }
    const caret = selection && quill.getSelection();
    if (caret && !caret.length) {
      const at = nearestShownIndex(quill, caret.index);
      if (at !== caret.index) quill.setSelection(at, 0, "silent");
    }
    const isMoving = !prefersReducedMotion();
    const sunk: [HTMLElement, DOMRect][] = [];
    const slides = sortedStarts.flatMap((start, index) => {
      const element = lineElement(quill, start);
      const from = tops.get(plan.origins[index]);
      if (!element || from === undefined) return [];
      if (isFoldedAway(element)) {
        const copy = copies.get(plan.origins[index]);
        if (copy) sunk.push(copy);
        return [];
      }
      return [{ element, from }];
    });
    if (isMoving && host)
      for (const [copy, rect] of sunk)
        rollLines(
          host,
          [[copy, rect]],
          [0, 0],
          [rect.bottom, rect.top],
          DURATION.sink,
        );
    const isSliding = isMoving && startSlide(quill, slides);
    if (!isSliding) live.current.onSlideEnd();
  }, [getQuill, startSlide, stopSlide]);

  const pop = useCallback((element: HTMLElement) => {
    window.clearTimeout(popTimers.current.get(element));
    element.classList.add(TICKED);
    popTimers.current.set(
      element,
      window.setTimeout(
        () => element.classList.remove(TICKED),
        DURATION.tick + 200,
      ),
    );
  }, []);

  /** Call with each user change and the contents before it. */
  const noteChange = useCallback(
    (change: QuillDelta, before: QuillDelta) => {
      const quill = getQuill();
      if (!quill) return;
      for (const position of findTickedLines(change, before)) {
        const element = lineElement(quill, position);
        if (element) pop(element);
      }
      if (!live.current.isEnabled || !didChangeChecklistItemState(change))
        return;
      const position = getToggledLinePosition(change);
      if (position < 0 || !isChecklistLineAt(before, position)) return;
      const [line] = quill.getLine(position);
      if (!line) return;
      if (!pendingRef.current.has(line))
        pendingRef.current.set(
          line,
          line.formats().list === LIST_FORMATS.CHECKED
            ? LIST_FORMATS.UNCHECKED
            : LIST_FORMATS.CHECKED,
        );
      window.clearTimeout(timerRef.current);
      timerRef.current = window.setTimeout(
        sort,
        prefersReducedMotion() ? 0 : DURATION.sinkDelay,
      );
    },
    [getQuill, pop, sort],
  );

  const cancel = useCallback(() => {
    window.clearTimeout(timerRef.current);
    pendingRef.current.clear();
    if (stopSlide()) live.current.onSlideEnd();
  }, [stopSlide]);

  const isSorting = useCallback(() => isSortingRef.current, []);

  useEffect(
    () => () => {
      window.clearTimeout(timerRef.current);
      const slide = slideRef.current;
      slideRef.current = null;
      if (slide) cancelAnimationFrame(slide.frame);
    },
    [],
  );

  return useMemo(
    () => ({ noteChange, cancel, isSorting }),
    [noteChange, cancel, isSorting],
  );
}
