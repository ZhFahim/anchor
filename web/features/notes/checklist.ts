import { parseStoredContent, type QuillOp } from "./quill";
import { type DeltaLine, deltaToLines, getLineText } from "./quill-lines";

export interface ChecklistTask {
  text: string;
  done: boolean;
  // Keep untouched rich text from other clients intact.
  line?: DeltaLine;
}

export function readChecklist(content: string): ChecklistTask[] {
  const delta = parseStoredContent(content);
  return deltaToLines(delta.ops).map((line) => ({
    text: getLineText(line),
    done: line.newlineOp.attributes?.list === "checked",
    line,
  }));
}

export function writeChecklist(tasks: ChecklistTask[]): string {
  const ops: QuillOp[] = tasks.flatMap((task) => [
    ...(task.line && getLineText(task.line) === task.text
      ? task.line.contentOps
      : task.text
        ? [{ insert: task.text }]
        : []),
    {
      insert: "\n",
      attributes: {
        ...task.line?.newlineOp.attributes,
        list: task.done ? "checked" : "unchecked",
      },
    },
  ]);
  return JSON.stringify({ ops: ops.length ? ops : [{ insert: "\n" }] });
}

export function moveTask<T>(tasks: T[], from: number, to: number): T[] {
  if (from < 0 || to < 0 || from >= tasks.length || to >= tasks.length)
    return tasks;
  const next = [...tasks];
  const [task] = next.splice(from, 1);
  next.splice(to, 0, task);
  return next;
}
