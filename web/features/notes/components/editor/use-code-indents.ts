"use client";

import { useEffect } from "react";
import { codeIndentColumns } from "../../code-lines";

const INDENT = "--code-indent";

function markIndents(root: HTMLElement) {
  for (const line of root.querySelectorAll<HTMLElement>(".ql-code-block")) {
    const columns = codeIndentColumns(line.textContent ?? "");
    const value = columns ? String(columns) : "";
    if (line.style.getPropertyValue(INDENT) === value) continue;
    if (value) line.style.setProperty(INDENT, value);
    else {
      line.style.removeProperty(INDENT);
      if (!line.style.length) line.removeAttribute("style");
    }
  }
}

export function useCodeIndents({
  containerEl,
}: {
  containerEl: HTMLElement | null;
}) {
  useEffect(() => {
    const host = containerEl;
    if (!host) return;
    let watched: HTMLElement | null = null;
    let frame = 0;
    let isComposing = false;
    const mark = () => {
      frame = 0;
      if (watched && !isComposing) markIndents(watched);
    };
    const markSoon = () => {
      frame ||= requestAnimationFrame(mark);
    };
    const rootObserver = new MutationObserver(markSoon);
    // Follows the editor's text box if Quill rebuilds it.
    const attach = () => {
      const root = host.querySelector<HTMLElement>(".ql-editor");
      if (root === watched) return;
      rootObserver.disconnect();
      watched = root;
      if (!root) return;
      rootObserver.observe(root, {
        childList: true,
        subtree: true,
        characterData: true,
      });
      markSoon();
    };
    attach();
    const hostObserver = new MutationObserver(attach);
    hostObserver.observe(host, { childList: true, subtree: true });
    const onCompositionStart = () => {
      isComposing = true;
    };
    const onCompositionEnd = () => {
      isComposing = false;
      markSoon();
    };
    host.addEventListener("compositionstart", onCompositionStart);
    host.addEventListener("compositionend", onCompositionEnd);
    return () => {
      cancelAnimationFrame(frame);
      hostObserver.disconnect();
      rootObserver.disconnect();
      host.removeEventListener("compositionstart", onCompositionStart);
      host.removeEventListener("compositionend", onCompositionEnd);
    };
  }, [containerEl]);
}
