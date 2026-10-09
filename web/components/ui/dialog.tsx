"use client";

import * as DialogPrimitive from "@radix-ui/react-dialog";
import { X } from "lucide-react";
import * as React from "react";
import { IconButton } from "@/components/ui/button";
import { toastHostRef } from "@/components/ui/toast";
import { cn } from "@/lib/utils";

interface ReturnPoint {
  element: HTMLElement;
  /** The element, then its ancestors. */
  path: { node: Element; place: number; likeCount: number }[];
}

const isLike = (a: Element, b: Element) =>
  a.tagName === b.tagName &&
  a.getAttribute("class") === b.getAttribute("class");

const TABBABLE =
  'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

const accessibleName = (el: Element) =>
  el.getAttribute("aria-label") ?? el.textContent?.trim() ?? "";

const returnPoints = new WeakMap<
  Element,
  React.RefObject<ReturnPoint | null>
>();

/** A menu item or a closing dialog stands for what opened it. */
function focusBeforeOpen(): ReturnPoint | null {
  let focused = document.activeElement as HTMLElement | null;
  for (let hops = 0; focused && hops < 8; hops++) {
    const menu = focused.closest("[role=menu]");
    if (menu) {
      const triggerId = menu.getAttribute("aria-labelledby");
      focused = triggerId ? document.getElementById(triggerId) : null;
      continue;
    }
    const closingDialog = focused.closest(
      "[data-slot=dialog][data-state=closed]",
    );
    if (!closingDialog) break;
    focused = returnPoints.get(closingDialog)?.current?.element ?? null;
  }
  if (!focused || focused === document.body) return null;
  const path: ReturnPoint["path"] = [];
  for (
    let node: Element | null = focused;
    node && node !== document.body;
    node = node.parentElement
  ) {
    const likeSiblings = node.parentElement
      ? [...node.parentElement.children].filter((sibling) =>
          isLike(sibling, node as Element),
        )
      : [node];
    path.push({
      node,
      place: likeSiblings.indexOf(node),
      likeCount: likeSiblings.length,
    });
  }
  return { element: focused, path };
}

function sameControlNearby({ element, path }: ReturnPoint) {
  const kept = path.findIndex(({ node }) => node.isConnected);
  if (kept < 1) return null;
  const removed = path[kept - 1];
  // Only a row or card of a list, not the whole page.
  if (removed.likeCount < 2) return null;
  const likeSiblings = [...path[kept].node.children].filter((sibling) =>
    isLike(sibling, removed.node),
  );
  const replacement =
    likeSiblings[Math.min(removed.place, likeSiblings.length - 1)];
  if (!replacement) return null;
  if (removed.node === element)
    return replacement.matches(TABBABLE) ? (replacement as HTMLElement) : null;
  const before = [...removed.node.querySelectorAll(TABBABLE)];
  const now = [...replacement.querySelectorAll<HTMLElement>(TABBABLE)];
  const name = accessibleName(element);
  const fromEnd = before.length - 1 - before.indexOf(element);
  return (
    now.find((control) => accessibleName(control) === name) ??
    now[now.length - 1 - fromEnd] ??
    null
  );
}

function pageLandmark() {
  const landmark =
    document.querySelector<HTMLElement>("main h1") ??
    document.querySelector<HTMLElement>("main");
  if (landmark && !landmark.hasAttribute("tabindex"))
    landmark.setAttribute("tabindex", "-1");
  return landmark;
}

const ReturnFocusContext =
  React.createContext<React.RefObject<ReturnPoint | null> | null>(null);

/** Radix returns focus only to a DialogTrigger. */
function Dialog({
  open,
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Root>) {
  const returnFocusRef = React.useRef<ReturnPoint | null>(null);
  // Must run before an input in the content takes focus on its own.
  React.useLayoutEffect(() => {
    if (open) returnFocusRef.current = focusBeforeOpen();
  }, [open]);
  return (
    <ReturnFocusContext.Provider value={returnFocusRef}>
      <DialogPrimitive.Root open={open} {...props} />
    </ReturnFocusContext.Provider>
  );
}

interface DialogContentProps
  extends React.ComponentProps<typeof DialogPrimitive.Content> {
  size?: "default" | "md" | "lg";
  showClose?: boolean;
  alert?: boolean;
  /** Where focus goes on closing when what opened the dialog is gone. */
  fallbackFocus?: () => HTMLElement | null | undefined;
}

function DialogContent({
  className,
  children,
  size = "default",
  showClose = true,
  alert,
  fallbackFocus,
  onInteractOutside,
  onCloseAutoFocus,
  ...props
}: DialogContentProps) {
  const returnFocusRef = React.useContext(ReturnFocusContext);
  const contentRef = React.useCallback(
    (el: HTMLDivElement | null) => {
      if (el && returnFocusRef) returnPoints.set(el, returnFocusRef);
      return toastHostRef(el);
    },
    [returnFocusRef],
  );
  return (
    <DialogPrimitive.Portal>
      <DialogPrimitive.Overlay className="fixed inset-0 z-(--z-overlay) grid place-items-center overflow-y-auto bg-overlay p-6 backdrop-blur-[6px] backdrop-saturate-110 animate-fade-in data-[state=closed]:pointer-events-none! data-[state=closed]:animate-fade-out max-md:items-end max-md:justify-items-stretch max-md:p-0 max-md:data-[state=closed]:[animation-duration:var(--duration-move)]">
        <DialogPrimitive.Content
          ref={contentRef}
          data-slot="dialog"
          role={alert ? "alertdialog" : "dialog"}
          onInteractOutside={(e) => {
            if ((e.target as Element | null)?.closest?.("[data-toast]"))
              e.preventDefault();
            onInteractOutside?.(e);
          }}
          onCloseAutoFocus={(e) => {
            onCloseAutoFocus?.(e);
            const returnTo = returnFocusRef?.current;
            if (!returnTo) return;
            // After Radix's own focus return.
            queueMicrotask(() => {
              const active = document.activeElement;
              if (active && active !== document.body) return;
              if (returnTo.element.isConnected) {
                returnTo.element.focus();
                return;
              }
              const nearby = fallbackFocus?.() ?? sameControlNearby(returnTo);
              nearby?.focus();
              if (!nearby || document.activeElement !== nearby)
                pageLandmark()?.focus({ preventScroll: true });
            });
          }}
          className={cn(
            "group/dialog relative grid max-h-full w-[min(420px,100%)] gap-2.5 overflow-auto rounded-dialog bg-card px-6 pt-(--dialog-top) pb-5 text-foreground shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent),var(--sh-dialog)] outline-none [--dialog-top:24px] animate-dialog-in md:has-data-[slot=dialog-footer]:pb-0 data-[state=closed]:pointer-events-none! data-[state=closed]:animate-dialog-out",
            size === "md" && "w-[min(520px,100%)]",
            size === "lg" && "w-[min(640px,100%)]",
            "max-md:w-full max-md:rounded-t-4xl max-md:rounded-b-none max-md:px-5 max-md:pb-[max(24px,env(safe-area-inset-bottom))] max-md:[--dialog-top:28px] max-md:animate-sheet-in max-md:data-[state=closed]:animate-sheet-out max-md:before:absolute max-md:before:top-2 max-md:before:left-1/2 max-md:before:-ml-4.5 max-md:before:h-1 max-md:before:w-9 max-md:before:rounded-full max-md:before:bg-muted-foreground/40 max-md:before:content-['']",
            className,
          )}
          {...props}
        >
          {children}
          {showClose && (
            <DialogPrimitive.Close asChild>
              <IconButton
                size="sm"
                label="Close"
                className="absolute top-[calc(var(--dialog-top)+(var(--text-heading)*var(--text-heading--line-height)-28px)/2)] right-3.5"
              >
                <X />
              </IconButton>
            </DialogPrimitive.Close>
          )}
        </DialogPrimitive.Content>
      </DialogPrimitive.Overlay>
    </DialogPrimitive.Portal>
  );
}

function DialogHeader({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="dialog-header"
      className={cn("grid gap-2.5", className)}
      {...props}
    />
  );
}

function DialogTitle({
  className,
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Title>) {
  return (
    <DialogPrimitive.Title
      className={cn("m-0 pr-7 text-heading", className)}
      {...props}
    />
  );
}

function DialogDescription({
  className,
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Description>) {
  return (
    <DialogPrimitive.Description
      className={cn(
        "m-0 text-muted-foreground text-ui leading-[1.55] [&_b]:font-semibold [&_b]:text-foreground",
        className,
      )}
      {...props}
    />
  );
}

function DialogBody({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="dialog-body"
      className={cn(
        "mt-2 grid gap-3.5 max-md:**:data-[slot=input]:h-11",
        className,
      )}
      {...props}
    />
  );
}

function DialogFooter({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="dialog-footer"
      className={cn(
        "-mx-6 mt-3.5 flex items-center justify-end gap-2 rounded-b-dialog border-border/50 border-t bg-foreground/2.5 px-6 pt-3.5 pb-4 **:data-[slot=button]:min-h-9",
        "max-md:mx-0 max-md:mt-2 max-md:flex-col-reverse max-md:items-stretch max-md:rounded-none max-md:border-t-0 max-md:bg-transparent max-md:p-0 max-md:**:data-[slot=button]:h-11 max-md:**:data-[slot=button]:justify-center",
        className,
      )}
      {...props}
    />
  );
}

export {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
};
