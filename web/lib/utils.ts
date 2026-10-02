import { type ClassValue, clsx } from "clsx";
import { extendTailwindMerge } from "tailwind-merge";
import { TAILWIND_THEME } from "@/lib/design/tokens";

// tailwind-merge must know the theme's names, or text-meta is taken for a color.
const twMerge = extendTailwindMerge({
  extend: {
    theme: {
      text: TAILWIND_THEME.text,
      spacing: TAILWIND_THEME.spacing,
      radius: TAILWIND_THEME.radius,
      shadow: TAILWIND_THEME.shadow,
      ease: TAILWIND_THEME.ease,
      "font-weight": TAILWIND_THEME["font-weight"],
    },
  },
});

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export const plural = (count: number, one: string, many = `${one}s`) =>
  `${count} ${count === 1 ? one : many}`;

export const firstName = (name: string) => name.split(" ")[0];
