"use client";

import { Check, Copy } from "lucide-react";
import * as React from "react";
import { copyText } from "@/lib/clipboard";

interface Spot {
  top: number;
  right: number;
}

const BLOCKS = ".ql-editor .ql-code-block-container";

/** Quill owns the code blocks' markup; the buttons sit in a layer over them. */
export function CodeCopyButtons({
  container,
}: {
  container: HTMLDivElement | null;
}) {
  const [spots, setSpots] = React.useState<Spot[]>([]);
  const [hover, setHover] = React.useState(-1);
  const [status, setStatus] = React.useState<{
    index: number;
    word: string;
  } | null>(null);

  React.useEffect(() => {
    if (!container) return;
    let frame = 0;
    const measure = () => {
      frame = 0;
      const readOnly = container.querySelector(
        '.ql-editor[contenteditable="false"]',
      );
      for (const el of container.querySelectorAll<HTMLElement>(BLOCKS)) {
        if (!readOnly || el.tabIndex === 0) continue;
        el.tabIndex = 0;
        el.setAttribute("role", "group");
        el.setAttribute("aria-label", "Code");
      }
      const box = container.getBoundingClientRect();
      const next = [...container.querySelectorAll<HTMLElement>(BLOCKS)].map(
        (el) => {
          const rect = el.getBoundingClientRect();
          return { top: rect.top - box.top, right: box.right - rect.right };
        },
      );
      setSpots((prev) =>
        prev.length === next.length &&
        prev.every((p, i) => p.top === next[i].top && p.right === next[i].right)
          ? prev
          : next,
      );
    };
    const measureSoon = () => {
      frame ||= requestAnimationFrame(measure);
    };
    const move = (e: PointerEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest(".copy")) return;
      const block = target.closest(BLOCKS.split(" ")[1]);
      setHover(
        block ? [...container.querySelectorAll(BLOCKS)].indexOf(block) : -1,
      );
    };
    const leave = () => setHover(-1);
    measure();
    const mutationObserver = new MutationObserver(measureSoon);
    mutationObserver.observe(container, {
      childList: true,
      subtree: true,
      characterData: true,
    });
    const resizeObserver = new ResizeObserver(measureSoon);
    resizeObserver.observe(container);
    container.addEventListener("pointermove", move);
    container.addEventListener("pointerleave", leave);
    return () => {
      cancelAnimationFrame(frame);
      mutationObserver.disconnect();
      resizeObserver.disconnect();
      container.removeEventListener("pointermove", move);
      container.removeEventListener("pointerleave", leave);
    };
  }, [container]);

  React.useEffect(() => {
    if (!status) return;
    const timer = window.setTimeout(() => setStatus(null), 1600);
    return () => window.clearTimeout(timer);
  }, [status]);

  const copy = (index: number) => {
    const block = container?.querySelectorAll<HTMLElement>(BLOCKS)[index];
    if (!block) return;
    const text = [...block.querySelectorAll(".ql-code-block")]
      .map((line) => line.textContent ?? "")
      .join("\n");
    const select = () => {
      const range = document.createRange();
      range.selectNodeContents(block);
      const sel = getSelection();
      sel?.removeAllRanges();
      sel?.addRange(range);
      setStatus({ index, word: "Selected" });
    };
    copyText(text).then(() => setStatus({ index, word: "Copied" }), select);
  };

  return (
    <>
      {spots.map((spot, i) => (
        <button
          key={i}
          type="button"
          className="copy"
          data-show={hover === i || status?.index === i || undefined}
          style={{ top: spot.top + 8, right: spot.right + 8 }}
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => copy(i)}
        >
          {status?.index === i ? <Check aria-hidden /> : <Copy aria-hidden />}
          <span aria-live="polite">
            {status?.index === i ? status.word : "Copy"}
          </span>
        </button>
      ))}
    </>
  );
}
