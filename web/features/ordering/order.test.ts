import { describe, expect, it } from "vitest";
import {
  compareByPosition,
  moveNextToNeighbours,
  type Placeable,
  planPositions,
  stepInOrder,
  withPositions,
} from "./order";

const item = (id: string, position: string | null = null): Placeable => ({
  id,
  position,
});
const ids = (list: readonly Placeable[]) => list.map((i) => i.id);
const byId = (a: Placeable, b: Placeable) => a.id.localeCompare(b.id);

/** Applies a plan and returns the ids in key order, as the board shows them. */
function sorted(list: Placeable[], movedId: string, placeAll = false) {
  const changes = planPositions(list, movedId, { placeAll });
  return {
    changes,
    order: ids(
      withPositions(list, changes).sort(compareByPosition("first", byId)),
    ),
  };
}

describe("compareByPosition", () => {
  it("puts unplaced items first or last, in fallback order", () => {
    const list = [item("c", "a1"), item("b"), item("a", "a0"), item("d")];
    expect(ids([...list].sort(compareByPosition("first", byId)))).toEqual([
      "b",
      "d",
      "a",
      "c",
    ]);
    expect(ids([...list].sort(compareByPosition("last", byId)))).toEqual([
      "a",
      "c",
      "b",
      "d",
    ]);
  });

  it("compares keys by code unit and breaks ties by id", () => {
    const list = [item("y", "a"), item("x", "Z"), item("w", "a")];
    expect(ids([...list].sort(compareByPosition("first", byId)))).toEqual([
      "x",
      "w",
      "y",
    ]);
  });
});

describe("planPositions", () => {
  it("gives the moved item one key between its neighbours", () => {
    const list = [item("a", "a0"), item("c", "a2"), item("b", "a1")];
    const { changes, order } = sorted(list, "c");
    expect(changes).toHaveLength(1);
    expect(changes[0]).toMatchObject({ id: "c", previous: "a2" });
    expect(order).toEqual(["a", "c", "b"]);
  });

  it("places the unplaced head too, keeping everyone else", () => {
    const list = [
      item("new"),
      item("a", "a0"),
      item("c", "a2"),
      item("b", "a1"),
    ];
    const { changes, order } = sorted(list, "c");
    expect(changes.map((c) => c.id).sort()).toEqual(["c", "new"]);
    expect(order).toEqual(["new", "a", "c", "b"]);
  });

  it("places everything when nothing has a key yet", () => {
    const list = [item("b"), item("a"), item("c")];
    const { changes, order } = sorted(list, "a");
    expect(changes).toHaveLength(3);
    expect(order).toEqual(["b", "a", "c"]);
  });

  it("starts over when kept keys tie or run backwards", () => {
    const tie = [item("a", "a0"), item("b", "a0"), item("m", "a5")];
    expect(sorted(tie, "m").order).toEqual(["a", "b", "m"]);
    const backwards = [item("a", "a5"), item("m"), item("b", "a1")];
    expect(sorted(backwards, "m").order).toEqual(["a", "m", "b"]);
  });

  it("starts over from a malformed key", () => {
    const list = [item("a", "a0"), item("m"), item("b", "!!")];
    expect(sorted(list, "m").order).toEqual(["a", "m", "b"]);
  });

  it("places all items from the order on screen when asked", () => {
    const list = [item("a", "a9"), item("b", "a1"), item("c", "a5")];
    const { changes, order } = sorted(list, "b", true);
    expect(order).toEqual(["a", "b", "c"]);
    expect(changes.find((c) => c.id === "a")?.previous).toBe("a9");
  });

  it("moves to either end", () => {
    const list = [item("a", "a0"), item("b", "a1"), item("c", "a2")];
    expect(sorted([list[2], list[0], list[1]], "c").order).toEqual([
      "c",
      "a",
      "b",
    ]);
    expect(sorted([list[1], list[2], list[0]], "a").order).toEqual([
      "b",
      "c",
      "a",
    ]);
  });
});

describe("moveNextToNeighbours", () => {
  const all = ["a", "b", "c", "d", "e"].map((id) => item(id));

  it("goes right after the item before it in the view", () => {
    expect(ids(moveNextToNeighbours(all, "e", ["b", "e", "d"]))).toEqual([
      "a",
      "b",
      "e",
      "c",
      "d",
    ]);
  });

  it("goes right before the next item when it leads the view", () => {
    expect(ids(moveNextToNeighbours(all, "e", ["e", "c"]))).toEqual([
      "a",
      "b",
      "e",
      "c",
      "d",
    ]);
  });

  it("stays put when alone in the view", () => {
    expect(ids(moveNextToNeighbours(all, "c", ["c"]))).toEqual(ids(all));
  });
});

describe("stepInOrder", () => {
  it("moves one place and stops at the ends", () => {
    expect(stepInOrder(["a", "b", "c"], "b", -1)).toEqual(["b", "a", "c"]);
    expect(stepInOrder(["a", "b", "c"], "c", 1)).toBeNull();
    expect(stepInOrder(["a", "b", "c"], "a", -1)).toBeNull();
  });
});
