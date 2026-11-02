export const isMac = () =>
  typeof navigator !== "undefined" && /mac/i.test(navigator.userAgent);

export const hasShortcutKey = (e: { metaKey: boolean; ctrlKey: boolean }) =>
  isMac() ? e.metaKey : e.ctrlKey;

/**
 * A field's ref that puts the caret in it once it is there, ready to type;
 * not on a touch screen, where that would bring up the keyboard.
 */
export function focusOnArrival(el: HTMLElement | null) {
  if (!el || !window.matchMedia("(pointer: fine)").matches) return;
  if (!document.activeElement || document.activeElement === document.body)
    el.focus();
}
