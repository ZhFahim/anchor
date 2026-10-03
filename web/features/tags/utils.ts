import type * as React from "react";
import { TAG_COLORS } from "@/lib/design/tokens";

type TagColor = (typeof TAG_COLORS)[number];

function findTagColor(stored: string | null | undefined): TagColor | undefined {
  if (!stored) return undefined;
  const hex = stored.toUpperCase();
  return TAG_COLORS.find((c) => c.stored === hex);
}

/** Variables for the .tag-color class. */
export function tagColorStyle(
  stored: string | null | undefined,
): React.CSSProperties {
  const color = findTagColor(stored);
  return {
    "--hash-l": color?.hash.light ?? "var(--note-muted)",
    "--hash-d": color?.hash.dark ?? "var(--note-muted)",
    "--tint-l": color?.tintFill.light ?? "var(--card)",
    "--tint-d": color?.tintFill.dark ?? "var(--card)",
  } as React.CSSProperties;
}

/** A color's name for people: “Deep purple”. */
export function tagColorName(stored: string | null | undefined): string {
  const color = findTagColor(stored);
  if (!color) return stored ?? "No color";
  const words = color.name.replace(/([A-Z])/g, " $1").toLowerCase();
  return words[0].toUpperCase() + words.slice(1);
}

export function nextTagColor(tagCount: number): string {
  return TAG_COLORS[tagCount % TAG_COLORS.length].stored;
}
