import { NOTE_BACKGROUND_STYLES } from "./data";
import type { NoteBackgroundData } from "./types";

export function getBackgroundStyle(
  styleId: string | null | undefined,
): NoteBackgroundData | null {
  if (!styleId) return null;
  return NOTE_BACKGROUND_STYLES.find((s) => s.id === styleId) ?? null;
}

export function getBackgroundColor(
  styleId: string | null | undefined,
  isDark: boolean,
): string | null {
  const style = getBackgroundStyle(styleId);
  if (!style) return null;
  return isDark ? style.darkColor : style.lightColor;
}
