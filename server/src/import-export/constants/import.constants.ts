export const IMPORT_MAX_NOTES_PER_BATCH = 50;
export const IMPORT_MAX_CONTENT_LENGTH = 1_000_000; // 1MB of stringified Delta
export const IMPORT_MAX_TITLE_LENGTH = 1000;
export const IMPORT_MAX_TAGS_PER_NOTE = 50;
export const IMPORT_MAX_TAGS_PER_BATCH = 500;
export const IMPORT_MAX_TAG_NAME_LENGTH = 100;

// Mirrors the background IDs defined in web/features/notes/backgrounds/data.ts
export const IMPORT_ALLOWED_BACKGROUNDS = new Set([
  'color_red',
  'color_orange',
  'color_yellow',
  'color_green',
  'color_teal',
  'color_blue',
  'color_dark_blue',
  'color_purple',
  'color_pink',
  'color_brown',
  'pattern_dots',
  'pattern_grid',
  'pattern_lines',
  'pattern_waves',
  'pattern_groceries',
  'pattern_music',
  'pattern_travel',
  'pattern_code',
]);
