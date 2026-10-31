import { describe, expect, it } from "vitest";
import { readChecklist, writeChecklist } from "../../checklist";
import { ChecklistHistory } from "./checklist-history";

describe("ChecklistHistory", () => {
  it("undoes and redoes mixed task edits in order", () => {
    const history = new ChecklistHistory<string>();
    const tasks = readChecklist(
      writeChecklist([{ text: "Milk", done: false }]),
    );
    const versions = [writeChecklist(tasks)];
    tasks[0] = { ...tasks[0], text: "Coffee" }; // typing
    versions.push(writeChecklist(tasks));
    tasks.push({ text: "Bread", done: false }); // Enter / add
    versions.push(writeChecklist(tasks));
    tasks.push({ text: "Apples", done: false }, { text: "Pears", done: false }); // paste
    versions.push(writeChecklist(tasks));
    tasks[0] = { ...tasks[0], done: true }; // completion
    versions.push(writeChecklist(tasks));
    [tasks[1], tasks[2]] = [tasks[2], tasks[1]]; // reorder
    versions.push(writeChecklist(tasks));
    tasks.splice(1, 1); // deletion
    versions.push(writeChecklist(tasks));
    for (let i = 1; i < versions.length; i++)
      history.record(versions[i - 1], versions[i]);
    expect(history.depth).toEqual({ undo: 6, redo: 0 });
    for (const expected of versions.slice(0, -1).reverse())
      expect(history.undo()).toBe(expected);
    expect(history.undo()).toBeUndefined();
    for (const expected of versions.slice(1))
      expect(history.redo()).toBe(expected);
    expect(history.redo()).toBeUndefined();
  });

  it("restores task identity, selection, completed visibility and rich content", () => {
    const before = {
      tasks: [
        {
          id: "milk",
          ...readChecklist(
            '{"ops":[{"insert":"Milk","attributes":{"bold":true}},{"insert":"\\n","attributes":{"list":"checked"}}]}',
          )[0],
        },
      ],
      focus: { id: "milk", start: 1, end: 3 },
      completedOpen: true,
    };
    const after = { ...before, tasks: [], focus: null };
    const history = new ChecklistHistory<typeof before | typeof after>();
    history.record(before, after);
    expect(history.undo()).toEqual(before);
    expect(writeChecklist(before.tasks)).toContain('"bold":true');
    expect(history.redo()).toEqual(after);
  });

  it("discards redo when a new edit branches from an undo", () => {
    const history = new ChecklistHistory<string>();
    history.record("a", "b");
    history.record("b", "c");
    expect(history.undo()).toBe("b");
    history.record("b", "d");
    expect(history.redo()).toBeUndefined();
    expect(history.undo()).toBe("b");
    expect(history.undo()).toBe("a");
  });

  it("clears both timelines when remote content replaces the note", () => {
    const history = new ChecklistHistory<string>();
    history.record("a", "b");
    history.record("b", "c");
    history.undo();
    history.clear();
    expect(history.depth).toEqual({ undo: 0, redo: 0 });
    expect(history.undo()).toBeUndefined();
    expect(history.redo()).toBeUndefined();
    history.record("remote", "local");
    expect(history.undo()).toBe("remote");
  });

  it("bounds history without losing redo of retained changes", () => {
    const history = new ChecklistHistory<number>();
    for (let i = 0; i < 150; i++) history.record(i, i + 1);
    expect(history.depth.undo).toBe(100);
    for (let i = 149; i >= 50; i--) expect(history.undo()).toBe(i);
    expect(history.undo()).toBeUndefined();
    for (let i = 51; i <= 150; i++) expect(history.redo()).toBe(i);
  });
});
