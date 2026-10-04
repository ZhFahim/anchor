"use client";

import * as React from "react";
import { createPortal } from "react-dom";
import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";
import { onUserScroll } from "@/lib/user-scroll";
import { cn } from "@/lib/utils";
import { toolbarTop } from "./toolbar-top";

const HEADING_GAP = 24;
const MAX_DASHES = 120;

interface Heading {
  level: number;
  text: string;
  el: HTMLElement;
}

export function NoteOutline({
  root,
}: {
  root: React.RefObject<HTMLElement | null>;
}) {
  const [noteElement, setNoteElement] = React.useState<HTMLElement | null>(
    null,
  );
  const [headings, setHeadings] = React.useState<Heading[]>([]);
  const [isLong, setIsLong] = React.useState(false);
  const [current, setCurrent] = React.useState(0);
  const [open, setOpen] = React.useState(false);
  const heldHeadingRef = React.useRef<number | null>(null);
  const list = React.useRef<HTMLDivElement>(null);
  const nav = React.useRef<HTMLElement>(null);
  const peek = React.useRef<HTMLButtonElement>(null);
  const listId = React.useId();

  React.useEffect(() => {
    const note = root.current?.closest<HTMLElement>(".note") ?? null;
    const scroller = root.current?.closest<HTMLElement>(".ed-scroll");
    const body = root.current;
    setNoteElement(note);
    if (!scroller || !body) return;
    let frame = 0;
    let found: Heading[] = [];

    const updateCurrent = () => {
      if (heldHeadingRef.current !== null) return;
      const top = scroller.getBoundingClientRect().top;
      let currentIndex = 0;
      let low = 0;
      let high = found.length - 1;
      while (low <= high) {
        const middle = (low + high) >> 1;
        if (found[middle].el.getBoundingClientRect().top - top <= 140) {
          currentIndex = middle;
          low = middle + 1;
        } else high = middle - 1;
      }
      if (
        scroller.scrollTop + scroller.clientHeight >=
        scroller.scrollHeight - 2
      )
        currentIndex = Math.max(0, found.length - 1);
      setCurrent(currentIndex);
    };
    const readHeadings = () => {
      frame = 0;
      found = [
        ...body.querySelectorAll<HTMLElement>(".ql-editor :is(h1, h2, h3)"),
      ]
        .map((el) => ({
          level: Number(el.tagName[1]),
          text: el.textContent?.trim() ?? "",
          el,
        }))
        .filter((h) => h.text);
      setHeadings((prev) =>
        prev.length === found.length &&
        prev.every(
          (heading, i) =>
            heading.text === found[i].text &&
            heading.level === found[i].level &&
            heading.el === found[i].el,
        )
          ? prev
          : found,
      );
      setIsLong(scroller.scrollHeight > scroller.clientHeight + 200);
      updateCurrent();
    };
    const readSoon = () => {
      frame ||= requestAnimationFrame(readHeadings);
    };
    readHeadings();
    const mutationObserver = new MutationObserver(readSoon);
    mutationObserver.observe(body, {
      childList: true,
      subtree: true,
      characterData: true,
    });
    const resizeObserver = new ResizeObserver(readSoon);
    resizeObserver.observe(scroller);
    scroller.addEventListener("scroll", updateCurrent, { passive: true });
    const stopWatching = onUserScroll(
      scroller,
      () => {
        heldHeadingRef.current = null;
      },
      "nav.outline",
    );
    return () => {
      cancelAnimationFrame(frame);
      mutationObserver.disconnect();
      resizeObserver.disconnect();
      scroller.removeEventListener("scroll", updateCurrent);
      stopWatching();
    };
  }, [root]);

  React.useEffect(() => {
    if (!open) return;
    const closeIfOutside = (e: PointerEvent) => {
      if (!nav.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("pointerdown", closeIfOutside);
    return () => document.removeEventListener("pointerdown", closeIfOutside);
  }, [open]);

  const jump = (index: number, byKeyboard: boolean) => {
    const scroller = root.current?.closest<HTMLElement>(".ed-scroll");
    const article = scroller?.closest<HTMLElement>(".ed");
    if (!scroller || !article) return;
    const heading = headings[index].el;
    heldHeadingRef.current = index;
    setCurrent(index);
    const at =
      heading.getBoundingClientRect().top -
      scroller.getBoundingClientRect().top +
      scroller.scrollTop;
    // The header hides while scrolling down and comes back on the way up.
    const toolbarHeight =
      article.querySelector<HTMLElement>(".tb")?.offsetHeight ?? 0;
    const below = (isHeadHidden: boolean) =>
      at - toolbarTop(article, isHeadHidden) - toolbarHeight - HEADING_GAP;
    const goingDown = below(true) >= scroller.scrollTop;
    const top = Math.min(
      Math.max(0, below(goingDown)),
      scroller.scrollHeight - scroller.clientHeight,
    );
    const tintOnce = () => {
      if (heldHeadingRef.current === index) tintHeading(heading);
    };
    if (Math.abs(top - scroller.scrollTop) < 1) tintOnce();
    else if ("onscrollend" in window)
      scroller.addEventListener("scrollend", tintOnce, { once: true });
    else setTimeout(tintOnce, DURATION.paint);
    scroller.scrollTo({
      top,
      behavior: prefersReducedMotion() ? "auto" : "smooth",
    });
    setOpen(false);
    if (byKeyboard) peek.current?.focus();
  };

  const showCurrent = () =>
    list.current
      ?.querySelector("[aria-current]")
      ?.scrollIntoView({ block: "nearest" });
  // biome-ignore lint/correctness/useExhaustiveDependencies: only when it opens
  React.useEffect(() => {
    if (open) showCurrent();
  }, [open]);

  const dashes = React.useMemo(() => {
    const size = Math.max(1, headings.length / MAX_DASHES);
    const count = Math.min(headings.length, MAX_DASHES);
    return Array.from({ length: count }, (_, i) => {
      const first = Math.floor(i * size);
      const last = Math.max(first, Math.floor((i + 1) * size) - 1);
      let level = 3;
      for (let j = first; j <= last; j++)
        level = Math.min(level, headings[j].level);
      return { first, last, level };
    });
  }, [headings]);

  if (!noteElement || headings.length < 2 || !isLong) return null;
  return createPortal(
    <nav
      ref={nav}
      className={cn("outline", open && "open")}
      aria-label="Outline"
      onKeyDown={(e) => {
        if (e.key === "Escape" && open) {
          e.stopPropagation();
          setOpen(false);
          peek.current?.focus();
        }
      }}
      onBlur={(e) => {
        if (!nav.current?.contains(e.relatedTarget as Node)) setOpen(false);
      }}
      onPointerEnter={showCurrent}
    >
      <button
        ref={peek}
        type="button"
        className="ol-peek"
        aria-expanded={open}
        aria-controls={listId}
        aria-label={`Outline, ${headings.length} headings`}
        onClick={() => setOpen((o) => !o)}
      >
        {dashes.map((dash, i) => (
          <span
            key={i}
            className={cn(
              "dash",
              current >= dash.first && current <= dash.last && "on",
            )}
            data-l={dash.level}
          />
        ))}
      </button>
      <div ref={list} className="ol-list" id={listId}>
        {headings.map((heading, i) => (
          <button
            key={i}
            type="button"
            data-l={heading.level}
            className={cn(i === current && "on")}
            aria-current={i === current || undefined}
            onClick={(e) => jump(i, e.detail === 0)}
          >
            <span className="lab">{heading.text}</span>
            <span className="dash" />
          </button>
        ))}
      </div>
    </nav>,
    noteElement,
  );
}

function tintHeading(heading: HTMLElement) {
  const host = heading.closest<HTMLElement>(".note-in");
  if (!host) return;
  const box = heading.getBoundingClientRect();
  const hostBox = host.getBoundingClientRect();
  const tint = document.createElement("div");
  tint.className = "heading-tint";
  Object.assign(tint.style, {
    left: `${box.left - hostBox.left}px`,
    top: `${box.top - hostBox.top}px`,
    width: `${box.width}px`,
    height: `${box.height}px`,
  });
  host.append(tint);
  const remove = () => tint.remove();
  tint
    .animate([{ opacity: 1 }, { opacity: 1, offset: 0.4 }, { opacity: 0 }], {
      duration: DURATION.flash,
      easing: EASE.standard,
    })
    .finished.then(remove, remove);
}
