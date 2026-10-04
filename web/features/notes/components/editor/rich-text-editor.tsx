"use client";

import { GripVertical } from "lucide-react";
import dynamic from "next/dynamic";
import Delta from "quill-delta";
import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { StatusRing } from "@/components/ui/status-ring";
import { toast } from "@/components/ui/toast";
import { usePreferencesStore } from "@/features/preferences";
import { copyText } from "@/lib/clipboard";
import { DURATION } from "@/lib/design/tokens";
import { watchHighlights } from "@/lib/highlight-paint";
import { hasShortcutKey } from "@/lib/platform";
import { cn } from "@/lib/utils";
import type { LinkRange } from "../../link-utils";
import {
  isFullUrl,
  isLikelyUrl,
  linkAtIndex,
  linkTypedAddress,
  normalizeUrl,
} from "../../link-utils";
import type { QuillDelta, QuillInstance } from "../../quill";
import {
  dropPendingFormat,
  isInCodeBlock,
  parseStoredContent,
  QUILL_FORMATS,
  QUILL_MODULES,
  startTypedBlock,
  stringifyDelta,
  undoConversion,
} from "../../quill";
import { registerNoteFormats } from "../../quill-formats";
import {
  targetHandlesOwnUndo,
  undoRedoActionForKeyEvent,
} from "../../undo-shortcuts";
import { CodeCopyButtons } from "./code-copy-buttons";
import { SelectionToolbar } from "./highlight-tools";
import { LinkBubble } from "./link-bubble";
import { LinkPopover } from "./link-popover";
import { QuillToolbar } from "./quill-toolbar";
import { SlashMenu } from "./slash-menu";
import { useChecklistBoxes } from "./use-checklist-boxes";
import { scrollerOf, useChecklistDrag } from "./use-checklist-drag";
import { useChecklistSort } from "./use-checklist-sort";

// Our formats must be registered before any note opens.
// biome-ignore lint/suspicious/noExplicitAny: react-quill-new's dynamic() wrapper drops the ref types
const ReactQuill: any = dynamic(
  async () => {
    const quillModule = await import("react-quill-new");
    registerNoteFormats(
      quillModule.Quill as unknown as Parameters<typeof registerNoteFormats>[0],
    );
    return quillModule.default;
  },
  { ssr: false },
);

const LONG_NOTE_LINES = 3000;

function isLongNote(content: QuillDelta) {
  let lines = 0;
  for (const op of content.ops) {
    if (typeof op.insert !== "string") continue;
    for (
      let at = op.insert.indexOf("\n");
      at !== -1;
      at = op.insert.indexOf("\n", at + 1)
    )
      if (++lines >= LONG_NOTE_LINES) return true;
  }
  return false;
}

function pasteAsLink(
  quill: QuillInstance,
  sel: { index: number; length: number },
  url: string,
) {
  const address = normalizeUrl(url);
  if (sel.length === 0) {
    quill.insertText(sel.index, url, "user");
    quill.formatText(sel.index, url.length, "link", address, "user");
    quill.setSelection(sel.index + url.length, 0, "user");
  } else {
    quill.formatText(sel.index, sel.length, "link", address, "user");
    quill.setSelection(sel.index + sel.length, 0, "user");
  }
}

const TEXT_FORMATS = ["bold", "italic", "underline", "strike", "highlight"];

const CARET_GAP = 12;

function replaceWithLink(
  quill: QuillInstance,
  start: number,
  length: number,
  text: string,
  url: string,
) {
  if (quill.getText(start, length) === text) {
    quill.formatText(start, length, "link", url, "user");
  } else {
    const shared = quill.getFormat(start, length);
    const attributes: Record<string, unknown> = { link: url };
    for (const name of TEXT_FORMATS) {
      const value = shared[name];
      // Quill returns a list for mixed values.
      if (value !== undefined && !Array.isArray(value))
        attributes[name] = value;
    }
    quill.updateContents(
      {
        ops: [
          ...(start > 0 ? [{ retain: start }] : []),
          { insert: text, attributes },
          { delete: length },
        ],
      },
      "user",
    );
  }
  quill.setSelection(start + text.length, 0, "user");
}

interface RichTextEditorProps {
  value: string;
  onChange: (nextStoredContent: string) => void;
  placeholder?: string;
  readOnly?: boolean;
  onAddAttachment?: () => void;
  below?: React.ReactNode;
}

export interface RichTextEditorHandle {
  setSelection: (index: number, length: number) => void;
  /** False when read-only. */
  focusEnd: (extend: boolean) => boolean;
  startList: (kind: "unchecked" | "bullet") => void;
}

export const RichTextEditor = forwardRef<
  RichTextEditorHandle,
  RichTextEditorProps
>(
  (
    {
      value,
      onChange,
      placeholder = "Start typing...",
      readOnly = false,
      onAddAttachment,
      below,
    },
    ref,
  ) => {
    const quillRef = useRef<{ getEditor: () => QuillInstance }>(null);
    const rootRef = useRef<HTMLDivElement>(null);
    const [editorContainerEl, setEditorContainerEl] =
      useState<HTMLDivElement | null>(null);
    const [isFocused, setIsFocused] = useState(false);
    const [toolbarUpdateKey, setToolbarUpdateKey] = useState(0);
    const [linkDialogState, setLinkDialogState] = useState<{
      open: boolean;
      version: number;
      initialText: string;
      initialUrl: string;
      editingRange: { start: number; length: number } | null;
      anchor: DOMRect | null;
    }>({
      open: false,
      version: 0,
      initialText: "",
      initialUrl: "",
      editingRange: null,
      anchor: null,
    });
    const rectOf = useCallback((index: number, length: number) => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      const bounds = quill?.getBounds(index, length);
      if (!quill || !bounds) return null;
      const editorBox = quill.container.getBoundingClientRect();
      return new DOMRect(
        editorBox.left + bounds.left,
        editorBox.top + bounds.top,
        bounds.width,
        bounds.height,
      );
    }, []);
    const sortChecklistItems = usePreferencesStore(
      (state) => state.editor.sortChecklistItems,
    );

    const getQuill = useCallback(
      () => (quillRef.current?.getEditor?.() as QuillInstance | null) ?? null,
      [],
    );
    const checklistDrag = useChecklistDrag({
      containerEl: editorContainerEl,
      getQuill,
      enabled: !readOnly,
    });
    useChecklistBoxes({ containerEl: editorContainerEl, getQuill, readOnly });
    const checklistSort = useChecklistSort({
      containerEl: editorContainerEl,
      getQuill,
      isEnabled: sortChecklistItems,
      onSlideStart: checklistDrag.pauseHandle,
      onSlideEnd: checklistDrag.resumeHandle,
    });

    useEffect(() => {
      const host = editorContainerEl;
      if (!host) return;
      let stop: (() => void) | undefined;
      let watched: HTMLElement | null = null;
      // Follows the editor's text box if Quill rebuilds it.
      const attach = () => {
        const root = host.querySelector<HTMLElement>(".ql-editor");
        if (root === watched) return;
        stop?.();
        stop = undefined;
        watched = root;
        if (root) stop = watchHighlights(host, root);
      };
      attach();
      const observer = new MutationObserver(attach);
      observer.observe(host, { childList: true, subtree: true });
      return () => {
        observer.disconnect();
        stop?.();
      };
    }, [editorContainerEl]);

    const [longContent, setLongContent] = useState<QuillDelta | null>(() => {
      const content = parseStoredContent(value);
      return isLongNote(content) ? content : null;
    });
    // Quill gets its own contents back, or some stored notes reload on every render.
    const [editorValue, setEditorValue] = useState<QuillDelta>(() =>
      parseStoredContent(longContent ? "" : value),
    );
    const previousContents = useRef(editorValue);
    const [appliedValue, setAppliedValue] = useState(value);
    const [incomingValue, setIncomingValue] = useState<string | null>(null);
    if (value !== appliedValue) {
      setAppliedValue(value);
      setIncomingValue(value);
    }
    // Text from elsewhere goes in as a diff, so the caret and undo history stay.
    useLayoutEffect(() => {
      if (incomingValue === null) return;
      setIncomingValue(null);
      const next = parseStoredContent(incomingValue);
      const quill = getQuill();
      if (!quill || quill.getLength() <= 1) {
        const isLong = isLongNote(next);
        setLongContent(isLong ? next : null);
        if (isLong) {
          if (!quill) setEditorValue(parseStoredContent(""));
        } else if (quill) quill.setContents(next, "api");
        else setEditorValue(next);
        return;
      }
      const change = new Delta(quill.getContents().ops as never).diff(
        new Delta(next.ops as never),
      );
      if (change.ops.length)
        quill.updateContents(change as unknown as QuillDelta, "api");
    }, [incomingValue, getQuill]);
    useEffect(() => {
      if (!longContent) return;
      let isCancelled = false;
      const moving = document
        .getAnimations()
        .filter(
          (animation) =>
            animation.playState === "running" &&
            animation.effect?.getTiming().iterations !== Infinity,
        );
      const build = () => {
        if (isCancelled) return;
        const quill = getQuill();
        if (!quill) {
          requestAnimationFrame(build);
          return;
        }
        quill.setContents(longContent, "api");
        setLongContent(null);
      };
      Promise.race([
        Promise.all(
          moving.map((animation) => animation.finished.catch(() => {})),
        ),
        new Promise((resolve) => setTimeout(resolve, DURATION.morph)),
      ]).then(() => requestAnimationFrame(() => setTimeout(build)));
      return () => {
        isCancelled = true;
      };
    }, [longContent, getQuill]);
    const handleChange = useCallback(
      (
        _html: string,
        changeDelta: unknown,
        source: "user" | "api" | "silent" | string,
        editor: QuillInstance,
      ) => {
        const currentDelta = editor.getContents() as QuillDelta;
        const before = previousContents.current;
        previousContents.current = currentDelta;
        setEditorValue(currentDelta);

        // Ignore non-user changes (hydration, API updates)
        if (source !== "user" || readOnly) return;

        const currentStr = stringifyDelta(currentDelta);
        setAppliedValue(currentStr);
        const quill = getQuill();
        // Quill sets ignoreChange while it applies Undo or Redo.
        if (quill?.history.ignoreChange) checklistSort.cancel();
        else if (quill && !checklistSort.isSorting()) {
          checklistSort.noteChange(changeDelta as QuillDelta, before);
          queueMicrotask(() => {
            startTypedBlock(quill, changeDelta as QuillDelta);
            linkTypedAddress(quill, changeDelta as QuillDelta);
          });
        }
        onChange(currentStr);
        setToolbarUpdateKey((k) => k + 1);
      },
      [checklistSort, getQuill, onChange, readOnly],
    );
    // A format set at a bare caret changes neither the text nor the selection.
    useEffect(() => {
      const el = editorContainerEl;
      if (!el) return;
      const bump = () => setToolbarUpdateKey((k) => k + 1);
      el.addEventListener("formatchange", bump);
      return () => el.removeEventListener("formatchange", bump);
    }, [editorContainerEl]);

    const handleSelectionChange = useCallback(() => {
      if (isFocused) {
        setToolbarUpdateKey((k) => k + 1);
      }
    }, [isFocused]);

    // A selection must not grow out of a pending format's placeholder.
    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      const beforeSelecting = (e: KeyboardEvent | MouseEvent) => {
        if (!e.shiftKey) return;
        if (
          e instanceof KeyboardEvent &&
          !/^(Arrow|Home$|End$|Page)/.test(e.key)
        )
          return;
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (quill?.root.contains(e.target as Node)) dropPendingFormat(quill);
      };
      el.addEventListener("keydown", beforeSelecting, true);
      el.addEventListener("mousedown", beforeSelecting, true);
      return () => {
        el.removeEventListener("keydown", beforeSelecting, true);
        el.removeEventListener("mousedown", beforeSelecting, true);
      };
    }, [editorContainerEl, readOnly]);

    // Ahead of Quill's Backspace bindings.
    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      const onKey = (e: KeyboardEvent) => {
        if (
          e.key !== "Backspace" ||
          e.isComposing ||
          e.metaKey ||
          e.ctrlKey ||
          e.altKey ||
          e.shiftKey
        )
          return;
        const quill = getQuill();
        if (!quill?.root.contains(e.target as Node) || !undoConversion(quill))
          return;
        e.preventDefault();
        e.stopPropagation();
      };
      el.addEventListener("keydown", onKey, true);
      return () => el.removeEventListener("keydown", onKey, true);
    }, [editorContainerEl, getQuill, readOnly]);

    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      const leaveLineBreak = (e: MouseEvent) => {
        if (e.detail !== 3) return;
        const quill = getQuill();
        if (!quill?.root.contains(e.target as Node)) return;
        const range = quill.getSelection();
        if (
          range?.length &&
          quill.getText(range.index + range.length - 1, 1) === "\n"
        )
          quill.setSelection(range.index, range.length - 1, "user");
      };
      el.addEventListener("click", leaveLineBreak);
      return () => el.removeEventListener("click", leaveLineBreak);
    }, [editorContainerEl, getQuill, readOnly]);

    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      let frame = 0;
      const keepCaretAboveToolbar = () => {
        frame = 0;
        const quill = getQuill();
        const toolbar =
          el.parentElement?.querySelector<HTMLElement>(":scope > .tb");
        if (!quill || !toolbar) return;
        if (getComputedStyle(toolbar).bottom === "auto") return;
        const selection = quill.getSelection();
        const caret =
          selection && quill.getBounds(selection.index + selection.length);
        if (!caret) return;
        const caretBottom =
          quill.container.getBoundingClientRect().top + caret.bottom;
        const overlap =
          caretBottom + CARET_GAP - toolbar.getBoundingClientRect().top;
        if (overlap > 0) scrollerOf(el).scrollTop += overlap;
      };
      const schedule = () => {
        frame ||= requestAnimationFrame(keepCaretAboveToolbar);
      };
      el.addEventListener("keydown", schedule);
      el.addEventListener("input", schedule);
      return () => {
        cancelAnimationFrame(frame);
        el.removeEventListener("keydown", schedule);
        el.removeEventListener("input", schedule);
      };
    }, [editorContainerEl, getQuill, readOnly]);

    // Tab into the text goes back to the last caret.
    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      let lastCaret: { index: number; length: number } | null = null;
      const onKeyDown = (e: KeyboardEvent) => {
        const quill = getQuill();
        if (e.key !== "Tab" || !quill) return;
        // Read before focus moves: focus handlers overwrite savedRange.
        lastCaret = { ...quill.selection.savedRange };
        setTimeout(() => {
          lastCaret = null;
        });
      };
      const onFocusIn = (e: FocusEvent) => {
        const quill = getQuill();
        if (!lastCaret || !quill || e.target !== quill.root) return;
        const end = quill.getLength() - 1;
        const start = Math.min(lastCaret.index, end);
        quill.setSelection(
          start,
          Math.min(lastCaret.length, end - start),
          "api",
        );
      };
      document.addEventListener("keydown", onKeyDown, true);
      el.addEventListener("focusin", onFocusIn, true);
      return () => {
        document.removeEventListener("keydown", onKeyDown, true);
        el.removeEventListener("focusin", onFocusIn, true);
      };
    }, [editorContainerEl, getQuill, readOnly]);

    const openLinkExternal = useCallback((url: string) => {
      const normalized = normalizeUrl(url);
      try {
        window.open(normalized, "_blank", "noopener,noreferrer");
      } catch {}
    }, []);

    const copyLinkToClipboard = useCallback((url: string) => {
      copyText(url).then(
        () => toast.success("Link copied"),
        () => toast.error("Couldn’t copy the link"),
      );
    }, []);

    const openLinkDialog = useCallback(() => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      if (!quill) return;
      const sel = quill.getSelection(true);
      if (sel && isInCodeBlock(quill, sel)) return;
      const existing = sel ? linkAtIndex(quill, sel.index) : null;
      if (existing) {
        setLinkDialogState((s) => ({
          open: true,
          version: s.version + 1,
          initialText: existing.text,
          initialUrl: existing.url,
          editingRange: { start: existing.start, length: existing.length },
          anchor: rectOf(existing.start, existing.length),
        }));
      } else {
        const selectedText = sel?.length
          ? (quill.getText(sel.index, sel.length) ?? "")
          : "";
        const selectionIsUrl = isLikelyUrl(selectedText);
        setLinkDialogState((s) => ({
          open: true,
          version: s.version + 1,
          initialText: selectionIsUrl ? "" : selectedText,
          initialUrl: selectionIsUrl ? selectedText.trim() : "",
          editingRange: null,
          anchor: sel ? rectOf(sel.index, sel.length) : null,
        }));
      }
    }, [rectOf]);

    useEffect(() => {
      const el = editorContainerEl;
      if (!el || readOnly) return;
      const onKey = (e: KeyboardEvent) => {
        if (
          !hasShortcutKey(e) ||
          e.altKey ||
          e.shiftKey ||
          e.key.toLowerCase() !== "k"
        )
          return;
        const quill = getQuill();
        const sel = quill?.getSelection();
        if (!quill || !sel || !quill.root.contains(e.target as Node)) return;
        if (!sel.length && !linkAtIndex(quill, sel.index)) return;
        e.preventDefault();
        openLinkDialog();
      };
      el.addEventListener("keydown", onKey);
      return () => el.removeEventListener("keydown", onKey);
    }, [editorContainerEl, getQuill, openLinkDialog, readOnly]);

    const editLinkFromBubble = useCallback(
      (link: LinkRange) => {
        setLinkDialogState((s) => ({
          open: true,
          version: s.version + 1,
          initialText: link.text,
          initialUrl: link.url,
          editingRange: { start: link.start, length: link.length },
          anchor: rectOf(link.start, link.length),
        }));
      },
      [rectOf],
    );

    const removeLinkRange = useCallback((link: LinkRange) => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      if (!quill) return;
      quill.formatText(link.start, link.length, "link", false, "user");
    }, []);

    const handleLinkSubmit = useCallback(
      (text: string, url: string) => {
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill) return;
        const editingRange = linkDialogState.editingRange;

        if (editingRange) {
          replaceWithLink(
            quill,
            editingRange.start,
            editingRange.length,
            text,
            url,
          );
        } else {
          const sel = quill.getSelection(true);
          if (!sel) return;
          if (sel.length === 0) {
            quill.insertText(sel.index, text, "user");
            quill.formatText(sel.index, text.length, "link", url, "user");
            quill.setSelection(sel.index + text.length, 0, "user");
          } else {
            const selectedText = quill.getText(sel.index, sel.length) ?? "";
            const trimmed = selectedText.trim();
            if (selectedText.includes("\n") || text === trimmed) {
              const lead =
                selectedText.length - selectedText.trimStart().length;
              quill.formatText(
                sel.index + lead,
                trimmed.length,
                "link",
                url,
                "user",
              );
            } else {
              replaceWithLink(quill, sel.index, sel.length, text, url);
            }
          }
        }

        setLinkDialogState((s) => ({ ...s, open: false }));
      },
      [linkDialogState.editingRange],
    );

    const handleLinkRemove = useCallback(() => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      const range = linkDialogState.editingRange;
      if (!quill || !range) return;
      quill.formatText(range.start, range.length, "link", false, "user");
      setLinkDialogState((s) => ({ ...s, open: false }));
      quill.setSelection(range.start + range.length, 0, "user");
    }, [linkDialogState.editingRange]);
    const handleFocus = useCallback(() => {
      if (readOnly) return;
      setIsFocused(true);
    }, [readOnly]);
    const handleBlur = useCallback(() => {
      setIsFocused(false);
    }, []);

    useImperativeHandle(
      ref,
      () => ({
        setSelection: (index: number, length: number) => {
          if (readOnly) return;
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          if (!quill) return;
          quill.setSelection(index, length, "user");
          setIsFocused(true);
        },
        focusEnd: (extend: boolean) => {
          if (readOnly) return false;
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          if (!quill) return false;
          const end = quill.getLength() - 1;
          const from = extend ? (quill.getSelection()?.index ?? end) : end;
          quill.setSelection(from, end - from, "user");
          setIsFocused(true);
          return true;
        },
        startList: (kind: "unchecked" | "bullet") => {
          if (readOnly) return;
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          if (!quill) return;
          quill.focus();
          quill.getSelection(true);
          quill.format("list", kind, "user");
          setIsFocused(true);
        },
      }),
      [readOnly],
    );

    useEffect(() => {
      const host = editorContainerEl;
      if (!host || readOnly) return;
      const markTextbox = () => {
        const root = host.querySelector<HTMLElement>(".ql-editor");
        if (!root || root.getAttribute("role") === "textbox") return;
        root.setAttribute("role", "textbox");
        root.setAttribute("aria-multiline", "true");
        root.setAttribute("aria-label", "Note text");
      };
      markTextbox();
      const observer = new MutationObserver(markTextbox);
      observer.observe(host, { childList: true, subtree: true });
      return () => {
        observer.disconnect();
        const root = host.querySelector<HTMLElement>(".ql-editor");
        root?.removeAttribute("role");
        root?.removeAttribute("aria-multiline");
        root?.removeAttribute("aria-label");
      };
    }, [editorContainerEl, readOnly]);

    useEffect(() => {
      const host = editorContainerEl;
      if (!host || !readOnly) return;
      const markReadOnly = () => {
        const root = host.querySelector<HTMLElement>(".ql-editor");
        if (!root || root.getAttribute("role") === "region") return;
        root.tabIndex = 0;
        root.setAttribute("role", "region");
        root.setAttribute("aria-label", "Note text, read-only");
      };
      markReadOnly();
      const observer = new MutationObserver(markReadOnly);
      observer.observe(host, { childList: true, subtree: true });
      // Quill's keyboard swallows Tab even when read-only.
      const passTab = (e: KeyboardEvent) => {
        const root = host.querySelector(".ql-editor");
        if (!root?.contains(e.target as Node)) return;
        if (e.key === "Tab") e.stopPropagation();
        if (e.key.toLowerCase() === "a" && (e.metaKey || e.ctrlKey)) {
          e.preventDefault();
          window.getSelection()?.selectAllChildren(root);
        }
      };
      host.addEventListener("keydown", passTab, true);
      return () => {
        observer.disconnect();
        host.removeEventListener("keydown", passTab, true);
        const root = host.querySelector<HTMLElement>(".ql-editor");
        root?.removeAttribute("tabindex");
        root?.removeAttribute("role");
        root?.removeAttribute("aria-label");
      };
    }, [editorContainerEl, readOnly]);

    // Runs before Quill's own paste handler.
    useEffect(() => {
      if (readOnly) return;
      const el = editorContainerEl;
      if (!el) return;
      const handler = (e: ClipboardEvent) => {
        const raw = e.clipboardData?.getData("text/plain")?.trim() ?? "";
        if (!isFullUrl(raw)) return;
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill) return;
        const sel = quill.getSelection(true);
        if (!sel || quill.getFormat(sel.index)["code-block"]) return;
        e.preventDefault();
        e.stopPropagation();
        pasteAsLink(quill, sel, raw);
      };
      el.addEventListener("paste", handler, { capture: true });
      return () => el.removeEventListener("paste", handler, { capture: true });
    }, [editorContainerEl, readOnly]);

    // Quill only hears the undo shortcut when the editor is focused;
    // checkbox clicks and handle drags never focus it.
    useEffect(() => {
      if (readOnly) return;
      const handler = (e: KeyboardEvent) => {
        if (e.defaultPrevented || linkDialogState.open) return;
        if (targetHandlesOwnUndo(e.target)) return;
        const action = undoRedoActionForKeyEvent(e);
        if (!action) return;
        // The browser's own undo would still change the note's text.
        e.preventDefault();
        const root = rootRef.current;
        const target = e.target as Node;
        if (
          !root?.checkVisibility() ||
          (target !== document.body && !root.contains(target))
        )
          return;
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        quill?.history[action]();
      };
      document.addEventListener("keydown", handler);
      return () => document.removeEventListener("keydown", handler);
    }, [readOnly, linkDialogState.open]);

    return (
      <div ref={rootRef} className="rte">
        {!readOnly && (
          <QuillToolbar
            getQuill={getQuill}
            isFocused={isFocused}
            updateKey={toolbarUpdateKey}
            onOpenLinkDialog={openLinkDialog}
            onAddAttachment={onAddAttachment}
          />
        )}
        <div
          ref={setEditorContainerEl}
          className={cn("anchor-quill", readOnly && "read-only")}
          data-building={longContent ? "" : undefined}
        >
          {longContent && (
            <p
              role="status"
              className="m-0 flex items-center gap-2 pt-1 text-note-muted text-meta"
            >
              <StatusRing turning />
              Loading the note…
            </p>
          )}
          <ReactQuill
            ref={quillRef}
            theme="snow"
            value={editorValue}
            onChange={handleChange}
            onChangeSelection={handleSelectionChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
            modules={QUILL_MODULES}
            formats={QUILL_FORMATS}
            placeholder={placeholder}
            readOnly={readOnly || !!longContent}
            useSemanticHTML={false}
          />
          {!readOnly && checklistDrag.handle && !checklistDrag.drag && (
            <button
              type="button"
              className="anchor-checklist-handle"
              style={{
                top: checklistDrag.handle.top,
                left: checklistDrag.handle.left,
              }}
              onPointerDown={(e) => {
                checklistSort.cancel();
                checklistDrag.startDrag(e);
              }}
              aria-label="Drag to reorder"
            >
              <GripVertical size={15} />
            </button>
          )}
          {checklistDrag.drag && checklistDrag.drag.indicatorTop !== null && (
            <div
              className="anchor-checklist-drag-indicator"
              style={{
                top: checklistDrag.drag.indicatorTop - 1,
                left: checklistDrag.drag.indicatorLeft,
              }}
            />
          )}
          {checklistDrag.drag && (
            <div
              className="anchor-checklist-ghost"
              style={{
                top: checklistDrag.drag.ghostTop - 16,
                left: checklistDrag.drag.ghostLeft,
              }}
            >
              <span
                className="anchor-checklist-ghost-box"
                data-checked={checklistDrag.drag.checked}
              />
              <span
                className="anchor-checklist-ghost-text"
                data-checked={checklistDrag.drag.checked}
              >
                {checklistDrag.drag.text || " "}
              </span>
              {checklistDrag.drag.childCount > 0 && (
                <span className="anchor-checklist-ghost-count">
                  +{checklistDrag.drag.childCount}
                </span>
              )}
            </div>
          )}
          <CodeCopyButtons container={editorContainerEl} />
          {!readOnly && (
            <SelectionToolbar
              getQuill={getQuill}
              container={editorContainerEl}
            />
          )}
          {!readOnly && (
            <SlashMenu
              getQuill={getQuill}
              container={editorContainerEl}
              onAddAttachment={onAddAttachment}
              onAddLink={openLinkDialog}
            />
          )}
          {!linkDialogState.open && (
            <LinkBubble
              getQuill={getQuill}
              container={editorContainerEl}
              readOnly={readOnly}
              onOpen={openLinkExternal}
              onCopy={copyLinkToClipboard}
              onEdit={editLinkFromBubble}
              onRemove={removeLinkRange}
            />
          )}
        </div>
        {below}
        {!readOnly && (
          <LinkPopover
            key={linkDialogState.version}
            open={linkDialogState.open}
            anchor={linkDialogState.anchor}
            initialText={linkDialogState.initialText}
            initialUrl={linkDialogState.initialUrl}
            isEditing={linkDialogState.editingRange !== null}
            onSubmit={handleLinkSubmit}
            onRemove={
              linkDialogState.editingRange ? handleLinkRemove : undefined
            }
            onClose={(returnFocus) => {
              setLinkDialogState((s) => ({ ...s, open: false }));
              if (returnFocus) getQuill()?.focus();
            }}
          />
        )}
      </div>
    );
  },
);

RichTextEditor.displayName = "RichTextEditor";
