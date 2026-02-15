/**
 * Shared OIDC types.
 */

export interface OidcUserClaims {
  email: string;
  name: string;
  subject: string;
  picture?: string;
}

export interface OidcConfig {
  enabled: boolean;
  providerName: string;
  issuerUrl?: string;
  clientId?: string;
  clientSecret?: string;
  disableInternalAuth: boolean;
}

export interface OidcUserPayload {
  id: string;
  email: string;
  name: string;
  profileImage: string | null;
  isAdmin: boolean;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface OidcAuthResult {
  access_token: string;
  refresh_token: string;
  user: OidcUserPayload;
  redirectUrl?: string;
}

export interface OidcExchangeResult {
  access_token: string;
  refresh_token: string;
  user: OidcUserPayload;
  redirectUrl: string;
}
