export interface User {
  id: string;
  email: string;
  name: string;
  profileImage?: string;
  isAdmin?: boolean;
  /** Older servers leave it out. */
  hasPassword?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuthResponse {
  access_token?: string;
  refresh_token?: string;
  user: User;
  message?: string;
}

export interface Tokens {
  access_token: string;
  refresh_token: string;
}

export interface Session extends Tokens {
  user: User;
}

export interface Capabilities {
  totp: boolean;
  passkeys: boolean;
}

/** Second steps the server offers a person who has to set one up. */
export interface EnrollMethods {
  totp: boolean;
  passkey: boolean;
}

/** What a sign-in came to: a session, or one more step first. */
export type SignInOutcome =
  | { kind: "signedIn"; session: Session }
  | { kind: "codeRequired"; challenge: string }
  | {
      kind: "setupRequired";
      challenge: string;
      methods: EnrollMethods;
    }
  /** Two-factor is required and they have only passkeys: a password isn’t enough. */
  | { kind: "passkeyRequired"; message: string };

export type RegisterOutcome =
  | { kind: "signedIn"; session: Session }
  | { kind: "pending"; message?: string }
  | {
      kind: "setupRequired";
      challenge: string;
      methods: EnrollMethods;
      user: User;
    };

export interface TwoFactorLoginDto {
  challenge: string;
  /** Exactly one of the two. */
  code?: string;
  recoveryCode?: string;
}

export interface TotpSetup {
  secret: string;
  otpauthUri: string;
}

export interface TotpEnabled extends Tokens {
  recoveryCodes: string[];
  user?: User;
}

export type TwoFactorPolicy = "optional" | "admins" | "everyone";

export interface PasskeySummary {
  id: string;
  name: string;
  createdAt: string;
  lastUsedAt: string | null;
  deviceType: "singleDevice" | "multiDevice";
  backedUp: boolean;
}

export interface TwoFactorStatus {
  available: Capabilities;
  policy: TwoFactorPolicy;
  /** The policy applies to me and I have no second step yet. */
  required: boolean;
  totp: {
    enabled: boolean;
    enabledAt: string | null;
    lastUsedAt: string | null;
    recoveryCodesRemaining: number;
  };
  passkeys: PasskeySummary[];
}

export interface RefreshTokenResponse {
  access_token: string;
  refresh_token: string;
}

export interface ApiTokenResponse {
  apiToken: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterCredentials {
  email: string;
  password: string;
  name: string;
}

export interface ChangePasswordCredentials {
  currentPassword: string;
  newPassword: string;
}

export interface UpdateProfileDto {
  name?: string | null;
}

export interface OidcConfig {
  enabled: boolean;
  providerName: string;
  issuerUrl?: string;
  clientId?: string;
  disableInternalAuth: boolean;
}

export interface OidcExchangeResponse {
  access_token: string;
  refresh_token: string;
  user: User;
  redirectUrl: string;
}

export type RegistrationMode = "disabled" | "enabled" | "review";
