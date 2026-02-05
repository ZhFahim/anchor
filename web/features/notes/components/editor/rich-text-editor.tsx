"use client";

import dynamic from "next/dynamic";
import { useCallback, useEffect, useRef, useState } from "react";
import type { QuillDelta, QuillInstance } from "@/features/notes";
import {
  parseStoredContent,
  stringifyDelta,
  didChangeChecklistItemState,
  getToggledLinePosition,
  createChecklistMoveDelta,
  QUILL_FORMATS,
  QUILL_MODULES,
} from "@/features/notes";
import { usePreferencesStore } from "@/features/preferences";
import { QuillToolbar } from "./quill-toolbar";

// Dynamic import for SSR compatibility
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const ReactQuill = dynamic(() => import("react-quill-new"), { ssr: false }) as any;

interface RichTextEditorProps {
  value: string;
  onChange: (nextStoredContent: string) => void;
  placeholder?: string;
  className?: string;
  readOnly?: boolean;
}

export function RichTextEditor({
  value,
  onChange,
  placeholder = "Start typing...",
  className,
  readOnly = false,
}: RichTextEditorProps) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any -- ReactQuill ref type
  const quillRef = useRef<any>(null);
  const quillInstanceRef = useRef<QuillInstance | null>(null);
  const [isFocused, setIsFocused] = useState(false);
  const [toolbarUpdateKey, setToolbarUpdateKey] = useState(0);
  const reorderTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

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
        const togglePosition = getToggledLinePosition(changeDelta as QuillDelta);

        if (togglePosition >= 0) {
          // Schedule reorder after Quill settles
          reorderTimeoutRef.current = setTimeout(() => {
            const quill = quillRef.current?.getEditor?.() as QuillInstance | null;
            if (!quill) return;

            const latestDelta = quill.getContents();
            const moveDelta = createChecklistMoveDelta(togglePosition, latestDelta);

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
  const handleSelectionChange = useCallback(() => {
    if (isFocused) {
      setToolbarUpdateKey((k) => k + 1);
    }
  }, [isFocused]);

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

  return (
    <div className={className}>
      {!readOnly && (
        <QuillToolbar
          getQuill={getQuillInstance}
          isFocused={isFocused}
          updateKey={toolbarUpdateKey}
        />
      )}
      <div className="anchor-quill">
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
      </div>
    </div>
  );
}
