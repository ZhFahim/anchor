"use client";

import { Check, CircleAlert, Info, LoaderCircle, X } from "lucide-react";
import * as React from "react";
import { createPortal } from "react-dom";
import { create } from "zustand";
import { onPageClose } from "@/lib/page-close";
import { cn } from "@/lib/utils";

type Kind = "done" | "error" | "info" | "busy";

interface ToastAction {
  label: string;
  onClick: () => void;
}

interface ToastItem {
  id: string;
  kind: Kind;
  message: string;
  action?: ToastAction;
  duration: number;
  serial: number;
  swap: boolean;
  onClose?: () => void;
}

interface ToastOptions {
  id?: string;
  duration?: number;
  undo?: () => void;
  retry?: () => void;
  action?: ToastAction;
  /** Runs once when the toast goes away without its button being pressed. */
  onClose?: () => void;
}

const DURATION: Record<Kind, number> = {
  done: 6000,
  info: 6000,
  error: 10000,
  busy: Number.POSITIVE_INFINITY,
};

interface ToastState {
  current: ToastItem | null;
  leaving: ToastItem | null;
  show: (kind: Kind, message: string, options?: ToastOptions) => string;
  dismiss: (id?: string, acted?: boolean) => void;
  finishLeaving: () => void;
}

let serial = 0;

const useToastStore = create<ToastState>((set, get) => ({
  current: null,
  leaving: null,
  show: (kind, message, options = {}) => {
    const id = options.id ?? `t${++serial}`;
    const previous = get().current;
    const action = options.undo
      ? { label: "Undo", onClick: options.undo }
      : options.retry
        ? { label: "Try again", onClick: options.retry }
        : options.action;
    const swap = !!previous && previous.id === id && previous.kind === "busy";
    if (previous && !swap) previous.onClose?.();
    set({
      current: {
        id,
        kind,
        message,
        action,
        duration: options.duration ?? DURATION[kind],
        serial: ++serial,
        swap,
        onClose: options.onClose,
      },
      leaving: null,
    });
    return id;
  },
  dismiss: (id, acted) => {
    const current = get().current;
    if (!current || (id && current.id !== id)) return;
    set({ current: null, leaving: current });
    if (!acted) current.onClose?.();
  },
  finishLeaving: () => set({ leaving: null }),
}));

// Open modal dialogs, newest last; a toast outside Radix's focus trap can't be reached.
const useToastHosts = create<{ hosts: HTMLElement[] }>(() => ({ hosts: [] }));

export function toastHostRef(el: HTMLElement | null) {
  if (!el) return;
  const remove = () =>
    useToastHosts.setState((s) => ({
      hosts: s.hosts.filter((host) => host !== el),
    }));
  const add = () =>
    useToastHosts.setState((s) => ({
      hosts: [...s.hosts.filter((host) => host !== el), el],
    }));
  add();
  const observer = new MutationObserver(() =>
    el.dataset.state === "closed" ? remove() : add(),
  );
  observer.observe(el, { attributes: true, attributeFilter: ["data-state"] });
  return () => {
    observer.disconnect();
    remove();
  };
}

// A change that waits for its toast to close is sent before the page goes.
onPageClose(() => {
  const { current } = useToastStore.getState();
  if (!current) return;
  useToastStore.setState({ current: null, leaving: null });
  current.onClose?.();
});

type Message = string;

function makeShow(kind: Kind) {
  return (message: Message, options?: ToastOptions) =>
    useToastStore.getState().show(kind, message, options);
}

function promise<T>(
  work: Promise<T>,
  messages: {
    loading: Message;
    success: Message | ((value: T) => Message);
    error: Message | ((error: unknown) => Message);
    retry?: () => void;
  },
) {
  const id = useToastStore.getState().show("busy", messages.loading);
  work.then(
    (value) => {
      const text =
        typeof messages.success === "function"
          ? messages.success(value)
          : messages.success;
      useToastStore.getState().show("done", text, { id });
    },
    (error: unknown) => {
      const text =
        typeof messages.error === "function"
          ? messages.error(error)
          : messages.error;
      useToastStore
        .getState()
        .show("error", text, { id, retry: messages.retry });
    },
  );
  return work;
}

export const toast = Object.assign(makeShow("done"), {
  success: makeShow("done"),
  error: makeShow("error"),
  info: makeShow("info"),
  busy: makeShow("busy"),
  promise,
  dismiss: (id?: string) => useToastStore.getState().dismiss(id),
});

const ICON: Record<Kind, React.ComponentType<{ className?: string }>> = {
  done: Check,
  error: CircleAlert,
  info: Info,
  busy: LoaderCircle,
};

function ToastView({
  item,
  leaving,
  moved,
}: {
  item: ToastItem;
  leaving?: boolean;
  moved?: boolean;
}) {
  const dismiss = useToastStore((s) => s.dismiss);
  const finishLeaving = useToastStore((s) => s.finishLeaving);
  const ref = React.useRef<HTMLDivElement>(null);
  const timer = React.useRef<{ id: number; left: number; startedAt: number }>({
    id: 0,
    left: item.duration,
    startedAt: 0,
  });

  // biome-ignore lint/correctness/useExhaustiveDependencies: serial restarts the clock
  React.useEffect(() => {
    if (leaving || !Number.isFinite(item.duration)) return;
    const clock = timer.current;
    clock.left = item.duration;
    const start = () => {
      if (clock.id || ref.current?.matches(":hover, :focus-within")) return;
      clock.startedAt = performance.now();
      clock.id = window.setTimeout(
        () => dismiss(item.id),
        Math.max(clock.left, 1200),
      );
    };
    const pause = () => {
      if (!clock.id) return;
      window.clearTimeout(clock.id);
      clock.id = 0;
      clock.left -= performance.now() - clock.startedAt;
    };
    const el = ref.current;
    const startLater = () => window.setTimeout(start);
    el?.addEventListener("pointerenter", pause);
    el?.addEventListener("focusin", pause);
    el?.addEventListener("pointerleave", start);
    el?.addEventListener("focusout", startLater);
    start();
    return () => {
      window.clearTimeout(clock.id);
      clock.id = 0;
      el?.removeEventListener("pointerenter", pause);
      el?.removeEventListener("focusin", pause);
      el?.removeEventListener("pointerleave", start);
      el?.removeEventListener("focusout", startLater);
    };
  }, [item.id, item.serial, item.duration, leaving, dismiss]);

  const Icon = ICON[item.kind];
  return (
    <div
      ref={ref}
      data-toast
      data-kind={item.kind}
      inert={leaving || undefined}
      onAnimationEnd={
        leaving
          ? (e) => e.target === e.currentTarget && finishLeaving()
          : undefined
      }
      style={{ "--toast-time": `${item.duration}ms` } as React.CSSProperties}
      className={cn(
        "group/toast pointer-events-auto relative flex max-w-[min(560px,calc(100%-24px))] items-center gap-2.5 overflow-hidden rounded-xl bg-inverse py-1.5 pr-1.5 pl-2.5 font-medium text-ui text-inverse-foreground shadow-[var(--sh-bar),inset_0_0_0_1px_color-mix(in_srgb,var(--inverse-foreground)_8%,transparent)]",
        leaving
          ? "animate-toast-out"
          : moved
            ? "max-md:animate-fade-in"
            : item.swap
              ? ""
              : "animate-toast-in",
      )}
    >
      <span
        aria-hidden
        className={cn(
          "grid size-6 flex-none place-items-center rounded-full [&_svg]:size-3.5 [&_svg]:stroke-[2.6]",
          item.kind === "done" && "bg-inverse-link/16 text-inverse-link",
          item.kind === "error" && "bg-inverse-danger/18 text-inverse-danger",
          item.kind === "info" &&
            "bg-inverse-foreground/12 text-inverse-foreground",
          item.kind === "busy" &&
            "text-inverse-foreground [&_svg]:size-4 [&_svg]:animate-spin [&_svg]:stroke-[2.4]",
          item.swap && "animate-fade-in",
        )}
      >
        <Icon />
      </span>
      <span
        className={cn(
          "min-w-0 whitespace-normal wrap-anywhere pr-1 leading-[1.35]",
          item.swap && "animate-fade-in",
        )}
      >
        {item.message}
      </span>
      {item.action && (
        <button
          type="button"
          onClick={() => {
            dismiss(item.id, true);
            item.action?.onClick();
          }}
          className="h-7.5 flex-none cursor-pointer rounded-sm bg-transparent px-3 font-semibold text-control text-inverse-link shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--inverse-foreground)_18%,transparent)] transition-shadow duration-(--duration-hover) hover:shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--inverse-foreground)_40%,transparent)]"
        >
          {item.action.label}
        </button>
      )}
      <button
        type="button"
        aria-label="Dismiss"
        onClick={() => dismiss(item.id)}
        className="grid size-7.5 flex-none cursor-pointer place-items-center rounded-sm bg-transparent text-inverse-foreground/65 hover:bg-inverse-foreground/10 hover:text-inverse-foreground [&_svg]:size-3.75"
      >
        <X />
      </button>
      {Number.isFinite(item.duration) && (
        <i
          aria-hidden
          data-toast-bar
          key={item.serial}
          className={cn(
            "absolute inset-x-0 bottom-0 h-0.5 origin-left animate-drain group-focus-within/toast:[animation-play-state:paused] group-hover/toast:[animation-play-state:paused]",
            item.kind === "error"
              ? "bg-inverse-danger/70"
              : "bg-inverse-link/70",
          )}
        />
      )}
    </div>
  );
}

/** Screen readers hear toasts through live regions that stay on the page. */
export function Toaster({ className }: { className?: string }) {
  const current = useToastStore((s) => s.current);
  const leaving = useToastStore((s) => s.leaving);
  const host = useToastHosts((s) => s.hosts[s.hosts.length - 1]);
  const shown = current ?? leaving;
  const placement = React.useRef<{
    serial: number;
    host?: HTMLElement;
    moved: boolean;
  }>({ serial: -1, moved: false });
  if (shown && placement.current.serial !== shown.serial)
    placement.current = { serial: shown.serial, host, moved: false };
  else if (shown && placement.current.host !== host)
    placement.current = { serial: shown.serial, host, moved: true };
  const moved = placement.current.moved;
  const area = React.useRef<HTMLDivElement>(null);
  const layer = React.useRef<HTMLDivElement>(null);
  React.useLayoutEffect(() => {
    const el = layer.current;
    if (!host || !el) return;
    const place = () => {
      const box = area.current?.getBoundingClientRect();
      if (!box) return;
      el.style.setProperty("--toast-left", `${box.left}px`);
      el.style.setProperty("--toast-width", `${box.width}px`);
      el.style.setProperty(
        "--toast-bottom",
        `${document.documentElement.clientHeight - box.bottom}px`,
      );
    };
    place();
    if (!el.matches(":popover-open")) el.showPopover();
    window.addEventListener("resize", place);
    return () => window.removeEventListener("resize", place);
  }, [host]);
  const view = shown && (
    <ToastView
      key={shown.serial}
      item={shown}
      leaving={!current}
      moved={moved}
    />
  );
  return (
    <>
      <div
        ref={area}
        className={cn(
          "pointer-events-none absolute inset-x-0 bottom-6 z-(--z-toast) flex justify-center transition-[bottom] duration-(--duration-move) ease-standard",
          className,
        )}
      >
        {!host && view}
      </div>
      {host &&
        createPortal(
          // The top layer isn't moved or clipped by the dialog's transform and overflow.
          <div
            ref={layer}
            popover="manual"
            className="pointer-events-none fixed top-auto right-auto bottom-(--toast-bottom) left-(--toast-left) m-0 flex w-(--toast-width) justify-center overflow-visible border-0 bg-transparent p-0 max-md:top-[max(12px,env(safe-area-inset-top))] max-md:bottom-auto"
          >
            {view}
          </div>,
          host,
        )}
      <div className="sr-only" aria-live="polite">
        {current && current.kind !== "error" ? current.message : ""}
      </div>
      <div className="sr-only" aria-live="assertive">
        {current?.kind === "error" ? current.message : ""}
      </div>
    </>
  );
}
