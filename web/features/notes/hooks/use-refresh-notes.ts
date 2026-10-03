"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";

export function useRefreshNotes() {
  const queryClient = useQueryClient();
  return useCallback(
    () =>
      Promise.all([
        queryClient.invalidateQueries({ queryKey: ["notes"] }),
        queryClient.invalidateQueries({ queryKey: ["tags"] }),
      ]),
    [queryClient],
  );
}
