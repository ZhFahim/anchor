/** Sets `<html data-input>` to "pointer" on a pointer press, and to "keyboard" when a key press moves focus. */
export function trackInputModality() {
  const root = document.documentElement;
  let keyPressed = false;
  const mark = (value: string) => {
    if (root.dataset.input !== value) root.dataset.input = value;
  };
  const listen = (type: string, handler: () => void) =>
    document.addEventListener(type, handler, true);
  listen("pointerdown", () => {
    keyPressed = false;
    mark("pointer");
  });
  for (const type of ["pointerover", "pointerout", "pointermove"])
    listen(type, () => {
      keyPressed = false;
    });
  listen("keydown", () => {
    keyPressed = true;
  });
  listen("focusin", () => {
    if (keyPressed) mark("keyboard");
  });
}
