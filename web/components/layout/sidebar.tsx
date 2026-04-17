"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useSearchParams, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  FileText,
  Trash2,
  Archive,
  LogOut,
  Moon,
  Sun,
  Monitor,
  ChevronRight,
  ChevronLeft,
  LucideHash,
  Plus,
  UserCog,
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
  DropdownMenuSeparator,
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
import { getTags, updateTag, deleteTag, TAG_COLORS, type Tag as TagType } from "@/features/tags";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

interface SidebarProps {
  className?: string;
  onNavigate?: () => void;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
  animateCollapse?: boolean;
}

const SIDEBAR_CONTENT_SWAP_MS = 500;
const railIconSlot = "flex h-10 w-10 shrink-0 items-center justify-center";
const railIconClass =
  "h-4 w-4 transition-colors duration-200";
const sidebarItemActiveClass = "bg-sidebar-accent text-sidebar-accent-foreground";
const sidebarItemInactiveClass =
  "text-sidebar-foreground/70 hover:bg-sidebar-accent/70 hover:text-sidebar-foreground";

function normalizePath(path: string | null | undefined): string {
  if (!path) return "/";

  const withoutQuery = path.split("?")[0] ?? "/";
  const trimmed = withoutQuery.replace(/\/+$/, "") || "/";
  const withoutLocaleAppPrefix = trimmed.replace(
    /^\/[a-z]{2}(?:-[a-z]{2})?\/app(?=\/|$)/i,
    ""
  );

  return withoutLocaleAppPrefix || "/";
}

export function Sidebar({
  className,
  onNavigate,
  isCollapsed = false,
  onToggleCollapse,
  animateCollapse = true,
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
  const [renameColor, setRenameColor] = useState<string>(TAG_COLORS[0]);
  const [renameError, setRenameError] = useState<string | null>(null);
  const [animatedCollapsed, setAnimatedCollapsed] = useState(isCollapsed);
  const renderCollapsed = animateCollapse ? animatedCollapsed : isCollapsed;

  useEffect(() => {
    if (!animateCollapse) {
      return;
    }

    const timer = setTimeout(
      () => setAnimatedCollapsed(isCollapsed),
      isCollapsed ? SIDEBAR_CONTENT_SWAP_MS : 0
    );

    return () => {
      clearTimeout(timer);
    };
  }, [isCollapsed, animateCollapse]);

  const { data: tags = [] } = useQuery({
    queryKey: ["tags"],
    queryFn: getTags,
  });

  const updateTagMutation = useMutation({
    mutationFn: ({
      id,
      name,
      color,
    }: {
      id: string;
      name: string;
      color?: string;
    }) => updateTag(id, { name, color }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setRenameDialogOpen(false);
      setSelectedTag(null);
      setRenameValue("");
      setRenameColor(TAG_COLORS[0]);
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
  const normalizedPathname = normalizePath(pathname);
  const isNotesPath = normalizedPathname === "/" || normalizedPathname === "/notes";
  const isRouteActive = (href: string) => normalizePath(href) === normalizedPathname;

  const handleRenameClick = (tag: TagType) => {
    setSelectedTag(tag);
    setRenameValue(tag.name);
    setRenameColor(tag.color || TAG_COLORS[0]);
    setRenameError(null);
    setRenameDialogOpen(true);
  };

  const handleDeleteClick = (tag: TagType) => {
    setSelectedTag(tag);
    setDeleteDialogOpen(true);
  };

  const handleRenameSubmit = () => {
    if (!selectedTag || !renameValue.trim()) {
      return;
    }

    const nextName = renameValue.trim();
    const nextColor = renameColor;

    if (nextName === selectedTag.name && nextColor === (selectedTag.color || TAG_COLORS[0])) {
      setRenameDialogOpen(false);
      setSelectedTag(null);
      setRenameValue("");
      setRenameColor(TAG_COLORS[0]);
      setRenameError(null);
      return;
    }

    if (selectedTag) {
      setRenameError(null);
      updateTagMutation.mutate({
        id: selectedTag.id,
        name: nextName,
        color: nextColor,
      });
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
      <div className={cn("flex h-full flex-col overflow-hidden bg-sidebar", className)}>
        {/* Header */}
        <div className="flex h-16 items-center border-b border-sidebar-border px-3">
          <Link
            href="/notes"
            onClick={onNavigate}
            className={cn(
              "flex min-w-0 items-center gap-2 transition-colors hover:opacity-80",
              renderCollapsed ? "w-10" : "w-full"
            )}
          >
            <span className={railIconSlot}>
              <Image
                src="/icons/anchor_icon.png"
                alt="Anchor"
                width={36}
                height={36}
              />
            </span>
            {!renderCollapsed && (
              <span className="min-w-0 truncate font-serif text-xl font-bold text-sidebar-foreground">
                Anchor
              </span>
            )}
          </Link>
        </div>

        {/* Collapse toggle */}
        {onToggleCollapse && (
          <div className="flex h-12 items-center border-b border-sidebar-border px-3">
            {renderCollapsed ? (
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    onClick={onToggleCollapse}
                    className={cn(
                      "group flex h-10 w-10 min-h-10 shrink-0 items-center justify-center rounded-xl border border-transparent bg-transparent transition-colors",
                      "text-sidebar-foreground/70 hover:bg-accent/15 hover:text-accent active:bg-accent/25"
                    )}
                  >
                    <ChevronRight className={railIconClass} />
                  </Button>
                </TooltipTrigger>
                <TooltipContent side="right">Expand sidebar</TooltipContent>
              </Tooltip>
            ) : (
              <Button
                variant="ghost"
                onClick={onToggleCollapse}
                className={cn(
                  "group flex h-10 w-full items-center justify-start gap-0 rounded-xl border border-transparent pl-0 pr-3 text-sm font-medium transition-colors",
                  "text-sidebar-foreground/70 hover:bg-accent/15 hover:text-accent active:bg-accent/25"
                )}
              >
                <span className={railIconSlot}>
                  <ChevronLeft className={railIconClass} />
                </span>
                <span className="truncate whitespace-nowrap">Collapse sidebar</span>
              </Button>
            )}
          </div>
        )}

        {/* New Note Button */}
        <div className="px-3 pb-2 pt-4">
          {renderCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Link
                  href="/notes/new"
                  onClick={handleNavClick}
                  className={cn(
                    "group relative flex h-12 w-12 items-center gap-0 overflow-hidden pl-0",
                    "rounded-2xl",
                    "border-2 border-dashed border-accent/40",
                    "bg-accent/5",
                    "text-accent",
                    "transition-colors duration-200",
                    "hover:border-solid hover:border-accent",
                    "hover:bg-accent hover:text-accent-foreground",
                    "hover:shadow-lg hover:shadow-accent/20",
                    "active:scale-95"
                  )}
                >
                  <span className="flex h-12 w-12 shrink-0 items-center justify-center">
                    <Plus className="h-5 w-5 transition-transform duration-200 group-hover:rotate-180" strokeWidth={2} />
                  </span>
                </Link>
              </TooltipTrigger>
              <TooltipContent side="right">New Note</TooltipContent>
            </Tooltip>
          ) : (
            <Link
              href="/notes/new"
              onClick={handleNavClick}
              className={cn(
                "group relative flex h-12 w-full items-center gap-0 overflow-hidden",
                "w-full h-12 pl-0 pr-4",
                "rounded-2xl",
                "border-2 border-dashed border-accent/40",
                "bg-accent/5",
                "text-accent font-medium",
                "transition-colors duration-200",
                "hover:border-solid hover:border-accent",
                "hover:bg-accent hover:text-accent-foreground",
                "hover:shadow-lg hover:shadow-accent/20",
                "active:scale-[0.98]"
              )}
            >
              <span className="flex h-12 w-12 shrink-0 items-center justify-center">
                <Plus className="h-5 w-5 transition-transform duration-200 group-hover:rotate-180" strokeWidth={2} />
              </span>
              <span className="truncate whitespace-nowrap">New Note</span>
            </Link>
          )}
        </div>

        {/* Middle Content - Navigation and Tags */}
        <div className="flex-1 min-h-0 flex flex-col overflow-hidden">
          {/* Navigation */}
          <div className="space-y-1 px-3 py-2">
            {navItems.map((item) => {
              const isActive =
                isRouteActive(item.href) && !(item.href === "/notes" && tagIdParam);
              const NavLink = (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={handleNavClick}
                  className={cn(
                    "group flex h-10 min-w-0 items-center overflow-hidden rounded-xl text-sm font-medium transition-colors duration-200",
                    renderCollapsed
                      ? "justify-center h-10 w-10"
                      : "gap-0 pl-0 pr-3",
                    isActive
                      ? sidebarItemActiveClass
                      : sidebarItemInactiveClass
                  )}
                  aria-current={isActive ? "page" : undefined}
                >
                  {renderCollapsed ? (
                    <item.icon className={railIconClass} />
                  ) : (
                    <span className={railIconSlot}>
                      <item.icon className={railIconClass} />
                    </span>
                  )}
                  {!renderCollapsed && <span className="truncate whitespace-nowrap">{item.label}</span>}
                </Link>
              );

              if (renderCollapsed) {
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
              {renderCollapsed ? (
                <ScrollArea className="flex-1 min-h-0">
                  <div className="space-y-1 px-3 py-2">
                    {tags.map((tag) => {
                      const isTagActive = isNotesPath && tagIdParam === String(tag.id);
                      const TagLink = (
                        <Link
                          key={tag.id}
                          href={`/notes?tagId=${tag.id}`}
                          onClick={handleNavClick}
                          className={cn(
                            "group flex items-center justify-center",
                            "h-10 w-10 rounded-xl",
                            "transition-colors duration-200",
                            isTagActive
                              ? sidebarItemActiveClass
                              : sidebarItemInactiveClass
                          )}
                          aria-current={isTagActive ? "page" : undefined}
                        >
                          <span className={railIconSlot}>
                            <LucideHash
                              className="h-4 w-4 flex-shrink-0"
                              style={{ color: tag.color || "var(--accent)" }}
                            />
                          </span>
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
                    <div className="space-y-1">
                      {tags.map((tag) => {
                        // Active if we are in /notes?tagId=this_tag.id
                        const isTagActive = isNotesPath && tagIdParam === String(tag.id);
                        return (
                          <div
                            key={tag.id}
                            className={cn(
                              "group flex h-10 items-center gap-0 rounded-xl pl-0 pr-3 text-sm transition-colors",
                              isTagActive
                                ? sidebarItemActiveClass
                                : sidebarItemInactiveClass
                            )}
                          >
                            <Link
                              href={`/notes?tagId=${tag.id}`}
                              onClick={handleNavClick}
                              className={cn(
                                "flex items-center gap-0 flex-1 min-w-0",
                              )}
                              aria-current={isTagActive ? "page" : undefined}
                            >
                              <span className={railIconSlot}>
                                <LucideHash
                                  className="h-4 w-4 flex-shrink-0"
                                  style={{ color: tag.color || "var(--accent)" }}
                                />
                              </span>
                              <span className="flex-1 truncate">{tag.name}</span>
                            </Link>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className={cn(
                                    "h-6 w-6 rounded-md transition-opacity",
                                    isTagActive
                                      ? "opacity-100 pointer-events-auto"
                                      : "opacity-0 pointer-events-none group-hover:opacity-100 group-hover:pointer-events-auto group-focus-within:opacity-100 group-focus-within:pointer-events-auto",
                                    "data-[state=open]:opacity-100 data-[state=open]:pointer-events-auto",
                                    "text-sidebar-foreground/50 hover:bg-sidebar-accent/70 hover:text-sidebar-foreground"
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
        <div
          className={cn(
            "border-t border-sidebar-border p-3",
            renderCollapsed ? "flex flex-col gap-2" : "space-y-2"
          )}
        >
          {/* Theme toggle */}
          {renderCollapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  onClick={cycleTheme}
                  className="group flex h-10 min-h-10 w-10 shrink-0 items-center justify-start gap-0 overflow-hidden rounded-xl border border-transparent bg-transparent pl-0 pr-0 text-sidebar-foreground/70 transition-colors
                  hover:text-sidebar-foreground hover:bg-sidebar-accent/70"
                >
                  <span className={railIconSlot}>
                    <ThemeIcon className={railIconClass} />
                  </span>
                </Button>
              </TooltipTrigger>
              <TooltipContent side="right">{themeLabel} theme</TooltipContent>
            </Tooltip>
          ) : (
            <Button
              onClick={cycleTheme}
              className="group flex h-10 min-h-10 w-full min-w-0 shrink-0 items-center justify-start gap-0 overflow-hidden rounded-xl border border-transparent bg-transparent pl-0 pr-3 text-sm font-medium text-sidebar-foreground/70 transition-colors
              hover:text-sidebar-foreground hover:bg-sidebar-accent/70"
            >
              <span className={railIconSlot}>
                <ThemeIcon className={railIconClass} />
              </span>
              <span className="min-w-0 flex-1 truncate whitespace-nowrap text-left">
                {themeLabel}
              </span>
            </Button>
          )}

          {/* User Profile */}
              {user && (
            <DropdownMenu>
              {renderCollapsed ? (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <DropdownMenuTrigger asChild>
                      <Button
                        className="group flex h-10 min-h-10 w-10 shrink-0 items-center justify-start gap-0 overflow-hidden rounded-xl border border-transparent bg-transparent pl-0 pr-0 text-sidebar-foreground/70 transition-colors
                        hover:text-sidebar-foreground hover:bg-sidebar-accent/70"
                      >
                        <span className={railIconSlot}>
                          <Avatar className="h-4 w-4 flex-shrink-0">
                            <AvatarImage
                              src={user.profileImage ? user.profileImage.startsWith('http') ? user.profileImage : user.profileImage : undefined}
                              alt={user.name}
                            />
                            <AvatarFallback className="text-[9px] leading-none">
                              {user.name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2)}
                            </AvatarFallback>
                          </Avatar>
                        </span>
                      </Button>
                    </DropdownMenuTrigger>
                  </TooltipTrigger>
                  <TooltipContent side="right">Profile</TooltipContent>
                </Tooltip>
              ) : (
                <DropdownMenuTrigger asChild>
                  <Button
                    className="group flex h-10 min-h-10 w-full min-w-0 shrink-0 items-center justify-start gap-0 overflow-hidden rounded-xl border border-transparent bg-transparent pl-0 pr-3 text-sidebar-foreground/70 transition-colors
                    hover:text-sidebar-foreground hover:bg-sidebar-accent/70"
                  >
                    <span className={railIconSlot}>
                      <Avatar className="h-4 w-4 flex-shrink-0">
                        <AvatarImage
                          src={user.profileImage ? user.profileImage.startsWith('http') ? user.profileImage : user.profileImage : undefined}
                          alt={user.name}
                        />
                        <AvatarFallback className="text-[9px] leading-none">
                          {user.name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2)}
                        </AvatarFallback>
                      </Avatar>
                    </span>
                    <div className="min-w-0 flex-1 text-left">
                      <p className="text-sm font-medium text-sidebar-foreground truncate">
                        {user.name}
                      </p>
                    </div>
                  </Button>
                </DropdownMenuTrigger>
              )}
              <DropdownMenuContent align="end" side="top" className="w-56">
                {user?.isAdmin && (
                  <>
                    <DropdownMenuItem
                      onClick={() => {
                        router.push("/admin");
                        handleNavClick();
                      }}
                      className="focus:bg-sidebar-accent/50 focus:text-sidebar-foreground"
                    >
                      <UserCog className="h-4 w-4" />
                      <span>Admin</span>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                  </>
                )}
                <DropdownMenuItem
                  onClick={() => {
                    router.push("/settings");
                    handleNavClick();
                  }}
                  className="focus:bg-sidebar-accent/50 focus:text-sidebar-foreground"
                >
                  <Settings className="h-4 w-4" />
                  <span>Settings</span>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  onClick={() => {
                    logout();
                  }}
                  className="text-destructive focus:text-destructive focus:bg-destructive/10"
                >
                  <LogOut className="h-4 w-4" />
                  <span>Sign Out</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>

        {/* Rename Tag Dialog */}
        <Dialog
          open={renameDialogOpen}
          onOpenChange={(open) => {
            setRenameDialogOpen(open);
            if (!open) {
              setSelectedTag(null);
              setRenameValue("");
              setRenameColor(TAG_COLORS[0]);
              setRenameError(null);
            }
          }}
        >
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
              <div className="space-y-2 px-1 pt-2">
                <p className="text-xs font-medium text-muted-foreground">
                  Tag color
                </p>
                <div className="flex flex-wrap gap-2">
                  {TAG_COLORS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      title={color}
                      aria-label={`Set tag color ${color}`}
                      onClick={() => setRenameColor(color)}
                      className={cn(
                        "h-6 w-6 rounded-full border transition-transform hover:scale-105",
                        renameColor === color
                          ? "ring-2 ring-accent ring-offset-2 ring-offset-background"
                          : "border-border/60",
                      )}
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
              </div>
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setRenameDialogOpen(false);
                  setSelectedTag(null);
                  setRenameValue("");
                  setRenameColor(TAG_COLORS[0]);
                  setRenameError(null);
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleRenameSubmit}
                variant={renameError ? "destructive" : "default"}
                disabled={!renameValue.trim() || updateTagMutation.isPending}
              >
                {updateTagMutation.isPending ? "Saving..." : "Save"}
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
