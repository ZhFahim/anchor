"use client";

import * as React from "react";

const HOLD_TOLERANCE = 8;

/**
 * On touch, a ring grows under the finger while a long press arms a drag, and
 * follows it while dragging. A swipe before the press completes is a scroll.
 * It also stops the long-press menu, which Android opens on the same gesture.
 */
export function useHoldRing(selector: string, isEnabled = true) {
  React.useEffect(() => {
    if (!isEnabled) return;
    const onStart = (event: TouchEvent) => {
      if (event.touches.length !== 1) return;
      const target = (event.target as Element | null)?.closest(selector);
      if (!target) return;
      const start = event.touches[0];
      const ring = document.createElement("div");
      ring.className = "hold-ring";
      ring.setAttribute("aria-hidden", "true");
      const place = (x: number, y: number) => {
        ring.style.left = `${x}px`;
        ring.style.top = `${y}px`;
      };
      place(start.clientX, start.clientY);
      document.body.append(ring);
      const startedAt = performance.now();

      const stopMenu = (e: Event) => e.preventDefault();
      const onMove = (e: TouchEvent) => {
        const touch = e.touches[0];
        if (!touch) return;
        const isArming = performance.now() - startedAt < 250;
        const distance = Math.hypot(
          touch.clientX - start.clientX,
          touch.clientY - start.clientY,
        );
        if (isArming && distance > HOLD_TOLERANCE) return end();
        place(touch.clientX, touch.clientY);
      };
      const end = () => {
        window.removeEventListener("touchmove", onMove);
        window.removeEventListener("touchend", end);
        window.removeEventListener("touchcancel", end);
        target.removeEventListener("contextmenu", stopMenu);
        ring.classList.add("is-leaving");
        setTimeout(() => ring.remove(), 160);
      };
      window.addEventListener("touchmove", onMove, { passive: true });
      window.addEventListener("touchend", end);
      window.addEventListener("touchcancel", end);
      target.addEventListener("contextmenu", stopMenu);
    };
    document.addEventListener("touchstart", onStart, { passive: true });
    return () => document.removeEventListener("touchstart", onStart);
  }, [selector, isEnabled]);
}
