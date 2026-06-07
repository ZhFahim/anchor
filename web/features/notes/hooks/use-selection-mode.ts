"use client";

import { useEffect } from "react";

interface UseSelectionModeOptions {
  isSelectionMode: boolean;
  onExit: () => void;
}

/**
 * Hook to handle keyboard shortcuts for selection mode
 * - Escape: Exits selection mode
 */
export function useSelectionMode({
  isSelectionMode,
  onExit,
}: UseSelectionModeOptions) {
  useEffect(() => {
    if (!isSelectionMode) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onExit();
      }
    };

    window.addEventListener("keydown", handleEscape);
    return () => window.removeEventListener("keydown", handleEscape);
  }, [isSelectionMode, onExit]);
}
