"use client";

import { Copy, ExternalLink, Pencil, Unlink } from "lucide-react";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import type { LinkRange } from "../../link-utils";
import { linkAtIndex, normalizeUrl, siteAndPath } from "../../link-utils";
import type { QuillInstance } from "../../quill";

const SHOW_DELAY = 120;
const HIDE_DELAY = 220;
const GAP = 6;
const EDGE = 8;

interface LinkBubbleProps {
  getQuill: () => QuillInstance | null;
  container: HTMLDivElement | null;
  readOnly: boolean;
  onOpen: (url: string) => void;
  onCopy: (url: string) => void;
  onEdit: (link: LinkRange) => void;
  onRemove: (link: LinkRange) => void;
}

type BlotLookup = {
  scroll: { find: (node: Node) => unknown };
  getIndex: (blot: unknown) => number;
};

function indexOfNode(quill: QuillInstance, node: Node) {
  const lookup = quill as unknown as BlotLookup;
  const blot = lookup.scroll.find(node);
  return blot ? lookup.getIndex(blot) : -1;
}

function linkOfAnchor(quill: QuillInstance, anchor: HTMLAnchorElement | null) {
  if (!anchor?.isConnected) return null;
  const index = indexOfNode(quill, anchor);
  // One character in: a link right after this one would match its end.
  return index < 0 ? null : linkAtIndex(quill, index + 1);
}

function anchorAt(quill: QuillInstance | null, target: EventTarget | null) {
  const anchor =
    target instanceof Element ? target.closest<HTMLAnchorElement>("a") : null;
  return quill && anchor && quill.root.contains(anchor) ? anchor : null;
}

function caretLink(quill: QuillInstance) {
  if (!quill.root.contains(document.activeElement)) return null;
  const selection = quill.getSelection();
  return selection && !selection.length
    ? linkAtIndex(quill, selection.index)
    : null;
}

const isSameLink = (a: LinkRange | null, b: LinkRange | null) =>
  a === b ||
  (!!a &&
    !!b &&
    a.start === b.start &&
    a.length === b.length &&
    a.url === b.url);

function markOpen(quill: QuillInstance, link: LinkRange | null) {
  for (const anchor of quill.root.querySelectorAll("a")) {
    let isOpen = false;
    if (link) {
      const index = indexOfNode(quill, anchor);
      isOpen = index >= link.start && index < link.start + link.length;
    }
    if (anchor.classList.contains("open") !== isOpen)
      anchor.classList.toggle("open", isOpen);
  }
}

interface Live {
  quill: QuillInstance | null;
  container: HTMLDivElement | null;
  readOnly: boolean;
  shown: LinkRange | null;
  hoveredAnchor: HTMLAnchorElement | null;
  pinnedAnchor: HTMLAnchorElement | null;
  dismissed: LinkRange | null;
  isPointerInside: boolean;
  isFocusInside: boolean;
  timer: number;
}

export function LinkBubble({
  getQuill,
  container,
  readOnly,
  onOpen,
  onCopy,
  onEdit,
  onRemove,
}: LinkBubbleProps) {
  const [link, setLink] = React.useState<LinkRange | null>(null);
  const [focusRequest, setFocusRequest] = React.useState(0);
  const handledFocusRequest = React.useRef(0);
  const bubble = React.useRef<HTMLDivElement>(null);
  const live = React.useRef<Live>({
    quill: null,
    container: null,
    readOnly,
    shown: null,
    hoveredAnchor: null,
    pinnedAnchor: null,
    dismissed: null,
    isPointerInside: false,
    isFocusInside: false,
    timer: 0,
  });
  live.current.readOnly = readOnly;
  live.current.container = container;

  const refresh = React.useCallback(() => {
    const now = live.current;
    const quill = now.quill;
    if (now.isFocusInside || now.isPointerInside) return;
    if (!quill || (!now.readOnly && quill.getSelection()?.length)) {
      setLink(null);
      return;
    }
    const caret = now.readOnly ? null : caretLink(quill);
    const pinned = linkOfAnchor(quill, now.pinnedAnchor);
    if (!isSameLink(caret, now.dismissed) && !isSameLink(pinned, now.dismissed))
      now.dismissed = null;
    const unlessDismissed = (candidate: LinkRange | null) =>
      isSameLink(candidate, now.dismissed) ? null : candidate;
    const next =
      linkOfAnchor(quill, now.hoveredAnchor) ??
      unlessDismissed(pinned) ??
      unlessDismissed(caret);
    setLink((prev) => (isSameLink(prev, next) ? prev : next));
  }, []);

  const later = React.useCallback((delay: number, action: () => void) => {
    window.clearTimeout(live.current.timer);
    live.current.timer = window.setTimeout(action, delay);
  }, []);

  const hideSoon = React.useCallback(() => {
    later(HIDE_DELAY, () => {
      live.current.hoveredAnchor = null;
      refresh();
    });
  }, [later, refresh]);

  const place = React.useCallback(() => {
    const { quill, container: box, shown } = live.current;
    if (quill) markOpen(quill, shown);
    const el = bubble.current;
    if (!quill || !box || !el || !shown) return;
    const first = quill.getBounds(shown.start, 1);
    const whole = quill.getBounds(shown.start, shown.length);
    if (!first || !whole) return;
    const boxRect = box.getBoundingClientRect();
    const editorRect = quill.container.getBoundingClientRect();
    const linkTop = editorRect.top + first.top;
    const linkBottom = editorRect.top + whole.bottom;
    const viewport = window.visualViewport;
    let roomTop = EDGE;
    let roomBottom =
      (viewport ? viewport.offsetTop + viewport.height : window.innerHeight) -
      EDGE;
    const toolbar = box.parentElement
      ?.querySelector(".tb")
      ?.getBoundingClientRect();
    if (toolbar && toolbar.top >= linkBottom)
      roomBottom = Math.min(roomBottom, toolbar.top - EDGE);
    else if (toolbar && toolbar.bottom <= linkTop)
      roomTop = Math.max(roomTop, toolbar.bottom + EDGE);
    const height = el.offsetHeight;
    const isAbove =
      linkBottom + GAP + height > roomBottom &&
      linkTop - GAP - height >= roomTop;
    const top = isAbove ? linkTop - GAP - height : linkBottom + GAP;
    const left = Math.max(
      0,
      Math.min(
        boxRect.width - el.offsetWidth,
        editorRect.left + first.left - boxRect.left,
      ),
    );
    el.style.top = `${top - boxRect.top}px`;
    el.style.left = `${left}px`;
    el.dataset.side = isAbove ? "top" : "bottom";
  }, []);

  const hide = React.useCallback(() => {
    const now = live.current;
    window.clearTimeout(now.timer);
    now.hoveredAnchor = null;
    now.pinnedAnchor = null;
    now.isPointerInside = false;
    now.isFocusInside = false;
    setLink(null);
  }, []);

  const returnToText = React.useCallback((anchor: HTMLElement | null) => {
    const { quill, readOnly: isReadOnly } = live.current;
    if (!quill) return;
    if (!isReadOnly) quill.focus();
    else (anchor?.isConnected ? anchor : quill.root).focus();
  }, []);

  React.useEffect(() => {
    if (!container) return;
    const now = live.current;

    const onChange = () =>
      queueMicrotask(() => {
        refresh();
        place();
      });
    // Quill can be rebuilt under the same box; follow the current one.
    const attach = () => {
      const next = getQuill();
      if (next === now.quill) return;
      if (now.quill) {
        now.quill.off("editor-change", onChange);
        markOpen(now.quill, null);
      }
      now.quill = next;
      next?.on("editor-change", onChange);
      refresh();
    };
    attach();
    const observer = new MutationObserver(attach);
    observer.observe(container, { childList: true, subtree: true });
    const resizeObserver = new ResizeObserver(() => place());
    resizeObserver.observe(container);

    const onPointerOver = (e: PointerEvent) => {
      if (e.pointerType !== "mouse") return;
      const anchor = anchorAt(now.quill, e.target);
      if (!anchor) return;
      if (anchor === now.hoveredAnchor) {
        window.clearTimeout(now.timer);
        return;
      }
      const show = () => {
        now.hoveredAnchor = anchor;
        refresh();
      };
      if (now.shown) {
        window.clearTimeout(now.timer);
        show();
      } else later(SHOW_DELAY, show);
    };
    const onPointerOut = (e: PointerEvent) => {
      if (e.pointerType !== "mouse") return;
      const anchor = anchorAt(now.quill, e.target);
      const to = e.relatedTarget as Node | null;
      if (!anchor || anchor.contains(to) || bubble.current?.contains(to))
        return;
      hideSoon();
    };
    const onFocusIn = (e: FocusEvent) => {
      if (bubble.current?.contains(e.target as Node)) return;
      const anchor = now.readOnly ? anchorAt(now.quill, e.target) : null;
      if (anchor) now.pinnedAnchor = anchor;
      queueMicrotask(refresh);
    };
    const onFocusOut = (e: FocusEvent) => {
      const to = e.relatedTarget as Node | null;
      if (bubble.current?.contains(e.target as Node)) return;
      if (bubble.current?.contains(to)) return;
      if (e.target === now.pinnedAnchor) now.pinnedAnchor = null;
      window.setTimeout(refresh);
    };
    const onClick = (e: MouseEvent) => {
      const anchor = now.readOnly ? anchorAt(now.quill, e.target) : null;
      if (!anchor || e.ctrlKey || e.metaKey || e.shiftKey) return;
      e.preventDefault();
      now.pinnedAnchor = anchor;
      now.dismissed = null;
      window.clearTimeout(now.timer);
      refresh();
      if (e.detail === 0) setFocusRequest((n) => n + 1);
    };
    const onPointerDown = (e: PointerEvent) => {
      if (!now.pinnedAnchor) return;
      const target = e.target as Node;
      if (bubble.current?.contains(target) || anchorAt(now.quill, target))
        return;
      now.pinnedAnchor = null;
      refresh();
    };
    const onKeyDown = (e: KeyboardEvent) => {
      const quill = now.quill;
      if (!quill?.root.contains(e.target as Node) || e.isComposing) return;
      const hasModifier = e.ctrlKey || e.metaKey || e.shiftKey;
      const anchor = now.readOnly ? anchorAt(quill, e.target) : null;
      if (e.key === "Enter" && !hasModifier && (e.altKey || anchor)) {
        const targetLink = anchor
          ? linkOfAnchor(quill, anchor)
          : caretLink(quill);
        if (!targetLink) return;
        e.preventDefault();
        e.stopPropagation();
        if (anchor) now.pinnedAnchor = anchor;
        now.dismissed = null;
        window.clearTimeout(now.timer);
        refresh();
        setFocusRequest((n) => n + 1);
      } else if (e.key === "Escape" && now.shown) {
        now.dismissed = now.shown;
        hide();
      }
    };

    container.addEventListener("pointerover", onPointerOver);
    container.addEventListener("pointerout", onPointerOut);
    container.addEventListener("focusin", onFocusIn);
    container.addEventListener("focusout", onFocusOut);
    container.addEventListener("click", onClick);
    container.addEventListener("keydown", onKeyDown, true);
    document.addEventListener("pointerdown", onPointerDown, true);
    return () => {
      observer.disconnect();
      resizeObserver.disconnect();
      container.removeEventListener("pointerover", onPointerOver);
      container.removeEventListener("pointerout", onPointerOut);
      container.removeEventListener("focusin", onFocusIn);
      container.removeEventListener("focusout", onFocusOut);
      container.removeEventListener("click", onClick);
      container.removeEventListener("keydown", onKeyDown, true);
      document.removeEventListener("pointerdown", onPointerDown, true);
      window.clearTimeout(now.timer);
      if (now.quill) {
        now.quill.off("editor-change", onChange);
        markOpen(now.quill, null);
      }
      now.quill = null;
    };
  }, [container, getQuill, refresh, place, later, hideSoon, hide]);

  // biome-ignore lint/correctness/useExhaustiveDependencies: `readOnly` is the trigger; the state it resets lives in `live`
  React.useEffect(() => {
    live.current.pinnedAnchor = null;
    live.current.dismissed = null;
    refresh();
  }, [readOnly, refresh]);

  React.useLayoutEffect(() => {
    live.current.shown = link;
    place();
    if (link && focusRequest !== handledFocusRequest.current) {
      handledFocusRequest.current = focusRequest;
      bubble.current?.querySelector<HTMLElement>("button")?.focus();
    }
  }, [link, focusRequest, place]);

  if (!link) return null;
  const address = siteAndPath(link.url);
  const actionClass = "text-note-muted hover:text-foreground";
  return (
    <div
      ref={bubble}
      role="dialog"
      aria-label="Link"
      aria-keyshortcuts="Alt+Enter"
      className="lb float animate-pop-in data-[side=top]:animate-pop-up"
      // Keep the caret in the text.
      onMouseDown={(e) => e.preventDefault()}
      onPointerEnter={(e) => {
        if (e.pointerType !== "mouse") return;
        window.clearTimeout(live.current.timer);
        live.current.isPointerInside = true;
      }}
      onPointerLeave={(e) => {
        if (e.pointerType !== "mouse") return;
        live.current.isPointerInside = false;
        hideSoon();
      }}
      onFocus={() => {
        window.clearTimeout(live.current.timer);
        live.current.isFocusInside = true;
      }}
      onBlur={(e) => {
        if (e.currentTarget.contains(e.relatedTarget as Node)) return;
        live.current.isFocusInside = false;
        window.setTimeout(refresh);
      }}
      onKeyDown={(e) => {
        if (e.key === "Escape") {
          e.preventDefault();
          e.stopPropagation();
          const anchor = live.current.pinnedAnchor;
          live.current.dismissed = link;
          hide();
          returnToText(anchor);
          return;
        }
        if (e.key !== "Tab") return;
        e.preventDefault();
        const controls = [...e.currentTarget.querySelectorAll("button")];
        const next =
          controls[
            controls.indexOf(document.activeElement as HTMLButtonElement) +
              (e.shiftKey ? -1 : 1)
          ];
        if (next) next.focus();
        else returnToText(live.current.pinnedAnchor);
      }}
    >
      <span className="fav" aria-hidden>
        {address.match(/[\p{L}\p{N}]/u)?.[0].toUpperCase()}
      </span>
      <a
        className="url"
        href={normalizeUrl(link.url)}
        title={link.url}
        tabIndex={-1}
        onClick={(e) => {
          e.preventDefault();
          onOpen(link.url);
        }}
      >
        {address}
      </a>
      <span className="dv" aria-hidden />
      <IconButton
        size="sm"
        label="Open"
        tabIndex={-1}
        className={actionClass}
        onClick={() => onOpen(link.url)}
      >
        <ExternalLink />
      </IconButton>
      <IconButton
        size="sm"
        label="Copy link"
        tabIndex={-1}
        className={actionClass}
        onClick={() => onCopy(link.url)}
      >
        <Copy />
      </IconButton>
      {!readOnly && (
        <>
          <IconButton
            size="sm"
            label="Edit link"
            tabIndex={-1}
            className={actionClass}
            onClick={() => {
              hide();
              onEdit(link);
            }}
          >
            <Pencil />
          </IconButton>
          <IconButton
            size="sm"
            label="Remove link"
            tabIndex={-1}
            className={actionClass}
            onClick={() => {
              const hadFocus = live.current.isFocusInside;
              hide();
              onRemove(link);
              if (hadFocus) returnToText(null);
            }}
          >
            <Unlink />
          </IconButton>
        </>
      )}
    </div>
  );
}
