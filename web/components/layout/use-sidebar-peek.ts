import * as React from "react";

const REST_MS = 300;
const STILL_PX = 6;
const MOVE_ON_PX = 16;

type Point = { x: number; y: number };

const distance = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y);

/**
 * Folded, resting the pointer on the sidebar opens it over the page. It doesn't
 * open again where it was just folded, clicked or closed until the pointer moves on.
 */
export function useSidebarPeek(
  root: React.RefObject<HTMLElement | null>,
  isFolded: boolean,
) {
  const [isPeeking, setIsPeeking] = React.useState(false);
  const isPeekingRef = React.useRef(false);
  const pointer = React.useRef<Point>({ x: -1, y: -1 });
  const blockedAt = React.useRef<Point | null>(null);
  const restTimer = React.useRef(0);
  const tuckTimer = React.useRef(0);

  const peek = React.useCallback((open: boolean) => {
    isPeekingRef.current = open;
    setIsPeeking(open);
  }, []);

  const isPointerInside = React.useCallback(() => {
    const box = root.current?.getBoundingClientRect();
    const { x, y } = pointer.current;
    return (
      !!box && x >= box.left && x < box.right && y >= box.top && y < box.bottom
    );
  }, [root]);

  const stopPeeking = React.useCallback(() => {
    clearTimeout(restTimer.current);
    clearTimeout(tuckTimer.current);
    if (isPointerInside()) blockedAt.current = pointer.current;
    peek(false);
  }, [isPointerInside, peek]);

  const onMenuClose = React.useCallback(() => {
    if (isPeekingRef.current && !isPointerInside()) peek(false);
  }, [isPointerInside, peek]);

  React.useEffect(() => {
    const onMove = (e: PointerEvent) => {
      pointer.current = { x: e.clientX, y: e.clientY };
    };
    document.addEventListener("pointermove", onMove, { passive: true });
    return () => document.removeEventListener("pointermove", onMove);
  }, []);

  React.useEffect(() => {
    const element = root.current;
    clearTimeout(restTimer.current);
    clearTimeout(tuckTimer.current);
    peek(false);
    if (!element || !isFolded) return;
    if (isPointerInside()) blockedAt.current = pointer.current;
    let restingAt: Point | null = null;
    const hasOpenMenu = () => !!element.querySelector("[aria-expanded=true]");

    const onMove = (e: PointerEvent) => {
      if (e.pointerType === "touch") return;
      clearTimeout(tuckTimer.current);
      if (isPeekingRef.current) return;
      const at = { x: e.clientX, y: e.clientY };
      if (blockedAt.current) {
        if (distance(at, blockedAt.current) < MOVE_ON_PX) return;
        blockedAt.current = null;
      }
      if (restingAt && distance(at, restingAt) < STILL_PX) return;
      restingAt = at;
      clearTimeout(restTimer.current);
      restTimer.current = window.setTimeout(() => peek(true), REST_MS);
    };
    const onLeave = () => {
      clearTimeout(restTimer.current);
      restingAt = null;
      blockedAt.current = null;
      if (isPeekingRef.current && !hasOpenMenu())
        tuckTimer.current = window.setTimeout(() => peek(false), REST_MS);
    };
    const onDown = () => {
      if (isPeekingRef.current) return;
      clearTimeout(restTimer.current);
      restingAt = null;
      blockedAt.current = pointer.current;
    };
    const onDocumentDown = (e: PointerEvent) => {
      const target = e.target as Element;
      if (
        isPeekingRef.current &&
        !hasOpenMenu() &&
        !element.contains(target) &&
        !target.closest?.("[data-radix-popper-content-wrapper]")
      )
        peek(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== "Escape" || !isPeekingRef.current || hasOpenMenu()) return;
      e.preventDefault();
      e.stopPropagation();
      stopPeeking();
    };

    document.addEventListener("pointerdown", onDocumentDown, true);
    document.addEventListener("keydown", onKey, true);
    element.addEventListener("pointermove", onMove);
    element.addEventListener("pointerleave", onLeave);
    element.addEventListener("pointerdown", onDown);
    return () => {
      clearTimeout(restTimer.current);
      clearTimeout(tuckTimer.current);
      document.removeEventListener("pointerdown", onDocumentDown, true);
      document.removeEventListener("keydown", onKey, true);
      element.removeEventListener("pointermove", onMove);
      element.removeEventListener("pointerleave", onLeave);
      element.removeEventListener("pointerdown", onDown);
    };
  }, [root, isFolded, isPointerInside, peek, stopPeeking]);

  return { isPeeking: isFolded && isPeeking, stopPeeking, onMenuClose };
}
