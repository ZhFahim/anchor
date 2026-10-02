/** The avatar colors from the tokens (color.avatar.*), in a fixed order. */
export const AVATAR_COLORS = [
  "rust",
  "blue",
  "purple",
  "teal",
  "olive",
  "brown",
  "rose",
  "navy",
  "amber",
  "indigo",
  "moss",
] as const;
export type AvatarColor = (typeof AVATAR_COLORS)[number];

export function avatarColor(id: string): AvatarColor {
  let hash = 0;
  for (let i = 0; i < id.length; i++) hash = (hash * 31 + id.charCodeAt(i)) | 0;
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

/** One or two letters for a name: “Alex Kim” → “AK”, “maya” → “M”. */
export function initials(name: string | null | undefined): string {
  const words = (name ?? "").trim().split(/\s+/).filter(Boolean);
  if (!words.length) return "?";
  const letters =
    words.length > 1 ? words[0][0] + words[words.length - 1][0] : words[0][0];
  return letters.toUpperCase();
}
