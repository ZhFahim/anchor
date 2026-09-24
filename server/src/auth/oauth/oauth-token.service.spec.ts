import { OAuthTokenService } from './oauth-token.service';
import { OAuthCodeStore, PKCE } from './oauth-code.store';

// Narrow the union return to a permissive shape for assertion convenience.
type TokenResult = {
  error?: string;
  error_description?: string;
  access_token?: string;
  token_type?: string;
  expires_in?: number;
  refresh_token?: string;
  scope?: string;
};
const asResult = (r: unknown): TokenResult => r as TokenResult;

describe('OAuthTokenService', () => {
  let codes: OAuthCodeStore;
  let authService: { createTokenPair: jest.Mock };
  let service: OAuthTokenService;

  const verifier = 'long-pkce-verifier-value';
  const challenge = PKCE.challenge(verifier);

  beforeEach(() => {
    codes = new OAuthCodeStore();
    authService = {
      createTokenPair: jest
        .fn()
        .mockResolvedValue({ access_token: 'at', refresh_token: 'rt' }),
    };
    service = new OAuthTokenService(codes, authService as never);
  });

  const issueCode = (codeChallenge: string | null = challenge) => {
    const { code } = codes.issue({
      userId: 'u1',
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeChallenge,
      scope: 'read-only',
      expiresAt: Date.now() + 60_000,
    });
    return code;
  };

  it('exchanges a PKCE-verified code for tokens', async () => {
    const code = issueCode();
    const out = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeVerifier: verifier,
    });
    expect(asResult(out).error).toBeUndefined();
    expect(asResult(out).access_token).toBe('at');
    expect(asResult(out).scope).toBe('read-only');
    expect(authService.createTokenPair).toHaveBeenCalledWith('u1', '');
  });

  it('rejects when the PKCE verifier does not match the challenge', async () => {
    const code = issueCode();
    const out = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeVerifier: 'wrong-verifier',
    });
    expect(asResult(out).error).toBe('invalid_grant');
    expect(authService.createTokenPair).not.toHaveBeenCalled();
  });

  it('rejects a missing PKCE verifier when the code has a challenge', async () => {
    const code = issueCode();
    const out = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'c1',
      redirectUri: 'https://app/cb',
    });
    expect(asResult(out).error).toBe('invalid_grant');
  });

  it('a code cannot be replayed (single-use)', async () => {
    const code = issueCode();
    const first = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeVerifier: verifier,
    });
    expect(asResult(first).error).toBeUndefined();
    const replay = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeVerifier: verifier,
    });
    expect(asResult(replay).error).toBe('invalid_grant');
  });

  it('rejects a client_id/redirect that does not match the code', async () => {
    const code = issueCode();
    const out = await service.token({
      grantType: 'authorization_code',
      code,
      clientId: 'other-client',
      redirectUri: 'https://app/cb',
      codeVerifier: verifier,
    });
    expect(asResult(out).error).toBe('invalid_grant');
  });
});
