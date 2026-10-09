import Delta from "quill-delta";
import type { QuillDelta, QuillInstance, QuillOp } from "../quill";

export function fakeQuill(ops: QuillOp[], caret: number) {
  let document = new Delta(ops as never);
  let selection = { index: caret, length: 0 };
  let undoCount = 0;
  const changeHandlers: (() => void)[] = [];
  const quill = {
    getSelection: () => selection,
    setSelection: (index: number) => {
      selection = { index, length: 0 };
    },
    getContents: (index = 0, length = document.length() - index) =>
      document.slice(index, index + length),
    getText: (index: number, length: number) =>
      document
        .map((op) => (typeof op.insert === "string" ? op.insert : ""))
        .join("")
        .slice(index, index + length),
    getLine: (index: number) => {
      let found: [unknown, number] = [null, 0];
      let start = 0;
      document.eachLine((line, attributes) => {
        const length = line.length() + 1;
        if (index < start + length) {
          found = [
            { length: () => length, formats: () => attributes },
            index - start,
          ];
          return false;
        }
        start += length;
      });
      return found;
    },
    updateContents: (delta: QuillDelta) => {
      document = document.compose(new Delta(delta.ops as never));
    },
    formatText: (
      index: number,
      length: number,
      name: string,
      value: unknown,
    ) => {
      document = document.compose(
        new Delta().retain(index).retain(length, { [name]: value }),
      );
    },
    once: (_event: string, handler: () => void) => {
      changeHandlers.push(handler);
    },
    history: {
      cutoff: () => {},
      stack: { undo: [] as unknown[], redo: [] as unknown[] },
      undo: () => {
        undoCount++;
      },
    },
  };
  return {
    quill: quill as unknown as QuillInstance,
    ops: () => document.ops,
    caret: () => selection.index,
    undoCount: () => undoCount,
    emitChange: () => {
      for (const handler of changeHandlers.splice(0)) handler();
    },
  };
}
