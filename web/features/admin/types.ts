export interface AdminStats {
  totalUsers: number;
  totalNotes: number;
  totalTags: number;
}

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  isAdmin: boolean;
  status: "active" | "pending";
  authMethod?: "oidc" | "local";
  createdAt: string;
  updatedAt: string;
  _count?: {
    notes: number;
    tags: number;
  };
}

export interface UsersListResponse {
  users: AdminUser[];
  total: number;
  skip: number;
  take: number;
}

export interface CreateUserDto {
  email: string;
  password: string;
  name: string;
}

export interface UpdateUserDto {
  email?: string;
  name?: string;
}

export interface ResetPasswordResponse {
  newPassword?: string;
  message: string;
}

export type RegistrationMode = "disabled" | "enabled" | "review";

export interface RegistrationSettings {
  mode: RegistrationMode;
  isLocked: boolean;
  source: "env" | "database" | "default";
}

export interface UpdateRegistrationModeDto {
  mode: RegistrationMode;
}

export interface OidcSettings {
  enabled: boolean;
  providerName: string;
  issuerUrl?: string;
  clientId?: string;
  hasClientSecret: boolean;
  disableInternalAuth: boolean;
  isLocked: boolean;
  source: "env" | "database" | "default";
}

export interface UpdateOidcSettingsDto {
  enabled?: boolean;
  providerName?: string;
  issuerUrl?: string;
  clientId?: string;
  clientSecret?: string;
  clearClientSecret?: boolean;
  disableInternalAuth?: boolean;
}
