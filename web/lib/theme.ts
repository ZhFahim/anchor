import { prefersReducedMotion } from "@/lib/motion";

type ViewTransitionDocument = Document & {
  startViewTransition?: (update: () => void) => unknown;
};

/** Sets the class itself: setTheme applies it too late for the transition. */
export function switchTheme(theme: string, setTheme: (theme: string) => void) {
  const apply = () => {
    const dark =
      theme === "dark" ||
      (theme === "system" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);
    const html = document.documentElement;
    html.classList.toggle("dark", dark);
    html.classList.toggle("light", !dark);
    html.style.colorScheme = dark ? "dark" : "light";
    setTheme(theme);
  };
  const doc = document as ViewTransitionDocument;
  if (doc.startViewTransition && !prefersReducedMotion())
    doc.startViewTransition(apply);
  else apply();
}
