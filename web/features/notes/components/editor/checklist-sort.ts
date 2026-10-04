import Delta from "quill-delta";
import type { QuillDelta, QuillOp } from "../../quill";
import { createChecklistSortDelta } from "../../quill-checklist";
import { deltaToLines, getLineStartPosition } from "../../quill-lines";

const LINE_TAG = "sortedLine";

/** The document with each newline carrying its line number. */
function tagLines(ops: QuillOp[]): Delta {
  const tagged = new Delta();
  deltaToLines(ops).forEach((line, index) => {
    for (const op of line.contentOps) tagged.push(op as never);
    tagged.push({
      insert: "\n",
      attributes: { ...line.newlineOp.attributes, [LINE_TAG]: index },
    } as never);
  });
  return tagged;
}

export type ChecklistSortPlan = {
  delta: QuillDelta;
  /** For each line after the sort, the line it was before. */
  origins: number[];
};

/**
 * Sorts each toggled line's checklist, in the order the lines were ticked. Null
 * when nothing moves.
 */
export function planChecklistSort(
  contents: QuillDelta,
  toggledLines: number[],
): ChecklistSortPlan | null {
  let document = new Delta(contents.ops as never);
  // The same sort on numbered lines tells where every line went.
  let tagged = tagLines(contents.ops);
  let total = new Delta();
  let origins = deltaToLines(contents.ops).map((_, index) => index);
  for (const line of toggledLines) {
    const at = origins.indexOf(line);
    if (at < 0) continue;
    const position = getLineStartPosition(
      deltaToLines(document.ops as QuillOp[]),
      at,
    );
    const step = createChecklistSortDelta(position, {
      ops: document.ops as QuillOp[],
    });
    const taggedStep = createChecklistSortDelta(position, {
      ops: tagged.ops as QuillOp[],
    });
    if (!step || !taggedStep) continue;
    document = document.compose(new Delta(step.ops as never));
    tagged = tagged.compose(new Delta(taggedStep.ops as never));
    total = total.compose(new Delta(step.ops as never));
    origins = deltaToLines(tagged.ops as QuillOp[]).map(
      (sorted) => sorted.newlineOp.attributes?.[LINE_TAG] as number,
    );
  }
  if (!total.ops.length) return null;
  return { delta: { ops: total.ops as QuillOp[] }, origins };
}
