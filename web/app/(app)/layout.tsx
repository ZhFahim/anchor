"use client";

import { useEffect, useState } from "react";
import { type ReactNode } from "react";
import { Sidebar } from "@/components/layout";
import { AuthGuard } from "@/features/auth";
import { cn } from "@/lib/utils";
import { usePreferencesStore } from "@/features/preferences";

export default function AppLayout({ children }: { children: ReactNode }) {
  const { ui, setUIPreference } = usePreferencesStore();
  const isCollapsed = ui.sidebarCollapsed;
  const toggleCollapsed = () => setUIPreference("sidebarCollapsed", !isCollapsed);
  const [transitionsEnabled, setTransitionsEnabled] = useState(false);

  useEffect(() => {
    if (usePreferencesStore.persist.hasHydrated()) {
      const frame = window.requestAnimationFrame(() => setTransitionsEnabled(true));
      return () => window.cancelAnimationFrame(frame);
    }

    const unsubscribe = usePreferencesStore.persist.onFinishHydration(() => {
      window.requestAnimationFrame(() => setTransitionsEnabled(true));
    });

    return () => {
      unsubscribe();
    };
  }, []);

  return (
    <AuthGuard>
      <div className="min-h-screen bg-background">
        {/* Desktop Sidebar */}
        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-50 hidden overflow-hidden border-r border-border lg:block",
            transitionsEnabled
              ? "transition-all duration-500 ease-in-out"
              : "transition-none",
            isCollapsed ? "w-[72px]" : "w-64"
          )}
        >
          <Sidebar
            isCollapsed={isCollapsed}
            onToggleCollapse={toggleCollapsed}
            animateCollapse={transitionsEnabled}
          />
        </aside>

        {/* Main Content */}
        <main
          className={cn(
            "min-h-screen",
            transitionsEnabled
              ? "transition-all duration-500 ease-in-out"
              : "transition-none",
            isCollapsed ? "lg:pl-[72px]" : "lg:pl-64"
          )}
        >
          {children}
        </main>
      </div>
    </AuthGuard>
  );
}
