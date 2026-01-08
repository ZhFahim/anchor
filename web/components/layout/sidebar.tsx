"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useSearchParams, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import {
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
  MoreVertical,
  Pencil,
  AlertTriangle,
  Settings,
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { useTheme } from "next-themes";
import { useAuth } from "@/features/auth";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { getTags, updateTag, deleteTag, type Tag as TagType } from "@/features/tags";

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
  const router = useRouter();
  const { theme, setTheme } = useTheme();
  const { logout, user } = useAuth();
  const queryClient = useQueryClient();

  const [renameDialogOpen, setRenameDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedTag, setSelectedTag] = useState<TagType | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [renameError, setRenameError] = useState<string | null>(null);

  const { data: tags = [] } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  const updateTagMutation = useMutation({
    mutationFn: ({ id, name }: { id: string; name: string }) =>
      updateTag(id, { name }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setRenameDialogOpen(false);
      setSelectedTag(null);
      setRenameValue("");
      setRenameError(null);
    },
    onError: (error: Error) => {
      setRenameError(error.message || "Failed to rename tag");
    },
  });

  const deleteTagMutation = useMutation({
    mutationFn: (id: string) => deleteTag(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      // If we're currently viewing this tag, navigate to all notes
      if (searchParams?.get("tagId") === selectedTag?.id) {
        router.push("/notes");
      }
      setDeleteDialogOpen(false);
      setSelectedTag(null);
    },
  });

  // Extract the currently selected tag id from URL param, e.g. /notes?tagId=tagid123
  const tagIdParam = searchParams?.get("tagId");

  const handleRenameClick = (tag: TagType) => {
    setSelectedTag(tag);
    setRenameValue(tag.name);
    setRenameError(null);
    setRenameDialogOpen(true);
  };

  const handleDeleteClick = (tag: TagType) => {
    setSelectedTag(tag);
    setDeleteDialogOpen(true);
  };

  const handleRenameSubmit = () => {
    if (selectedTag && renameValue.trim() && renameValue.trim() !== selectedTag.name) {
      setRenameError(null);
      updateTagMutation.mutate({ id: selectedTag.id, name: renameValue.trim() });
    }
  };

  const handleRenameValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setRenameValue(e.target.value);
    // Clear error when user starts typing
    if (renameError) {
      setRenameError(null);
    }
  };

  const handleDeleteSubmit = () => {
    if (selectedTag) {
      deleteTagMutation.mutate(selectedTag.id);
    }
  };

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
            <Image
              src="/icons/anchor_icon.png"
              alt="Anchor"
              width={36}
              height={36}
            />
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

        {/* Middle Content - Navigation and Tags */}
        <div className="flex-1 min-h-0 flex flex-col overflow-hidden">
          {/* Navigation */}
          <div className={cn("space-y-1", isCollapsed ? "px-2 py-2" : "px-3 py-2")}>
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
              <Separator className={cn("bg-sidebar-border")} />
              {isCollapsed ? (
                <ScrollArea className="flex-1 min-h-0">
                  <div className="space-y-1 px-2 py-2">
                    {tags.map((tag) => {
                      const isTagActive = pathname === "/notes" && tagIdParam === String(tag.id);
                      const TagLink = (
                        <Link
                          key={tag.id}
                          href={`/notes?tagId=${tag.id}`}
                          onClick={handleNavClick}
                          className={cn(
                            "flex items-center justify-center",
                            "h-10 w-10 mx-auto rounded-xl",
                            "transition-all duration-200",
                            isTagActive
                              ? "bg-sidebar-accent text-sidebar-accent-foreground"
                              : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
                          )}
                          aria-current={isTagActive ? "page" : undefined}
                        >
                          <LucideHash
                            className="h-4 w-4"
                            style={{ color: tag.color || "var(--accent)" }}
                          />
                        </Link>
                      );
                      return (
                        <Tooltip key={tag.id}>
                          <TooltipTrigger asChild>{TagLink}</TooltipTrigger>
                          <TooltipContent side="right">
                            <div className="flex items-center gap-2">
                              <span>{tag.name}</span>
                              {tag._count && (
                                <span className="text-xs opacity-60">({tag._count.notes})</span>
                              )}
                            </div>
                          </TooltipContent>
                        </Tooltip>
                      );
                    })}
                  </div>
                </ScrollArea>
              ) : (
                <ScrollArea className="flex-1 min-h-0">
                  <div className="space-y-1 px-3 py-2">
                    <div className="flex w-full items-center gap-2 px-3 py-2 text-xs font-semibold uppercase tracking-wider text-sidebar-foreground/50">
                      <Tag className="h-3 w-3" />
                      <span>Tags</span>
                    </div>
                    <div className="space-y-1">
                      {tags.map((tag) => {
                        // Active if we are in /notes?tagId=this_tag.id
                        const isTagActive = pathname === "/notes" && tagIdParam === String(tag.id);
                        return (
                          <div
                            key={tag.id}
                            className={cn(
                              "group flex items-center gap-2 rounded-xl px-3 py-2 text-sm transition-colors",
                              isTagActive
                                ? "bg-sidebar-accent text-sidebar-accent-foreground"
                                : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
                            )}
                          >
                            <Link
                              href={`/notes?tagId=${tag.id}`}
                              onClick={handleNavClick}
                              className={cn(
                                "flex items-center gap-3 flex-1 min-w-0",
                              )}
                              aria-current={isTagActive ? "page" : undefined}
                            >
                              <LucideHash
                                className="h-3 w-3 flex-shrink-0"
                                style={{ color: tag.color || "var(--accent)" }}
                              />
                              <span className="flex-1 truncate">{tag.name}</span>
                            </Link>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className={cn(
                                    "h-6 w-6 opacity-0 group-hover:opacity-100 transition-opacity",
                                    "text-sidebar-foreground/50 hover:text-sidebar-foreground"
                                  )}
                                  onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                  }}
                                >
                                  <MoreVertical className="h-3 w-3" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end" side="right">
                                <DropdownMenuItem
                                  onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleRenameClick(tag);
                                  }}
                                >
                                  <Pencil className="h-4 w-4" />
                                  <span>Rename tag</span>
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                  variant="destructive"
                                  onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleDeleteClick(tag);
                                  }}
                                >
                                  <Trash2 className="h-4 w-4" />
                                  <span>Delete tag</span>
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                            {tag._count && (
                              <span className="text-xs text-sidebar-foreground/40 font-medium">
                                {tag._count.notes}
                              </span>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </ScrollArea>
              )}
            </>
          )}
        </div>

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

          {/* Admin */}
          {user?.isAdmin && (
            <>
              {isCollapsed ? (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Link
                      href="/admin"
                      onClick={handleNavClick}
                      className={cn(
                        "flex items-center justify-center",
                        "w-10 h-10 mx-auto rounded-xl",
                        "text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent/50",
                        "transition-all duration-200"
                      )}
                    >
                      <Settings className="h-4 w-4" />
                    </Link>
                  </TooltipTrigger>
                  <TooltipContent side="right">Admin</TooltipContent>
                </Tooltip>
              ) : (
                <Link
                  href="/admin"
                  onClick={handleNavClick}
                  className={cn(
                    "flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200",
                    pathname === "/admin"
                      ? "bg-sidebar-accent text-sidebar-accent-foreground"
                      : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
                  )}
                >
                  <Settings className="h-4 w-4" />
                  Admin
                </Link>
              )}
            </>
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

          {/* Settings */}
          {isCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Link
                  href="/settings"
                  onClick={handleNavClick}
                  className={cn(
                    "flex items-center justify-center",
                    "w-10 h-10 mx-auto rounded-xl",
                    "text-sidebar-foreground/70 hover:text-sidebar-foreground hover:bg-sidebar-accent/50",
                    "transition-all duration-200"
                  )}
                >
                  <Settings className="h-4 w-4" />
                </Link>
              </TooltipTrigger>
              <TooltipContent side="right">Settings</TooltipContent>
            </Tooltip>
          ) : (
            <Link
              href="/settings"
              onClick={handleNavClick}
              className={cn(
                "flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200",
                pathname === "/settings"
                  ? "bg-sidebar-accent text-sidebar-accent-foreground"
                  : "text-sidebar-foreground/70 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground"
              )}
            >
              <Settings className="h-4 w-4" />
              Settings
            </Link>
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

        {/* Rename Tag Dialog */}
        <Dialog open={renameDialogOpen} onOpenChange={setRenameDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Rename Tag</DialogTitle>
              <DialogDescription>
                Enter a new name for this tag.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4 space-y-2">
              <Input
                value={renameValue}
                onChange={handleRenameValueChange}
                placeholder="Tag name"
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    handleRenameSubmit();
                  }
                }}
                className={cn(
                  renameError && "border-destructive focus:border-destructive focus:ring-destructive/20"
                )}
                autoFocus
              />
              {renameError && (
                <p className="text-xs text-destructive px-1">
                  {renameError}
                </p>
              )}
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setRenameDialogOpen(false);
                  setSelectedTag(null);
                  setRenameValue("");
                  setRenameError(null);
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleRenameSubmit}
                variant={renameError ? "destructive" : "default"}
                disabled={!renameValue.trim() || renameValue.trim() === selectedTag?.name || updateTagMutation.isPending}
              >
                {updateTagMutation.isPending ? "Renaming..." : "Rename"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Delete Tag Dialog */}
        <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 rounded-full bg-destructive/10">
                  <AlertTriangle className="h-5 w-5 text-destructive" />
                </div>
                <DialogTitle>Delete Tag</DialogTitle>
              </div>
              <DialogDescription>
                Delete <span className="font-semibold">{selectedTag?.name}</span>? This will remove it from all notes. This action cannot be undone.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setDeleteDialogOpen(false);
                  setSelectedTag(null);
                }}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={handleDeleteSubmit}
                disabled={deleteTagMutation.isPending}
              >
                {deleteTagMutation.isPending ? "Deleting..." : "Delete"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </TooltipProvider>
  );
}
