import { useSyncExternalStore } from "react";
import { usePreferencesStore } from "@/features/preferences";

// The width from which the sidebar stays on screen.
const WIDE_QUERY = "(width >= 1024px)";

const isWide = () => window.matchMedia(WIDE_QUERY).matches;

const watchWidth = (onChange: () => void) => {
  const query = window.matchMedia(WIDE_QUERY);
  query.addEventListener("change", onChange);
  return () => query.removeEventListener("change", onChange);
};

/** The notes list and the open note side by side. Narrower screens show a list. */
export function useColumns() {
  const isChosen = usePreferencesStore((s) => s.notes.viewMode === "columns");
  const wide = useSyncExternalStore(watchWidth, isWide, () => false);
  return isChosen && wide;
}
