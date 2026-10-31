import { describe, expect, it } from "vitest";
import {
  checklistProgress,
  moveActiveTask,
  moveTask,
  readChecklist,
  writeChecklist,
} from "./checklist";

describe("checklist content", () => {
  it("counts real tasks, ignoring blank and whitespace-only entry rows", () => {
    expect(
      checklistProgress(
        writeChecklist([
          { text: "Milk", done: false },
          { text: "Bread", done: true },
          { text: "", done: false },
          { text: "  ", done: true },
        ]),
      ),
    ).toEqual({ total: 2, done: 1, allDone: false, label: "1 of 2 done" });
  });

  it("shows All done only when at least one real task exists", () => {
    expect(
      checklistProgress(
        writeChecklist([
          { text: "Milk", done: true },
          { text: "", done: false },
        ]),
      ),
    ).toMatchObject({ total: 1, done: 1, allDone: true, label: "All done" });
    expect(checklistProgress(null)).toMatchObject({
      total: 0,
      allDone: false,
      label: "No tasks",
    });
    expect(
      checklistProgress(writeChecklist([{ text: "", done: true }])),
    ).toMatchObject({ total: 0, allDone: false, label: "No tasks" });
  });
  it("keeps completed tasks stored and restores them without changing order", () => {
    const tasks = [
      { text: "Milk", done: false },
      { text: "Bread", done: true },
    ];
    const read = readChecklist(writeChecklist(tasks));
    expect(read.map(({ text, done }) => ({ text, done }))).toEqual(tasks);
    expect(read.filter((task) => !task.done).map((task) => task.text)).toEqual([
      "Milk",
    ]);
    read[1].done = false;
    expect(
      readChecklist(writeChecklist(read)).every((task) => !task.done),
    ).toBe(true);
  });

  it("keeps blank task rows and unicode text", () => {
    const tasks = [
      { text: "", done: false },
      { text: "Köp mjölk 🥛", done: false },
    ];
    expect(
      readChecklist(writeChecklist(tasks)).map(({ text, done }) => ({
        text,
        done,
      })),
    ).toEqual(tasks);
  });

  it("preserves formatting from other clients when toggling a task", () => {
    const original = {
      ops: [
        { insert: "Milk", attributes: { bold: true } },
        { insert: "\n", attributes: { list: "unchecked", indent: 1 } },
      ],
    };
    const tasks = readChecklist(JSON.stringify(original));
    tasks[0].done = true;
    expect(JSON.parse(writeChecklist(tasks))).toEqual({
      ops: [
        original.ops[0],
        { insert: "\n", attributes: { list: "checked", indent: 1 } },
      ],
    });
  });

  it("reorders tasks without dropping completed items", () => {
    const tasks = [
      { text: "First", done: false },
      { text: "Done", done: true },
      { text: "Last", done: false },
    ];
    expect(moveTask(tasks, 2, 0).map((task) => task.text)).toEqual([
      "Last",
      "First",
      "Done",
    ]);
    expect(tasks[0].text).toBe("First");
    expect(moveTask(tasks, -1, 1)).toBe(tasks);
  });

  it("handles empty content", () => {
    expect(readChecklist("")[0].text).toBe("");
    expect(readChecklist(writeChecklist([]))[0].text).toBe("");
  });

  it("keyboard reorder skips completed tasks and preserves their storage slots", () => {
    const tasks = [
      { id: "first", text: "First", done: false },
      { id: "done", text: "Done", done: true },
      { id: "last", text: "Last", done: false },
    ];
    const moved = moveActiveTask(tasks, tasks[0], 1);
    expect(moved.map((task) => task.id)).toEqual(["last", "done", "first"]);
    expect(moved[1]).toBe(tasks[1]);
    expect(moveActiveTask(moved, tasks[0], -1)).toEqual(tasks);
    expect(tasks[0].id).toBe("first");
  });

  it("keyboard reorder is a no-op at boundaries and for completed or missing tasks", () => {
    const tasks = [
      { text: "First", done: false },
      { text: "Done", done: true },
      { text: "Last", done: false },
    ];
    expect(moveActiveTask(tasks, tasks[0], -1)).toBe(tasks);
    expect(moveActiveTask(tasks, tasks[2], 1)).toBe(tasks);
    expect(moveActiveTask(tasks, tasks[1], 1)).toBe(tasks);
    expect(moveActiveTask(tasks, { text: "Missing", done: false }, 1)).toBe(
      tasks,
    );
  });
});
