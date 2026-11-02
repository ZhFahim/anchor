"use client";

import * as DialogPrimitive from "@radix-ui/react-dialog";
import { useRouter } from "next/navigation";
import * as React from "react";
import { Toaster } from "@/components/ui/toast";
import { focusEdgeCard } from "@/features/notes/card-focus";
import { usePreferencesStore } from "@/features/preferences";
import { useOnlineStatus, useSync, useWarnWhenUnsaved } from "@/features/sync";
import { useTrackPageChanges } from "@/lib/app-history";
import { findNewNoteButton, rememberNewNoteButton } from "@/lib/morph";
import { hasShortcutKey } from "@/lib/platform";
import { cn } from "@/lib/utils";
import { PageTransition } from "./page-transition";
import { useShellStore } from "./shell-store";
import { ShortcutsDialog } from "./shortcuts-dialog";
import { newNoteHref, Sidebar } from "./sidebar";

const GO_TO: Record<string, string> = {
  n: "/notes",
  a: "/archive",
  t: "/trash",
  s: "/settings",
};

export function AppShell({ children }: { children: React.ReactNode }) {
  useSync();
  useOnlineStatus();
  useWarnWhenUnsaved();
  useTrackPageChanges();
  const router = useRouter();
  const folded = usePreferencesStore((s) => s.ui.sidebarCollapsed);
  const setUI = usePreferencesStore((s) => s.setUIPreference);
  const { drawerOpen, setDrawer, barShown, shortcutsOpen, setShortcuts } =
    useShellStore();
  const drawerRef = React.useRef<HTMLDivElement>(null);
  const drawerOpener = React.useRef<HTMLElement | null>(null);
  const goPressedAt = React.useRef(0);

  React.useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented) return;
      // Read-only note text (.ql-editor) takes focus too.
      const typing = (e.target as HTMLElement)?.closest?.(
        "input, textarea, select, [contenteditable='true'], .ql-editor",
      );
      const mod = e.metaKey || e.ctrlKey;
      const inDialog = !!document.querySelector(
        ":is([role=dialog], [role=alertdialog], [role=menu]):not([data-state=closed])",
      );
      const isPlain = !typing && !mod && !e.altKey && !inDialog;
      // G and a letter goes to a page, as in Gmail; G G to the first note.
      const after = goPressedAt.current;
      goPressedAt.current = 0;
      if (isPlain && performance.now() - after < 1500) {
        const page = GO_TO[e.key];
        if (page || e.key === "g") {
          e.preventDefault();
          if (page) router.push(page);
          else focusEdgeCard("first");
          return;
        }
      }
      if (isPlain && e.key === "g") {
        e.preventDefault();
        goPressedAt.current = performance.now();
        return;
      }
      if (isPlain && e.key === "?") {
        e.preventDefault();
        setShortcuts(true);
        return;
      }
      if (mod && e.key === "\\") {
        e.preventDefault();
        setUI(
          "sidebarCollapsed",
          !usePreferencesStore.getState().ui.sidebarCollapsed,
        );
        return;
      }
      if (
        hasShortcutKey(e) &&
        !e.altKey &&
        e.key.toLowerCase() === "k" &&
        !inDialog
      ) {
        // SearchField handles Ctrl K itself.
        const field = document.querySelector<HTMLInputElement>(
          "main input[type=search]",
        );
        if (field?.closest("[data-search-field]")) return;
        e.preventDefault();
        if (field) {
          field.focus();
          field.select();
        } else router.push("/notes?search");
        return;
      }
      if (
        !typing &&
        !mod &&
        !e.altKey &&
        e.key.toLowerCase() === "n" &&
        !inDialog
      ) {
        e.preventDefault();
        startNote();
      }
    };
    const startNote = () => {
      rememberNewNoteButton(findNewNoteButton());
      const { pathname, search } = window.location;
      router.push(
        newNoteHref(pathname, new URLSearchParams(search).get("tagId")),
      );
    };
    document.addEventListener("keydown", onKey);
    // The desktop app's shortcut from anywhere on the computer.
    window.addEventListener("anchor:new-note", startNote);
    return () => {
      document.removeEventListener("keydown", onKey);
      window.removeEventListener("anchor:new-note", startNote);
    };
  }, [router, setUI, setShortcuts]);

  return (
    <div
      data-slot="app-shell"
      className="flex h-dvh overflow-hidden bg-background text-foreground"
    >
      <div className="hidden min-h-0 lg:flex">
        <Sidebar
          folded={folded}
          onToggleFold={() => setUI("sidebarCollapsed", !folded)}
        />
      </div>
      <DialogPrimitive.Root open={drawerOpen} onOpenChange={setDrawer}>
        <DialogPrimitive.Portal>
          <DialogPrimitive.Overlay className="fixed inset-0 z-(--z-scrim) bg-overlay animate-fade-in data-[state=closed]:pointer-events-none! data-[state=closed]:animate-fade-out lg:hidden" />
          <DialogPrimitive.Content
            ref={drawerRef}
            aria-describedby={undefined}
            onOpenAutoFocus={(e) => {
              e.preventDefault();
              drawerOpener.current = document.activeElement as HTMLElement;
              const drawer = drawerRef.current;
              const current = drawer?.querySelector<HTMLElement>(
                "a[aria-current=page]",
              );
              (current ?? drawer)?.focus();
            }}
            onCloseAutoFocus={(e) => {
              e.preventDefault();
              const opener = drawerOpener.current;
              drawerOpener.current = null;
              if (opener?.isConnected) opener.focus();
            }}
            className="fixed inset-y-0 left-0 z-(--z-drawer) flex overflow-hidden rounded-r-3xl shadow-menu outline-none animate-drawer-in data-[state=closed]:pointer-events-none! data-[state=closed]:animate-drawer-out lg:hidden"
          >
            <DialogPrimitive.Title className="sr-only">
              Menu
            </DialogPrimitive.Title>
            <Sidebar drawer onNavigate={() => setDrawer(false)} />
          </DialogPrimitive.Content>
        </DialogPrimitive.Portal>
      </DialogPrimitive.Root>
      <main className="relative flex min-w-0 flex-1 flex-col">
        <PageTransition>{children}</PageTransition>
        <Toaster className={cn(barShown && "bottom-20")} />
      </main>
      <ShortcutsDialog open={shortcutsOpen} onOpenChange={setShortcuts} />
    </div>
  );
}
