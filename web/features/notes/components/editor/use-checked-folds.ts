"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { usePreferencesStore } from "@/features/preferences";
import { DURATION, EASE } from "@/lib/design/tokens";
import { isNearScreen, prefersReducedMotion } from "@/lib/motion";
import type { QuillInstance } from "../../quill";
import {
  type CheckedFold,
  checkedFoldStyles,
  findCheckedFolds,
  foldCount,
} from "./checked-folds";

export interface CheckedFoldRow {
  top: number;
  left: number;
  count: number;
}

function listStates(root: HTMLElement) {
  return [...root.children].map((block) =>
    block.tagName === "OL"
      ? [...block.children].map((item) => item.getAttribute("data-list"))
      : null,
  );
}

function lineElements(root: HTMLElement) {
  return [...root.children].flatMap((block) =>
    block.tagName === "OL"
      ? ([...block.children] as HTMLElement[])
      : [block as HTMLElement],
  );
}

type Lines = Map<HTMLElement, DOMRect>;
type Run = [HTMLElement, DOMRect][];

function linesOnScreen(root: HTMLElement): Lines {
  const lines: Lines = new Map();
  for (const line of lineElements(root)) {
    if (!line.getClientRects().length) continue;
    const rect = line.getBoundingClientRect();
    if (isNearScreen(rect)) lines.set(line, rect);
  }
  return lines;
}

const hasHeight = (rect: DOMRect | undefined) => !!rect && rect.height > 0;

export const isFoldedAway = (line: Element) =>
  !hasHeight(line.getBoundingClientRect());

export function nearestShownIndex(quill: QuillInstance, index: number) {
  let at = index;
  for (let [line] = quill.getLine(at); line && at > 0; ) {
    if (!isFoldedAway(line.domNode)) break;
    at = quill.getIndex(line) - 1;
    [line] = quill.getLine(at);
  }
  return at;
}

/** [shift] and [edge] are [start, end] in page pixels; copies are cut off below [edge]. */
export function rollLines(
  container: HTMLElement,
  lines: Run,
  shift: [number, number],
  edge: [number, number],
  duration: number,
) {
  const layer = document.createElement("div");
  layer.className = "ql-editor fold-copies";
  layer.inert = true;
  layer.setAttribute("aria-hidden", "true");
  container.append(layer);
  const box = container.getBoundingClientRect();
  for (const [line, rect] of lines) {
    const copy = (
      line.isConnected ? line.cloneNode(true) : line
    ) as HTMLElement;
    Object.assign(copy.style, {
      position: "absolute",
      top: `${rect.top - box.top}px`,
      left: `${rect.left - box.left}px`,
      width: `${rect.width}px`,
      margin: "0",
    });
    layer.append(copy);
  }
  const frame = (at: 0 | 1) => ({
    transform: `translateY(${shift[at]}px)`,
    clipPath: `inset(0 0 ${box.bottom - edge[at]}px 0)`,
  });
  const roll = layer.animate([frame(0), frame(1)], {
    duration,
    easing: EASE.standard,
    fill: "forwards",
  });
  roll.finished.finally(() => layer.remove());
  return roll;
}

/** Runs of lines matching [isIn], each with the steady line above it. */
function runsOf(
  root: HTMLElement,
  before: Lines,
  after: Lines,
  isIn: (line: HTMLElement) => boolean,
) {
  const runs: { run: Run; above?: HTMLElement }[] = [];
  let above: HTMLElement | undefined;
  let current: Run = [];
  for (const line of lineElements(root)) {
    if (isIn(line)) {
      const rect = hasHeight(before.get(line))
        ? before.get(line)
        : after.get(line);
      if (rect) current.push([line, rect]);
      continue;
    }
    const isSteady = hasHeight(before.get(line)) && hasHeight(after.get(line));
    if (!isSteady) continue;
    if (current.length) runs.push({ run: current, above });
    current = [];
    above = line;
  }
  if (current.length) runs.push({ run: current, above });
  return runs;
}

const spanOf = (run: Run) => ({
  top: Math.min(...run.map(([, rect]) => rect.top)),
  bottom: Math.max(...run.map(([, rect]) => rect.bottom)),
});

export function useCheckedFolds({
  containerEl,
  getQuill,
  isEnabled,
  noteId,
}: {
  containerEl: HTMLElement | null;
  getQuill: () => QuillInstance | null;
  isEnabled: boolean;
  noteId?: string;
}) {
  const scopeId = useId();
  const scope = `[data-folds="${scopeId}"]`;
  const styleRef = useRef<HTMLStyleElement>(null);
  const foldsRef = useRef<CheckedFold[]>([]);
  const isFoldedSaved = usePreferencesStore(
    (s) => !!noteId && s.editor.foldedChecklistNoteIds.includes(noteId),
  );
  const setChecklistFolded = usePreferencesStore((s) => s.setChecklistFolded);
  const [isFoldedHere, setIsFoldedHere] = useState(false);
  const isFolded = noteId ? isFoldedSaved : isFoldedHere;
  const isFoldedRef = useRef(isFolded);
  const [rows, setRows] = useState<CheckedFoldRow[]>([]);
  const frameRef = useRef(0);

  useEffect(() => {
    if (noteId && isFoldedHere) {
      setChecklistFolded(noteId, true);
      setIsFoldedHere(false);
    }
  }, [noteId, isFoldedHere, setChecklistFolded]);

  const measure = useCallback(() => {
    frameRef.current = 0;
    const root = getQuill()?.root;
    if (!root || !containerEl) return;
    const folds = foldsRef.current;
    const box = folds.length ? containerEl.getBoundingClientRect() : null;
    const next = folds.flatMap((fold) => {
      const firstItem = root.children[fold.block - 1]?.children[fold.first - 1];
      if (!(firstItem instanceof HTMLElement) || !box) return [];
      const rect = firstItem.getBoundingClientRect();
      const marginTop =
        Number.parseFloat(getComputedStyle(firstItem).marginTop) || 0;
      return [
        {
          top: rect.top - box.top - marginTop,
          left: rect.left - box.left,
          count: foldCount(fold),
        },
      ];
    });
    setRows((prev) =>
      prev.length === next.length &&
      prev.every(
        (row, i) =>
          Math.abs(row.top - next[i].top) < 0.5 &&
          Math.abs(row.left - next[i].left) < 0.5 &&
          row.count === next[i].count,
      )
        ? prev
        : next,
    );
    const isSliding = root
      .getAnimations({ subtree: true })
      .some((animation) => animation.playState === "running");
    if (folds.length && isSliding)
      frameRef.current = requestAnimationFrame(measure);
  }, [containerEl, getQuill]);

  const measureSoon = useCallback(() => {
    frameRef.current ||= requestAnimationFrame(measure);
  }, [measure]);

  /** Call right after the text changes, before anything measures the lines. */
  const refresh = useCallback(() => {
    const root = getQuill()?.root;
    const style = styleRef.current;
    if (!root || !style) return;
    const folds = isEnabled ? findCheckedFolds(listStates(root)) : [];
    foldsRef.current = folds;
    const css = checkedFoldStyles(scope, folds, isFoldedRef.current);
    if (style.textContent !== css) style.textContent = css;
    measureSoon();
  }, [getQuill, isEnabled, measureSoon, scope]);

  useEffect(() => {
    isFoldedRef.current = isFolded;
    refresh();
  }, [isFolded, refresh]);

  useEffect(() => {
    const host = containerEl;
    if (!host) return;
    const observer = new MutationObserver(() => refresh());
    observer.observe(host, { childList: true });
    const resizeObserver = new ResizeObserver(measureSoon);
    resizeObserver.observe(host);
    return () => {
      observer.disconnect();
      resizeObserver.disconnect();
      cancelAnimationFrame(frameRef.current);
      frameRef.current = 0;
    };
  }, [containerEl, measureSoon, refresh]);

  const setFolded = useCallback(
    (next: boolean) => {
      const root = getQuill()?.root;
      if (!root || !containerEl || next === isFoldedRef.current) return;
      const isMoving = !prefersReducedMotion();
      const before = isMoving ? linesOnScreen(root) : null;
      isFoldedRef.current = next;
      refresh();
      if (noteId) setChecklistFolded(noteId, next);
      else setIsFoldedHere(next);
      if (!before) return;
      const after = linesOnScreen(root);
      for (const [line, rect] of after) {
        const rectBefore = before.get(line);
        const dy = rectBefore ? rectBefore.top - rect.top : 0;
        if (Math.abs(dy) > 0.5)
          line.animate(
            [{ transform: `translateY(${dy}px)` }, { transform: "none" }],
            { duration: DURATION.move, easing: EASE.standard },
          );
      }
      const shiftOf = (line?: HTMLElement) => {
        const from = line && before.get(line);
        const to = line && after.get(line);
        return from && to ? to.top - from.top : 0;
      };
      const isFolding = (line: HTMLElement) =>
        hasHeight(before.get(line)) && !hasHeight(after.get(line));
      for (const { run, above } of runsOf(root, before, after, isFolding)) {
        const { top, bottom } = spanOf(run);
        rollLines(
          containerEl,
          run,
          [0, shiftOf(above)],
          [bottom, top],
          DURATION.move,
        );
      }
      const isOpening = (line: HTMLElement) =>
        !hasHeight(before.get(line)) && hasHeight(after.get(line));
      for (const { run, above } of runsOf(root, before, after, isOpening)) {
        const { top, bottom } = spanOf(run);
        for (const [line] of run)
          line.animate([{ opacity: 0 }, { opacity: 0 }], {
            duration: DURATION.move,
          });
        rollLines(
          containerEl,
          run,
          [-shiftOf(above), 0],
          [top, bottom],
          DURATION.move,
        );
      }
      measureSoon();
    },
    [containerEl, getQuill, measureSoon, noteId, refresh, setChecklistFolded],
  );

  const revealSelection = useCallback(
    (index: number) => {
      if (!isFoldedRef.current) return;
      const line = getQuill()?.getLine(index)[0]?.domNode;
      if (line && isFoldedAway(line)) setFolded(false);
    },
    [getQuill, setFolded],
  );

  const isActive = useCallback(
    () => isFoldedRef.current && foldsRef.current.length > 0,
    [],
  );
  const toggle = useCallback(
    () => setFolded(!isFoldedRef.current),
    [setFolded],
  );

  return {
    scopeId,
    styleRef,
    rows,
    isFolded,
    isActive,
    toggle,
    refresh,
    revealSelection,
  };
}
