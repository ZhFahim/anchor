import { generateNKeysBetween } from "fractional-indexing";

/** Anything that can sit in someone's own order. */
export interface Placeable {
  id: string;
  /** A fractional index; null or absent until it is placed. */
  position?: string | null;
}

export interface PositionChange {
  id: string;
  position: string | null;
  /** The key before the change, so it can be undone. */
  previous: string | null;
}

/** Keys compare by code unit, never by locale. */
const compareKeys = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0);

/**
 * Custom order: placed items by key; unplaced ones before them (new notes
 * show at the top) or after them (new tags join the end), in `fallback` order.
 */
export function compareByPosition<T extends Placeable>(
  unplaced: "first" | "last",
  fallback: (a: T, b: T) => number,
) {
  return (a: T, b: T): number => {
    const keyA = a.position ?? null;
    const keyB = b.position ?? null;
    if (keyA === null || keyB === null) {
      if (keyA === keyB) return fallback(a, b);
      const aFirst = (keyA === null) === (unplaced === "first");
      return aFirst ? -1 : 1;
    }
    return compareKeys(keyA, keyB) || compareKeys(a.id, b.id);
  };
}

/**
 * New keys for `ordered`, the full list in the order it should now have.
 *
 * Only the moved item and the unplaced ones get keys; everything already in
 * place keeps its key. When the kept keys don't run strictly upward (another
 * sort was showing, or two devices made the same key) every item is placed
 * again from the order on screen.
 */
export function planPositions(
  ordered: readonly Placeable[],
  movedId: string,
  { placeAll = false }: { placeAll?: boolean } = {},
): PositionChange[] {
  if (!placeAll) {
    try {
      return placeGaps(ordered, movedId);
    } catch {
      // Fall through to placing everything again.
    }
  }
  const keys = generateNKeysBetween(null, null, ordered.length);
  return changesFor(ordered, keys);
}

function placeGaps(ordered: readonly Placeable[], movedId: string) {
  const keys: (string | null)[] = ordered.map((item) =>
    item.id === movedId ? null : (item.position ?? null),
  );
  let last: string | null = null;
  for (const key of keys) {
    if (key === null) continue;
    if (last !== null && compareKeys(last, key) >= 0)
      throw new Error("Keys out of order");
    last = key;
  }
  let start = 0;
  while (start < keys.length) {
    if (keys[start] !== null) {
      start += 1;
      continue;
    }
    let end = start;
    while (end < keys.length && keys[end] === null) end += 1;
    const fresh = generateNKeysBetween(
      start > 0 ? keys[start - 1] : null,
      end < keys.length ? keys[end] : null,
      end - start,
    );
    fresh.forEach((key, i) => {
      keys[start + i] = key;
    });
    start = end;
  }
  return changesFor(ordered, keys as string[]);
}

function changesFor(ordered: readonly Placeable[], keys: string[]) {
  return ordered.flatMap((item, i) =>
    (item.position ?? null) === keys[i]
      ? []
      : [{ id: item.id, position: keys[i], previous: item.position ?? null }],
  );
}

/**
 * Moves `movedId` in `all` next to its neighbours from a filtered view:
 * just after the item before it there, else just before the item after it.
 */
export function moveNextToNeighbours<T extends Placeable>(
  all: readonly T[],
  movedId: string,
  visibleOrder: readonly string[],
): T[] {
  const moved = all.find((item) => item.id === movedId);
  if (!moved) return [...all];
  const rest = all.filter((item) => item.id !== movedId);
  const at = visibleOrder.indexOf(movedId);
  const before = at > 0 ? visibleOrder[at - 1] : undefined;
  const after = at >= 0 ? visibleOrder[at + 1] : undefined;
  let index = -1;
  if (before !== undefined) {
    const i = rest.findIndex((item) => item.id === before);
    if (i >= 0) index = i + 1;
  }
  if (index < 0 && after !== undefined)
    index = rest.findIndex((item) => item.id === after);
  if (index < 0) index = all.findIndex((item) => item.id === movedId);
  return [...rest.slice(0, index), moved, ...rest.slice(index)];
}

/** One step up or down within `visibleOrder`, for keyboard moves. */
export function stepInOrder(
  visibleOrder: readonly string[],
  id: string,
  step: -1 | 1,
): string[] | null {
  const from = visibleOrder.indexOf(id);
  const to = from + step;
  if (from < 0 || to < 0 || to >= visibleOrder.length) return null;
  const next = [...visibleOrder];
  next.splice(from, 1);
  next.splice(to, 0, id);
  return next;
}

/** Applies changes to a cached list without touching anything else. */
export function withPositions<T extends Placeable>(
  list: readonly T[],
  changes: readonly Pick<PositionChange, "id" | "position">[],
): T[] {
  const byId = new Map(changes.map((c) => [c.id, c.position]));
  return list.map((item) =>
    byId.has(item.id) ? { ...item, position: byId.get(item.id) ?? null } : item,
  );
}
