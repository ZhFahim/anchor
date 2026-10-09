/** Presses and keys inside `except` don't count. */
export function onUserScroll(
  scroller: HTMLElement,
  task: () => void,
  except?: string,
) {
  const unlessExcepted = (event: Event) => {
    if (!except || !(event.target as Element).closest?.(except)) task();
  };
  scroller.addEventListener("wheel", task, { passive: true });
  scroller.addEventListener("touchstart", unlessExcepted, { passive: true });
  scroller.addEventListener("pointerdown", unlessExcepted);
  window.addEventListener("keydown", unlessExcepted);
  return () => {
    scroller.removeEventListener("wheel", task);
    scroller.removeEventListener("touchstart", unlessExcepted);
    scroller.removeEventListener("pointerdown", unlessExcepted);
    window.removeEventListener("keydown", unlessExcepted);
  };
}
