"use client";

import * as DialogPrimitive from "@radix-ui/react-dialog";
import { useRouter } from "next/navigation";
import * as React from "react";
import { Toaster } from "@/components/ui/toast";
import { usePreferencesStore } from "@/features/preferences";
import { useOnlineStatus, useSync, useWarnWhenUnsaved } from "@/features/sync";
import { useTrackPageChanges } from "@/lib/app-history";
import { findNewNoteButton, rememberNewNoteButton } from "@/lib/morph";
import { hasShortcutKey } from "@/lib/platform";
import { cn } from "@/lib/utils";
import { PageTransition } from "./page-transition";
import { useShellStore } from "./shell-store";
import { newNoteHref, Sidebar } from "./sidebar";

export function AppShell({ children }: { children: React.ReactNode }) {
  useSync();
  useOnlineStatus();
  useWarnWhenUnsaved();
  useTrackPageChanges();
  const router = useRouter();
  const folded = usePreferencesStore((s) => s.ui.sidebarCollapsed);
  const setUI = usePreferencesStore((s) => s.setUIPreference);
  const { drawerOpen, setDrawer, barShown } = useShellStore();
  const drawerRef = React.useRef<HTMLDivElement>(null);
  const drawerOpener = React.useRef<HTMLElement | null>(null);

  React.useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented) return;
      // Read-only note text (.ql-editor) takes focus too.
      const typing = (e.target as HTMLElement)?.closest?.(
        "input, textarea, select, [contenteditable='true'], .ql-editor",
      );
      const mod = e.metaKey || e.ctrlKey;
      const inDialog = !!document.querySelector(
        "[role=dialog], [role=alertdialog], [role=menu]",
      );
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
        rememberNewNoteButton(findNewNoteButton());
        const { pathname, search } = window.location;
        router.push(
          newNoteHref(pathname, new URLSearchParams(search).get("tagId")),
        );
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [router, setUI]);

  return (
    <div className="flex h-dvh overflow-hidden bg-background text-foreground">
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
    </div>
  );
}
