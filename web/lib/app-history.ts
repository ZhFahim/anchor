"use client";

import { usePathname } from "next/navigation";
import { useEffect, useRef } from "react";

// For browsers without the Navigation API.
let pagesVisited = 0;

/** Call once, in the app shell. */
export function useTrackPageChanges() {
  const pathname = usePathname();
  const lastPath = useRef(pathname);
  useEffect(() => {
    if (pathname === lastPath.current) return;
    lastPath.current = pathname;
    pagesVisited += 1;
  }, [pathname]);
}

type HistoryEntry = { index: number; sameDocument?: boolean };
type Navigation = {
  currentEntry?: HistoryEntry | null;
  entries?: () => HistoryEntry[];
};

/** Whether browser Back stays inside the current page load. */
export function canGoBackInApp(): boolean {
  const navigation = (window as { navigation?: Navigation }).navigation;
  const current = navigation?.currentEntry;
  if (current && navigation?.entries) {
    const previous = navigation.entries()[current.index - 1];
    return !!previous?.sameDocument;
  }
  return pagesVisited > 0;
}
