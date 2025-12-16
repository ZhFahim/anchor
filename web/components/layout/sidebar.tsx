"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  Anchor,
  FileText,
  Trash2,
  Archive,
  Tag,
  LogOut,
  Moon,
  Sun,
  Monitor,
  ChevronRight,
  ChevronLeft,
  LucideHash,
  Plus,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
  TooltipProvider,
} from "@/components/ui/tooltip";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { useTheme } from "next-themes";
import { useAuth } from "@/features/auth";
import { useQuery } from "@tanstack/react-query";
import { getTags } from "@/features/tags";
import { useState } from "react";

interface SidebarProps {
  className?: string;
  onNavigate?: () => void;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
}

export function Sidebar({
  className,
  onNavigate,
  isCollapsed = false,
  onToggleCollapse,
}: SidebarProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { theme, setTheme } = useTheme();
  const { logout, user } = useAuth();
  const [tagsOpen, setTagsOpen] = useState(true);

  const { data: tags = [] } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  // Extract the currently selected tag id from URL param, e.g. /notes?tagId=tagid123
  const tagIdParam = searchParams?.get("tagId");

  const navItems = [
    {
      href: "/notes",
      label: "All Notes",
      icon: FileText,
    },
    {
      href: "/archive",
      label: "Archive",
      icon: Archive,
    },
    {
      href: "/trash",
      label: "Trash",
      icon: Trash2,
    },
  ];

  const handleNavClick = () => {
    onNavigate?.();
  };

  const cycleTheme = () => {
    if (theme === "light") {
      setTheme("dark");
    } else if (theme === "dark") {
      setTheme("system");
    } else {
      setTheme("light");
    }
  };

  const ThemeIcon = theme === "dark" ? Moon : theme === "light" ? Sun : Monitor;
  const themeLabel =
    theme === "dark" ? "Dark" : theme === "light" ? "Light" : "System";

  return (
    <TooltipProvider delayDuration={0}>
      <div className={cn("flex h-full flex-col bg-sidebar", className)}>
        {/* Header */}
        <div
          className={cn(
            "flex h-16 items-center border-b border-sidebar-border transition-all duration-300",
            isCollapsed ? "justify-center px-2" : "justify-between px-4"
          )}
        >
          <div className={cn("flex items-center gap-2", isCollapsed && "justify-center")}>
            <div className="w-9 h-9 bg-accent/10 rounded-xl flex items-center justify-center flex-shrink-0">
              <Anchor className="w-5 h-5 text-accent" />
            </div>
            {!isCollapsed && (
              <span className="font-serif text-xl font-bold text-sidebar-foreground">
                Anchor
              </span>
            )}
          </div>
          {!isCollapsed && onToggleCollapse && (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={onToggleCollapse}
                  className="h-8 w-8 text-sidebar-foreground/50 hover:text-sidebar-foreground"
                >
                  <ChevronLeft className="h-4 w-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right">Collapse sidebar</TooltipContent>
            </Tooltip>
          )}
        </div>

        {/* Collapse toggle for collapsed state */}
        {isCollapsed && onToggleCollapse && (
          <div className="flex justify-center py-2 border-b border-sidebar-border">
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={onToggleCollapse}
                  className="h-8 w-8 text-sidebar-foreground/50 hover:text-sidebar-foreground"
                >
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right">Expand sidebar</TooltipContent>
            </Tooltip>
          </div>
        )}

        {/* New Note Button */}
        <div className={cn("px-3 pt-4 pb-2", isCollapsed && "px-2")}>
          {isCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Link
                  href="/notes/new"
                  onClick={handleNavClick}
                  className={cn(
                    "group flex items-center justify-center",
                    "w-12 h-12 mx-auto",
                    "rounded-2xl",
                    "border-2 border-dashed border-accent/40",
                    "bg-accent/5",
                    "text-accent",
                    "transition-all duration-300 ease-out",
                    "hover:border-solid hover:border-accent",
                    "hover:bg-accent hover:text-accent-foreground",
                    "hover:shadow-lg hover:shadow-accent/20",
                    "active:scale-95"
                  )}
                >
                  <Plus className="h-6 w-6 transition-transform duration-300 group-hover:rotate-180" strokeWidth={2} />
                </Link>
              </TooltipTrigger>
              <TooltipContent side="right">New Note</TooltipContent>
            </Tooltip>
          ) : (
            <Link
              href="/notes/new"
              onClick={handleNavClick}
              className={cn(
                "group relative flex items-center gap-3",
                "w-full h-12 px-4",
                "rounded-2xl",
                "border-2 border-dashed border-accent/40",
                "bg-accent/5",
                "text-accent font-medium",
                "transition-all duration-300 ease-out",
                "hover:border-solid hover:border-accent",
                "hover:bg-accent hover:text-accent-foreground",
                "hover:shadow-lg hover:shadow-accent/20",
                "active:scale-[0.98]"
              )}
            >
              <Plus className="h-5 w-5 transition-transform duration-300 group-hover:rotate-180" strokeWidth={2} />
              <span>New Note</span>
            </Link>
          )}
        </div>

        {/* Navigation */}
        <ScrollArea className="flex-1 px-3 py-2">
          <div className="space-y-1">
            {navItems.map((item) => {
              const isActive = pathname === item.href && !(item.href === "/notes" && tagIdParam);
              const NavLink = (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={handleNavClick}
                  className={cn(
                    "flex items-center rounded-xl text-sm font-medium transition-all duration-200",
                    isCollapsed
                      ? "justify-center h-10 w-10 mx-auto"
                      : "gap-3 px-3 py-2.5",
                    isActive
                      ? "bg-sidebar-accent text-sidebar-accent-foreground"
                      : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
                  )}
                  aria-current={isActive ? "page" : undefined}
                >
                  <item.icon className="h-4 w-4 flex-shrink-0" />
                  {!isCollapsed && item.label}
                </Link>
              );

              if (isCollapsed) {
                return (
                  <Tooltip key={item.href}>
                    <TooltipTrigger asChild>{NavLink}</TooltipTrigger>
                    <TooltipContent side="right">{item.label}</TooltipContent>
                  </Tooltip>
                );
              }

              return NavLink;
            })}
          </div>

          {/* Tags Section */}
          {tags.length > 0 && (
            <>
              <Separator className="my-4 bg-sidebar-border" />
              {isCollapsed ? (
                <div className="space-y-1">
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="flex justify-center">
                        <div className="h-10 w-10 rounded-xl flex items-center justify-center text-sidebar-foreground/50">
                          <Tag className="h-4 w-4" />
                        </div>
                      </div>
                    </TooltipTrigger>
                    <TooltipContent side="right">
                      <div className="space-y-1">
                        <span className="font-semibold">Tags</span>
                        <div className="text-xs opacity-70">
                          {tags.map((tag) => tag.name).join(", ")}
                        </div>
                      </div>
                    </TooltipContent>
                  </Tooltip>
                </div>
              ) : (
                <Collapsible open={tagsOpen} onOpenChange={setTagsOpen}>
                  <CollapsibleTrigger className="flex w-full items-center gap-2 px-3 py-2 text-xs font-semibold uppercase tracking-wider text-sidebar-foreground/50 hover:text-sidebar-foreground/70 transition-colors">
                    <Tag className="h-3 w-3" />
                    <span className="flex-1 text-left">Tags</span>
                    <ChevronRight
                      className={cn(
                        "h-3 w-3 transition-transform duration-200",
                        tagsOpen && "rotate-90"
                      )}
                    />
                  </CollapsibleTrigger>
                  <CollapsibleContent className="space-y-1 overflow-hidden data-[state=closed]:animate-collapsible-up data-[state=open]:animate-collapsible-down">
                    {tags.map((tag) => {
                      // Active if we are in /notes?tagId=this_tag.id
                      const isTagActive = pathname === "/notes" && tagIdParam === String(tag.id);
                      return (
                        <Link
                          key={tag.id}
                          href={`/notes?tagId=${tag.id}`}
                          onClick={handleNavClick}
                          className={cn(
                            "flex items-center gap-3 rounded-xl px-3 py-2 text-sm transition-colors",
                            isTagActive
                              ? "bg-sidebar-accent text-sidebar-accent-foreground"
                              : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
                          )}
                          aria-current={isTagActive ? "page" : undefined}
                        >
                          <LucideHash
                            className="h-3 w-3"
                            style={{ color: tag.color || "var(--accent)" }}
                          />
                          <span className="flex-1 truncate">{tag.name}</span>
                        </Link>
                      );
                    })}
                  </CollapsibleContent>
                </Collapsible>
              )}
            </>
          )}
        </ScrollArea>

        {/* Footer */}
        <div className="border-t border-sidebar-border p-3 space-y-2">
          {/* User info */}
          {user && !isCollapsed && (
            <div className="px-3 py-2">
              <p className="text-xs text-sidebar-foreground/50 truncate">
                {user.email}
              </p>
            </div>
          )}

          {/* Theme toggle */}
          {isCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={cycleTheme}
                  className="w-full h-10 text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent/50"
                >
                  <ThemeIcon className="h-4 w-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right">{themeLabel} theme</TooltipContent>
            </Tooltip>
          ) : (
            <Button
              variant="ghost"
              size="sm"
              onClick={cycleTheme}
              className="w-full justify-start gap-3 text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent/50"
            >
              <ThemeIcon className="h-4 w-4" />
              {themeLabel}
            </Button>
          )}

          {/* Logout */}
          {isCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={logout}
                  className="w-full h-10 text-sidebar-foreground/70 hover:text-destructive hover:bg-destructive/10"
                >
                  <LogOut className="h-4 w-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right">Sign Out</TooltipContent>
            </Tooltip>
          ) : (
            <Button
              variant="ghost"
              size="sm"
              onClick={logout}
              className="w-full justify-start gap-3 text-sidebar-foreground/70 hover:text-destructive hover:bg-destructive/10"
            >
              <LogOut className="h-4 w-4" />
              Sign Out
            </Button>
          )}
        </div>
      </div>
    </TooltipProvider>
  );
}
