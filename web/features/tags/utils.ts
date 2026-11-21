import type * as React from "react";
import type { Messages } from "@/i18n/messages";
import type { Translate } from "@/i18n/translate";
import { TAG_COLORS } from "@/lib/design/tokens";

type TagColor = (typeof TAG_COLORS)[number];

const COLOR_NAME_KEYS = {
  red: "colorRed",
  pink: "colorPink",
  purple: "colorPurple",
  deepPurple: "colorDeepPurple",
  indigo: "colorIndigo",
  blue: "colorBlue",
  lightBlue: "colorLightBlue",
  cyan: "colorCyan",
  teal: "colorTeal",
  green: "colorGreen",
  lightGreen: "colorLightGreen",
  lime: "colorLime",
  amber: "colorAmber",
  orange: "colorOrange",
  deepOrange: "colorDeepOrange",
  brown: "colorBrown",
  blueGrey: "colorBlueGrey",
} as const satisfies Record<TagColor["name"], keyof Messages>;

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
export function tagColorName(
  stored: string | null | undefined,
  t: Translate,
): string {
  const color = findTagColor(stored);
  if (!color) return stored ?? t("colorNone");
  return t(COLOR_NAME_KEYS[color.name]);
}

const tagNameOrder = new Intl.Collator("en");

export const compareTagNames = (a: string, b: string): number =>
  tagNameOrder.compare(a, b);

export function sortTagsByName<T extends { name: string }>(
  tags: readonly T[],
): T[] {
  return [...tags].sort((a, b) => compareTagNames(a.name, b.name));
}

export function nextTagColor(tagCount: number): string {
  return TAG_COLORS[tagCount % TAG_COLORS.length].stored;
}
