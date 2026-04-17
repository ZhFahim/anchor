/// Curated list of pleasant tag colors (standard hex format for cross-platform)
export const TAG_COLORS = [
  '#E57373', // Red 300
  '#F06292', // Pink 300
  '#BA68C8', // Purple 300
  '#9575CD', // Deep Purple 300
  '#7986CB', // Indigo 300
  '#64B5F6', // Blue 300
  '#4FC3F7', // Light Blue 300
  '#4DD0E1', // Cyan 300
  '#4DB6AC', // Teal 300
  '#81C784', // Green 300
  '#AED581', // Light Green 300
  '#DCE775', // Lime 300
  '#FFD54F', // Amber 300
  '#FFB74D', // Orange 300
  '#FF8A65', // Deep Orange 300
  '#A1887F', // Brown 300
  '#90A4AE', // Blue Grey 300
] as const;

/**
 * Generates a random tag color as a standard hex string (#RRGGBB)
 * Uses the same color palette as the mobile app
 */
export function generateRandomTagColor(): string {
  return TAG_COLORS[Math.floor(Math.random() * TAG_COLORS.length)];
}
