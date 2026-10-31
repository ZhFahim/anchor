import Delta from "quill-delta";
import type { QuillDelta, QuillInstance } from "../../quill";
import { parseStoredContent, stringifyDelta } from "../../quill";

export class UndoableEdit {
  private laterChanges = new Delta();
  private contentsAtClose: Delta | null = null;
  private isUndone = false;

  constructor(
    private quill: QuillInstance | null,
    readonly itemCount: number,
    private readonly change: Delta,
    private readonly before: Delta,
    /** The undo stack's depth with this edit on top. */
    private readonly depth: number,
  ) {}

  get isClosed() {
    return this.contentsAtClose !== null;
  }

  get isLive() {
    return !!this.quill && !this.isUndone;
  }

  dispose() {
    this.quill = null;
    this.contentsAtClose = null;
  }

  /** Restored lines go before anything typed at the same spot since. */
  private get inverse() {
    return this.laterChanges.transform(this.change.invert(this.before), false);
  }

  /** Call with each change made after the edit. */
  follow(change: QuillDelta) {
    const quill = this.quill;
    if (!quill || this.isUndone) return;
    if (quill.history.stack.undo.length < this.depth) this.isUndone = true;
    else
      this.laterChanges = this.laterChanges.compose(
        new Delta(change.ops as never),
      );
  }

  close(contents: QuillDelta) {
    if (!this.quill) return;
    this.quill = null;
    this.contentsAtClose = new Delta(contents.ops as never);
  }

  /** False once the note is closed or the edit was undone in the text. */
  undo(): boolean {
    const quill = this.quill;
    if (!quill || this.isUndone) return false;
    this.isUndone = true;
    const history = quill.history;
    if (
      !this.laterChanges.ops.length &&
      history.stack.undo.length === this.depth
    ) {
      history.undoKeepingSelection();
      return true;
    }
    history.cutoff();
    quill.updateContents(this.inverse as never, "user");
    history.cutoff();
    return true;
  }

  /** The saved text with the edit undone, or null if it changed after closing. */
  undoInContent(saved: string | null | undefined): string | null {
    const contentsAtClose = this.contentsAtClose;
    if (!contentsAtClose || this.isUndone) return null;
    const current = new Delta(parseStoredContent(saved).ops as never);
    if (current.diff(contentsAtClose).ops.length) return null;
    this.isUndone = true;
    return stringifyDelta(contentsAtClose.compose(this.inverse));
  }
}
