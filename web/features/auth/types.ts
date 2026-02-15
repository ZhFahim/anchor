export interface User {
  id: string;
  email: string;
  name: string;
  profileImage?: string;
  isAdmin?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuthResponse {
  access_token?: string;
  refresh_token?: string;
  user: User;
  message?: string;
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
