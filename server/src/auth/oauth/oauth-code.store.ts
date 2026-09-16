import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';

export interface OAuthAuthorizationCode {
  code: string;
  userId: string;
  clientId: string;
  redirectUri: string;
  /** Base64url SHA-256 of the PKCE code_verifier (S256), or null if not used. */
  codeChallenge: string | null;
  /** Scope string the user approved (space-separated OAuth scopes). */
  scope: string;
  expiresAt: number;
  used: boolean;
}

/**
 * In-memory store for OAuth authorization codes (PKCE). Codes are single-use,
 * short-lived, and scoped to a client+redirect. In a multi-instance deployment
 * this is a stand-in for a DB table; codes are inherently short-lived.
 */
@Injectable()
export class OAuthCodeStore {
  private readonly codes = new Map<string, OAuthAuthorizationCode>();

  private static random(n = 32): string {
    return randomBytes(n).toString('base64url');
  }

  issue(input: Omit<OAuthAuthorizationCode, 'code' | 'used'>): {
    code: string;
    authorizationCode: OAuthAuthorizationCode;
  } {
    // OAuth 2.1: authorization codes MUST be short-lived and single-use.
    const code = OAuthCodeStore.random(32);
    const authorizationCode: OAuthAuthorizationCode = {
      ...input,
      code,
      used: false,
    };
    this.codes.set(code, authorizationCode);
    return { code, authorizationCode };
  }

  /** Consume a code exactly once. Returns the code record or null if invalid/expired. */
  consume(code: string): OAuthAuthorizationCode | null {
    const rec = this.codes.get(code);
    if (!rec) return null;
    this.codes.delete(code);
    if (rec.used || rec.expiresAt < Date.now()) return null;
    rec.used = true;
    return rec;
  }
}

export const PKCE = {
  /** OAuth 2.1 requires S256 challenge for confidential/public clients. */
  challenge(verifier: string): string {
    return createHash('sha256').update(verifier).digest('base64url');
  },
};
