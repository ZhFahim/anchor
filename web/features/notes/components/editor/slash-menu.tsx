"use client";

import {
  Code,
  Heading1,
  Heading2,
  Heading3,
  ImagePlus,
  Link,
  List,
  ListChecks,
  ListOrdered,
  Quote,
  Type,
} from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { menuItem, menuSurface } from "@/components/ui/dropdown-menu";
import { ShortcutHints } from "@/components/ui/shortcut-hints";
import type { Messages } from "@/i18n/messages";
import { isPhoneWidth } from "@/lib/hooks/use-is-phone";
import { cn } from "@/lib/utils";
import { lineFormatChange, type QuillInstance } from "../../quill";
import { findSlashItems } from "../../slash-search";

type Kind =
  | "checklist"
  | "heading1"
  | "heading2"
  | "heading3"
  | "bullets"
  | "numbers"
  | "quote"
  | "code"
  | "text"
  | "link"
  | "attachment";

const ITEMS: {
  kind: Kind;
  label: keyof Messages;
  icon: React.ReactNode;
  words: keyof Messages;
  englishWords: string;
  isPopular?: boolean;
  format?: Record<string, unknown>;
}[] = [
  {
    kind: "checklist",
    label: "editorChecklist",
    icon: <ListChecks />,
    words: "editorSlashWordsChecklist",
    englishWords: "checklist todo to-do task checkbox list",
    isPopular: true,
    format: { list: "unchecked" },
  },
  {
    kind: "heading1",
    label: "editorHeading1",
    icon: <Heading1 />,
    words: "editorSlashWordsHeading1",
    englishWords: "heading 1 h1 title",
    isPopular: true,
    format: { header: 1 },
  },
  {
    kind: "heading2",
    label: "editorHeading2",
    icon: <Heading2 />,
    words: "editorSlashWordsHeading2",
    englishWords: "heading 2 h2 subtitle subheading",
    format: { header: 2 },
  },
  {
    kind: "heading3",
    label: "editorHeading3",
    icon: <Heading3 />,
    words: "editorSlashWordsHeading3",
    englishWords: "heading 3 h3 subheading",
    format: { header: 3 },
  },
  {
    kind: "bullets",
    label: "editorBulletList",
    icon: <List />,
    words: "editorSlashWordsBullets",
    englishWords: "bullet list unordered ul dashes",
    isPopular: true,
    format: { list: "bullet" },
  },
  {
    kind: "numbers",
    label: "editorNumberedList",
    icon: <ListOrdered />,
    words: "editorSlashWordsNumbers",
    englishWords: "numbered list ordered ol",
    isPopular: true,
    format: { list: "ordered" },
  },
  {
    kind: "quote",
    label: "editorQuote",
    icon: <Quote />,
    words: "editorSlashWordsQuote",
    englishWords: "quote blockquote citation",
    isPopular: true,
    format: { blockquote: true },
  },
  {
    kind: "code",
    label: "editorCodeBlock",
    icon: <Code />,
    words: "editorSlashWordsCode",
    englishWords: "code block pre snippet",
    format: { "code-block": "plain" },
  },
  {
    kind: "text",
    label: "editorText",
    icon: <Type />,
    words: "editorSlashWordsText",
    englishWords: "text paragraph plain normal body",
    format: {},
  },
  {
    kind: "link",
    label: "editorLink",
    icon: <Link />,
    words: "editorSlashWordsLink",
    englishWords: "link url web address",
  },
  {
    kind: "attachment",
    label: "editorPictureOrAudio",
    icon: <ImagePlus />,
    words: "editorSlashWordsAttachment",
    englishWords:
      "picture or audio image img photo file voice recording attachment",
    isPopular: true,
  },
];

interface Slash {
  index: number;
  query: string;
}

interface Place {
  top: number;
  left: number;
  height: number;
}

interface SlashMenuProps {
  getQuill: () => QuillInstance | null;
  container: HTMLDivElement | null;
  onAddAttachment?: () => void;
  onAddLink: () => void;
}

export const isSlashMenuOpen = (root: HTMLElement) =>
  root.hasAttribute("aria-controls");

export function SlashMenu({
  getQuill,
  container,
  onAddAttachment,
  onAddLink,
}: SlashMenuProps) {
  const t = useTranslations();
  const [slash, setSlash] = React.useState<Slash | null>(null);
  const [place, setPlace] = React.useState<Place | null>(null);
  const [hint, setHint] = React.useState<Place | null>(null);
  const [searchHint, setSearchHint] = React.useState<Place | null>(null);
  const [active, setActive] = React.useState(0);
  const [keyboard, setKeyboard] = React.useState(false);
  const [above, setAbove] = React.useState(false);
  const slashRef = React.useRef<Slash | null>(null);
  const menu = React.useRef<HTMLDivElement>(null);
  const listId = React.useId();

  const items = React.useMemo(
    () =>
      findSlashItems(
        ITEMS.filter(
          (item) => item.kind !== "attachment" || onAddAttachment,
        ).map((item) => ({
          kind: item.kind,
          icon: item.icon,
          label: t(item.label),
          keywords: `${t(item.words)} ${item.englishWords}`,
          isPopular: item.isPopular,
        })),
        slash?.query ?? "",
      ),
    [slash?.query, onAddAttachment, t],
  );
  const activeIndex = Math.min(active, Math.max(0, items.length - 1));

  const updateSlash = React.useCallback((next: Slash | null) => {
    slashRef.current = next;
    setSlash(next);
  }, []);

  const placeAt = React.useCallback(
    (quill: QuillInstance, index: number): Place | null => {
      if (!container) return null;
      const bounds = quill.getBounds(index);
      if (!bounds) return null;
      const box = container.getBoundingClientRect();
      const editorBox = quill.container.getBoundingClientRect();
      return {
        top: editorBox.top - box.top + bounds.top,
        left: editorBox.left - box.left + bounds.left,
        height: bounds.height,
      };
    },
    [container],
  );

  React.useEffect(() => {
    if (!container) return;
    let quill: QuillInstance | null = null;

    const update = (typed: boolean) => {
      if (!quill) return;
      const selection = quill.getSelection();
      if (!selection || selection.length) {
        updateSlash(null);
        setHint(null);
        setSearchHint(null);
        return;
      }
      const [line, offset] = quill.getLine(selection.index);
      if (!line) return;
      const start = selection.index - offset;
      const format = line.formats();
      const current = slashRef.current;
      if (current) {
        const command =
          current.index >= start && current.index < selection.index
            ? quill.getText(current.index, selection.index - current.index)
            : "";
        const query = command.slice(1);
        if (!command.startsWith("/") || /^\s/.test(query) || query.length > 24)
          updateSlash(null);
        else if (query !== current.query) {
          updateSlash({ index: current.index, query });
          setActive(0);
        }
      } else if (typed && offset > 0 && !format["code-block"]) {
        const before = quill.getText(start, offset);
        if (before.endsWith("/") && /^\s?$/.test(before.slice(-2, -1))) {
          const index = selection.index - 1;
          updateSlash({ index, query: "" });
          setActive(0);
          setKeyboard(false);
          setPlace(placeAt(quill, index));
        }
      }
      const isAtLineEnd = offset === line.length() - 1;
      setSearchHint(
        slashRef.current && !slashRef.current.query && isAtLineEnd
          ? placeAt(quill, selection.index)
          : null,
      );
      const plain =
        !format.list &&
        !format.header &&
        !format.blockquote &&
        !format["code-block"];
      const empty = line.length() === 1 && plain && quill.getLength() > 1;
      setHint(
        empty && !slashRef.current ? placeAt(quill, selection.index) : null,
      );
    };

    const onChange = (name: string, ...args: unknown[]) => {
      if (name === "text-change") {
        const [delta, , source] = args as [
          { ops: { insert?: unknown }[] },
          unknown,
          string,
        ];
        const typed =
          source === "user" && delta.ops.some((op) => op.insert === "/");
        // Quill settles the selection after the change.
        queueMicrotask(() => update(typed));
      } else update(false);
    };

    // Quill is rebuilt under the same box in strict mode; follow the current one.
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
    return () => {
      observer.disconnect();
      quill?.off("editor-change", onChange);
    };
  }, [container, getQuill, placeAt, updateSlash]);

  const pick = React.useCallback(
    (kind: Kind) => {
      const quill = getQuill();
      const current = slashRef.current;
      const item = ITEMS.find((i) => i.kind === kind);
      if (!quill || !current || !item) return;
      updateSlash(null);
      setSearchHint(null);
      const [line, offset] = quill.getLine(current.index);
      if (!line) return;
      const length = 1 + current.query.length;
      const end = current.index + length;
      const lineEnd = current.index - offset + line.length() - 1;
      const formats = line.formats();
      const dropsSpace =
        !!item.format &&
        offset > 1 &&
        quill.getText(current.index - 1, 1) === " " &&
        (end === lineEnd || quill.getText(end, 1) === " ");
      const from = dropsSpace ? current.index - 1 : current.index;
      quill.history.cutoff();
      quill.deleteText(from, end - from, "user");
      if (!item.format) {
        quill.history.cutoff();
        quill.setSelection(from, 0, "silent");
        if (kind === "attachment") onAddAttachment?.();
        else if (kind === "link") onAddLink();
        return;
      }
      const newLineEnd = lineEnd - (end - from);
      quill.updateContents(
        {
          ops: [
            ...(newLineEnd ? [{ retain: newLineEnd }] : []),
            { retain: 1, attributes: lineFormatChange(formats, item.format) },
          ],
        },
        "user",
      );
      quill.history.cutoff();
      quill.setSelection(from, 0, "user");
    },
    [getQuill, onAddAttachment, onAddLink, updateSlash],
  );

  // Keys go to the menu before the editor sees them.
  React.useEffect(() => {
    if (!container || !slash) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.isComposing) return;
      const move = { ArrowDown: 1, ArrowUp: -1 }[e.key];
      if (e.key === "Escape") {
        updateSlash(null);
        setSearchHint(null);
      } else if (!items.length) return;
      else if (move) {
        setKeyboard(true);
        setActive(
          (prev) =>
            (Math.min(prev, items.length - 1) + move + items.length) %
            items.length,
        );
      } else if (e.key === "Enter" || e.key === "Tab")
        pick(items[activeIndex].kind);
      else return;
      e.preventDefault();
      e.stopPropagation();
    };
    container.addEventListener("keydown", onKey, true);
    return () => container.removeEventListener("keydown", onKey, true);
  }, [container, slash, items, activeIndex, pick, updateSlash]);

  React.useEffect(() => {
    if (slash && !items.length && /\s$/.test(slash.query)) updateSlash(null);
  }, [slash, items.length, updateSlash]);

  React.useEffect(() => {
    const root = getQuill()?.root;
    if (!root) return;
    if (!slash || !items.length) {
      root.removeAttribute("aria-activedescendant");
      root.removeAttribute("aria-controls");
      return;
    }
    root.setAttribute("aria-controls", listId);
    root.setAttribute("aria-activedescendant", `${listId}-${activeIndex}`);
  }, [slash, items.length, activeIndex, listId, getQuill]);

  React.useLayoutEffect(() => {
    if (!slash || !menu.current || !container || !place) return;
    const menuHeight = menu.current.offsetHeight + 14;
    const lineTop = container.getBoundingClientRect().top + place.top;
    const toolbarHeight = isPhoneWidth() ? 64 : 0;
    setAbove(
      window.innerHeight - toolbarHeight - (lineTop + place.height) <
        menuHeight && lineTop > menuHeight,
    );
  }, [slash, place, container]);

  return (
    <>
      {hint && !slash && (
        <span
          aria-hidden
          className="slash-hint"
          style={{
            top: hint.top,
            left: hint.left,
            height: hint.height,
            lineHeight: `${hint.height}px`,
          }}
        >
          {t("editorSlashHint")}
        </span>
      )}
      {searchHint && slash && (
        <span
          aria-hidden
          className="slash-hint"
          style={{
            top: searchHint.top,
            left: searchHint.left,
            height: searchHint.height,
            lineHeight: `${searchHint.height}px`,
          }}
        >
          {t("editorSlashSearchHint")}
        </span>
      )}
      {slash && place && (
        <div
          ref={menu}
          className={cn(
            menuSurface,
            "absolute z-(--z-float) grid w-62.5 max-w-[calc(100%-8px)] gap-px rounded-menu p-1.5 animate-pop-in",
          )}
          style={
            above
              ? {
                  bottom: `calc(100% - ${place.top}px + 6px)`,
                  left: place.left,
                }
              : { top: place.top + place.height + 6, left: place.left }
          }
          onMouseDown={(e) => e.preventDefault()}
        >
          {items.length ? (
            <div
              role="listbox"
              id={listId}
              data-slot="slash-menu"
              aria-label={t("editorSlashMenu")}
              className="grid gap-px"
            >
              {items.map((item, i) => (
                <div
                  key={item.kind}
                  id={`${listId}-${i}`}
                  role="option"
                  tabIndex={-1}
                  aria-selected={i === activeIndex}
                  data-kbd={(keyboard && i === activeIndex) || undefined}
                  data-highlighted={i === activeIndex ? "" : undefined}
                  onPointerMove={() => {
                    setKeyboard(false);
                    setActive(i);
                  }}
                  onClick={() => pick(item.kind)}
                  className={cn(
                    menuItem,
                    "data-kbd:after:absolute data-kbd:after:top-1/2 data-kbd:after:left-0.75 data-kbd:after:-mt-2 data-kbd:after:h-4 data-kbd:after:w-0.75 data-kbd:after:rounded-xs data-kbd:after:bg-accent-strong data-kbd:after:content-['']",
                  )}
                >
                  {item.icon}
                  {item.label}
                </div>
              ))}
            </div>
          ) : (
            <div role="status" className="px-2 py-1.5 text-muted-foreground">
              {t("editorSlashNoResults")}
            </div>
          )}
          {items.length > 0 && (
            <div className="mt-1 flex items-center border-border/55 border-t px-1.5 pt-2 pb-0.5 text-caption text-muted-foreground max-md:hidden">
              <ShortcutHints
                groups={[
                  [["↑", "↓"], t("editorSlashMove")],
                  [["↵"], t("editorSlashAdd")],
                ]}
                screenReaderText={t("editorSlashKeys")}
              />
            </div>
          )}
        </div>
      )}
    </>
  );
}
