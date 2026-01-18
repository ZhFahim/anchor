"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { AdminGuard } from "@/features/admin";
import {
  getAdminStats,
  getUsers,
  createUser,
  updateUser,
  deleteUser,
  resetPassword,
  getRegistrationSettings,
  updateRegistrationMode,
  getPendingUsers,
  approveUser,
  rejectUser,
  type AdminUser,
  type CreateUserDto,
  type UpdateUserDto,
  type RegistrationMode,
} from "@/features/admin";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  MoreVertical,
  Plus,
  Users,
  FileText,
  Tag,
  AlertTriangle,
  Loader2,
  Settings,
  Lock,
  CheckCircle,
  XCircle,
  Info,
} from "lucide-react";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { toast } from "sonner";
import { format } from "date-fns";

export default function AdminPage() {
  const queryClient = useQueryClient();
  const [userDialogOpen, setUserDialogOpen] = useState(false);
  const [resetPasswordDialogOpen, setResetPasswordDialogOpen] = useState(false);
  const [deleteUserDialogOpen, setDeleteUserDialogOpen] = useState(false);
  const [rejectUserDialogOpen, setRejectUserDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState<CreateUserDto>({
    email: "",
    password: "",
    name: "",
  });
  const [resetPasswordResult, setResetPasswordResult] = useState<string | null>(null);

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["admin", "stats"],
    queryFn: getAdminStats,
  });

  const { data: registrationSettings, isLoading: registrationSettingsLoading } = useQuery({
    queryKey: ["admin", "settings", "registration"],
    queryFn: getRegistrationSettings,
  });

  const { data: pendingUsers = [], isLoading: pendingUsersLoading } = useQuery({
    queryKey: ["admin", "users", "pending"],
    queryFn: getPendingUsers,
  });

  const { data: usersData, isLoading: usersLoading } = useQuery({
    queryKey: ["admin", "users"],
    queryFn: () => getUsers(),
  });

  const updateRegistrationModeMutation = useMutation({
    mutationFn: updateRegistrationMode,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users", "pending"] });
      toast.success("Registration mode updated successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to update registration mode");
    },
  });

  const approveUserMutation = useMutation({
    mutationFn: approveUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users", "pending"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "stats"] });
      toast.success("User approved successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to approve user");
    },
  });

  const rejectUserMutation = useMutation({
    mutationFn: rejectUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users", "pending"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "stats"] });
      setRejectUserDialogOpen(false);
      setSelectedUser(null);
      toast.success("User rejected successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to reject user");
    },
  });


  const createUserMutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "stats"] });
      setUserDialogOpen(false);
      setFormData({ email: "", password: "", name: "" });
      setIsEditing(false);
      toast.success("User created successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to create user");
    },
  });

  const updateUserMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateUserDto }) =>
      updateUser(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      setUserDialogOpen(false);
      setSelectedUser(null);
      setFormData({ email: "", password: "", name: "" });
      setIsEditing(false);
      toast.success("User updated successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to update user");
    },
  });

  const deleteUserMutation = useMutation({
    mutationFn: deleteUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "stats"] });
      setDeleteUserDialogOpen(false);
      setSelectedUser(null);
      toast.success("User deleted successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to delete user");
    },
  });

  const resetPasswordMutation = useMutation({
    mutationFn: (id: string) => resetPassword(id),
    onSuccess: (data) => {
      setResetPasswordResult(data.newPassword || null);
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      toast.success("Password reset successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to reset password");
    },
  });

  const handleCreateUser = () => {
    setSelectedUser(null);
    setIsEditing(false);
    setFormData({ email: "", password: "", name: "" });
    setUserDialogOpen(true);
  };

  const handleEditUser = (user: AdminUser) => {
    setSelectedUser(user);
    setIsEditing(true);
    setFormData({ email: user.email, password: "", name: user.name || "" });
    setUserDialogOpen(true);
  };

  const handleDeleteUser = (user: AdminUser) => {
    setSelectedUser(user);
    setDeleteUserDialogOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (selectedUser) {
      deleteUserMutation.mutate(selectedUser.id);
    }
  };

  const handleRejectUser = (user: AdminUser) => {
    setSelectedUser(user);
    setRejectUserDialogOpen(true);
  };

  const handleRejectConfirm = () => {
    if (selectedUser) {
      rejectUserMutation.mutate(selectedUser.id);
    }
  };

  const handleResetPassword = (user: AdminUser) => {
    setSelectedUser(user);
    setResetPasswordResult(null);
    setResetPasswordDialogOpen(true);
  };

  const handleSubmitUser = () => {
    if (isEditing && selectedUser) {
      updateUserMutation.mutate({
        id: selectedUser.id,
        data: { email: formData.email, name: formData.name },
      });
    } else {
      if (!formData.password) {
        toast.error("Password is required");
        return;
      }
      createUserMutation.mutate(formData);
    }
  };

  const handleResetPasswordSubmit = () => {
    if (selectedUser) {
      resetPasswordMutation.mutate(selectedUser.id);
    }
  };

  const copyPassword = () => {
    if (resetPasswordResult) {
      navigator.clipboard.writeText(resetPasswordResult);
      toast.success("Password copied to clipboard");
    }
  };

  return (
    <AdminGuard>
      <div className="container mx-auto p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-serif font-bold">Admin Settings</h1>
            <p className="text-muted-foreground mt-1">
              Manage users and view statistics
            </p>
          </div>
        </div>

        {/* Statistics */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {statsLoading ? "..." : stats?.totalUsers || 0}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Notes</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {statsLoading ? "..." : stats?.totalNotes || 0}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Tags</CardTitle>
              <Tag className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {statsLoading ? "..." : stats?.totalTags || 0}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Registration Settings */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                <CardTitle>Registration Settings</CardTitle>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {registrationSettingsLoading ? (
              <div className="flex items-center justify-center py-4">
                <Loader2 className="h-4 w-4 animate-spin" />
              </div>
            ) : registrationSettings ? (
              <>
                {registrationSettings.isLocked && (
                  <div className="flex items-start gap-2 p-3 border rounded-lg bg-muted/50">
                    <Lock className="h-3.5 w-3.5 mt-0.5 text-muted-foreground shrink-0" />
                    <p className="text-xs text-muted-foreground">
                      Controlled by <code className="px-1 py-0.5 bg-background rounded text-[10px] font-mono">USER_SIGNUP</code> env variable. Remove it to manage from UI.
                    </p>
                  </div>
                )}
                <div className="space-y-2">
                  <div className="flex flex-col md:flex-row md:items-center gap-2 md:gap-4">
                    <Label className="whitespace-nowrap">Registration Mode</Label>
                    <ToggleGroup
                      type="single"
                      value={registrationSettings.mode}
                      onValueChange={(value) => {
                        if (value && !registrationSettings.isLocked) {
                          updateRegistrationModeMutation.mutate({ mode: value as RegistrationMode });
                        }
                      }}
                      disabled={registrationSettings.isLocked || updateRegistrationModeMutation.isPending}
                      className="justify-start border rounded-md"
                    >
                      <ToggleGroupItem value="enabled" aria-label="Enabled">
                        Enabled
                      </ToggleGroupItem>
                      <ToggleGroupItem value="review" aria-label="Require Review">
                        Require Review
                      </ToggleGroupItem>
                      <ToggleGroupItem value="disabled" aria-label="Disabled">
                        Disabled
                      </ToggleGroupItem>
                    </ToggleGroup>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {registrationSettings.mode === "disabled" && "Registration is disabled. Only admins can create users."}
                    {registrationSettings.mode === "enabled" && "Users can register immediately without approval."}
                    {registrationSettings.mode === "review" && "Users can register but require admin approval before they can log in."}
                  </p>
                </div>
              </>
            ) : null}
          </CardContent>
        </Card>

        {/* Pending Users */}
        {pendingUsers.length > 0 && (
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Pending User Approvals</CardTitle>
                  <p className="text-sm text-muted-foreground mt-1">
                    Users awaiting approval to access the system
                  </p>
                </div>
                <Badge variant="outline" className="text-sm">
                  {pendingUsersLoading ? "..." : pendingUsers.length} pending
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              {pendingUsersLoading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="h-4 w-4 animate-spin" />
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Registered</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {pendingUsers.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell className="font-medium">{user.name}</TableCell>
                        <TableCell className="font-medium">{user.email}</TableCell>
                        <TableCell>
                          {format(new Date(user.createdAt), "MMM d, yyyy")}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            <Button
                              size="sm"
                              variant="default"
                              onClick={() => approveUserMutation.mutate(user.id)}
                              disabled={approveUserMutation.isPending}
                            >
                              <CheckCircle className="h-4 w-4 mr-1" />
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              onClick={() => handleRejectUser(user)}
                              disabled={rejectUserMutation.isPending}
                            >
                              <XCircle className="h-4 w-4 mr-1" />
                              Reject
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        )}

        {/* User Management */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Users</CardTitle>
                <p className="text-sm text-muted-foreground mt-1">
                  Manage all users in the system
                </p>
              </div>
              <Button onClick={handleCreateUser}>
                <Plus className="h-4 w-4" />
                Create User
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {usersLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-4 w-4 animate-spin" />
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>Role</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Notes</TableHead>
                    <TableHead>Tags</TableHead>
                    <TableHead>Created</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {usersData?.users.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-medium">{user.name || "-"}</TableCell>
                      <TableCell className="font-medium">{user.email}</TableCell>
                      <TableCell>
                        {user.isAdmin ? (
                          <Badge variant="default">Admin</Badge>
                        ) : (
                          <Badge variant="outline">User</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        {user.status === "pending" ? (
                          <Badge variant="secondary">Pending</Badge>
                        ) : (
                          <Badge variant="outline">Active</Badge>
                        )}
                      </TableCell>
                      <TableCell>{user._count?.notes || 0}</TableCell>
                      <TableCell>{user._count?.tags || 0}</TableCell>
                      <TableCell>
                        {format(new Date(user.createdAt), "MMM d, yyyy")}
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem
                              onClick={() => handleEditUser(user)}
                            >
                              Edit
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleResetPassword(user)}
                            >
                              Reset Password
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDeleteUser(user)}
                              className="text-destructive"
                            >
                              Delete
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {/* Create/Edit User Dialog */}
        <Dialog open={userDialogOpen} onOpenChange={setUserDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {isEditing ? "Edit User" : "Create User"}
              </DialogTitle>
              <DialogDescription>
                {isEditing
                  ? "Update user information"
                  : "Create a new user account"}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="name">Name</Label>
                <Input
                  id="name"
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  placeholder="User name"
                  maxLength={100}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) =>
                    setFormData({ ...formData, email: e.target.value })
                  }
                  placeholder="user@example.com"
                />
              </div>
              {!isEditing && (
                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    value={formData.password}
                    onChange={(e) =>
                      setFormData({ ...formData, password: e.target.value })
                    }
                    placeholder="Minimum 8 characters"
                    minLength={8}
                  />
                </div>
              )}
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setUserDialogOpen(false);
                  setFormData({ email: "", password: "", name: "" });
                  setIsEditing(false);
                  setSelectedUser(null);
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleSubmitUser}
                disabled={
                  createUserMutation.isPending ||
                  updateUserMutation.isPending ||
                  !formData.name ||
                  !formData.email ||
                  (!isEditing && !formData.password)
                }
              >
                {isEditing ? "Update" : "Create"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Reset Password Dialog */}
        <Dialog
          open={resetPasswordDialogOpen}
          onOpenChange={setResetPasswordDialogOpen}
        >
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Reset Password</DialogTitle>
              <DialogDescription>
                Reset password for {selectedUser?.email}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              {resetPasswordResult ? (
                <div className="space-y-2">
                  <Label>New Password</Label>
                  <div className="flex gap-2">
                    <Input value={resetPasswordResult} readOnly />
                    <Button onClick={copyPassword} variant="outline">
                      Copy
                    </Button>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Please copy this password and share it securely with the
                    user.
                  </p>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">
                  A new random password will be generated for this user.
                </p>
              )}
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setResetPasswordDialogOpen(false);
                  setResetPasswordResult(null);
                  setSelectedUser(null);
                }}
              >
                {resetPasswordResult ? "Close" : "Cancel"}
              </Button>
              {!resetPasswordResult && (
                <Button
                  onClick={handleResetPasswordSubmit}
                  disabled={resetPasswordMutation.isPending}
                >
                  {resetPasswordMutation.isPending
                    ? "Resetting..."
                    : "Reset Password"}
                </Button>
              )}
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Delete User Confirmation Dialog */}
        <Dialog
          open={deleteUserDialogOpen}
          onOpenChange={setDeleteUserDialogOpen}
        >
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-destructive/10 flex items-center justify-center">
                  <AlertTriangle className="h-5 w-5 text-destructive" />
                </div>
                Delete User?
              </DialogTitle>
              <DialogDescription className="pt-2">
                Are you sure you want to delete user{" "}
                <span className="font-semibold text-foreground">
                  {selectedUser?.email}
                </span>
                ? This action cannot be undone.
              </DialogDescription>
            </DialogHeader>
            {selectedUser && (
              <div className="py-4 space-y-2">
                <div className="text-sm text-muted-foreground">
                  This will permanently delete:
                </div>
                <ul className="text-sm space-y-1 list-disc list-inside text-muted-foreground">
                  <li>The user account</li>
                  <li>
                    {selectedUser._count?.notes || 0} note
                    {(selectedUser._count?.notes || 0) !== 1 ? "s" : ""}
                  </li>
                  <li>
                    {selectedUser._count?.tags || 0} tag
                    {(selectedUser._count?.tags || 0) !== 1 ? "s" : ""}
                  </li>
                </ul>
                {selectedUser.isAdmin && (
                  <div className="pt-2 text-sm text-amber-600 dark:text-amber-500 font-medium">
                    Warning: This is an admin user.
                  </div>
                )}
              </div>
            )}
            <DialogFooter className="gap-2">
              <Button
                variant="outline"
                onClick={() => {
                  setDeleteUserDialogOpen(false);
                  setSelectedUser(null);
                }}
                disabled={deleteUserMutation.isPending}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={handleDeleteConfirm}
                disabled={deleteUserMutation.isPending}
              >
                {deleteUserMutation.isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Deleting...
                  </>
                ) : (
                  "Delete User"
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Reject User Confirmation Dialog */}
        <Dialog
          open={rejectUserDialogOpen}
          onOpenChange={setRejectUserDialogOpen}
        >
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-destructive/10 flex items-center justify-center">
                  <XCircle className="h-5 w-5 text-destructive" />
                </div>
                Reject User?
              </DialogTitle>
              <DialogDescription className="pt-2">
                Are you sure you want to reject the registration request for{" "}
                <span className="font-semibold text-foreground">
                  {selectedUser?.email}
                </span>
                ? This will permanently delete their account and they will need to register again.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter className="gap-2">
              <Button
                variant="outline"
                onClick={() => {
                  setRejectUserDialogOpen(false);
                  setSelectedUser(null);
                }}
                disabled={rejectUserMutation.isPending}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={handleRejectConfirm}
                disabled={rejectUserMutation.isPending}
              >
                {rejectUserMutation.isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Rejecting...
                  </>
                ) : (
                  "Reject User"
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </AdminGuard>
  );
}