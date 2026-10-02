import { type RefObject, useEffect, useState } from "react";

const MARGIN = "600px 0px";
const observers = new WeakMap<Element | Document, IntersectionObserver>();
const onNear = new WeakMap<Element, () => void>();

function watch(element: HTMLElement, callback: () => void) {
  const root = element.closest("[data-slot=page-scroll]");
  let observer = observers.get(root ?? document);
  if (!observer) {
    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries)
          if (entry.isIntersecting) onNear.get(entry.target)?.();
      },
      { root, rootMargin: MARGIN },
    );
    observers.set(root ?? document, observer);
  }
  onNear.set(element, callback);
  observer.observe(element);
  return () => {
    observer.unobserve(element);
    onNear.delete(element);
  };
}

export function useNearScreen(
  ref: RefObject<HTMLElement | null>,
  isEnabled = true,
) {
  const [isNear, setIsNear] = useState(false);
  useEffect(() => {
    const element = ref.current;
    if (!isEnabled || isNear || !element) return;
    return watch(element, () => setIsNear(true));
  }, [ref, isEnabled, isNear]);
  return isNear;
}
