import type { NoteBackgroundData } from "./types";

export const SOLID_COLORS: NoteBackgroundData[] = [
  { id: "color_red", isPattern: false, lightColor: "#FFEBEE", darkColor: "#331D21" },
  { id: "color_orange", isPattern: false, lightColor: "#FFE8D6", darkColor: "#3D2A1A" },
  { id: "color_yellow", isPattern: false, lightColor: "#FFF9DC", darkColor: "#3A3A1A" },
  { id: "color_green", isPattern: false, lightColor: "#E8F5E9", darkColor: "#1B3022" },
  { id: "color_teal", isPattern: false, lightColor: "#E0F7FA", darkColor: "#193135" },
  { id: "color_blue", isPattern: false, lightColor: "#E3F2FD", darkColor: "#192A3A" },
  { id: "color_dark_blue", isPattern: false, lightColor: "#E8EAF6", darkColor: "#1A1F3A" },
  { id: "color_purple", isPattern: false, lightColor: "#F3E5F5", darkColor: "#2D1D31" },
  { id: "color_pink", isPattern: false, lightColor: "#FCE4EC", darkColor: "#331D21" },
  { id: "color_brown", isPattern: false, lightColor: "#EFEBE9", darkColor: "#2E1F1A" },
];

export const PATTERNS: NoteBackgroundData[] = [
  { id: "pattern_dots", isPattern: true, lightColor: "#F5F5F5", darkColor: "#1E1E1E" },
  { id: "pattern_grid", isPattern: true, lightColor: "#FFF9DC", darkColor: "#3A3A1A" },
  { id: "pattern_lines", isPattern: true, lightColor: "#E3F2FD", darkColor: "#192A3A" },
  { id: "pattern_waves", isPattern: true, lightColor: "#E8F5E9", darkColor: "#1B3022" },
  { id: "pattern_groceries", isPattern: true, lightColor: "#FFEBEE", darkColor: "#331D21" },
  { id: "pattern_music", isPattern: true, lightColor: "#F3E5F5", darkColor: "#2D1D31" },
  { id: "pattern_travel", isPattern: true, lightColor: "#E0F7FA", darkColor: "#193135" },
  { id: "pattern_code", isPattern: true, lightColor: "#ECEFF1", darkColor: "#1E2325" },
];

export const NOTE_BACKGROUND_STYLES: NoteBackgroundData[] = [
  ...SOLID_COLORS,
  ...PATTERNS,
];
