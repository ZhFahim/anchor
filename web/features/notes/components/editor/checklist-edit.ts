import Delta from "quill-delta";
import { UndoableEdit } from "./undoable-edit";

/** Task-input bulk actions share the rich-text editor's toast undo contract. */
export class ChecklistEdit extends UndoableEdit {
  private restore: (() => boolean) | null;
  private closedContent: string | null = null;
  private disposed = false;

  constructor(
    count: number,
    restore: () => boolean,
    private readonly beforeContent: string,
    private readonly afterContent: string,
  ) {
    super(null, count, new Delta(), new Delta(), 0);
    this.restore = restore;
  }

  override get isLive() {
    return this.restore !== null;
  }
  override get isClosed() {
    return this.closedContent !== null;
  }

  override undo() {
    const restored = this.restore?.() ?? false;
    if (restored) this.dispose();
    return restored;
  }

  closeChecklist(content: string) {
    if (this.disposed) return;
    this.restore = null;
    // Never replace changes made after the bulk action.
    this.closedContent = content === this.afterContent ? content : null;
  }

  override undoInContent(saved: string | null | undefined) {
    if (saved !== this.closedContent || this.closedContent === null)
      return null;
    const restored = this.beforeContent;
    this.dispose();
    return restored;
  }

  override dispose() {
    this.disposed = true;
    this.restore = null;
    this.closedContent = null;
  }
}
