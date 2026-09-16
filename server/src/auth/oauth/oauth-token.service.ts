import { Injectable } from '@nestjs/common';
import { OAuthCodeStore, PKCE } from './oauth-code.store';
import { AuthService } from '../auth.service';

export interface OAuthTokenRequest {
  grantType: 'authorization_code';
  code: string;
  redirectUri: string;
  clientId: string;
  /** PKCE code_verifier (RFC 7636) — required per OAuth 2.1 (require_pkce). */
  codeVerifier?: string;
  scope?: string;
}

export type OAuthTokenResult =
  | { error: 'invalid_grant'; error_description: string }
  | {
      access_token: string;
      token_type: 'Bearer';
      expires_in: number;
      refresh_token: string;
      scope?: string;
    };

/**
 * The OAuth token endpoint handler. Exchanges a single-use, PKCE-verified
 * authorization code for an access + refresh token pair. Issuing reuses
 * `AuthService.createTokenPair` (the same JWT/refresh mechanism the app
 * already uses), so OAuth tokens are first-class with the rest of Anchor auth.
 */
@Injectable()
export class OAuthTokenService {
  constructor(
    private readonly codes: OAuthCodeStore,
    private readonly authService: AuthService,
  ) {}

  async token(req: OAuthTokenRequest): Promise<OAuthTokenResult> {
    if (req.grantType !== 'authorization_code') {
      return this.invalidGrant('Unsupported grant_type');
    }
    if (!req.code || !req.clientId || !req.redirectUri) {
      return this.invalidGrant('Missing required parameters');
    }

    const code = this.codes.consume(req.code);
    if (!code) {
      return this.invalidGrant(
        'Authorization code is invalid, expired, or already used',
      );
    }
    if (
      code.clientId !== req.clientId ||
      code.redirectUri !== req.redirectUri
    ) {
      return this.invalidGrant(
        'client_id or redirect_uri does not match the code',
      );
    }

    // OAuth 2.1 mandates PKCE. If the code was issued with a challenge, the
    // verifier must match; refuse otherwise.
    if (code.codeChallenge) {
      if (!req.codeVerifier)
        return this.invalidGrant('PKCE code_verifier required');
      if (PKCE.challenge(req.codeVerifier) !== code.codeChallenge) {
        return this.invalidGrant('PKCE verification failed');
      }
    }

    const { access_token, refresh_token } =
      await this.authService.createTokenPair(code.userId, '');
    return {
      access_token,
      token_type: 'Bearer',
      expires_in: 3600,
      refresh_token,
      scope: code.scope,
    };
  }

  private invalidGrant(
    msg: string,
  ): Extract<OAuthTokenResult, { error: string }> {
    return {
      error: 'invalid_grant',
      error_description: msg,
    };
  }
}
