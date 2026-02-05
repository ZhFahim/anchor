"use client";

import { type ReactNode } from "react";
import { Sidebar } from "@/components/layout";
import { AuthGuard } from "@/features/auth";
import { cn } from "@/lib/utils";
import { usePreferencesStore } from "@/features/preferences";

export default function AppLayout({ children }: { children: ReactNode }) {
  const { ui, setUIPreference } = usePreferencesStore();
  const isCollapsed = ui.sidebarCollapsed;
  const toggleCollapsed = () => setUIPreference("sidebarCollapsed", !isCollapsed);

  return (
    <AuthGuard>
      <div className="min-h-screen bg-background">
        {/* Desktop Sidebar */}
        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-50 hidden border-r border-border lg:block",
            "transition-all duration-300 ease-in-out",
            isCollapsed ? "w-[72px]" : "w-64"
          )}
        >
          <Sidebar isCollapsed={isCollapsed} onToggleCollapse={toggleCollapsed} />
        </aside>

        {/* Main Content */}
        <main
          className={cn(
            "min-h-screen transition-all duration-300 ease-in-out",
            isCollapsed ? "lg:pl-[72px]" : "lg:pl-64"
          )}
        >
          {children}
        </main>
      </div>
    </AuthGuard>
  );
}
