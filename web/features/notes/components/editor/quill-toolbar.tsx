"use client";

import {
  Bold,
  Code,
  Heading1,
  Heading2,
  Heading3,
  ImagePlus,
  IndentDecrease,
  IndentIncrease,
  Italic,
  Link as LinkIcon,
  List,
  ListChecks,
  ListOrdered,
  Quote,
  Redo2,
  Strikethrough,
  Underline,
  Undo2,
} from "lucide-react";
import type * as React from "react";
import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { Tip } from "@/components/ui/tooltip";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { isMac } from "@/lib/platform";
import type { QuillInstance } from "../../quill";
import {
  applyListIndent,
  getTextFormat,
  LIST_FORMATS,
  toggleTextFormat,
} from "../../quill";
import { buildListIndentDelta } from "../../quill-lines";
import {
  HighlightSplitButton,
  hasHighlight,
  PhoneHighlightRow,
} from "./highlight-tools";

/**
 * Formats at the selection without argument-less getFormat()'s
 * focus-and-scroll side effect. Button handlers keep getFormat(): its
 * focus-first read sees the cursor's formats after a click steals focus.
 */
function selectionFormat(quill: QuillInstance): Record<string, unknown> {
  const sel = quill.getSelection();
  return sel ? getTextFormat(quill, sel.index, sel.length) : {};
}

function toggleInlineFormat(quill: QuillInstance, key: string) {
  const sel = quill.getSelection(true);
  if (sel) toggleTextFormat(quill, sel, key);
}

function toggleHeader(quill: QuillInstance, level: 1 | 2 | 3) {
  const current = quill.getFormat() ?? {};
  quill.format("header", current.header === level ? false : level, "user");
  quill.format("indent", false, "user");
}

function toggleList(
  quill: QuillInstance,
  value: "ordered" | "bullet" | "unchecked",
) {
  const current = quill.getFormat() ?? {};
  const currentList = current.list as string | undefined;

  if (value === LIST_FORMATS.UNCHECKED) {
    const isChecklist =
      currentList === LIST_FORMATS.CHECKED ||
      currentList === LIST_FORMATS.UNCHECKED;
    quill.format("list", isChecklist ? false : LIST_FORMATS.UNCHECKED, "user");
    if (isChecklist) quill.format("indent", false, "user");
    return;
  }

  quill.format("list", currentList === value ? false : value, "user");
  if (currentList === value) quill.format("indent", false, "user");
}

function toggleBlock(quill: QuillInstance, key: "blockquote" | "code-block") {
  const current = quill.getFormat() ?? {};
  // Quill stores a code block's value as its language.
  const on = key === "code-block" ? "plain" : true;
  quill.format(key, current[key] ? false : on, "user");
  quill.format("indent", false, "user");
}

interface QuillToolbarProps {
  getQuill: () => QuillInstance | null;
  isFocused: boolean;
  updateKey: number;
  onOpenLinkDialog: () => void;
  onAddAttachment?: () => void;
}

export function QuillToolbar({
  getQuill,
  isFocused,
  updateKey,
  onOpenLinkDialog,
  onAddAttachment,
}: QuillToolbarProps) {
  const [format, setFormat] = useState<Record<string, unknown>>({});
  const [canUndo, setCanUndo] = useState(false);
  const [canRedo, setCanRedo] = useState(false);
  const [showColors, setShowColors] = useState(false);
  const [canIndent, setCanIndent] = useState(false);
  const [canOutdent, setCanOutdent] = useState(false);
  const [canErase, setCanErase] = useState(false);
  const formatting = useRovingFocus<HTMLDivElement>();
  const colors = useRovingFocus<HTMLDivElement>();
  // Set when a key press opens or closes the phone colors.
  const focusAfterSwitch = useRef(false);

  // biome-ignore lint/correctness/useExhaustiveDependencies: updateKey re-syncs the toolbar
  useEffect(() => {
    const quill = getQuill();
    if (!quill) {
      setFormat((current) =>
        Object.keys(current).length === 0 ? current : {},
      );
      setCanUndo(false);
      setCanRedo(false);
      return;
    }
    // Format highlights need a cursor; undo/redo must work unfocused.
    const nextFormat = isFocused ? selectionFormat(quill) : {};
    setFormat((current) =>
      JSON.stringify(current) === JSON.stringify(nextFormat)
        ? current
        : nextFormat,
    );
    const sel = isFocused ? quill.getSelection() : null;
    const contents = sel ? quill.getContents() : null;
    const canMove = (direction: 1 | -1) =>
      !!sel &&
      !!contents &&
      !!buildListIndentDelta(contents, sel.index, sel.length, direction);
    setCanIndent(canMove(1));
    setCanOutdent(canMove(-1));
    setCanErase(!!sel && hasHighlight(quill, sel));
    const hist = quill.history;
    setCanUndo(Boolean(hist?.stack?.undo?.length));
    setCanRedo(Boolean(hist?.stack?.redo?.length));
  }, [getQuill, isFocused, updateKey]);

  useLayoutEffect(() => {
    if (!focusAfterSwitch.current) return;
    focusAfterSwitch.current = false;
    const target = showColors
      ? (colors.ref.current?.querySelector<HTMLElement>(
          '.hl-dot[aria-pressed="true"]',
        ) ?? colors.ref.current?.querySelector<HTMLElement>(".hl-dot"))
      : formatting.ref.current?.querySelector<HTMLElement>(".hl-main");
    target?.focus();
  }, [showColors, colors.ref, formatting.ref]);
  const switchColors = (isOpen: boolean) => {
    const bar = showColors ? colors.ref.current : formatting.ref.current;
    // Toolbar buttons only take focus from the keyboard.
    focusAfterSwitch.current = !!bar?.contains(document.activeElement);
    setShowColors(isOpen);
  };

  const quill = getQuill();
  const changeIndent = (direction: 1 | -1) => {
    const sel = quill?.getSelection();
    if (!quill || !sel) return;
    applyListIndent(quill, sel, direction);
  };

  const headerLevel = useMemo(
    () => (typeof format.header === "number" ? format.header : 0),
    [format.header],
  );
  const listValue = (format.list as string | undefined) ?? "";
  const isChecklist =
    listValue === LIST_FORMATS.CHECKED || listValue === LIST_FORMATS.UNCHECKED;
  const isInCode = !!format["code-block"];
  const modKey = isMac() ? "⌘" : "Ctrl+";

  const toolButton = (
    label: string,
    icon: React.ReactNode,
    onClick: () => void,
    options: { active?: boolean; disabled?: boolean; toggle?: boolean } = {},
  ) => (
    <Tip label={label}>
      <button
        type="button"
        className="b"
        aria-label={label}
        aria-pressed={options.toggle ? !!options.active : undefined}
        aria-disabled={options.disabled || undefined}
        // Keep the editor's selection: the click must not move focus.
        onMouseDown={(e) => e.preventDefault()}
        onClick={options.disabled ? undefined : onClick}
      >
        {icon}
      </button>
    </Tip>
  );
  const divider = <span className="dv" aria-hidden />;

  if (showColors)
    return (
      <div
        ref={colors.ref}
        className="tb"
        role="toolbar"
        aria-label="Highlight colors"
        onFocus={colors.onFocus}
        onKeyDown={colors.onKeyDown}
      >
        <PhoneHighlightRow
          getQuill={getQuill}
          current={format.highlight}
          canErase={canErase}
          onBack={() => switchColors(false)}
        />
      </div>
    );

  return (
    <div
      ref={formatting.ref}
      className="tb"
      role="toolbar"
      aria-label="Formatting"
      onFocus={formatting.onFocus}
      onKeyDown={formatting.onKeyDown}
    >
      {toolButton(
        `Undo (${modKey}Z)`,
        <Undo2 />,
        () => quill?.history?.undo?.(),
        {
          disabled: !canUndo,
        },
      )}
      {toolButton(
        `Redo (${isMac() ? "⇧⌘Z" : "Ctrl+Y"})`,
        <Redo2 />,
        () => quill?.history?.redo?.(),
        { disabled: !canRedo },
      )}
      {divider}
      {toolButton(
        `Bold (${modKey}B)`,
        <Bold />,
        () => quill && toggleInlineFormat(quill, "bold"),
        { active: !!format.bold, toggle: true, disabled: isInCode },
      )}
      {toolButton(
        `Italic (${modKey}I)`,
        <Italic />,
        () => quill && toggleInlineFormat(quill, "italic"),
        { active: !!format.italic, toggle: true, disabled: isInCode },
      )}
      {toolButton(
        `Underline (${modKey}U)`,
        <Underline />,
        () => quill && toggleInlineFormat(quill, "underline"),
        { active: !!format.underline, toggle: true, disabled: isInCode },
      )}
      {toolButton(
        "Strikethrough",
        <Strikethrough />,
        () => quill && toggleInlineFormat(quill, "strike"),
        { active: !!format.strike, toggle: true, disabled: isInCode },
      )}
      <HighlightSplitButton
        getQuill={getQuill}
        disabled={isInCode}
        onPhoneColors={() => switchColors(true)}
      />
      {divider}
      {toolButton(
        "Heading 1",
        <Heading1 />,
        () => quill && toggleHeader(quill, 1),
        {
          active: headerLevel === 1,
          toggle: true,
        },
      )}
      {toolButton(
        "Heading 2",
        <Heading2 />,
        () => quill && toggleHeader(quill, 2),
        {
          active: headerLevel === 2,
          toggle: true,
        },
      )}
      {toolButton(
        "Heading 3",
        <Heading3 />,
        () => quill && toggleHeader(quill, 3),
        {
          active: headerLevel === 3,
          toggle: true,
        },
      )}
      {divider}
      {toolButton(
        `Checklist (tick with ${isMac() ? "⌘↵" : "Ctrl+Enter"})`,
        <ListChecks />,
        () => quill && toggleList(quill, "unchecked"),
        { active: isChecklist, toggle: true },
      )}
      {toolButton(
        "Bullet list",
        <List />,
        () => quill && toggleList(quill, "bullet"),
        { active: listValue === LIST_FORMATS.BULLET, toggle: true },
      )}
      {toolButton(
        "Numbered list",
        <ListOrdered />,
        () => quill && toggleList(quill, "ordered"),
        { active: listValue === LIST_FORMATS.ORDERED, toggle: true },
      )}
      {toolButton(
        "Outdent (Shift+Tab)",
        <IndentDecrease />,
        () => changeIndent(-1),
        {
          disabled: !canOutdent,
        },
      )}
      {toolButton("Indent (Tab)", <IndentIncrease />, () => changeIndent(1), {
        disabled: !canIndent,
      })}
      {divider}
      {toolButton(
        "Quote",
        <Quote />,
        () => quill && toggleBlock(quill, "blockquote"),
        { active: !!format.blockquote, toggle: true },
      )}
      {toolButton(
        "Code block",
        <Code />,
        () => quill && toggleBlock(quill, "code-block"),
        { active: !!format["code-block"], toggle: true },
      )}
      {divider}
      {toolButton(
        `${format.link ? "Edit link" : "Link"} (${modKey}K)`,
        <LinkIcon />,
        onOpenLinkDialog,
        {
          active: !!format.link,
          toggle: true,
          disabled: isInCode,
        },
      )}
      {onAddAttachment &&
        toolButton("Add a picture or audio", <ImagePlus />, onAddAttachment)}
    </div>
  );
}
