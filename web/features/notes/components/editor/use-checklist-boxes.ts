"use client";

import { useEffect } from "react";
import { isMac } from "@/lib/platform";
import type { QuillInstance, QuillOp } from "../../quill";
import { LIST_FORMATS, setUndoCaret } from "../../quill";

const CHECKLIST_ITEM = 'li[data-list="checked"], li[data-list="unchecked"]';

const BOX_ATTRIBUTES = [
  "role",
  "aria-checked",
  "aria-label",
  "aria-disabled",
  "aria-keyshortcuts",
];

/** Only real changes: Quill observes every change to its root. */
function setAttribute(el: Element, name: string, value: string | null) {
  if (el.getAttribute(name) === value) return;
  if (value === null) el.removeAttribute(name);
  else el.setAttribute(name, value);
}

function labelBoxes(root: HTMLElement, isReadOnly: boolean) {
  const shortcut = isMac() ? "Meta+Enter" : "Control+Enter";
  for (const box of root.querySelectorAll("li > .ql-ui")) {
    const item = box.parentElement as HTMLElement;
    const state = item.getAttribute("data-list");
    if (state !== LIST_FORMATS.CHECKED && state !== LIST_FORMATS.UNCHECKED) {
      for (const name of BOX_ATTRIBUTES) setAttribute(box, name, null);
      continue;
    }
    const text = (item.textContent ?? "")
      .replace(/﻿/g, "")
      .replace(/\s+/g, " ")
      .trim();
    setAttribute(box, "role", "checkbox");
    setAttribute(box, "aria-checked", String(state === LIST_FORMATS.CHECKED));
    setAttribute(box, "aria-label", text || "Empty item");
    setAttribute(box, "aria-disabled", isReadOnly ? "true" : null);
    setAttribute(box, "aria-keyshortcuts", isReadOnly ? null : shortcut);
  }
}

export function useChecklistBoxes({
  containerEl,
  getQuill,
  readOnly,
}: {
  containerEl: HTMLElement | null;
  getQuill: () => QuillInstance | null;
  readOnly: boolean;
}) {
  useEffect(() => {
    const host = containerEl;
    if (!host) return;
    let watched: HTMLElement | null = null;
    let frame = 0;
    let isComposing = false;
    const label = () => {
      frame = 0;
      if (watched && !isComposing) labelBoxes(watched, readOnly);
    };
    const labelSoon = () => {
      frame ||= requestAnimationFrame(label);
    };
    const rootObserver = new MutationObserver(labelSoon);
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
        attributes: true,
        attributeFilter: ["data-list"],
      });
      labelSoon();
    };
    attach();
    const hostObserver = new MutationObserver(attach);
    hostObserver.observe(host, { childList: true, subtree: true });
    const onCompositionStart = () => {
      isComposing = true;
    };
    const onCompositionEnd = () => {
      isComposing = false;
      labelSoon();
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
  }, [containerEl, readOnly]);

  useEffect(() => {
    const host = containerEl;
    if (!host || readOnly) return;
    const onPress = (e: Event) => {
      const box = e.target as HTMLElement;
      const item = box.parentElement;
      if (!box.matches?.(".ql-ui") || !item?.matches(CHECKLIST_ITEM)) return;
      const quill = getQuill();
      const line = quill?.scroll.find(item);
      if (!quill || !line) return;
      quill.history.cutoff();
      const restoreCaret = setUndoCaret(
        quill,
        quill.getIndex(line) + line.length() - 1,
      );
      // Quill records the tick after this event.
      setTimeout(restoreCaret);
    };
    host.addEventListener("mousedown", onPress, true);
    host.addEventListener("touchstart", onPress, {
      capture: true,
      passive: true,
    });
    return () => {
      host.removeEventListener("mousedown", onPress, true);
      host.removeEventListener("touchstart", onPress, true);
    };
  }, [containerEl, getQuill, readOnly]);

  useEffect(() => {
    const host = containerEl;
    if (!host || readOnly) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (
        e.key !== "Enter" ||
        !(e.ctrlKey || e.metaKey) ||
        e.altKey ||
        e.shiftKey ||
        e.isComposing
      )
        return;
      const quill = getQuill();
      if (!quill?.root.contains(e.target as Node)) return;
      const selection = quill.getSelection();
      if (!selection) return;
      const items: { newline: number; state: unknown }[] = [];
      const end = selection.index + selection.length;
      for (let pos = selection.index; ; ) {
        const [line, offset] = quill.getLine(pos);
        if (!line) break;
        const start = pos - offset;
        const state = line.formats().list;
        if (state === LIST_FORMATS.CHECKED || state === LIST_FORMATS.UNCHECKED)
          items.push({ newline: start + line.length() - 1, state });
        pos = start + line.length();
        if (pos > end) break;
      }
      if (!items.length) return;
      e.preventDefault();
      e.stopPropagation();
      const next = items.every((item) => item.state === LIST_FORMATS.CHECKED)
        ? LIST_FORMATS.UNCHECKED
        : LIST_FORMATS.CHECKED;
      // Must be "user": other sources skip sorting and saving.
      if (items.length === 1) {
        quill.formatLine(items[0].newline, 0, "list", next, "user");
        return;
      }
      const ops: QuillOp[] = [];
      let at = 0;
      for (const { newline } of items) {
        if (newline > at) ops.push({ retain: newline - at });
        ops.push({ retain: 1, attributes: { list: next } });
        at = newline + 1;
      }
      quill.updateContents({ ops }, "user");
    };
    host.addEventListener("keydown", onKeyDown, true);
    return () => host.removeEventListener("keydown", onKeyDown, true);
  }, [containerEl, getQuill, readOnly]);
}
