"use client";

import { useQuery } from "@tanstack/react-query";
import { useMemo } from "react";
import { getTags } from "./api";
import type { Tag, TagLabel } from "./types";

const NO_TAGS: TagLabel[] = [];

// Without counts, archiving or trashing a note doesn't redraw every card.
const toLabels = (tags: Tag[]): TagLabel[] =>
  tags.map(({ id, name, color }) => ({ id, name, color }));

export function useTags() {
  return useQuery({ queryKey: ["tags"], queryFn: getTags });
}

export function useTagMap(): Map<string, TagLabel> {
  const { data: tags = NO_TAGS } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
    select: toLabels,
  });
  return useMemo(() => new Map(tags.map((t) => [t.id, t])), [tags]);
}
