"use client";

import { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Search, UserPlus, X, Loader2, Edit, Eye, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  shareNote,
  getNoteShares,
  updateNoteSharePermission,
  revokeShare,
  searchUsers,
} from "../api";
import type { NoteSharePermission, UserSearchResult } from "../types";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

interface ShareDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  noteId: string;
}

export function ShareDialog({ open, onOpenChange, noteId }: ShareDialogProps) {
  const queryClient = useQueryClient();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [selectedPermission, setSelectedPermission] =
    useState<NoteSharePermission>("viewer");
  const [searchResults, setSearchResults] = useState<UserSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  // Fetch current shares
  const { data: shares = [], isLoading: sharesLoading } = useQuery({
    queryKey: ["note-shares", noteId],
    queryFn: () => getNoteShares(noteId),
    enabled: open && !!noteId,
  });

  // Search users with debounce
  useEffect(() => {
    if (!searchQuery || searchQuery.trim().length < 2) {
      setSearchResults([]);
      return;
    }

    const timeoutId = setTimeout(async () => {
      setIsSearching(true);
      try {
        const results = await searchUsers(searchQuery);
        setSearchResults(results);
      } catch (error) {
        console.error("Error searching users:", error);
        setSearchResults([]);
      } finally {
        setIsSearching(false);
      }
    }, 300);

    setSelectedUserId(null);
    setSelectedPermission("viewer");

    return () => clearTimeout(timeoutId);
  }, [searchQuery]);

  const shareMutation = useMutation({
    mutationFn: ({
      userId,
      permission,
    }: {
      userId: string;
      permission: NoteSharePermission;
    }) => shareNote(noteId, userId, permission),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["note-shares", noteId] });
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      setSearchQuery("");
      setSelectedUserId(null);
      setSelectedPermission("viewer");
      toast.success("Note shared successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to share note");
    },
  });

  const updatePermissionMutation = useMutation({
    mutationFn: ({
      shareId,
      permission,
    }: {
      shareId: string;
      permission: NoteSharePermission;
    }) => updateNoteSharePermission(noteId, shareId, permission),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["note-shares", noteId] });
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      toast.success("Permission updated");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to update permission");
    },
  });

  const revokeMutation = useMutation({
    mutationFn: (shareId: string) => revokeShare(noteId, shareId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["note-shares", noteId] });
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      toast.success("Share revoked");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to revoke share");
    },
  });

  const handleShare = () => {
    if (!selectedUserId) return;
    shareMutation.mutate({
      userId: selectedUserId,
      permission: selectedPermission,
    });
  };

  const handleUpdatePermission = (shareId: string, permission: NoteSharePermission) => {
    updatePermissionMutation.mutate({ shareId, permission });
  };

  const handleRevoke = (shareId: string) => {
    revokeMutation.mutate(shareId);
  };

  // Filter out already shared users from search results
  const availableUsers = useMemo(() => {
    const sharedUserIds = new Set(shares.map((s) => s.sharedWithUser.id));
    return searchResults.filter((user) => !sharedUserIds.has(user.id));
  }, [searchResults, shares]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
              <UserPlus className="h-5 w-5 text-primary" />
            </div>
            Share Note
          </DialogTitle>
          <DialogDescription className="pt-2">
            Share this note with other users. Viewers can read, editors can edit.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* User Search */}
          <div className="space-y-2">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Enter email address..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
              {isSearching && (
                <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
              )}
            </div>

            {/* Search Results */}
            {availableUsers.length > 0 && (
              <div className="border rounded-md max-h-48 overflow-y-auto divide-y">
                {availableUsers.map((user) => (
                  <button
                    key={user.id}
                    onClick={() => setSelectedUserId(user.id)}
                    className={cn(
                      "w-full px-3 py-2.5 text-left hover:bg-muted transition-colors flex items-center gap-3",
                      selectedUserId === user.id && "bg-muted"
                    )}
                  >
                    <Avatar className="size-8">
                      {user.profileImage && (
                        <AvatarImage src={user.profileImage} alt={user.name} />
                      )}
                      <AvatarFallback className="bg-primary/10 text-primary font-medium text-sm">
                        {user.name.charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0 text-left">
                      <div className="font-medium truncate">{user.name}</div>
                      <div className="text-sm text-muted-foreground truncate">
                        {user.email}
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            )}

            {/* Permission Selector */}
            {selectedUserId && (
              <div className="flex items-center gap-2">
                <DropdownMenu>
                  <DropdownMenuTrigger asChild className="hover:bg-primary/10 hover:text-primary">
                    <Button variant="outline" className="flex-1 justify-between">
                      <div className="flex items-center gap-2">
                        {selectedPermission === "viewer" ? (
                          <>
                            <Eye className="h-4 w-4" />
                            <span>Viewer - Read only</span>
                          </>
                        ) : (
                          <>
                            <Edit className="h-4 w-4" />
                            <span>Editor - Can edit</span>
                          </>
                        )}
                      </div>
                      <ChevronDown className="h-4 w-4 opacity-50" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="start" className="w-56">
                    <DropdownMenuItem
                      className="focus:bg-primary/10 focus:text-primary"
                      onClick={() => setSelectedPermission("viewer")}
                    >
                      <Eye className="h-4 w-4 mr-2" />
                      <div className="flex flex-col">
                        <span>Viewer</span>
                        <span className="text-xs text-muted-foreground">
                          Read only
                        </span>
                      </div>
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="focus:bg-primary/10 focus:text-primary"
                      onClick={() => setSelectedPermission("editor")}
                    >
                      <Edit className="h-4 w-4 mr-2" />
                      <div className="flex flex-col">
                        <span>Editor</span>
                        <span className="text-xs text-muted-foreground">
                          Can edit
                        </span>
                      </div>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
                <Button
                  onClick={handleShare}
                  disabled={shareMutation.isPending || !selectedUserId}
                >
                  {shareMutation.isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    "Share"
                  )}
                </Button>
              </div>
            )}
          </div>

          <Separator />

          {/* Current Shares */}
          <div className="space-y-3">
            <div className="text-sm font-medium">Shared with</div>
            {sharesLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
              </div>
            ) : shares.length === 0 ? (
              <div className="text-sm text-muted-foreground py-8 text-center border border-dashed rounded-md">
                No shares yet. Enter an email address to share this note.
              </div>
            ) : (
              <div className="border rounded-md divide-y">
                {shares.map((share) => (
                  <div
                    key={share.id}
                    className="px-3 py-3 flex items-center justify-between gap-3 hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <Avatar className="size-9 shrink-0">
                        {share.sharedWithUser.profileImage && (
                          <AvatarImage
                            src={share.sharedWithUser.profileImage}
                            alt={share.sharedWithUser.name}
                          />
                        )}
                        <AvatarFallback className="bg-primary/10 text-primary font-medium">
                          {share.sharedWithUser.name.charAt(0).toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium truncate">
                          {share.sharedWithUser.name}
                        </div>
                        <div className="text-sm text-muted-foreground truncate">
                          {share.sharedWithUser.email}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild className="hover:bg-primary/10 hover:text-primary">
                          <Button
                            variant="outline"
                            size="sm"
                            className="w-28 justify-between"
                            disabled={updatePermissionMutation.isPending}
                          >
                            <div className="flex items-center gap-1.5">
                              {share.permission === "viewer" ? (
                                <>
                                  <Eye className="h-3.5 w-3.5" />
                                  <span>Viewer</span>
                                </>
                              ) : (
                                <>
                                  <Edit className="h-3.5 w-3.5" />
                                  <span>Editor</span>
                                </>
                              )}
                            </div>
                            <ChevronDown className="h-3.5 w-3.5 opacity-50" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="w-56">
                          <DropdownMenuItem
                            className="focus:bg-primary/10 focus:text-primary"
                            onClick={() =>
                              handleUpdatePermission(share.id, "viewer")
                            }
                          >
                            <Eye className="h-4 w-4 mr-2" />
                            <div className="flex flex-col">
                              <span>Viewer</span>
                              <span className="text-xs text-muted-foreground">
                                Read only
                              </span>
                            </div>
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            className="focus:bg-primary/10 focus:text-primary"
                            onClick={() =>
                              handleUpdatePermission(share.id, "editor")
                            }
                          >
                            <Edit className="h-4 w-4 mr-2" />
                            <div className="flex flex-col">
                              <span>Editor</span>
                              <span className="text-xs text-muted-foreground">
                                Can edit
                              </span>
                            </div>
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleRevoke(share.id)}
                        disabled={revokeMutation.isPending}
                        className="h-8 w-8 text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                      >
                        {revokeMutation.isPending ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <X className="h-4 w-4" />
                        )}
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <DialogFooter className="gap-2 sm:gap-0">
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
