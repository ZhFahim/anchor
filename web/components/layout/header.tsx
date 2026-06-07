"use client";

import { Command, Menu, Search, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";
import { Sidebar } from "./sidebar";

interface HeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
}

export function Header({ searchQuery, onSearchChange }: HeaderProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isSearchFocused, setIsSearchFocused] = useState(false);
  const isMac =
    typeof window !== "undefined" &&
    navigator.userAgent.toLowerCase().includes("mac");
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut: Cmd+K or Ctrl+K to focus search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        searchInputRef.current?.focus();
      }
      // Escape to blur search
      if (e.key === "Escape" && isSearchFocused) {
        searchInputRef.current?.blur();
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isSearchFocused]);

  return (
    <header
      className={cn(
        "sticky top-0 z-40",
        "flex h-16 items-center gap-3",
        "bg-background/60 backdrop-blur-2xl",
        "border-b border-border/30",
        "px-4 lg:px-6",
        "transition-all duration-300",
      )}
    >
      {/* Mobile menu */}
      <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
        <SheetTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            className={cn(
              "lg:hidden h-10 w-10 rounded-xl",
              "hover:bg-accent/80",
              "transition-all duration-200",
            )}
            aria-label="Open menu"
          >
            <Menu className="h-5 w-5" />
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="w-72 p-0">
          <SheetTitle className="sr-only">Navigation Menu</SheetTitle>
          <Sidebar onNavigate={() => setSidebarOpen(false)} />
        </SheetContent>
      </Sheet>

      {/* Search */}
      <div className="flex-1 flex justify-center">
        <div className="relative w-full max-w-xl">
          <div
            className={cn(
              "relative flex items-center",
              "rounded-md",
              "bg-muted/50",
              "border border-border/40",
              "transition-colors duration-200",
              isSearchFocused && ["bg-card", "border-border"],
            )}
          >
            <Search
              className={cn(
                "absolute left-4 h-4 w-4 pointer-events-none",
                "transition-colors duration-200",
                isSearchFocused ? "text-accent" : "text-muted-foreground",
              )}
            />
            <input
              ref={searchInputRef}
              type="text"
              placeholder="Search notes..."
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              onFocus={() => setIsSearchFocused(true)}
              onBlur={() => setIsSearchFocused(false)}
              className={cn(
                "w-full h-11 pl-11 pr-24",
                "bg-transparent",
                "rounded-md",
                "text-sm text-foreground",
                "placeholder:text-muted-foreground/50",
              )}
            />

            {/* Clear button or keyboard shortcut */}
            <div className="absolute right-3 flex items-center gap-2">
              {searchQuery ? (
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7 rounded-md hover:bg-accent/50"
                  onClick={() => {
                    onSearchChange("");
                    searchInputRef.current?.focus();
                  }}
                >
                  <X className="h-4 w-4" />
                </Button>
              ) : (
                <button
                  type="button"
                  onClick={() => searchInputRef.current?.focus()}
                  className={cn(
                    "hidden sm:flex items-center gap-1",
                    "px-2 py-1 rounded-md",
                    "bg-muted/60 text-muted-foreground/60",
                    "text-xs font-medium",
                    "hover:bg-muted hover:text-muted-foreground",
                    "transition-all duration-200",
                    isSearchFocused && "opacity-0 pointer-events-none",
                  )}
                >
                  {isMac ? (
                    <>
                      <Command className="h-3 w-3" />
                      <span>K</span>
                    </>
                  ) : (
                    <span>Ctrl+K</span>
                  )}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Spacer for balance on mobile */}
      <div className="w-10 lg:hidden" />
    </header>
  );
}
