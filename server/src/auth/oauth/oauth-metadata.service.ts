import { Injectable } from '@nestjs/common';
import { AppConfig } from '../../config/configuration';
import type { ConfigType } from '@nestjs/config';

/**
 * OAuth 2.1 authorization-server discovery metadata (RFC 8414) and
 * protected-resource metadata (RFC 9728 `/resource`).
 *
 * Anchor is the AS. It delegates its login step to the configured OIDC/IdP when
 * one exists (plain-password installs still work); OAuth scopes reuse the PAT
 * scopes (read-only / read-write). See the PR-3 plan.
 */
@Injectable()
export class OAuthMetadataService {
  constructor(private readonly appConfig: ConfigType<typeof AppConfig>) {}

  private get issuer(): string {
    return this.appConfig.appUrl;
  }

  private endpoints() {
    const base = this.issuer;
    return {
      authorizationEndpoint: `${base}/api/oauth/authorize`,
      tokenEndpoint: `${base}/api/oauth/token`,
      jwksUri: `${base}/api/oauth/jwks`,
      registrationEndpoint: `${base}/api/oauth/register`,
      resourceMetadata: `${base}/api/oauth/.well-known/resource`,
      revocationEndpoint: `${base}/api/oauth/revoke`,
      introspectionEndpoint: `${base}/api/oauth/introspect`,
    };
  }

  /** RFC 8414 `/.well-known/oauth-authorization-server` document. */
  serverMetadata() {
    return {
      issuer: this.issuer,
      authorization_endpoint: this.endpoints().authorizationEndpoint,
      token_endpoint: this.endpoints().tokenEndpoint,
      jwks_uri: this.endpoints().jwksUri,
      registration_endpoint: this.endpoints().registrationEndpoint,
      revocation_endpoint: this.endpoints().revocationEndpoint,
      introspection_endpoint: this.endpoints().introspectionEndpoint,
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code', 'refresh_token'],
      token_endpoint_auth_methods_supported: ['client_secret_post'],
      code_challenge_methods_supported: ['S256'],
      scopes_supported: ['read-only', 'read-write'],
      // OAuth 2.1 (RFC 9700) requires PKCE and short-lived codes.
      require_pkce: true,
      require_refresh_token_rotation: true,
    };
  }

  /** RFC 9728 `/.well-known/resource` document for protected-resource metadata. */
  resourceMetadata() {
    return {
      resource: this.issuer,
      authorization_servers: [this.issuer],
      scopes_supported: ['read-only', 'read-write'],
    };
  }
}
