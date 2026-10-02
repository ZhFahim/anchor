import { DURATION, EASE } from "@/lib/design/tokens";
import { prefersReducedMotion } from "@/lib/motion";

let opened: {
  id: string;
  card: HTMLElement;
  rect: DOMRect;
  at: number;
  grown?: boolean;
} | null = null;

export function rememberCard(id: string, card: HTMLElement) {
  opened = {
    id,
    card,
    rect: card.getBoundingClientRect(),
    at: performance.now(),
  };
}

const isFresh = (at: number) => performance.now() - at < 3000;

function cardRadius() {
  return getComputedStyle(document.documentElement)
    .getPropertyValue("--radius-card")
    .trim();
}

const clipOf = (rect: DOMRect, box: DOMRect, radius = cardRadius()) =>
  `inset(${rect.top - box.top}px ${box.right - rect.right}px ${box.bottom - rect.bottom}px ${rect.left - box.left}px round ${radius})`;

const FULL = "inset(0px round 0px)";

const within = (rect: DOMRect, box: DOMRect) =>
  rect.width > 0 &&
  rect.left >= box.left - 1 &&
  rect.right <= box.right + 1 &&
  rect.top >= box.top - 1 &&
  rect.bottom <= box.bottom + 1;

// New notes ----------------------------------------------------------------

let newNoteButton: {
  button: HTMLElement;
  kind: string;
  rect: DOMRect;
  radius: string;
  at: number;
  grown?: boolean;
} | null = null;

/** Call when a New note button is used. Buttons carry data-new-note: "sidebar", "fab" or "empty". */
export function rememberNewNoteButton(button: HTMLElement | null) {
  newNoteButton = button
    ? {
        button,
        kind: button.dataset.newNote ?? "",
        rect: button.getBoundingClientRect(),
        radius: getComputedStyle(button).borderTopLeftRadius,
        at: performance.now(),
      }
    : null;
}

function isInView(element: HTMLElement) {
  const rect = element.getBoundingClientRect();
  return (
    within(rect, new DOMRect(0, 0, window.innerWidth, window.innerHeight)) &&
    element.checkVisibility()
  );
}

export function findNewNoteButton(kind?: string) {
  const shown = [
    ...document.querySelectorAll<HTMLElement>("[data-new-note]"),
  ].filter(isInView);
  return (
    shown.find((button) => button.dataset.newNote === kind) ??
    shown.find((button) => button.dataset.newNote !== "empty") ??
    null
  );
}

function seedOf(rect: DOMRect, box: DOMRect, radius: string) {
  if (within(rect, box)) return { rect, radius: parseFloat(radius) || 0 };
  const size = Math.round(rect.height * 0.6);
  const top = Math.max(
    box.top + 8,
    Math.min(rect.top + (rect.height - size) / 2, box.bottom - size - 8),
  );
  return {
    rect: new DOMRect(box.left + 12, top, size, size),
    radius: size / 2,
  };
}

function grow(note: HTMLElement, from: string) {
  const animation = note.animate([{ clipPath: from }, { clipPath: FULL }], {
    duration: DURATION.morph,
    easing: EASE.standard,
  });
  for (const inner of note.querySelectorAll<HTMLElement>(":scope > .ed-scroll"))
    inner.animate([{ opacity: 0 }, { opacity: 1 }], {
      duration: DURATION.morph * 0.7,
      delay: DURATION.morph * 0.3,
      easing: EASE.standard,
      fill: "backwards",
    });
  const page = note.closest<HTMLElement>(".pg-editor");
  if (!page) return;
  page.style.zIndex = "calc(var(--z-float) + 2)";
  const lower = () => {
    page.style.zIndex = "";
  };
  animation.finished.then(lower, lower);
}

function growFromButton(note: HTMLElement) {
  const from = newNoteButton;
  if (!from || from.grown || !isFresh(from.at)) return;
  from.grown = true;
  const box = note.getBoundingClientRect();
  const seed = seedOf(from.rect, box, from.radius);
  grow(note, clipOf(seed.rect, box, `${seed.radius}px`));
  note.animate([{ opacity: 0 }, { opacity: 1 }], {
    duration: DURATION.morph * 0.22,
    easing: "linear",
  });
}

export function growNote(id: string, note: HTMLElement) {
  if (prefersReducedMotion()) return;
  if (id === "new") return growFromButton(note);
  if (!opened || opened.id !== id || opened.grown || !isFresh(opened.at))
    return;
  opened.grown = true;
  grow(note, clipOf(opened.rect, note.getBoundingClientRect()));
}

// Page changes -------------------------------------------------------------

const SCROLLERS = '[data-slot="page-scroll"], .ed-scroll, .hs-main, .hs-list';
const PAGE_HEADER = '[data-slot="page-scroll"] > header';
const NOTE_PATH = /^\/notes\/([^/]+)$/;

export interface PageSnapshot {
  originals: HTMLElement[];
  copies: HTMLElement[];
  scrollTops: number[];
  card: { copy: HTMLElement; rect: DOMRect } | null;
  /** Opening a new note: a copy of its New note button when that is on the page. */
  newNote: { face: { copy: HTMLElement; rect: DOMRect } | null } | null;
  leavingBlankNote: boolean;
  noteId: string | null;
}

let ghostLayer: HTMLElement | null = null;

// Navigations started by code show the new page at once.
const startedByPerson = () => navigator.userActivation?.isActive ?? true;

const scrollersIn = (root: HTMLElement) => [
  ...(root.matches(SCROLLERS) ? [root] : []),
  ...root.querySelectorAll<HTMLElement>(SCROLLERS),
];

function inertCopy(element: HTMLElement) {
  return makeInert(element.cloneNode(true) as HTMLElement);
}

function makeInert(copy: HTMLElement) {
  for (const node of [
    copy,
    ...copy.querySelectorAll<HTMLElement | SVGElement>("*"),
  ]) {
    if (!(node instanceof SVGElement)) node.removeAttribute("id");
    node.removeAttribute("name");
    node.removeAttribute("role");
    node.style.animation = "none";
  }
  return copy;
}

const SKIPPABLE = ".nc, .ql-editor > *, .hl-paint > *";

function copyOnScreen(element: HTMLElement, box: DOMRect) {
  const holdsSkippable = new Set<Element>();
  for (const piece of element.querySelectorAll(SKIPPABLE))
    for (
      let parent = piece.parentElement;
      parent && !holdsSkippable.has(parent);
      parent = parent === element ? null : parent.parentElement
    )
      holdsSkippable.add(parent);

  const copy = (node: Node): Node => {
    if (!(node instanceof HTMLElement || node instanceof SVGElement))
      return node.cloneNode(true);
    if (node.matches(SKIPPABLE)) {
      const rect = node.getBoundingClientRect();
      if (rect.bottom > box.top && rect.top < box.bottom)
        return node.cloneNode(true);
      const empty = node.cloneNode(false) as HTMLElement | SVGElement;
      empty.style.height = `${rect.height}px`;
      empty.style.visibility = "hidden";
      return empty;
    }
    if (!holdsSkippable.has(node)) return node.cloneNode(true);
    const shell = node.cloneNode(false);
    for (const child of node.childNodes) shell.appendChild(copy(child));
    return shell;
  };
  return makeInert(copy(element) as HTMLElement);
}

/** Call while the old page is still in the DOM, just before it changes. */
export function capturePage(
  container: HTMLElement,
  fromPath: string,
  toPath: string,
): PageSnapshot | null {
  ghostLayer?.remove();
  ghostLayer = null;
  if (prefersReducedMotion() || !startedByPerson()) return null;
  const originals = [...container.children] as HTMLElement[];
  if (!originals.length) return null;
  const pageBox = container.parentElement?.getBoundingClientRect();
  const copies = originals.map((element) =>
    pageBox ? copyOnScreen(element, pageBox) : inertCopy(element),
  );
  const scrollTops = originals.flatMap(scrollersIn).map((el) => el.scrollTop);
  const isOpening =
    !!opened &&
    !opened.grown &&
    isFresh(opened.at) &&
    toPath === `/notes/${opened.id}` &&
    opened.card.isConnected;
  const card =
    opened && isOpening
      ? {
          copy: inertCopy(opened.card),
          rect: opened.card.getBoundingClientRect(),
        }
      : null;
  const newNote =
    !card &&
    pageBox &&
    toPath === "/notes/new" &&
    newNoteButton &&
    !newNoteButton.grown &&
    isFresh(newNoteButton.at)
      ? {
          face:
            newNoteButton.button.isConnected &&
            within(newNoteButton.rect, pageBox)
              ? {
                  copy: inertCopy(newNoteButton.button),
                  rect: newNoteButton.rect,
                }
              : null,
        }
      : null;
  const noteId = fromPath.match(NOTE_PATH)?.[1] ?? null;
  return {
    originals,
    copies,
    scrollTops,
    card,
    newNote,
    leavingBlankNote:
      noteId === "new" &&
      originals.some((element) => element.querySelector("[data-blank]")),
    noteId: noteId === "new" ? null : noteId,
  };
}

function onScreen(element: Element | null, box: DOMRect) {
  if (!element) return null;
  const rect = element.getBoundingClientRect();
  return rect.width > 0 &&
    rect.bottom > box.top + 8 &&
    rect.top < box.bottom - 8
    ? rect
    : null;
}

function showGhost(copies: HTMLElement[], box: DOMRect, scrollTops: number[]) {
  const layer = document.createElement("div");
  layer.inert = true;
  layer.setAttribute("aria-hidden", "true");
  Object.assign(layer.style, {
    position: "fixed",
    left: `${box.left}px`,
    top: `${box.top}px`,
    width: `${box.width}px`,
    height: `${box.height}px`,
    zIndex: "calc(var(--z-float) + 1)",
    overflow: "hidden",
    pointerEvents: "none",
  });
  const ghost = document.createElement("div");
  Object.assign(ghost.style, {
    position: "absolute",
    inset: "0",
    display: "flex",
    flexDirection: "column",
  });
  ghost.append(...copies);
  layer.append(ghost);
  document.body.append(layer);
  ghostLayer = layer;
  copies.flatMap(scrollersIn).forEach((el, index) => {
    el.scrollTop = scrollTops[index] ?? 0;
  });
  const remove = () => {
    layer.remove();
    if (ghostLayer === layer) ghostLayer = null;
  };
  return { ghost, remove };
}

function shrinkGhost(
  ghost: HTMLElement,
  rect: DOMRect,
  box: DOMRect,
  radius: string,
  fades: boolean,
) {
  for (const inner of ghost.querySelectorAll<HTMLElement>(".ed-scroll"))
    inner.animate([{ opacity: 1 }, { opacity: 0 }], {
      duration: DURATION.morph * 0.3,
      easing: EASE.exit,
      fill: "forwards",
    });
  const clip = clipOf(rect, box, radius);
  return ghost.animate(
    fades
      ? [
          { clipPath: FULL, opacity: 1 },
          { opacity: 1, offset: 0.45 },
          { clipPath: clip, opacity: 0 },
        ]
      : [
          { clipPath: FULL, opacity: 1 },
          { clipPath: clip, opacity: 1, offset: 0.8 },
          { clipPath: clip, opacity: 0 },
        ],
    { duration: DURATION.morph, easing: EASE.standard, fill: "forwards" },
  );
}

function fadeThrough(ghost: HTMLElement, fresh: HTMLElement[]) {
  // Pages that share the header bar keep it still; only what is under it fades through.
  const oldHeader = ghost.querySelector(PAGE_HEADER);
  const header = fresh
    .map((element) => element.querySelector(PAGE_HEADER))
    .find(Boolean);
  let rising = fresh;
  if (oldHeader && header?.parentElement) {
    const below =
      oldHeader.getBoundingClientRect().bottom -
      ghost.getBoundingClientRect().top;
    ghost.style.clipPath = `inset(${below}px 0 0 0)`;
    const content = [...header.parentElement.children].filter(
      (child): child is HTMLElement => child !== header,
    );
    rising = fresh.flatMap((element) =>
      element.contains(header) ? content : [element],
    );
  }
  for (const element of rising)
    element.animate(
      [
        { opacity: 0, translate: "0 6px" },
        { opacity: 1, translate: "0 0" },
      ],
      {
        duration: DURATION.fade,
        delay: DURATION.exit * 0.5,
        easing: EASE.standard,
        fill: "backwards",
      },
    );
  return ghost.animate([{ opacity: 1 }, { opacity: 0 }], {
    duration: DURATION.exit,
    easing: EASE.standard,
    fill: "forwards",
  });
}

export function playPageChange(snapshot: PageSnapshot, container: HTMLElement) {
  const main = container.parentElement;
  if (!main) return;
  const box = main.getBoundingClientRect();
  if (!box.width || !box.height) return;
  const fresh = [...container.children] as HTMLElement[];
  const { ghost, remove } = showGhost(
    snapshot.copies,
    box,
    snapshot.scrollTops,
  );

  const animations: Animation[] = [];
  const source = snapshot.card ?? snapshot.newNote?.face ?? null;
  const finish = () => {
    remove();
    source?.copy.remove();
  };
  const shrink = (rect: DOMRect, radius: string, fades: boolean) => {
    animations.push(shrinkGhost(ghost, rect, box, radius, fades));
    for (const element of fresh)
      element.animate([{ opacity: 0 }, { opacity: 1 }], {
        duration: DURATION.morph * 0.6,
        easing: EASE.standard,
        fill: "backwards",
      });
  };

  const into = snapshot.noteId
    ? onScreen(
        container.querySelector(
          `.nc[data-flip="${CSS.escape(snapshot.noteId)}"]`,
        ),
        box,
      )
    : null;

  const home =
    !snapshot.card && !into && snapshot.leavingBlankNote
      ? findNewNoteButton(newNoteButton?.kind)
      : null;

  if (snapshot.card || snapshot.newNote) {
    if (source) animations.push(floatAway(source.copy, source.rect));
    animations.push(fadeOut(ghost, DURATION.morph * 0.5));
  } else if (into) {
    shrink(into, cardRadius(), false);
  } else if (home) {
    const seed = seedOf(
      home.getBoundingClientRect(),
      box,
      getComputedStyle(home).borderTopLeftRadius,
    );
    shrink(seed.rect, `${seed.radius}px`, true);
    home.animate([{ scale: "1" }, { scale: ".96" }, { scale: "1" }], {
      duration: DURATION.morph * 0.45,
      delay: DURATION.morph * 0.25,
      easing: EASE.standard,
    });
  } else {
    animations.push(fadeThrough(ghost, fresh));
  }
  Promise.all(animations.map((animation) => animation.finished)).then(
    finish,
    finish,
  );
}

// A page swapping one view for another in place ---------------------------

interface SwapMotion {
  /** The old view shrinks into this card on the new one, while `side` slides in. */
  into?: string;
  side?: string;
  /** The new view's `grow` element grows out of this card on the old one. */
  from?: string;
  grow?: string;
}

/** `swap` must change the DOM before it returns (React's flushSync). */
export function swapView(
  page: HTMLElement,
  swap: () => void,
  motion: SwapMotion,
) {
  ghostLayer?.remove();
  ghostLayer = null;
  const box = page.getBoundingClientRect();
  if (prefersReducedMotion() || !box.width || !box.height) return swap();
  const from = motion.from && page.querySelector<HTMLElement>(motion.from);
  const fromRect = from ? onScreen(from, box) : null;
  const card =
    from && fromRect
      ? {
          copy: noteCopy(from),
          rect: fromRect,
          radius: getComputedStyle(from).borderTopLeftRadius,
        }
      : null;
  const old = copyOnScreen(page, box);
  const scrollTops = scrollersIn(page).map((el) => el.scrollTop);
  swap();

  const { ghost, remove } = showGhost([old], box, scrollTops);
  const into = motion.into && page.querySelector<HTMLElement>(motion.into);
  const intoRect = into ? onScreen(into, box) : null;
  const grown = motion.grow && page.querySelector<HTMLElement>(motion.grow);
  if (into && intoRect) {
    const radius = getComputedStyle(into).borderTopLeftRadius;
    shrinkGhost(ghost, intoRect, box, radius, false).finished.then(
      remove,
      remove,
    );
    if (motion.side)
      page.querySelector(motion.side)?.animate(
        [
          { opacity: 0, translate: "24px 0" },
          { opacity: 1, translate: "0 0" },
        ],
        {
          duration: DURATION.move,
          delay: DURATION.morph * 0.25,
          easing: EASE.standard,
          fill: "backwards",
        },
      );
  } else if (card && grown) {
    const finish = () => {
      remove();
      card.copy.remove();
    };
    Promise.all([
      floatAway(card.copy, card.rect).finished,
      fadeOut(ghost, DURATION.morph * 0.5).finished,
    ]).then(finish, finish);
    grow(grown, clipOf(card.rect, grown.getBoundingClientRect(), card.radius));
  } else {
    fadeThrough(ghost, [page]).finished.then(remove, remove);
  }
}

/** A copy of part of a note that keeps the note's class and colors outside it. */
function noteCopy(part: HTMLElement) {
  const copy = inertCopy(part);
  const note = part.closest<HTMLElement>(".note");
  copy.classList.add("note");
  if (note?.dataset.note !== undefined) copy.dataset.note = note.dataset.note;
  return copy;
}

function fadeOut(element: HTMLElement, duration: number) {
  return element.animate([{ opacity: 1 }, { opacity: 0 }], {
    duration,
    easing: EASE.exit,
    fill: "forwards",
  });
}

function floatAway(copy: HTMLElement, rect: DOMRect) {
  Object.assign(copy.style, {
    position: "fixed",
    margin: "0",
    left: `${rect.left}px`,
    top: `${rect.top}px`,
    right: "auto",
    bottom: "auto",
    width: `${rect.width}px`,
    height: `${rect.height}px`,
    zIndex: "calc(var(--z-float) + 3)",
    pointerEvents: "none",
  });
  copy.inert = true;
  copy.setAttribute("aria-hidden", "true");
  document.body.append(copy);
  return fadeOut(copy, DURATION.morph * 0.35);
}
