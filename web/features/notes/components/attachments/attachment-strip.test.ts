import { describe, expect, it } from "vitest";
import type { NoteAttachment } from "../../types";
import { moveAttachment, shortFileName } from "./attachment-strip";

const file = (id: string, type: NoteAttachment["type"]): NoteAttachment => ({
  id,
  noteId: "n",
  type,
  originalFilename: `${id}.bin`,
  mimeType: "",
  fileSize: 1,
  position: 0,
  createdAt: "",
});

const ids = (list: NoteAttachment[] | undefined) => list?.map((a) => a.id);

describe("shortFileName", () => {
  it("keeps short names", () => {
    expect(shortFileName("red.png")).toBe("red.png");
  });

  it("cuts long names and keeps the extension", () => {
    const short = shortFileName("a-very-long-name-for-a-picture.png");
    expect(short).toBe("a-very-long-nam….png");
    expect(short.length).toBe(20);
  });

  it("cuts a long name with no extension", () => {
    expect(shortFileName("x".repeat(30))).toBe(`${"x".repeat(19)}…`);
  });
});

describe("moveAttachment", () => {
  const list = [
    file("a", "image"),
    file("v1", "audio"),
    file("b", "image"),
    file("c", "image"),
    file("v2", "audio"),
  ];
  const none = new Set<string>();

  it("moves a picture before a later slot", () => {
    const moved = moveAttachment(list, none, "a", 3);
    expect(ids(moved?.list)).toEqual(["b", "c", "a", "v1", "v2"]);
    expect(moved?.place).toBe(2);
    expect(moved?.size).toBe(3);
  });

  it("moves a voice note to the front of its kind", () => {
    const moved = moveAttachment(list, none, "v2", 0);
    expect(ids(moved?.list)).toEqual(["a", "b", "c", "v2", "v1"]);
  });

  it("does nothing when the file would stay put or the slot is out of range", () => {
    expect(moveAttachment(list, none, "b", 1)).toBeNull();
    expect(moveAttachment(list, none, "b", 2)).toBeNull();
    expect(moveAttachment(list, none, "c", 4)).toBeNull();
    expect(moveAttachment(list, none, "a", -1)).toBeNull();
    expect(moveAttachment(list, none, "gone", 0)).toBeNull();
  });

  it("counts only shown files and keeps hidden ones at the end", () => {
    const moved = moveAttachment(list, new Set(["b"]), "c", 0);
    expect(ids(moved?.list)).toEqual(["c", "a", "v1", "v2", "b"]);
    expect(moved?.size).toBe(2);
  });

  it("builds each move on the order the last one left", () => {
    let order = list;
    for (let step = 0; step < 2; step++) {
      const at = order
        .filter((a) => a.type === "image")
        .findIndex((a) => a.id === "a");
      order = moveAttachment(order, none, "a", at + 2)?.list ?? order;
    }
    expect(ids(order)).toEqual(["b", "c", "a", "v1", "v2"]);
  });
});
