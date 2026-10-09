"use client";

import * as React from "react";
import { DURATION } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";

// The --hl-<name> colors come from notes.css.

function seededRandom(seed: number) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const hash = (text: string) => {
  let value = 2166136261;
  for (let i = 0; i < text.length; i++)
    value = Math.imul(value ^ text.charCodeAt(i), 16777619);
  return value >>> 0;
};
const fixed1 = (value: number) => value.toFixed(1);
const PAD = 24;

function markerStroke(
  width: number,
  height: number,
  seed: number,
  color: string,
  id: string,
  overLeft: number,
  overRight: number,
) {
  const random = seededRandom(seed);
  const between = (min: number, max: number) => min + random() * (max - min);
  const top = height * between(0.27, 0.33);
  const bottom = height * between(0.98, 1.04);
  const slant = (bottom - top) * 0.4;
  const left = between(0, overLeft * 0.45);
  const right = width - between(0, overRight * 0.35);
  const rise = between(-0.2, 1) * Math.min(2.6, width * 0.012);
  const tiltAt = (x: number) =>
    (-(x - left) / Math.max(1, right - left)) * rise;
  const points: [number, number][] = [];
  for (let x = left + slant; x < right; x += 9)
    points.push([x, top + tiltAt(x) + between(-0.35, 0.35)]);
  points.push(
    [right, top + tiltAt(right)],
    [right - slant, bottom + tiltAt(right - slant)],
  );
  for (let x = right - slant - 9; x > left; x -= 9)
    points.push([x, bottom + tiltAt(x) + between(-0.35, 0.35)]);
  points.push([left, bottom + tiltAt(left)]);
  const stops: [number, number][] = [
    [0, 0.84],
    [0.05, 0.97],
  ];
  for (let i = 1; i <= 3; i++) stops.push([0.05 + i * 0.22, between(0.92, 1)]);
  stops.push([0.95, 0.97], [1, 0.86]);
  const [viewX, viewY, viewWidth, viewHeight] = [
    -PAD,
    -PAD,
    width + 2 * PAD,
    height + 2 * PAD,
  ];
  return (
    `<svg width="${fixed1(viewWidth)}" height="${fixed1(viewHeight)}" viewBox="${fixed1(viewX)} ${fixed1(viewY)} ${fixed1(viewWidth)} ${fixed1(viewHeight)}"><defs>` +
    `<linearGradient id="${id}g" gradientUnits="userSpaceOnUse" x1="${fixed1(left)}" y1="0" x2="${fixed1(right)}" y2="0">${stops.map(([offset, opacity]) => `<stop offset="${offset.toFixed(2)}" stop-color="${color}" stop-opacity="${opacity.toFixed(2)}"/>`).join("")}</linearGradient>` +
    `<filter id="${id}f" filterUnits="userSpaceOnUse" x="${fixed1(viewX)}" y="${fixed1(viewY)}" width="${fixed1(viewWidth)}" height="${fixed1(viewHeight)}">` +
    `<feTurbulence type="fractalNoise" baseFrequency="0.05 0.4" numOctaves="2" seed="${seed % 997}" result="g"/>` +
    `<feDisplacementMap in="SourceGraphic" in2="g" scale="1.6" xChannelSelector="R" yChannelSelector="G"/></filter>` +
    `</defs><path filter="url(#${id}f)" fill="url(#${id}g)" d="M${points.map(([x, y]) => `${fixed1(x)} ${fixed1(y)}`).join("L")}Z"/></svg>`
  );
}

const strokes = new Map<string, string>();
const drawStart = new WeakMap<Element, number>();

type Area = { top: number; right: number; bottom: number; left: number };

function visibleArea(
  mark: HTMLElement,
  root: HTMLElement,
  rootBox: DOMRect,
  clips: Map<Element, DOMRect | null>,
): Area {
  const area = {
    top: rootBox.top,
    right: rootBox.right,
    bottom: rootBox.bottom,
    left: rootBox.left,
  };
  for (let el = mark.parentElement; el && el !== root; el = el.parentElement) {
    let box = clips.get(el);
    if (box === undefined) {
      const { overflowX, overflowY } = getComputedStyle(el);
      box =
        overflowX === "visible" && overflowY === "visible"
          ? null
          : el.getBoundingClientRect();
      clips.set(el, box);
    }
    if (!box) continue;
    area.top = Math.max(area.top, box.top);
    area.right = Math.min(area.right, box.right);
    area.bottom = Math.min(area.bottom, box.bottom);
    area.left = Math.max(area.left, box.left);
  }
  return area;
}

function measureHighlights(host: HTMLElement, root: HTMLElement) {
  const marks = root.querySelectorAll<HTMLElement>("mark.hl");
  if (!marks.length) return null;
  const box = host.getBoundingClientRect();
  const rootBox = root.getBoundingClientRect();
  const clips = new Map<Element, DOMRect | null>();
  const originX = box.left + host.clientLeft;
  const originY = box.top + host.clientTop;
  const style = getComputedStyle(host);
  const reduceMotion = prefersReducedMotion();
  let html = "";
  for (const mark of marks) {
    const name = mark.dataset.hl ?? "yellow";
    const color = style.getPropertyValue(`--hl-${name}`).trim() || "#feea74";
    const painting = !reduceMotion && mark.classList.contains("sweep");
    if (painting && !drawStart.has(mark))
      drawStart.set(mark, performance.now());
    const elapsed = painting
      ? (performance.now() - (drawStart.get(mark) ?? 0)) / 1000
      : 0;
    const fontSize = Number.parseFloat(getComputedStyle(mark).fontSize) || 16;
    const key = `${name}|${mark.textContent?.slice(0, 14)}`;
    const area = visibleArea(mark, root, rootBox, clips);
    let line = 0;
    for (const rect of mark.getClientRects()) {
      const left = Math.max(rect.left, area.left);
      const right = Math.min(rect.right, area.right);
      if (
        right - left < 3 ||
        rect.top > area.bottom - 4 ||
        rect.bottom < area.top + 4
      )
        continue;
      const overLeft = left > rect.left ? 0 : fontSize * 0.38;
      const overRight = right < rect.right ? 0 : fontSize * 0.5;
      const width = Math.round(right - left + overLeft + overRight);
      const height = Math.round(rect.height);
      const seed = hash(`${key}|${line}`);
      const strokeKey = `${seed}|${width}|${height}|${color}`;
      if (!strokes.has(strokeKey))
        strokes.set(
          strokeKey,
          markerStroke(
            width,
            height,
            seed,
            color,
            `hm${seed.toString(36)}${width}x${height}`,
            overLeft,
            overRight,
          ),
        );
      const x = left - originX - overLeft - PAD;
      const y = rect.top - originY - PAD;
      const fresh = painting && elapsed < line * 0.3 + DURATION.paint / 1000;
      html += (strokes.get(strokeKey) as string).replace(
        "<svg ",
        `<svg class="hl-stroke${fresh ? " draw" : ""}" style="left:${fixed1(x)}px;top:${fixed1(y)}px${fresh ? `;animation-delay:${(line * 0.3 - elapsed).toFixed(2)}s` : ""}" `,
      );
      line++;
    }
  }
  return html;
}

function drawHighlights(host: HTMLElement, html: string | null) {
  let layer = host.querySelector<HTMLElement>(":scope > .hl-paint");
  if (html === null) {
    layer?.remove();
    return;
  }
  if (!layer) {
    layer = document.createElement("div");
    layer.className = "hl-paint";
    layer.setAttribute("aria-hidden", "true");
    host.prepend(layer);
  }
  if (layer.dataset.html !== html) {
    layer.innerHTML = html;
    layer.dataset.html = html;
  }
}

/** Paints every <mark class="hl"> in `root` behind the text of `host`. */
export function paintHighlights(host: HTMLElement, root: HTMLElement) {
  drawHighlights(host, measureHighlights(host, root));
}

const queued = new Map<HTMLElement, HTMLElement>();
let isFlushQueued = false;
let flushFrame = 0;

function flushQueued() {
  isFlushQueued = false;
  cancelAnimationFrame(flushFrame);
  flushFrame = 0;
  const jobs = [...queued].filter(([host]) => host.isConnected);
  queued.clear();
  const htmls = jobs.map(([host, root]) => measureHighlights(host, root));
  for (const [index, [host]] of jobs.entries())
    drawHighlights(host, htmls[index]);
}

function queuePaint(host: HTMLElement, root: HTMLElement, inFrame = false) {
  queued.set(host, root);
  if (isFlushQueued) return;
  if (!inFrame) {
    isFlushQueued = true;
    queueMicrotask(flushQueued);
  } else if (!flushFrame) flushFrame = requestAnimationFrame(flushQueued);
}

const resized = new Map<Element, () => void>();
let resizeObserver: ResizeObserver | null = null;

function watchSize(element: Element, onResize: () => void) {
  resizeObserver ??= new ResizeObserver((entries) => {
    for (const entry of entries) resized.get(entry.target)?.();
  });
  resized.set(element, onResize);
  resizeObserver.observe(element);
  return () => {
    resized.delete(element);
    resizeObserver?.unobserve(element);
  };
}

const painters = new Set<() => void>();
let frame = 0;
function repaintAll() {
  cancelAnimationFrame(frame);
  frame = requestAnimationFrame(() => {
    for (const paint of painters) paint();
  });
}
if (typeof window !== "undefined") {
  document.fonts?.ready.then(repaintAll);
  new MutationObserver(repaintAll).observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["class"],
  });
}

/** Runs [paint] again when fonts load or the theme changes. */
export function onHighlightRepaint(paint: () => void): () => void {
  painters.add(paint);
  return () => painters.delete(paint);
}

export function useHighlightPaint(
  host: React.RefObject<HTMLElement | null>,
  root: React.RefObject<HTMLElement | null>,
  deps: React.DependencyList,
  hasHighlights = true,
) {
  // biome-ignore lint/correctness/useExhaustiveDependencies: repaint when the caller's content changes
  React.useLayoutEffect(() => {
    const hostEl = host.current;
    if (!hostEl || !root.current) return;
    if (!hasHighlights) {
      hostEl.querySelector(":scope > .hl-paint")?.remove();
      return;
    }
    const paint = (inFrame = false) =>
      host.current &&
      root.current &&
      queuePaint(host.current, root.current, inFrame);
    paint();
    painters.add(paint);
    const stopWatching = watchSize(hostEl, () => paint(true));
    return () => {
      queued.delete(hostEl);
      painters.delete(paint);
      stopWatching();
    };
  }, [...deps, hasHighlights]);
}

export function watchHighlights(
  host: HTMLElement,
  root: HTMLElement,
): () => void {
  let frame = 0;
  const paint = () => {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(() => paintHighlights(host, root));
  };
  paint();
  painters.add(paint);
  const mutationObserver = new MutationObserver(paint);
  mutationObserver.observe(root, {
    childList: true,
    subtree: true,
    characterData: true,
    attributes: true,
    attributeFilter: ["class", "data-hl"],
  });
  const resizeObserver = new ResizeObserver(paint);
  resizeObserver.observe(host);
  return () => {
    cancelAnimationFrame(frame);
    painters.delete(paint);
    mutationObserver.disconnect();
    resizeObserver.disconnect();
  };
}
