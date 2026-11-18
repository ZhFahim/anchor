"use client";

import { useQuery } from "@tanstack/react-query";
import { useMemo } from "react";
import { type TagOrder, usePreferencesStore } from "@/features/preferences";
import { getTags } from "./api";
import type { Tag, TagLabel } from "./types";

const NO_TAGS: TagLabel[] = [];

// Without counts, archiving or trashing a note doesn't redraw every card.
const toLabels = (tags: Tag[]): TagLabel[] =>
  tags.map(({ id, name, color, position }) => ({ id, name, color, position }));

export function useTags() {
  return useQuery({ queryKey: ["tags"], queryFn: getTags });
}

const hasPlacedTags = (tags: Tag[]) => tags.some((tag) => tag.position);

/** The tag order to show. Unset, a custom order made on any device wins. */
export function useTagOrder(): TagOrder {
  const chosen = usePreferencesStore((s) => s.tags.order);
  const { data: isPlaced = false } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
    select: hasPlacedTags,
  });
  return chosen ?? (isPlaced ? "custom" : "name");
}

export function useTagMap(): Map<string, TagLabel> {
  const { data: tags = NO_TAGS } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
    select: toLabels,
  });
  return useMemo(() => new Map(tags.map((t) => [t.id, t])), [tags]);
}
