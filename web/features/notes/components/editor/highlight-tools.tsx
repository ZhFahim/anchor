"use client";

import * as PopoverPrimitive from "@radix-ui/react-popover";
import {
  Bold,
  ChevronDown,
  ChevronLeft,
  Eraser,
  Highlighter,
  Italic,
  Strikethrough,
  Underline,
} from "lucide-react";
import * as React from "react";
import { create } from "zustand";
import { menuSurface } from "@/components/ui/dropdown-menu";
import { Tip } from "@/components/ui/tooltip";
import { HIGHLIGHTS } from "@/lib/design/tokens";
import { useIsPhone } from "@/lib/hooks/use-is-phone";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { isMac } from "@/lib/platform";
import { cn } from "@/lib/utils";
import {
  getTextFormat,
  isInCodeBlock,
  type QuillInstance,
  rememberConversion,
  toggleTextFormat,
} from "../../quill";

export type HighlightColor = (typeof HIGHLIGHTS)[number];

const COLOR_NAMES: Record<HighlightColor, string> = {
  yellow: "Yellow",
  green: "Green",
  blue: "Blue",
  pink: "Pink",
  purple: "Purple",
};

const LAST_KEY = "anchor.highlight.last";

function readLast(): HighlightColor {
  try {
    const saved = localStorage.getItem(LAST_KEY) as HighlightColor | null;
    if (saved && HIGHLIGHTS.includes(saved)) return saved;
  } catch {}
  return "yellow";
}

const useLastHighlightColor = create<{
  color: HighlightColor;
  set: (color: HighlightColor) => void;
}>((set) => ({
  color: typeof window === "undefined" ? "yellow" : readLast(),
  set: (color) => {
    try {
      localStorage.setItem(LAST_KEY, color);
    } catch {}
    set({ color });
  },
}));

const highlightKeys = () => (isMac() ? "⇧⌘H" : "Ctrl+Shift+H");

const useColorsMenu = create<{ isOpen: boolean }>(() => ({ isOpen: false }));

function applyHighlight(quill: QuillInstance, color: HighlightColor) {
  const selection = quill.getSelection();
  if (!selection || isInCodeBlock(quill, selection)) return;
  const turnOff =
    getTextFormat(quill, selection.index, selection.length).highlight === color;
  if (selection.length)
    quill.formatText(
      selection.index,
      selection.length,
      "highlight",
      turnOff ? false : color,
      "user",
    );
  else quill.format("highlight", turnOff ? false : color, "user");
  if (!turnOff) useLastHighlightColor.getState().set(color);
}

/** Any highlight in the selection, or on the text typed at the caret. */
export function hasHighlight(
  quill: QuillInstance,
  selection: { index: number; length: number },
) {
  if (!selection.length)
    return !!getTextFormat(quill, selection.index, 0).highlight;
  return quill
    .getContents(selection.index, selection.length)
    .ops.some((op) => op.attributes?.highlight);
}

function removeHighlight(quill: QuillInstance) {
  const selection = quill.getSelection();
  if (!selection || isInCodeBlock(quill, selection)) return;
  if (selection.length)
    quill.formatText(
      selection.index,
      selection.length,
      "highlight",
      false,
      "user",
    );
  else quill.format("highlight", false, "user");
}

const keepSelection = (e: React.MouseEvent) => e.preventDefault();

function HighlightSwatches({
  current,
  onPick,
}: {
  current: unknown;
  onPick: (color: HighlightColor) => void;
}) {
  return (
    <>
      {HIGHLIGHTS.map((color) => (
        <Tip key={color} label={COLOR_NAMES[color]}>
          <button
            type="button"
            className="hl-dot"
            data-hl={color}
            aria-label={COLOR_NAMES[color]}
            aria-pressed={current === color}
            onMouseDown={keepSelection}
            onClick={() => onPick(color)}
          />
        </Tip>
      ))}
    </>
  );
}

export function HighlightSplitButton({
  getQuill,
  disabled,
  onPhoneColors,
}: {
  getQuill: () => QuillInstance | null;
  disabled?: boolean;
  onPhoneColors: () => void;
}) {
  const last = useLastHighlightColor((s) => s.color);
  const isPhone = useIsPhone();
  const [open, setOpen] = React.useState(false);
  // Read on open: the toolbar loses the formats once focus leaves the text.
  const [openColor, setOpenColor] = React.useState<unknown>(undefined);
  const [noteElement, setNoteElement] = React.useState<HTMLElement | null>(
    null,
  );
  const box = React.useRef<HTMLSpanElement>(null);
  const more = React.useRef<HTMLButtonElement>(null);
  const colors = React.useRef<HTMLDivElement>(null);
  const isOpenedByKeyboard = React.useRef(false);
  React.useEffect(
    () => setNoteElement(box.current?.closest<HTMLElement>(".note") ?? null),
    [],
  );
  React.useEffect(() => {
    useColorsMenu.setState({ isOpen: open });
    return () => useColorsMenu.setState({ isOpen: false });
  }, [open]);

  const openColors = (isByKeyboard: boolean) => {
    const quill = getQuill();
    const selection = quill?.getSelection();
    setOpenColor(
      quill && selection
        ? getTextFormat(quill, selection.index, selection.length).highlight
        : undefined,
    );
    isOpenedByKeyboard.current = isByKeyboard;
    setOpen(true);
  };
  const dots = () => [
    ...(colors.current?.querySelectorAll<HTMLButtonElement>(".hl-dot") ?? []),
  ];
  const isFocusInColors = () =>
    !!colors.current?.contains(document.activeElement);

  return (
    <PopoverPrimitive.Root open={open} onOpenChange={setOpen}>
      <PopoverPrimitive.Anchor asChild>
        <span ref={box} className="hl-split" data-hl={last}>
          <Tip label={isPhone ? undefined : `Highlight (${highlightKeys()})`}>
            <button
              type="button"
              className="b hl-main"
              aria-label={
                isPhone
                  ? "Highlight colors"
                  : `Highlight with ${COLOR_NAMES[last]} (${highlightKeys()})`
              }
              aria-disabled={disabled || undefined}
              onMouseDown={keepSelection}
              onClick={() => {
                if (disabled) return;
                if (isPhone) {
                  onPhoneColors();
                  return;
                }
                const quill = getQuill();
                if (quill) applyHighlight(quill, last);
              }}
            >
              <Highlighter aria-hidden />
              <span className="hl-bar" />
            </button>
          </Tip>
          {!isPhone && (
            <button
              ref={more}
              type="button"
              className="b hl-more"
              aria-label="Highlight colors"
              aria-expanded={open}
              aria-disabled={disabled || undefined}
              onMouseDown={keepSelection}
              onClick={(e) => {
                if (disabled) return;
                if (isPhone) onPhoneColors();
                else if (open) setOpen(false);
                // Enter or Space gives a click with no count.
                else openColors(e.detail === 0);
              }}
            >
              <ChevronDown aria-hidden />
            </button>
          )}
        </span>
      </PopoverPrimitive.Anchor>
      {/* Inside the note, whose styles set the colors. */}
      <PopoverPrimitive.Portal container={noteElement}>
        <PopoverPrimitive.Content
          ref={colors}
          role="group"
          aria-label="Highlight colors"
          align="start"
          sideOffset={6}
          onOpenAutoFocus={(e) => {
            e.preventDefault();
            if (!isOpenedByKeyboard.current) return;
            const list = dots();
            (
              list.find((dot) => dot.dataset.hl === openColor) ?? list[0]
            )?.focus();
          }}
          onCloseAutoFocus={(e) => e.preventDefault()}
          onEscapeKeyDown={() => {
            if (isFocusInColors()) more.current?.focus();
          }}
          onKeyDown={(e) => {
            const list = dots();
            const at = list.indexOf(
              document.activeElement as HTMLButtonElement,
            );
            if (at < 0) return;
            const step = {
              ArrowRight: 1,
              ArrowDown: 1,
              ArrowLeft: -1,
              ArrowUp: -1,
            }[e.key];
            if (step) {
              e.preventDefault();
              list[(at + step + list.length) % list.length].focus();
            } else if (e.key === "Home" || e.key === "End") {
              e.preventDefault();
              list[e.key === "Home" ? 0 : list.length - 1].focus();
            } else if (e.key === "Tab") {
              setOpen(false);
              more.current?.focus();
            }
          }}
          className={cn(
            menuSurface,
            "hl-pop rounded-menu animate-pop-in data-[side=top]:animate-pop-up data-[state=closed]:animate-pop-out data-[side=top]:data-[state=closed]:animate-pop-down-out",
          )}
        >
          <HighlightSwatches
            current={openColor}
            onPick={(color) => {
              const quill = getQuill();
              if (quill) applyHighlight(quill, color);
              setOpen(false);
            }}
          />
        </PopoverPrimitive.Content>
      </PopoverPrimitive.Portal>
    </PopoverPrimitive.Root>
  );
}

export function PhoneHighlightRow({
  getQuill,
  current,
  canErase,
  onBack,
}: {
  getQuill: () => QuillInstance | null;
  current: unknown;
  canErase: boolean;
  onBack: () => void;
}) {
  return (
    <>
      <button
        type="button"
        className="b"
        aria-label="Back to formatting"
        onMouseDown={keepSelection}
        onClick={onBack}
      >
        <ChevronLeft aria-hidden />
      </button>
      <HighlightSwatches
        current={current}
        onPick={(color) => {
          const quill = getQuill();
          if (quill) applyHighlight(quill, color);
        }}
      />
      <span className="dv" aria-hidden />
      <Tip label="Remove highlight">
        <button
          type="button"
          className="b"
          aria-label="Remove highlight"
          aria-disabled={!canErase || undefined}
          onMouseDown={keepSelection}
          onClick={() => {
            const quill = getQuill();
            if (quill && canErase) removeHighlight(quill);
          }}
        >
          <Eraser aria-hidden />
        </button>
      </Tip>
    </>
  );
}

interface Place {
  top: number;
  left: number;
  below: boolean;
}

const FORMATS = [
  { key: "bold", label: "Bold", icon: <Bold /> },
  { key: "italic", label: "Italic", icon: <Italic /> },
  { key: "underline", label: "Underline", icon: <Underline /> },
  { key: "strike", label: "Strikethrough", icon: <Strikethrough /> },
] as const;

export function SelectionToolbar({
  getQuill,
  container,
}: {
  getQuill: () => QuillInstance | null;
  container: HTMLDivElement | null;
}) {
  const [place, setPlace] = React.useState<Place | null>(null);
  const [format, setFormat] = React.useState<Record<string, unknown>>({});
  const [canErase, setCanErase] = React.useState(false);
  const isColorsMenuOpen = useColorsMenu((s) => s.isOpen);
  const roving = useRovingFocus<HTMLDivElement>();
  const bar = roving.ref;

  React.useEffect(() => {
    if (!container) return;
    let quill: QuillInstance | null = null;
    let followsScroll = false;
    const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");

    const show = () => {
      const selection = quill?.getSelection();
      followsScroll = false;
      if (
        !quill ||
        !selection?.length ||
        !finePointer.matches ||
        isInCodeBlock(quill, selection)
      ) {
        setPlace(null);
        return;
      }
      const bounds = quill.getBounds(selection.index, selection.length);
      if (!bounds) return;
      followsScroll = true;
      const box = container.getBoundingClientRect();
      const editorBox = quill.container.getBoundingClientRect();
      const top = editorBox.top - box.top + bounds.top;
      const width = bar.current?.offsetWidth ?? 330;
      const mid = editorBox.left - box.left + bounds.left + bounds.width / 2;
      const left = Math.max(0, Math.min(box.width - width, mid - width / 2));
      const toolbar = container.parentElement
        ?.querySelector(".tb")
        ?.getBoundingClientRect();
      const toolbarBottom = toolbar ? toolbar.bottom : 0;
      if (editorBox.top + bounds.bottom < toolbarBottom) {
        setPlace(null);
        return;
      }
      const below = box.top + top - 52 < toolbarBottom;
      setPlace({
        top: below ? editorBox.top - box.top + bounds.bottom + 8 : top - 8,
        left,
        below,
      });
      setFormat(getTextFormat(quill, selection.index, selection.length));
      setCanErase(hasHighlight(quill, selection));
    };

    const convertMarks = () => {
      const selection = quill?.getSelection();
      if (!quill || !selection || selection.length) return;
      if (quill.getFormat(selection.index, 0)["code-block"]) return;
      const [, offset] = quill.getLine(selection.index);
      const start = selection.index - offset;
      const match = /==(\S(?:[^=\n]*\S)?)==$/.exec(
        quill.getText(start, offset),
      );
      if (!match) return;
      const from = start + match.index;
      quill.history.cutoff();
      quill.deleteText(selection.index - 2, 2, "user");
      quill.deleteText(from, 2, "user");
      quill.formatText(from, match[1].length, "highlight", "yellow", "user");
      quill.history.cutoff();
      quill.setSelection(from + match[1].length, 0, "silent");
      quill.format("highlight", false, "api");
      rememberConversion(quill);
    };

    const onChange = (name: string, ...args: unknown[]) => {
      if (name === "text-change") {
        const [delta, , source] = args as [
          { ops: { insert?: unknown }[] },
          unknown,
          string,
        ];
        if (
          source === "user" &&
          !quill?.history.ignoreChange &&
          delta.ops.some((op) => op.insert === "=")
        )
          queueMicrotask(convertMarks);
      }
      queueMicrotask(show);
    };

    // Quill fires no selection-change when the same text is selected again.
    let frame = 0;
    const onScroll = () => {
      if (!followsScroll || frame) return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        show();
      });
    };

    const onKey = (e: KeyboardEvent) => {
      // Radix prevents the Esc that closed the colors; the bar stays then.
      if (e.key === "Escape" && !e.defaultPrevented) {
        followsScroll = false;
        setPlace(null);
      }
      const isSelectingKey =
        (e.shiftKey && /^(Arrow|Home$|End$|Page)/.test(e.key)) ||
        ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "a");
      if (isSelectingKey) window.setTimeout(show);
      if (
        !(e.ctrlKey || e.metaKey) ||
        !e.shiftKey ||
        e.code !== "KeyH" ||
        !quill
      )
        return;
      e.preventDefault();
      applyHighlight(quill, useLastHighlightColor.getState().color);
      show();
    };
    let isSelectingWithPointer = false;
    const onPointerDown = (e: PointerEvent) => {
      isSelectingWithPointer = !!quill?.root.contains(e.target as Node);
    };
    const onPointerUp = () => {
      if (!isSelectingWithPointer) return;
      isSelectingWithPointer = false;
      window.setTimeout(show);
    };

    // Quill can be rebuilt under the same box; follow the current one.
    const attach = () => {
      const next = getQuill();
      if (next === quill) return;
      quill?.off("editor-change", onChange);
      quill = next;
      quill?.on("editor-change", onChange);
    };
    attach();
    const observer = new MutationObserver(attach);
    observer.observe(container, { childList: true, subtree: true });
    container.addEventListener("keydown", onKey);
    container.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("pointerup", onPointerUp);
    document.addEventListener("scroll", onScroll, true);
    return () => {
      observer.disconnect();
      cancelAnimationFrame(frame);
      container.removeEventListener("keydown", onKey);
      container.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("pointerup", onPointerUp);
      document.removeEventListener("scroll", onScroll, true);
      quill?.off("editor-change", onChange);
    };
  }, [container, getQuill, bar]);

  const run = (
    fn: (
      quill: QuillInstance,
      selection: { index: number; length: number },
    ) => void,
  ) => {
    const quill = getQuill();
    const selection = quill?.getSelection();
    if (!quill || !selection) return;
    fn(quill, selection);
    setFormat(getTextFormat(quill, selection.index, selection.length));
    setCanErase(hasHighlight(quill, selection));
  };

  if (!place || isColorsMenuOpen) return null;
  return (
    <div
      ref={bar}
      className={cn(
        "hl-bubble float",
        place.below ? "animate-pop-in" : "animate-pop-up",
      )}
      role="toolbar"
      aria-label="Format selection"
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
      style={{
        top: place.top,
        left: place.left,
        // The pop animation sets `transform`.
        translate: place.below ? undefined : "0 -100%",
      }}
      onMouseDown={keepSelection}
    >
      <HighlightSwatches
        current={format.highlight}
        onPick={(color) => run((quill) => applyHighlight(quill, color))}
      />
      <span className="dv" aria-hidden />
      {FORMATS.map((option) => (
        <Tip key={option.key} label={option.label}>
          <button
            type="button"
            className="fb"
            aria-label={option.label}
            aria-pressed={!!format[option.key]}
            onClick={() =>
              run((quill, selection) =>
                toggleTextFormat(quill, selection, option.key),
              )
            }
          >
            {option.icon}
          </button>
        </Tip>
      ))}
      <span className="dv" aria-hidden />
      <Tip label="Remove highlight">
        <button
          type="button"
          className="fb"
          aria-label="Remove highlight"
          aria-disabled={!canErase || undefined}
          onClick={() => canErase && run((quill) => removeHighlight(quill))}
        >
          <Eraser aria-hidden />
        </button>
      </Tip>
    </div>
  );
}
