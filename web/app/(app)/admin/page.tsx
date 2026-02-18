"use client";

import { useState, useEffect } from "react";
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
  getOidcSettings,
  updateOidcSettings,
  type AdminUser,
  type CreateUserDto,
  type UpdateUserDto,
  type RegistrationMode,
  type UpdateOidcSettingsDto,
} from "@/features/admin";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
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
  Lock,
  CheckCircle,
  XCircle,
  UserPlus,
  KeyRound,
  Clock,
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
  const [oidcFormData, setOidcFormData] = useState<UpdateOidcSettingsDto | null>(null);
  const [oidcClearSecretRequested, setOidcClearSecretRequested] = useState(false);

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ["admin", "stats"],
    queryFn: getAdminStats,
  });

  const { data: registrationSettings, isLoading: registrationSettingsLoading } = useQuery({
    queryKey: ["admin", "settings", "registration"],
    queryFn: getRegistrationSettings,
  });

  const { data: oidcSettings, isLoading: oidcSettingsLoading } = useQuery({
    queryKey: ["admin", "settings", "oidc"],
    queryFn: getOidcSettings,
  });

  // Initialize form data when settings are loaded
  useEffect(() => {
    if (oidcSettings) {
      setOidcFormData({
        enabled: oidcSettings.enabled,
        providerName: oidcSettings.providerName,
        issuerUrl: oidcSettings.issuerUrl || "",
        clientId: oidcSettings.clientId || "",
        clientSecret: oidcSettings.hasClientSecret ? "" : "",
        disableInternalAuth: oidcSettings.disableInternalAuth,
      });
      setOidcClearSecretRequested(false);
    }
  }, [oidcSettings]);

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

  const updateOidcSettingsMutation = useMutation({
    mutationFn: updateOidcSettings,
    onSuccess: () => {
      setOidcClearSecretRequested(false);
      queryClient.invalidateQueries({ queryKey: ["admin", "settings", "oidc"] });
      queryClient.invalidateQueries({ queryKey: ["oidc-config"] });
      toast.success("OIDC settings updated successfully");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to update OIDC settings");
    },
  });

  const oidcFormHasChanges =
    !!oidcSettings &&
    !!oidcFormData &&
    !oidcSettings.isLocked &&
    (oidcFormData.enabled !== oidcSettings.enabled ||
      (oidcFormData.providerName ?? "") !== (oidcSettings.providerName ?? "") ||
      (oidcFormData.issuerUrl ?? "") !== (oidcSettings.issuerUrl ?? "") ||
      (oidcFormData.clientId ?? "") !== (oidcSettings.clientId ?? "") ||
      (oidcFormData.disableInternalAuth ?? false) !== oidcSettings.disableInternalAuth ||
      oidcClearSecretRequested ||
      (!!oidcFormData.clientSecret && oidcFormData.clientSecret.trim() !== ""));

  const handleSaveOidcSettings = () => {
    if (!oidcFormData) return;

    // Validate required fields when enabling
    if (oidcFormData.enabled) {
      if (!oidcFormData.issuerUrl?.trim() || !oidcFormData.clientId?.trim()) {
        toast.error("Issuer URL and Client ID are required when OIDC is enabled");
        return;
      }
    }

    const settingsToSave: UpdateOidcSettingsDto = { ...oidcFormData };

    if (oidcClearSecretRequested) {
      settingsToSave.clearClientSecret = true;
      delete settingsToSave.clientSecret;
    } else if (oidcSettings?.hasClientSecret && (!oidcFormData.clientSecret || oidcFormData.clientSecret.trim() === "")) {
      // Leave existing secret unchanged
      delete settingsToSave.clientSecret;
    }

    updateOidcSettingsMutation.mutate(settingsToSave);
  };

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
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md border bg-muted/50">
                <UserPlus className="h-5 w-5 text-muted-foreground" />
              </div>
              <div>
                <CardTitle>Registration Settings</CardTitle>
                <CardDescription className="mt-1">
                  Control who can create accounts and whether approval is required.
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {registrationSettingsLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : registrationSettings ? (
              <>
                {registrationSettings.isLocked && (
                  <div className="flex items-start gap-2 p-3 border rounded-lg bg-muted/50">
                    <Lock className="h-3.5 w-3.5 mt-0.5 text-muted-foreground shrink-0" />
                    <p className="text-sm text-muted-foreground">
                      Controlled by <code className="px-1 py-0.5 bg-background rounded text-xs font-mono">USER_SIGNUP</code> env variable. Remove it to manage from UI.
                    </p>
                  </div>
                )}
                <div className="space-y-3">
                  <div className="flex flex-col gap-2 md:flex-row md:items-center md:gap-4">
                    <Label className="w-36 shrink-0">Registration Mode</Label>
                    <ToggleGroup
                      type="single"
                      value={registrationSettings.mode}
                      onValueChange={(value) => {
                        if (value && !registrationSettings.isLocked) {
                          updateRegistrationModeMutation.mutate({ mode: value as RegistrationMode });
                        }
                      }}
                      disabled={registrationSettings.isLocked || updateRegistrationModeMutation.isPending}
                      className="justify-start rounded-md border"
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

        {/* OIDC Settings */}
        <Card>
          <CardHeader>
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md border bg-muted/50">
                  <KeyRound className="h-5 w-5 text-muted-foreground" />
                </div>
                <div>
                  <CardTitle>OIDC Authentication</CardTitle>
                  <CardDescription className="mt-1">
                    Allow users to sign in with your OIDC provider.
                  </CardDescription>
                </div>
              </div>
              {oidcSettings && (
                <Switch
                  id="oidc-enabled"
                  checked={oidcFormData?.enabled ?? false}
                  onCheckedChange={(checked) => {
                    if (!oidcSettings.isLocked && oidcFormData) {
                      setOidcFormData({ ...oidcFormData, enabled: checked });
                    }
                  }}
                  disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                />
              )}
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {oidcSettingsLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : oidcSettings ? (
              <>
                {oidcSettings.isLocked && (
                  <div className="flex items-start gap-2 p-3 border rounded-lg bg-muted/50">
                    <Lock className="h-3.5 w-3.5 mt-0.5 text-muted-foreground shrink-0" />
                    <p className="text-sm text-muted-foreground">
                      Controlled by <code className="px-1 py-0.5 bg-background rounded text-xs font-mono">OIDC_ENABLED</code>, <code className="px-1 py-0.5 bg-background rounded text-xs font-mono">OIDC_ISSUER_URL</code> and <code className="px-1 py-0.5 bg-background rounded text-xs font-mono">OIDC_CLIENT_ID</code> env variables. Remove them to manage from UI.
                    </p>
                  </div>
                )}

                {oidcFormData?.enabled && (
                  <>
                    <div className="grid gap-4 sm:grid-cols-2">
                      <div className="space-y-2 sm:col-span-2">
                        <Label htmlFor="oidc-provider-name">Provider name</Label>
                        <Input
                          id="oidc-provider-name"
                          value={oidcFormData?.providerName || ""}
                          onChange={(e) => {
                            if (!oidcSettings.isLocked && oidcFormData) {
                              setOidcFormData({ ...oidcFormData, providerName: e.target.value });
                            }
                          }}
                          disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                          placeholder="e.g. Pocket ID, Authelia"
                        />
                        <p className="text-xs text-muted-foreground">
                          Shown on the login button: &quot;Login with {oidcFormData?.providerName || "Provider"}&quot;
                        </p>
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="oidc-issuer-url">
                          Issuer URL <span className="text-destructive">*</span>
                        </Label>
                        <Input
                          id="oidc-issuer-url"
                          value={oidcFormData?.issuerUrl || ""}
                          onChange={(e) => {
                            if (!oidcSettings.isLocked && oidcFormData) {
                              setOidcFormData({ ...oidcFormData, issuerUrl: e.target.value });
                            }
                          }}
                          disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                          placeholder="https://auth.example.com"
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="oidc-client-id">
                          Client ID <span className="text-destructive">*</span>
                        </Label>
                        <Input
                          id="oidc-client-id"
                          value={oidcFormData?.clientId || ""}
                          onChange={(e) => {
                            if (!oidcSettings.isLocked && oidcFormData) {
                              setOidcFormData({ ...oidcFormData, clientId: e.target.value });
                            }
                          }}
                          disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                          placeholder="your-client-id"
                        />
                      </div>
                      <div className="space-y-2 sm:col-span-2">
                        <Label htmlFor="oidc-client-secret">Client secret (optional)</Label>
                        <div className="flex gap-2">
                          <Input
                            id="oidc-client-secret"
                            type="password"
                            autoComplete="off"
                            value={oidcClearSecretRequested ? "" : (oidcFormData?.clientSecret ?? "")}
                            onChange={(e) => {
                              if (!oidcSettings.isLocked && oidcFormData) {
                                setOidcClearSecretRequested(false);
                                setOidcFormData({ ...oidcFormData, clientSecret: e.target.value });
                              }
                            }}
                            disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                            placeholder={
                              oidcSettings?.hasClientSecret && !oidcClearSecretRequested
                                ? "••••••••••••"
                                : "Leave empty for public client (PKCE)"
                            }
                            className="flex-1"
                          />
                          {oidcSettings?.hasClientSecret && !oidcSettings.isLocked && (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              onClick={() => setOidcClearSecretRequested(true)}
                              disabled={updateOidcSettingsMutation.isPending || oidcClearSecretRequested}
                            >
                              Clear secret
                            </Button>
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground">
                          The Anchor mobile app requires a public client (no client secret). If users sign in from the app using OIDC, leave this empty and set Anchor as a public client in your OIDC provider.
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center justify-between rounded-lg border p-4">
                      <div className="space-y-0.5">
                        <Label htmlFor="oidc-disable-internal-auth" className="text-sm font-medium">
                          OIDC-only mode
                        </Label>
                        <p className="text-sm text-muted-foreground">
                          Hide local username/password login
                        </p>
                      </div>
                      <Switch
                        id="oidc-disable-internal-auth"
                        checked={oidcFormData?.disableInternalAuth ?? false}
                        onCheckedChange={(checked) => {
                          if (!oidcSettings.isLocked && oidcFormData) {
                            setOidcFormData({ ...oidcFormData, disableInternalAuth: checked });
                          }
                        }}
                        disabled={oidcSettings.isLocked || updateOidcSettingsMutation.isPending}
                      />
                    </div>

                    <div className="rounded-lg border bg-muted/30 p-4">
                      <p className="text-sm font-medium mb-1">Callback URL</p>
                      <code className="text-xs break-all rounded bg-background px-2 py-1 block">
                        {typeof window !== "undefined"
                          ? `${window.location.origin}/api/auth/oidc/callback`
                          : "/api/auth/oidc/callback"}
                      </code>
                      <p className="text-xs text-muted-foreground mt-2">
                        Add this URL in your OIDC provider as the redirect/callback URL.
                      </p>
                    </div>
                  </>
                )}

                {oidcFormHasChanges && (
                  <div className="flex justify-end pt-2">
                    <Button
                      onClick={handleSaveOidcSettings}
                      disabled={
                        updateOidcSettingsMutation.isPending ||
                        !oidcFormData ||
                        (oidcFormData.enabled && (!oidcFormData.issuerUrl?.trim() || !oidcFormData.clientId?.trim()))
                      }
                    >
                      {updateOidcSettingsMutation.isPending ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          Saving…
                        </>
                      ) : (
                        "Save OIDC settings"
                      )}
                    </Button>
                  </div>
                )}
              </>
            ) : null}
          </CardContent>
        </Card>

        {/* Pending Users */}
        {pendingUsers.length > 0 && (
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md border bg-muted/50">
                    <Clock className="h-5 w-5 text-muted-foreground" />
                  </div>
                  <div>
                    <CardTitle>Pending User Approvals</CardTitle>
                    <CardDescription className="mt-1">
                      Users awaiting approval to access the system
                    </CardDescription>
                  </div>
                </div>
                <Badge variant="outline" className="shrink-0 text-sm">
                  {pendingUsersLoading ? "..." : pendingUsers.length} pending
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              {pendingUsersLoading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead className="text-center">Auth</TableHead>
                      <TableHead>Registered</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {pendingUsers.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell className="font-medium">{user.name}</TableCell>
                        <TableCell className="font-medium">{user.email}</TableCell>
                        <TableCell className="text-center">
                          <Badge variant={user.authMethod === "oidc" ? "secondary" : "outline"} className="font-normal">
                            {user.authMethod === "oidc" ? "OIDC" : "Local"}
                          </Badge>
                        </TableCell>
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
            <div className="flex items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md border bg-muted/50">
                  <Users className="h-5 w-5 text-muted-foreground" />
                </div>
                <div>
                  <CardTitle>Users</CardTitle>
                  <CardDescription className="mt-1">
                    Manage all users in the system
                  </CardDescription>
                </div>
              </div>
              <Button onClick={handleCreateUser} size="sm">
                <Plus className="h-4 w-4" />
                Create User
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {usersLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead className="text-center">Role</TableHead>
                    <TableHead className="text-center">Auth</TableHead>
                    <TableHead className="text-center">Status</TableHead>
                    <TableHead className="text-center">Notes</TableHead>
                    <TableHead className="text-center">Tags</TableHead>
                    <TableHead>Created</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {usersData?.users.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-medium">{user.name || "-"}</TableCell>
                      <TableCell className="font-medium">{user.email}</TableCell>
                      <TableCell className="text-center">
                        {user.isAdmin ? (
                          <Badge variant="default">Admin</Badge>
                        ) : (
                          <Badge variant="outline">User</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-center">
                        <Badge variant={user.authMethod === "oidc" ? "secondary" : "outline"} className="font-normal">
                          {user.authMethod === "oidc" ? "OIDC" : "Local"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center">
                        {user.status === "pending" ? (
                          <Badge variant="secondary">Pending</Badge>
                        ) : (
                          <Badge variant="outline">Active</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-center">{user._count?.notes || 0}</TableCell>
                      <TableCell className="text-center">{user._count?.tags || 0}</TableCell>
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