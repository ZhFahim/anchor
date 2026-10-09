"use client";

import * as React from "react";

type Orientation = "horizontal" | "vertical" | "both";

interface RovingFocusOptions {
  orientation?: Orientation;
  selectsOnMove?: boolean;
  itemSelector?: string;
}

const KEYS: Record<Orientation, { back: string[]; forward: string[] }> = {
  horizontal: { back: ["ArrowLeft"], forward: ["ArrowRight"] },
  vertical: { back: ["ArrowUp"], forward: ["ArrowDown"] },
  both: {
    back: ["ArrowLeft", "ArrowUp"],
    forward: ["ArrowRight", "ArrowDown"],
  },
};

/** Items with `aria-disabled` stay reachable; `disabled` and hidden ones are skipped. */
export function useRovingFocus<T extends HTMLElement>({
  orientation = "horizontal",
  selectsOnMove = false,
  itemSelector = "button",
}: RovingFocusOptions = {}) {
  const ref = React.useRef<T>(null);
  const current = React.useRef<HTMLElement | null>(null);
  const watched = React.useRef<{
    root: T | null;
    observer: MutationObserver | null;
  }>({ root: null, observer: null });

  const items = React.useCallback(() => {
    const root = ref.current;
    if (!root) return [];
    return [...root.querySelectorAll<HTMLElement>(itemSelector)].filter(
      (el) =>
        !(el as HTMLButtonElement).disabled && el.getClientRects().length > 0,
    );
  }, [itemSelector]);

  const update = React.useCallback(() => {
    const list = items();
    const active =
      (current.current && list.includes(current.current)
        ? current.current
        : null) ??
      list.find((el) => el.getAttribute("aria-checked") === "true") ??
      list[0];
    for (const el of list) {
      const tabIndex = el === active ? 0 : -1;
      // Writing the same value would wake the observer again.
      if (el.tabIndex !== tabIndex) el.tabIndex = tabIndex;
    }
  }, [items]);

  React.useLayoutEffect(() => {
    update();
    const root = ref.current;
    if (root === watched.current.root) return;
    watched.current.observer?.disconnect();
    // Catches items that change without a render here.
    let observer: MutationObserver | null = null;
    if (root) {
      observer = new MutationObserver(update);
      observer.observe(root, {
        subtree: true,
        childList: true,
        attributes: true,
        attributeFilter: ["disabled", "hidden", "tabindex", "aria-disabled"],
      });
    }
    watched.current = { root, observer };
  });
  React.useEffect(
    () => () => {
      watched.current.observer?.disconnect();
      watched.current = { root: null, observer: null };
    },
    [],
  );

  const onFocus = (e: React.FocusEvent<T>) => {
    const item = items().find((el) => el.contains(e.target as Node));
    if (!item) return;
    current.current = item;
    update();
  };

  const onKeyDown = (e: React.KeyboardEvent<T>) => {
    if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return;
    const list = items();
    const index = list.findIndex((el) => el.contains(e.target as Node));
    if (index < 0) return;
    const { back, forward } = KEYS[orientation];
    let next: number;
    if (e.key === "Home") next = 0;
    else if (e.key === "End") next = list.length - 1;
    else if (back.includes(e.key))
      next = (index - 1 + list.length) % list.length;
    else if (forward.includes(e.key)) next = (index + 1) % list.length;
    else return;
    e.preventDefault();
    const item = list[next];
    current.current = item;
    update();
    item.focus();
    if (selectsOnMove) item.click();
  };

  return { ref, onFocus, onKeyDown };
}
