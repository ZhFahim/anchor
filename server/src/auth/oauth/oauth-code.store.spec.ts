import { OAuthCodeStore, PKCE } from './oauth-code.store';

describe('OAuthCodeStore + PKCE', () => {
  it('PKCE.challenge produces base64url SHA-256 (S256)', () => {
    const verifier = 'abcdefgh';
    const c = PKCE.challenge(verifier);
    expect(c).toMatch(/^[A-Za-z0-9_-]+$/);
    // deterministic
    expect(PKCE.challenge(verifier)).toBe(c);
  });

  it('issues a single-use code that can only be consumed once', () => {
    const store = new OAuthCodeStore();
    const { code } = store.issue({
      userId: 'u1',
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeChallenge: null,
      scope: 'read-only',
      expiresAt: Date.now() + 60_000,
    });
    const first = store.consume(code);
    expect(first?.userId).toBe('u1');
    // second consume must be null (single-use)
    expect(store.consume(code)).toBeNull();
  });

  it('rejects expired codes', () => {
    const store = new OAuthCodeStore();
    const { code } = store.issue({
      userId: 'u1',
      clientId: 'c1',
      redirectUri: 'https://app/cb',
      codeChallenge: null,
      scope: 'read-only',
      expiresAt: Date.now() - 1,
    });
    expect(store.consume(code)).toBeNull();
  });
});
