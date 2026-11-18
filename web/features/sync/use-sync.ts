"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { getAccessToken, useAuthStore } from "@/features/auth";
import { refreshAccessToken } from "@/lib/api/client";
import { connectSyncEvents } from "./events";

const syncedQueryKeys = [
  ["notes"],
  ["tags"],
  ["attachments"],
  ["note-shares"],
  ["note-revisions"],
];

const reorderedQueryKeys = new Set(["notes", "tags"]);

/** Note and tag orders share it; see useNoteReorder and the sidebar. */
export const REORDER_MUTATION_KEY = ["reorder"];

const pushDebounceMs = 300;

// For servers and proxies that never deliver the push channel.
const pollIntervalMs = 5 * 60 * 1000;

export function useSync(): void {
  const queryClient = useQueryClient();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

  useEffect(() => {
    if (!isAuthenticated) return;

    const pull = () => {
      // A reorder on its way would snap back; its last save pulls instead.
      const isReordering =
        queryClient.isMutating({ mutationKey: REORDER_MUTATION_KEY }) > 0;
      for (const queryKey of syncedQueryKeys) {
        if (isReordering && reorderedQueryKeys.has(queryKey[0])) continue;
        void queryClient.invalidateQueries({ queryKey });
      }
    };

    let debounce: ReturnType<typeof setTimeout> | undefined;
    const stream = connectSyncEvents({
      onSync: () => {
        clearTimeout(debounce);
        debounce = setTimeout(pull, pushDebounceMs);
      },
      // Messages sent while we were disconnected are lost.
      onReconnect: pull,
      getToken: getAccessToken,
      refreshToken: refreshAccessToken,
    });

    const poll = setInterval(pull, pollIntervalMs);
    const pullWhenVisible = () => {
      if (document.visibilityState === "visible") pull();
    };

    document.addEventListener("visibilitychange", pullWhenVisible);
    window.addEventListener("online", pull);

    return () => {
      stream.close();
      clearTimeout(debounce);
      clearInterval(poll);
      document.removeEventListener("visibilitychange", pullWhenVisible);
      window.removeEventListener("online", pull);
    };
  }, [isAuthenticated, queryClient]);
}
