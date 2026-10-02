import { DURATION, EASE } from "@/lib/design/tokens";

export function prefersReducedMotion(): boolean {
  return (
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  );
}

export function glidePill(
  container: HTMLElement,
  fromItem: HTMLElement,
  to: HTMLElement,
  pillClass: string,
) {
  snap(fromItem);
  let from = fromItem.getBoundingClientRect();
  const moving = container.querySelector(":scope > [data-glide-pill]");
  if (moving) {
    from = moving.getBoundingClientRect();
    moving.remove();
  }
  for (const target of container.querySelectorAll(".pill-to"))
    if (target !== to) target.classList.remove("pill-to");
  if (prefersReducedMotion()) return settle(to);
  const box = container.getBoundingClientRect();
  const end = to.getBoundingClientRect();
  if (
    !end.width ||
    (Math.abs(from.top - end.top) < 1 && Math.abs(from.left - end.left) < 1)
  )
    return settle(to);
  to.classList.add("pill-to");
  const pill = document.createElement("div");
  pill.dataset.glidePill = "";
  pill.className = pillClass;
  Object.assign(pill.style, {
    position: "absolute",
    left: "0",
    top: "0",
    zIndex: "-1",
    pointerEvents: "none",
    width: `${end.width}px`,
    height: `${end.height}px`,
    transform: `translate(${end.left - box.left + container.scrollLeft}px, ${end.top - box.top + container.scrollTop}px)`,
  });
  container.prepend(pill);
  const translateTo = (rect: DOMRect) =>
    `translate(${rect.left - box.left + container.scrollLeft}px, ${rect.top - box.top + container.scrollTop}px)`;
  const animation = pill.animate(
    [
      {
        transform: translateTo(from),
        width: `${from.width}px`,
        height: `${from.height}px`,
      },
      {
        transform: translateTo(end),
        width: `${end.width}px`,
        height: `${end.height}px`,
      },
    ],
    { duration: DURATION.move, easing: EASE.standard },
  );
  const done = () => {
    if (!pill.isConnected) return;
    pill.remove();
    settle(to);
  };
  animation.onfinish = done;
  animation.oncancel = done;
}

function settle(item: Element) {
  if (!item.classList.contains("pill-to")) return;
  item.classList.remove("pill-to");
  snap(item);
}

function snap(item: Element) {
  item.classList.add("pill-snap");
  requestAnimationFrame(() =>
    requestAnimationFrame(() => item.classList.remove("pill-snap")),
  );
}

const REVEAL_EDGE = 40;

/** For a monospace field: call once `field` shows its new text; `oldText` is what it showed before. */
export function revealText(field: HTMLInputElement, oldText: string) {
  if (prefersReducedMotion()) return;
  let same = 0;
  while (same < oldText.length && oldText[same] === field.value[same]) same++;
  const mask = {
    maskImage: `linear-gradient(90deg, #000 calc(100% - ${REVEAL_EDGE}px), transparent)`,
    maskRepeat: "no-repeat",
  };
  field.animate(
    [
      { ...mask, maskSize: `calc(${same}ch + ${REVEAL_EDGE}px) 100%` },
      { ...mask, maskSize: `calc(100% + ${REVEAL_EDGE}px) 100%` },
    ],
    { duration: DURATION.morph, easing: EASE.inOut },
  );
}

export function popIconIn(icon: Element | null | undefined) {
  if (!icon || prefersReducedMotion()) return;
  icon.animate(
    [
      { opacity: 0, transform: "scale(.6)" },
      { opacity: 1, transform: "none" },
    ],
    { duration: DURATION.move, easing: EASE.pop },
  );
}
