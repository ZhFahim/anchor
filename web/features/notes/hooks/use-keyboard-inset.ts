"use client";

import * as React from "react";

const CARET_GAP = 12;

function caretRect(selection: Selection): DOMRect | null {
  const rect = selection.getRangeAt(0).getClientRects()[0];
  if (rect) return rect;
  const node = selection.focusNode;
  const child = node?.childNodes[selection.focusOffset] ?? node;
  const el = child instanceof Element ? child : child?.parentElement;
  const box = el?.getBoundingClientRect();
  if (box?.height) return box;
  return el?.parentElement?.getBoundingClientRect() ?? null;
}

/** Sets `--keyboard` on the note where the keyboard covers the page (iPhone) and keeps the caret line above it and the phone toolbar. */
export function useKeyboardInset(
  noteRef: React.RefObject<HTMLElement | null>,
  scrollerRef: React.RefObject<HTMLElement | null>,
  active: boolean,
) {
  React.useEffect(() => {
    const note = noteRef.current;
    const scroller = scrollerRef.current;
    if (!active || !note || !scroller) return;
    const viewport = window.visualViewport;
    const phone = window.matchMedia("(width < 768px)");
    let covered = 0;
    let frame = 0;

    const keepCaretVisible = () => {
      const editor = scroller.querySelector(".ql-editor");
      const selection = document.getSelection();
      if (
        !editor ||
        document.activeElement !== editor ||
        !selection?.rangeCount ||
        !selection.isCollapsed ||
        !editor.contains(selection.focusNode)
      )
        return;
      if (!phone.matches && !covered) return;
      const caret = caretRect(selection);
      if (!caret) return;
      let limit = scroller.getBoundingClientRect().bottom;
      const toolbar = note.querySelector(".tb");
      if (toolbar && phone.matches)
        limit = Math.min(limit, toolbar.getBoundingClientRect().top);
      const overlap = caret.bottom - (limit - CARET_GAP);
      if (overlap > 0) scroller.scrollTop += overlap;
    };
    const schedule = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(keepCaretVisible);
    };
    const measure = () => {
      const next =
        viewport && viewport.scale < 1.01
          ? Math.max(
              0,
              Math.round(
                note.getBoundingClientRect().bottom -
                  (viewport.offsetTop + viewport.height),
              ),
            )
          : 0;
      if (next === covered) return;
      covered = next;
      if (covered) note.style.setProperty("--keyboard", `${covered}px`);
      else note.style.removeProperty("--keyboard");
    };

    measure();
    viewport?.addEventListener("resize", measure);
    viewport?.addEventListener("scroll", measure);
    document.addEventListener("selectionchange", schedule);
    const resized = new ResizeObserver(schedule);
    resized.observe(scroller);
    return () => {
      cancelAnimationFrame(frame);
      viewport?.removeEventListener("resize", measure);
      viewport?.removeEventListener("scroll", measure);
      document.removeEventListener("selectionchange", schedule);
      resized.disconnect();
      note.style.removeProperty("--keyboard");
    };
  }, [active, noteRef, scrollerRef]);
}
