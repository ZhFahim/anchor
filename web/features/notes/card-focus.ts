// Keeps a keyboard user's place: the card of a closed note takes focus again
// when its list comes back, and arrows or h j k l move between cards.

let left: { id: string; at: number } | null = null;
let openedByKey: string | null = null;

const isFresh = (at: number) => performance.now() - at < 3000;
const nothingFocused = () =>
  !document.activeElement || document.activeElement === document.body;

export function noteLeft(id: string) {
  left = { id, at: performance.now() };
}

export function noteOpenedByKey(id: string) {
  openedByKey = id;
}

/** For a note opened from its card with Enter; forget it once used. */
export function wasOpenedByKey(id: string) {
  return openedByKey === id;
}

export function forgetOpenedByKey() {
  openedByKey = null;
}

const cardLinks = () =>
  [...document.querySelectorAll<HTMLElement>("main .nc-link")].filter(
    (el) => el.getClientRects().length > 0,
  );

function focusCard(link: HTMLElement) {
  link.focus({ preventScroll: true });
  link.scrollIntoView({ block: "nearest" });
}

/** Back from a note: focus its card, if nothing else took focus first. */
export function refocusLeftCard() {
  if (!left) return;
  if (!isFresh(left.at)) {
    left = null;
    return;
  }
  const link = document.querySelector<HTMLElement>(
    `main [data-flip="${CSS.escape(left.id)}"] .nc-link`,
  );
  if (!link) return;
  left = null;
  if (nothingFocused()) focusCard(link);
}

export function focusEdgeCard(edge: "first" | "last") {
  const links = cardLinks();
  const link = edge === "first" ? links[0] : links.at(-1);
  if (!link) return false;
  focusCard(link);
  return true;
}

type Direction = "up" | "down" | "left" | "right";

export const CARD_KEYS: Record<string, Direction> = {
  ArrowUp: "up",
  ArrowDown: "down",
  ArrowLeft: "left",
  ArrowRight: "right",
  k: "up",
  j: "down",
  h: "left",
  l: "right",
};

/**
 * Moves to the nearest card that way. Cards stand in masonry columns, so
 * "down" keeps to the column: sideways distance counts double.
 */
export function moveCardFocus(from: HTMLElement, direction: Direction) {
  const a = from.getBoundingClientRect();
  const ax = a.left + a.width / 2;
  const ay = a.top + a.height / 2;
  let best: HTMLElement | null = null;
  let bestScore = Number.POSITIVE_INFINITY;
  for (const link of cardLinks()) {
    if (link === from) continue;
    const b = link.getBoundingClientRect();
    const bx = b.left + b.width / 2;
    const by = b.top + b.height / 2;
    const ahead = {
      up: a.top - b.bottom,
      down: b.top - a.bottom,
      left: a.left - b.right,
      right: b.left - a.right,
    }[direction];
    const isAhead = {
      up: by < ay,
      down: by > ay,
      left: bx < ax,
      right: bx > ax,
    }[direction];
    if (!isAhead) continue;
    const across =
      direction === "up" || direction === "down"
        ? Math.abs(bx - ax)
        : Math.abs(by - ay);
    const score = Math.max(ahead, 0) + across * 2;
    if (score < bestScore) {
      bestScore = score;
      best = link;
    }
  }
  if (best) focusCard(best);
}
