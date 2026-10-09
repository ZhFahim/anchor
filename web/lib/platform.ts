export const isMac = () =>
  typeof navigator !== "undefined" && /mac/i.test(navigator.userAgent);

export const hasShortcutKey = (e: { metaKey: boolean; ctrlKey: boolean }) =>
  isMac() ? e.metaKey : e.ctrlKey;
