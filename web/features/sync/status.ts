"use client";

import { useEffect } from "react";
import { create } from "zustand";

interface SyncStatusState {
  online: boolean;
  waiting: Record<string, number>;
  setOnline: (online: boolean) => void;
  setWaiting: (noteId: string, count: number) => void;
}

export const useSyncStatus = create<SyncStatusState>((set) => ({
  online: true,
  waiting: {},
  setOnline: (online) => set({ online }),
  setWaiting: (noteId, count) =>
    set((s) => {
      const waiting = { ...s.waiting };
      if (count > 0) waiting[noteId] = count;
      else delete waiting[noteId];
      return { waiting };
    }),
}));

export function useOnlineStatus() {
  const setOnline = useSyncStatus((s) => s.setOnline);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    update();
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, [setOnline]);
}

export function useUnsavedCount() {
  return useSyncStatus((s) =>
    Object.values(s.waiting).reduce((a, b) => a + b, 0),
  );
}

export function useWarnWhenUnsaved() {
  const unsaved = useUnsavedCount();
  useEffect(() => {
    if (!unsaved) return;
    const warn = (event: BeforeUnloadEvent) => event.preventDefault();
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [unsaved]);
}
