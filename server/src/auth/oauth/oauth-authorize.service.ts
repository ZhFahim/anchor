import { Injectable } from '@nestjs/common';
import { OAuthCodeStore } from './oauth-code.store';
import { OAuthClientService } from './oauth-client.service';

export interface OAuthAuthorizeRequest {
  clientId: string;
  redirectUri: string;
  /** Base64url SHA-256 code_challenge (RFC 7636 S256). */
  codeChallenge: string;
  scope?: string;
}

export type OAuthAuthorizeResult = {
  redirectUri?: string;
  code?: string;
  state?: string;
  error?: 'invalid_client' | 'invalid_request';
  error_description?: string;
};

/**
 * The OAuth authorization endpoint: verifies the client + redirect and, after
 * (implicitly) user consent, issues a short-lived single-use authorization code
 * bound to the client/redirect and the PKCE challenge. It does not hold the
 * challenge->issued association in a DB; the code store carries it.
 */
@Injectable()
export class OAuthAuthorizeService {
  constructor(
    private readonly clients: OAuthClientService,
    private readonly codes: OAuthCodeStore,
  ) {}

  async authorize(
    userId: string,
    req: OAuthAuthorizeRequest,
    state?: string,
  ): Promise<OAuthAuthorizeResult> {
    const client = await this.clients.validateCredentials(req.clientId);
    if (!client) {
      return {
        error: 'invalid_client',
        error_description: 'Unknown client_id',
      };
    }
    if (!client.redirectUris.includes(req.redirectUri)) {
      return {
        error: 'invalid_request',
        error_description: 'redirect_uri is not registered',
      };
    }
    if (!req.codeChallenge) {
      return {
        error: 'invalid_request',
        error_description: 'OAuth 2.1 requires PKCE (code_challenge)',
      };
    }

    const { code } = this.codes.issue({
      userId,
      clientId: req.clientId,
      redirectUri: req.redirectUri,
      codeChallenge: req.codeChallenge,
      scope: req.scope ?? 'read-only',
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes; short-lived
    });

    const sep = req.redirectUri.includes('?') ? '&' : '?';
    const fragment = `code=${encodeURIComponent(code)}${state ? `&state=${encodeURIComponent(state)}` : ''}`;
    return { redirectUri: `${req.redirectUri}${sep}${fragment}`, code };
  }
}
