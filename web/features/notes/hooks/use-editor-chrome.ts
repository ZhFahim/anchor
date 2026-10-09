"use client";

import { type RefObject, useEffect, useLayoutEffect, useRef } from "react";
import { isPhoneWidth } from "@/lib/hooks/use-is-phone";
import { growNote } from "@/lib/morph";
import type { RichTextEditorHandle } from "../components/editor/rich-text-editor";
import { toolbarTop } from "../components/note-editor/toolbar-top";
import { useKeyboardInset } from "./use-keyboard-inset";

export function useEditorChrome({
  noteId,
  isLoading,
  isNew,
  contentEditorRef,
}: {
  noteId: string;
  isLoading: boolean;
  isNew: boolean;
  contentEditorRef: RefObject<RichTextEditorHandle | null>;
}) {
  const articleRef = useRef<HTMLElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  // biome-ignore lint/correctness/useExhaustiveDependencies: the note mounts once loading ends
  useLayoutEffect(() => {
    if (articleRef.current) growNote(noteId, articleRef.current);
  }, [isLoading, noteId]);

  // biome-ignore lint/correctness/useExhaustiveDependencies: the note mounts once loading ends
  useEffect(() => {
    const article = articleRef.current;
    const scroller = scrollRef.current;
    if (!article || !scroller) return;
    let lastScrollTop = 0;
    const onScroll = () => {
      const scrollTop = scroller.scrollTop;
      const delta = scrollTop - lastScrollTop;
      lastScrollTop = scrollTop;
      article.toggleAttribute("data-scrolled", scrollTop > 2);
      const menuOpen = !!document.querySelector(
        "[data-slot=menu], [data-slot=popover]",
      );
      if (scrollTop < 40 || delta < -3)
        article.removeAttribute("data-head-hidden");
      else if (delta > 3 && !menuOpen)
        article.setAttribute("data-head-hidden", "");
      const toolbarOffset = toolbarTop(
        article,
        article.hasAttribute("data-head-hidden"),
      );
      article.style.setProperty("--tb-top", `${toolbarOffset}px`);
      const toolbar = article.querySelector<HTMLElement>(".tb");
      toolbar?.classList.toggle(
        "stuck",
        !isPhoneWidth() &&
          scrollTop > 0 &&
          toolbar.getBoundingClientRect().top -
            scroller.getBoundingClientRect().top <=
            toolbarOffset + 1,
      );
    };
    const onToolbarMoved = (e: TransitionEvent) => {
      if (
        e.propertyName === "top" &&
        (e.target as Element).classList.contains("tb")
      )
        onScroll();
    };
    onScroll();
    scroller.addEventListener("scroll", onScroll, { passive: true });
    article.addEventListener("transitionend", onToolbarMoved);
    return () => {
      scroller.removeEventListener("scroll", onScroll);
      article.removeEventListener("transitionend", onToolbarMoved);
    };
  }, [isLoading]);

  useKeyboardInset(articleRef, scrollRef, !isLoading || isNew);

  // biome-ignore lint/correctness/useExhaustiveDependencies: the note mounts once loading ends
  useEffect(() => {
    const scroller = scrollRef.current;
    if (!scroller) return;
    const onMouseDown = (e: MouseEvent) => {
      const target = e.target as Element;
      if (
        e.button !== 0 ||
        (target !== scroller && !target.matches(".note-in, .ed-body, .rte"))
      )
        return;
      const last = scroller
        .querySelector(".ql-editor")
        ?.lastElementChild?.getBoundingClientRect();
      if (!last || e.clientY <= last.bottom) return;
      if (contentEditorRef.current?.focusEnd(e.shiftKey)) e.preventDefault();
    };
    scroller.addEventListener("mousedown", onMouseDown);
    return () => scroller.removeEventListener("mousedown", onMouseDown);
  }, [isLoading]);

  return { articleRef, scrollRef };
}
