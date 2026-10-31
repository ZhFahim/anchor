type TaskInput = Pick<
  HTMLInputElement,
  "value" | "selectionStart" | "focus" | "setSelectionRange"
>;

/** Move between the inputs in display order without editing or reordering tasks. */
export function navigateChecklist(
  event: Pick<
    KeyboardEvent,
    | "key"
    | "altKey"
    | "ctrlKey"
    | "metaKey"
    | "shiftKey"
    | "isComposing"
    | "preventDefault"
  >,
  inputs: readonly TaskInput[],
  current: TaskInput,
) {
  if (
    event.isComposing ||
    event.altKey ||
    event.ctrlKey ||
    event.metaKey ||
    event.shiftKey ||
    (event.key !== "ArrowUp" && event.key !== "ArrowDown")
  )
    return;
  const index = inputs.indexOf(current);
  if (index < 0) return;
  event.preventDefault();
  const target = inputs[index + (event.key === "ArrowUp" ? -1 : 1)];
  if (!target) return;
  const column = Math.min(current.selectionStart ?? 0, target.value.length);
  target.focus();
  target.setSelectionRange(column, column);
}
