"use client";

import { GripVertical } from "lucide-react";
import dynamic from "next/dynamic";
import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import type { LinkRange, QuillDelta, QuillInstance } from "@/features/notes";
import {
  createChecklistSortDelta,
  didChangeChecklistItemState,
  getToggledLinePosition,
  isLikelyUrl,
  linkAtIndex,
  normalizeUrl,
  parseStoredContent,
  QUILL_FORMATS,
  QUILL_MODULES,
  stringifyDelta,
  targetHandlesOwnUndo,
  undoRedoActionForKeyEvent,
} from "@/features/notes";
import { usePreferencesStore } from "@/features/preferences";
import { LinkBubble } from "./link-bubble";
import { LinkDialog } from "./link-dialog";
import { QuillToolbar } from "./quill-toolbar";
import { useChecklistDrag } from "./use-checklist-drag";

// Dynamic import for SSR compatibility
const ReactQuill = dynamic(() => import("react-quill-new"), {
  ssr: false,
  // biome-ignore lint/suspicious/noExplicitAny: react-quill-new's dynamic() wrapper drops the ref/prop types at this boundary
}) as any;

function pasteAsLink(
  quill: QuillInstance,
  sel: { index: number; length: number },
  url: string,
) {
  if (sel.length === 0) {
    quill.insertText(sel.index, url, "user");
    quill.formatText(sel.index, url.length, "link", url, "user");
    quill.setSelection(sel.index + url.length, 0, "user");
  } else {
    quill.formatText(sel.index, sel.length, "link", url, "user");
    quill.setSelection(sel.index + sel.length, 0, "user");
  }
}

interface RichTextEditorProps {
  value: string;
  onChange: (nextStoredContent: string) => void;
  placeholder?: string;
  className?: string;
  readOnly?: boolean;
}

export interface RichTextEditorHandle {
  focus: () => void;
  getSelection: () => { index: number; length: number } | null;
  setSelection: (index: number, length: number) => void;
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
      className,
      readOnly = false,
    },
    ref,
  ) => {
    const quillRef = useRef<{ getEditor: () => QuillInstance }>(null);
    const [editorContainerEl, setEditorContainerEl] =
      useState<HTMLDivElement | null>(null);
    const [isFocused, setIsFocused] = useState(false);
    const [toolbarUpdateKey, setToolbarUpdateKey] = useState(0);
    const [activeLink, setActiveLink] = useState<LinkRange | null>(null);
    const [linkDialogState, setLinkDialogState] = useState<{
      open: boolean;
      version: number;
      initialText: string;
      initialUrl: string;
      editingRange: { start: number; length: number } | null;
    }>({
      open: false,
      version: 0,
      initialText: "",
      initialUrl: "",
      editingRange: null,
    });
    const reorderTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(
      null,
    );
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

    const deltaValue: QuillDelta = parseStoredContent(value);
    useEffect(() => {
      return () => {
        if (reorderTimeoutRef.current) {
          clearTimeout(reorderTimeoutRef.current);
        }
      };
    }, []);
    const handleChange = useCallback(
      (
        _html: string,
        changeDelta: unknown,
        source: "user" | "api" | "silent" | string,
        editor: QuillInstance,
      ) => {
        // Ignore non-user changes (hydration, API updates)
        if (source !== "user" || readOnly) return;

        const currentDelta = editor.getContents() as QuillDelta;
        const currentStr = stringifyDelta(currentDelta);
        if (
          sortChecklistItems &&
          didChangeChecklistItemState(changeDelta as QuillDelta)
        ) {
          if (reorderTimeoutRef.current) {
            clearTimeout(reorderTimeoutRef.current);
          }
          const togglePosition = getToggledLinePosition(
            changeDelta as QuillDelta,
          );

          if (togglePosition >= 0) {
            // Schedule reorder after Quill settles
            reorderTimeoutRef.current = setTimeout(() => {
              const quill =
                quillRef.current?.getEditor?.() as QuillInstance | null;
              if (!quill) return;

              const latestDelta = quill.getContents();
              const moveDelta = createChecklistSortDelta(
                togglePosition,
                latestDelta,
              );

              if (moveDelta) {
                quill.updateContents(moveDelta, "user");
                const newDelta = quill.getContents();
                onChange(stringifyDelta(newDelta));
                setToolbarUpdateKey((k) => k + 1);
              }
            }, 50);
          }
          onChange(currentStr);
          setToolbarUpdateKey((k) => k + 1);
          return;
        }
        onChange(currentStr);
        setToolbarUpdateKey((k) => k + 1);
      },
      [onChange, readOnly, sortChecklistItems],
    );
    const handleSelectionChange = useCallback(
      (range: { index: number; length: number } | null) => {
        if (isFocused) {
          setToolbarUpdateKey((k) => k + 1);
        }
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill || !range) {
          setActiveLink(null);
          return;
        }
        setActiveLink(linkAtIndex(quill, range.index));
      },
      [isFocused],
    );

    const openLinkExternal = useCallback((url: string) => {
      const normalized = normalizeUrl(url);
      try {
        window.open(normalized, "_blank", "noopener,noreferrer");
      } catch {}
    }, []);

    const copyLinkToClipboard = useCallback((url: string) => {
      if (typeof navigator === "undefined" || !navigator.clipboard?.writeText)
        return;
      navigator.clipboard.writeText(url).catch(() => {});
    }, []);

    const openLinkDialog = useCallback(() => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      if (!quill) return;
      const sel = quill.getSelection();
      const existing = sel ? linkAtIndex(quill, sel.index) : null;
      if (existing) {
        setLinkDialogState((s) => ({
          open: true,
          version: s.version + 1,
          initialText: existing.text,
          initialUrl: existing.url,
          editingRange: { start: existing.start, length: existing.length },
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
        }));
      }
    }, []);

    const editLinkFromBubble = useCallback((link: LinkRange) => {
      setLinkDialogState((s) => ({
        open: true,
        version: s.version + 1,
        initialText: link.text,
        initialUrl: link.url,
        editingRange: { start: link.start, length: link.length },
      }));
    }, []);

    const removeLinkRange = useCallback((link: LinkRange) => {
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      if (!quill) return;
      quill.formatText(link.start, link.length, "link", false, "user");
      setActiveLink(null);
    }, []);

    const handleLinkSubmit = useCallback(
      (text: string, url: string) => {
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill) return;
        const editingRange = linkDialogState.editingRange;

        if (editingRange) {
          quill.deleteText(editingRange.start, editingRange.length, "user");
          quill.insertText(editingRange.start, text, "user");
          quill.formatText(
            editingRange.start,
            text.length,
            "link",
            url,
            "user",
          );
          quill.setSelection(editingRange.start + text.length, 0, "user");
        } else {
          const sel = quill.getSelection(true);
          if (!sel) return;
          if (sel.length === 0) {
            quill.insertText(sel.index, text, "user");
            quill.formatText(sel.index, text.length, "link", url, "user");
            quill.setSelection(sel.index + text.length, 0, "user");
          } else {
            const selectedText = quill.getText(sel.index, sel.length) ?? "";
            if (text !== selectedText) {
              quill.deleteText(sel.index, sel.length, "user");
              quill.insertText(sel.index, text, "user");
              quill.formatText(sel.index, text.length, "link", url, "user");
              quill.setSelection(sel.index + text.length, 0, "user");
            } else {
              quill.format("link", url, "user");
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
      setActiveLink(null);
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
        focus: () => {
          if (readOnly) return;
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          if (!quill) return;
          quill.focus();
          setIsFocused(true);
        },
        getSelection: () => {
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          return quill?.getSelection() ?? null;
        },
        setSelection: (index: number, length: number) => {
          if (readOnly) return;
          const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
          if (!quill) return;
          quill.focus();
          quill.setSelection(index, length, "silent");
          setIsFocused(true);
        },
      }),
      [readOnly],
    );

    const handleEditorClick = useCallback(
      (e: React.MouseEvent<HTMLDivElement>) => {
        if (!readOnly) return;
        const target = e.target as HTMLElement;
        const anchor = target.closest("a");
        if (!anchor) return;
        const href = anchor.getAttribute("href");
        if (!href) return;
        e.preventDefault();
        openLinkExternal(href);
      },
      [readOnly, openLinkExternal],
    );

    // Capture phase so we run before Quill's bubble-phase paste handler.
    useEffect(() => {
      if (readOnly) return;
      const el = editorContainerEl;
      if (!el) return;
      const handler = (e: ClipboardEvent) => {
        const raw = e.clipboardData?.getData("text/plain")?.trim() ?? "";
        if (!isLikelyUrl(raw)) return;
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill) return;
        const sel = quill.getSelection(true);
        if (!sel) return;
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
        const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
        if (!quill) return;
        e.preventDefault();
        quill.history[action]();
      };
      document.addEventListener("keydown", handler);
      return () => document.removeEventListener("keydown", handler);
    }, [readOnly, linkDialogState.open]);

    return (
      <div className={className}>
        {!readOnly && (
          <div className="sticky top-16 z-30 mb-2 px-4 py-1.5 lg:-mx-3 lg:px-6 rounded-2xl backdrop-blur-sm bg-white/5 dark:bg-white/5">
            <QuillToolbar
              getQuill={getQuill}
              isFocused={isFocused}
              updateKey={toolbarUpdateKey}
              onOpenLinkDialog={openLinkDialog}
            />
          </div>
        )}
        <div
          ref={setEditorContainerEl}
          className="anchor-quill relative"
          onClick={handleEditorClick}
        >
          <ReactQuill
            ref={quillRef}
            theme="snow"
            value={deltaValue}
            onChange={handleChange}
            onChangeSelection={handleSelectionChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
            modules={QUILL_MODULES}
            formats={QUILL_FORMATS}
            placeholder={placeholder}
            readOnly={readOnly}
          />
          {!readOnly && checklistDrag.handle && !checklistDrag.drag && (
            <button
              type="button"
              className="anchor-checklist-handle"
              style={{
                top: checklistDrag.handle.top,
                left: checklistDrag.handle.left,
              }}
              onPointerDown={checklistDrag.startDrag}
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
          {!readOnly && isFocused && activeLink && (
            <LinkBubble
              getQuill={getQuill}
              link={activeLink}
              containerEl={editorContainerEl}
              onOpen={openLinkExternal}
              onCopy={copyLinkToClipboard}
              onEdit={editLinkFromBubble}
              onRemove={removeLinkRange}
            />
          )}
        </div>
        {!readOnly && (
          <LinkDialog
            key={linkDialogState.version}
            open={linkDialogState.open}
            initialText={linkDialogState.initialText}
            initialUrl={linkDialogState.initialUrl}
            isEditing={linkDialogState.editingRange !== null}
            onSubmit={handleLinkSubmit}
            onRemove={
              linkDialogState.editingRange ? handleLinkRemove : undefined
            }
            onOpenChange={(open) => setLinkDialogState((s) => ({ ...s, open }))}
          />
        )}
      </div>
    );
  },
);

RichTextEditor.displayName = "RichTextEditor";
