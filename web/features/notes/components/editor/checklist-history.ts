/** Editor-local snapshots: structural edits and typing share one undo timeline. */
export class ChecklistHistory<T> {
  private past: { before: T; after: T }[] = [];
  private future: { before: T; after: T }[] = [];

  get depth() {
    return { undo: this.past.length, redo: this.future.length };
  }

  record(before: T, after: T) {
    this.past.push({ before, after });
    if (this.past.length > 100) this.past.shift();
    this.future = [];
  }

  undo(): T | undefined {
    const edit = this.past.pop();
    if (!edit) return;
    this.future.push(edit);
    return edit.before;
  }

  redo(): T | undefined {
    const edit = this.future.pop();
    if (!edit) return;
    this.past.push(edit);
    return edit.after;
  }

  clear() {
    this.past = [];
    this.future = [];
  }
}
