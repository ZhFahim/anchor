import Delta from "quill-delta";
import { describe, expect, it } from "vitest";
import { fakeQuill } from "../../fixtures/fake-quill";
import type { QuillOp } from "../../quill";
import { parseStoredContent, stringifyDelta } from "../../quill";
import { buildDeleteCheckedDelta } from "../../quill-checklist";
import { UndoableEdit } from "./undoable-edit";

const base: QuillOp[] = [
  { insert: "milk" },
  { insert: "\n", attributes: { list: "unchecked" } },
  { insert: "eggs" },
  { insert: "\n", attributes: { list: "checked" } },
  { insert: "bread" },
  { insert: "\n", attributes: { list: "checked" } },
];

function deleteChecked() {
  const before = new Delta(base as never);
  const change = new Delta(
    buildDeleteCheckedDelta({ ops: base })?.ops as never,
  );
  const fake = fakeQuill(before.compose(change).ops as QuillOp[], 0);
  fake.quill.history.stack.undo.push({});
  const edit = new UndoableEdit(fake.quill, 2, change, before, 1);
  return { fake, edit };
}

describe("UndoableEdit", () => {
  it("uses the editor's own Undo when nothing changed since", () => {
    const { fake, edit } = deleteChecked();
    expect(edit.undo()).toBe(true);
    expect(fake.undoCount()).toBe(1);
    expect(edit.undo()).toBe(false);
  });

  it("puts deleted items back after what was typed at the end of the line above", () => {
    const { fake, edit } = deleteChecked();
    const typed = { ops: [{ retain: 4 }, { insert: "x" }] };
    fake.quill.updateContents(typed);
    edit.follow(typed);
    expect(edit.undo()).toBe(true);
    expect(fake.ops()).toEqual([
      { insert: "milkx" },
      { insert: "\n", attributes: { list: "unchecked" } },
      { insert: "eggs" },
      { insert: "\n", attributes: { list: "checked" } },
      { insert: "bread" },
      { insert: "\n", attributes: { list: "checked" } },
    ]);
  });

  it("stops once the text's own Undo took the edit back", () => {
    const { fake, edit } = deleteChecked();
    fake.quill.history.stack.undo.pop();
    edit.follow({ ops: [{ delete: 1 }] });
    expect(edit.isLive).toBe(false);
    expect(edit.undo()).toBe(false);
  });

  it("undoes in the saved text once the note is closed", () => {
    const { fake, edit } = deleteChecked();
    const closed = { ops: fake.ops() as QuillOp[] };
    edit.close(closed);
    expect(edit.undo()).toBe(false);
    expect(
      edit.undoInContent(stringifyDelta({ ops: [{ insert: "new\n" }] })),
    ).toBeNull();
    const undone = edit.undoInContent(stringifyDelta(closed));
    expect(parseStoredContent(undone).ops).toEqual(base);
    expect(edit.undoInContent(stringifyDelta(closed))).toBeNull();
  });
});
