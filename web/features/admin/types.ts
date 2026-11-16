import type {
  Capabilities,
  RegistrationMode,
  TwoFactorPolicy,
} from "@/features/auth/types";

export interface AdminStats {
  totalUsers: number;
  totalNotes: number;
  totalTags: number;
}

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  profileImage?: string | null;
  isAdmin: boolean;
  status: "active" | "pending";
  authMethod?: "oidc" | "local";
  /** Which second steps this person has. Older servers leave it out. */
  twoFactor?: TwoFactorKind;
  /** False for someone who only signs in with a provider. */
  hasPassword?: boolean;
  createdAt: string;
  updatedAt: string;
  _count?: {
    notes: number;
    tags: number;
  };
}

export type TwoFactorKind = "none" | "totp" | "passkey" | "both";

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
  isAdmin?: boolean;
}

export interface ResetPasswordResponse {
  newPassword?: string;
  message: string;
}

export type { RegistrationMode };

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
  callbackUrl: string;
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

export type { TwoFactorPolicy };

export interface TwoFactorSettings {
  policy: TwoFactorPolicy;
  isLocked: boolean;
  available: Capabilities;
  /** Active people with a password: those with a second step, and all. */
  coverage: { covered: number; total: number };
}
