"use client";

import { ChevronDown, GripVertical, Plus, Trash2 } from "lucide-react";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import { newId } from "@/lib/id";
import { cn } from "@/lib/utils";
import {
  type ChecklistTask,
  moveTask,
  readChecklist,
  writeChecklist,
} from "../../checklist";
import { ChecklistEdit } from "./checklist-edit";
import type { RichTextEditorHandle } from "./rich-text-editor";

type Task = ChecklistTask & { id: string };
const emptyTask = (): Task => ({ id: newId(), text: "", done: false });
function loadTasks(value: string): Task[] {
  const tasks = readChecklist(value).map((task) => ({ ...task, id: newId() }));
  return tasks.length ? tasks : [emptyTask()];
}

export const ChecklistEditor = React.forwardRef<
  RichTextEditorHandle,
  {
    value: string;
    onChange: (value: string) => void;
    readOnly?: boolean;
  }
>(function ChecklistEditor({ value, onChange, readOnly = false }, ref) {
  const [tasks, setTasks] = React.useState(() => loadTasks(value));
  const [completedOpen, setCompletedOpen] = React.useState(false);
  const lastValue = React.useRef(value);
  const currentTasks = React.useRef(tasks);
  currentTasks.current = tasks;
  const edits = React.useRef(new Set<ChecklistEdit>());
  React.useEffect(
    () => () => {
      for (const edit of edits.current) edit.closeChecklist(lastValue.current);
    },
    [],
  );
  const inputs = React.useRef(new Map<string, HTMLInputElement>());
  const pendingFocus = React.useRef<string | null>(null);
  const addButton = React.useRef<HTMLButtonElement>(null);
  const dragging = React.useRef<string | null>(null);
  const [announcement, setAnnouncement] = React.useState("");

  React.useEffect(() => {
    if (lastValue.current === value) return;
    lastValue.current = value;
    setTasks(loadTasks(value));
  }, [value]);

  React.useLayoutEffect(() => {
    if (!pendingFocus.current) return;
    if (pendingFocus.current === "add-task") addButton.current?.focus();
    else inputs.current.get(pendingFocus.current)?.focus();
    pendingFocus.current = null;
  });

  const commit = (next: Task[], focus?: string) => {
    if (readOnly) return;
    pendingFocus.current = focus ?? null;
    currentTasks.current = next;
    setTasks(next);
    const stored = writeChecklist(next);
    lastValue.current = stored;
    onChange(stored);
  };
  const add = (after?: string) => {
    const task = emptyTask();
    const next = [...tasks];
    next.splice(
      after ? tasks.findIndex((t) => t.id === after) + 1 : tasks.length,
      0,
      task,
    );
    commit(next, task.id);
  };
  const focusFirst = () => {
    const first = tasks.find((task) => !task.done);
    if (first) inputs.current.get(first.id)?.focus();
    else if (!readOnly) add();
  };
  const bulkEdit = (remove: boolean) => {
    const before = currentTasks.current;
    const checked = before.filter((task) => task.done);
    if (readOnly || !checked.length) return null;
    const next = remove
      ? before.filter((task) => !task.done)
      : before.map((task) => ({ ...task, done: false }));
    commit(next);
    const edit = new ChecklistEdit(
      checked.length,
      () => {
        // Do not overwrite subsequent typing or another collaborator's update.
        if (readOnly || lastValue.current !== writeChecklist(next))
          return false;
        commit(before);
        return true;
      },
      writeChecklist(before),
      writeChecklist(next),
    );
    edits.current.add(edit);
    return edit;
  };
  React.useImperativeHandle(ref, () => ({
    setSelection: focusFirst,
    focusEnd: () => {
      if (readOnly) return false;
      const last = tasks.filter((task) => !task.done).at(-1);
      if (last) {
        const input = inputs.current.get(last.id);
        input?.focus();
        input?.setSelectionRange(last.text.length, last.text.length);
      } else add();
      return true;
    },
    startList: focusFirst,
    checklistCount: () => {
      const entries = currentTasks.current.filter((task) => task.text.trim());
      return {
        items: entries.length,
        checked: entries.filter((task) => task.done).length,
      };
    },
    uncheckAll: () => bulkEdit(false),
    deleteChecked: () => bulkEdit(true),
    // Title-to-body rich-text history is not used by the task-input editor.
    addFirstLine: () => false,
    historyDepth: () => ({ undo: 0, redo: 0 }),
    undoOrRedoText: () => {},
  }));

  const active = tasks.filter((task) => !task.done);
  const completed = tasks.filter((task) => task.done);
  const row = (task: Task) => (
    <li
      key={task.id}
      className="group/task flex items-center gap-2 rounded-md py-1 focus-within:bg-foreground/3 hover:bg-foreground/3"
      onDragOver={(e) => {
        if (!readOnly && !task.done) e.preventDefault();
      }}
      onDrop={(e) => {
        e.preventDefault();
        if (readOnly || task.done) return;
        const from = tasks.findIndex((t) => t.id === dragging.current);
        commit(moveTask(tasks, from, tasks.indexOf(task)));
        dragging.current = null;
      }}
    >
      {!readOnly && !task.done && (
        <button
          type="button"
          draggable
          aria-label={`Reorder ${task.text || "task"}. Use Alt and arrow keys to move.`}
          className="cursor-grab rounded p-1 text-muted-foreground opacity-40 hover:opacity-100 focus:opacity-100 active:cursor-grabbing"
          onDragStart={(e) => {
            dragging.current = task.id;
            e.dataTransfer.effectAllowed = "move";
            e.dataTransfer.setData("text/plain", task.id);
          }}
          onDragEnd={() => {
            dragging.current = null;
          }}
          onKeyDown={(e) => {
            if (!e.altKey || !["ArrowUp", "ArrowDown"].includes(e.key)) return;
            e.preventDefault();
            const target =
              active[active.indexOf(task) + (e.key === "ArrowUp" ? -1 : 1)];
            if (target)
              commit(
                moveTask(tasks, tasks.indexOf(task), tasks.indexOf(target)),
              );
          }}
        >
          <GripVertical className="size-4" aria-hidden />
        </button>
      )}
      <input
        type="checkbox"
        checked={task.done}
        disabled={readOnly}
        aria-label={`${task.done ? "Restore" : "Complete"} ${task.text || "task"}`}
        className="size-4 shrink-0 cursor-pointer accent-foreground disabled:cursor-default"
        onChange={() => {
          const next = tasks.map((t) =>
            t.id === task.id ? { ...t, done: !t.done } : t,
          );
          const neighbor =
            active[active.indexOf(task) + 1] ??
            active[active.indexOf(task) - 1];
          commit(next, task.done ? task.id : (neighbor?.id ?? "add-task"));
          setAnnouncement(
            task.done
              ? "Task restored"
              : "Task completed. Available in Completed.",
          );
        }}
      />
      <input
        ref={(input) => {
          if (input) inputs.current.set(task.id, input);
          else inputs.current.delete(task.id);
        }}
        value={task.text}
        readOnly={readOnly}
        aria-label={task.done ? "Completed task" : "Task"}
        placeholder="Add a task"
        className={cn(
          "min-w-0 flex-1 border-0 bg-transparent py-1.5 text-base outline-none placeholder:text-muted-foreground",
          task.done && "text-muted-foreground line-through",
        )}
        onChange={(e) =>
          commit(
            tasks.map((t) =>
              t.id === task.id ? { ...t, text: e.target.value } : t,
            ),
          )
        }
        onKeyDown={(e) => {
          if (readOnly || e.nativeEvent.isComposing) return;
          if (e.key === "Enter") {
            e.preventDefault();
            add(task.id);
          }
          if (e.key === "Backspace" && !task.text && active.length > 1) {
            e.preventDefault();
            const previous =
              active[active.indexOf(task) - 1] ??
              active[active.indexOf(task) + 1];
            commit(
              tasks.filter((t) => t.id !== task.id),
              previous?.id,
            );
          }
        }}
        onPaste={(e) => {
          if (readOnly) return;
          const text = e.clipboardData.getData("text/plain");
          if (!text.includes("\n")) return;
          e.preventDefault();
          const input = e.currentTarget;
          const pasted = (
            task.text.slice(0, input.selectionStart ?? 0) +
            text +
            task.text.slice(input.selectionEnd ?? task.text.length)
          ).split(/\r?\n/);
          const inserted = pasted.map((text, i) => ({
            ...emptyTask(),
            id: i === 0 ? task.id : newId(),
            text,
          }));
          const next = [...tasks];
          next.splice(tasks.indexOf(task), 1, ...inserted);
          commit(next, inserted.at(-1)?.id);
        }}
      />
      {!readOnly && (
        <IconButton
          label={`Delete ${task.text || "task"}`}
          size="sm"
          className="opacity-0 group-hover/task:opacity-100 focus:opacity-100 max-md:opacity-100"
          onClick={() => {
            const next = tasks.filter((t) => t.id !== task.id);
            const remaining = next.length ? next : [emptyTask()];
            commit(remaining, remaining.find((t) => !t.done)?.id ?? "add-task");
          }}
        >
          <Trash2 className="size-3.5" />
        </IconButton>
      )}
    </li>
  );

  return (
    <section className="mt-4" aria-label="Checklist">
      <span role="status" className="sr-only">
        {announcement}
      </span>
      <ul className="m-0 list-none p-0" aria-label="Active tasks">
        {active.map(row)}
      </ul>
      {!active.length && (
        <p className="py-2 text-muted-foreground">All tasks completed</p>
      )}
      {!readOnly && (
        <button
          ref={addButton}
          type="button"
          onClick={() => add()}
          className="mt-2 flex cursor-pointer items-center gap-2 rounded-md px-2 py-2 text-muted-foreground text-ui hover:bg-foreground/5 hover:text-foreground"
        >
          <Plus className="size-4" aria-hidden />
          Add task
        </button>
      )}
      {completed.length > 0 && (
        <div className="mt-6 border-t border-border pt-3">
          <button
            type="button"
            aria-expanded={completedOpen}
            onClick={() => setCompletedOpen(!completedOpen)}
            className="flex cursor-pointer items-center gap-2 rounded-md px-2 py-2 text-muted-foreground text-ui hover:bg-foreground/5"
          >
            <ChevronDown
              aria-hidden
              className={cn(
                "size-4 transition-transform",
                !completedOpen && "-rotate-90",
              )}
            />
            Completed ({completed.length})
          </button>
          {completedOpen && (
            <ul className="m-0 list-none p-0" aria-label="Completed tasks">
              {completed.map(row)}
            </ul>
          )}
        </div>
      )}
    </section>
  );
});
