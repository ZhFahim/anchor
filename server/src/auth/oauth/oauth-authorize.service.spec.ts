import { OAuthAuthorizeService } from './oauth-authorize.service';
import { OAuthCodeStore, PKCE } from './oauth-code.store';

describe('OAuthAuthorizeService', () => {
  let codes: OAuthCodeStore;
  let authorize: OAuthAuthorizeService;

  beforeEach(() => {
    codes = new OAuthCodeStore();
    const clients = {
      validateCredentials: jest.fn().mockResolvedValue({
        clientId: 'c1',
        redirectUris: ['https://app/cb'],
      }),
    };
    authorize = new OAuthAuthorizeService(clients as never, codes);
  });

  const req = {
    clientId: 'c1',
    redirectUri: 'https://app/cb',
    codeChallenge: PKCE.challenge('v'),
  };

  it('issues a short-lived code and builds the redirect with code+state', async () => {
    const out = await authorize.authorize('u1', req, 'st');
    expect(out.error).toBeUndefined();
    expect(out.redirectUri).toContain('https://app/cb?code=');
    expect(out.redirectUri).toContain('&state=st');
    // The issued code must be consumable exactly once.
    const consumed = codes.consume(out.code!);
    expect(consumed?.userId).toBe('u1');
    expect(codes.consume(out.code!)).toBeNull();
  });

  it('rejects an unregistered redirect_uri', async () => {
    const out = await authorize.authorize('u1', {
      ...req,
      redirectUri: 'https://evil/cb',
    });
    expect(out.error).toBe('invalid_request');
  });

  it('refuses when PKCE code_challenge is missing (OAuth 2.1)', async () => {
    const out = await authorize.authorize('u1', { ...req, codeChallenge: '' });
    expect(out.error).toBe('invalid_request');
  });
});
