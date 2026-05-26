"use client";

import type { LinkRange, QuillDelta, QuillInstance } from "@/features/notes";
import {
  createChecklistMoveDelta,
  didChangeChecklistItemState,
  getToggledLinePosition,
  isLikelyUrl,
  linkAtIndex,
  normalizeUrl,
  parseStoredContent,
  QUILL_FORMATS,
  QUILL_MODULES,
  stringifyDelta,
} from "@/features/notes";
import { usePreferencesStore } from "@/features/preferences";
import dynamic from "next/dynamic";
import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import { LinkBubble } from "./link-bubble";
import { LinkDialog } from "./link-dialog";
import { QuillToolbar } from "./quill-toolbar";

// Dynamic import for SSR compatibility
const ReactQuill = dynamic(() => import("react-quill-new"), {
  ssr: false,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any -- ReactQuill ref type
    const quillRef = useRef<any>(null);
    const quillInstanceRef = useRef<QuillInstance | null>(null);
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

    // Editor preferences
    const sortChecklistItems = usePreferencesStore(
      (state) => state.editor.sortChecklistItems,
    );

    const deltaValue: QuillDelta = parseStoredContent(value);

    // Cleanup timeout on unmount
    useEffect(() => {
      return () => {
        if (reorderTimeoutRef.current) {
          clearTimeout(reorderTimeoutRef.current);
        }
      };
    }, []);

    // Get quill instance - callable by toolbar
    const getQuillInstance = useCallback(() => quillInstanceRef.current, []);

    // Handle editor content changes
    const handleChange = useCallback(
      (
        _html: string,
        changeDelta: unknown,
        source: "user" | "api" | "silent" | string,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any -- react-quill editor type
        editor: any,
      ) => {
        // Ignore non-user changes (hydration, API updates)
        if (source !== "user" || readOnly) return;

        const currentDelta = editor.getContents() as QuillDelta;
        const currentStr = stringifyDelta(currentDelta);

        // Handle checklist reordering if enabled
        if (
          sortChecklistItems &&
          didChangeChecklistItemState(changeDelta as QuillDelta)
        ) {
          // Clear any pending reorder
          if (reorderTimeoutRef.current) {
            clearTimeout(reorderTimeoutRef.current);
          }

          // Get the position of the toggled line from the change delta
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
              const moveDelta = createChecklistMoveDelta(
                togglePosition,
                latestDelta,
              );

              if (moveDelta) {
                // Use updateContents to preserve undo history as single operation
                quill.updateContents(moveDelta, "user");

                // Update parent with new content
                const newDelta = quill.getContents();
                onChange(stringifyDelta(newDelta));
                setToolbarUpdateKey((k) => k + 1);
              }
            }, 50);
          }

          // Notify parent of immediate change
          onChange(currentStr);
          setToolbarUpdateKey((k) => k + 1);
          return;
        }

        // Normal change
        onChange(currentStr);
        setToolbarUpdateKey((k) => k + 1);
      },
      [onChange, readOnly, sortChecklistItems],
    );

    // Handle selection changes for toolbar state
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
        const selectedText =
          sel && sel.length ? (quill.getText(sel.index, sel.length) ?? "") : "";
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

    // Handle editor focus
    const handleFocus = useCallback(() => {
      if (readOnly) return;
      const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
      if (quill) {
        quillInstanceRef.current = quill;
        setIsFocused(true);
      }
    }, [readOnly]);

    // Handle editor blur
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
          quillInstanceRef.current = quill;
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
          quillInstanceRef.current = quill;
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

    return (
      <div className={className}>
        {!readOnly && (
          <div className="sticky top-16 z-30 mb-2 px-4 py-1.5 lg:-mx-3 lg:px-6 rounded-2xl backdrop-blur-sm bg-white/5 dark:bg-white/5">
            <QuillToolbar
              getQuill={getQuillInstance}
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
          {!readOnly && isFocused && activeLink && (
            <LinkBubble
              getQuill={getQuillInstance}
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
