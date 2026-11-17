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

export const themeColorScript = `(() => {
  const html = document.documentElement;
  const meta = document.createElement("meta");
  meta.name = "theme-color";
  document.head.append(meta);
  const sync = () => {
    meta.content = getComputedStyle(html).getPropertyValue("--background").trim();
  };
  sync();
  new MutationObserver(sync).observe(html, { attributeFilter: ["class"] });
})();`;
