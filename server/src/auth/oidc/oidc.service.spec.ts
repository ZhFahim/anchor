import { beforeEach, describe, expect, it, vi } from 'vitest';
import { BadRequestException, Logger } from '@nestjs/common';
import { OidcService } from './oidc.service';
import { AuthService } from '../auth.service';
import { OidcConfigService } from './oidc-config.service';
import { OidcClientService } from './oidc-client.service';
import { OidcStateService } from './oidc-state.service';
import { OidcUserService } from './oidc-user.service';
import { UserStatus } from '../../generated/prisma/enums';

describe('OidcService redirects', () => {
  const APP_URL = 'https://notes.example.com';

  const oidcConfigService = {
    getAppUrl: vi.fn(() => APP_URL),
  };
  const oidcClientService = {
    generateState: vi.fn(() => 'state-1'),
    generatePKCE: vi.fn(() =>
      Promise.resolve({ codeVerifier: 'verifier', codeChallenge: 'challenge' }),
    ),
    buildAuthorizationUrl: vi.fn(() =>
      Promise.resolve('https://idp.example.com/authorize'),
    ),
    exchangeCodeForTokens: vi.fn(() =>
      Promise.resolve({
        access_token: 'idp-token',
        claims: () => ({ sub: 'sub-1', email: 'pat@example.com' }),
      }),
    ),
    fetchUserInfo: vi.fn(() =>
      Promise.resolve({ sub: 'sub-1', email: 'pat@example.com', name: 'Pat' }),
    ),
  };
  const oidcStateService = {
    storeState: vi.fn<OidcStateService['storeState']>(),
    getState: vi.fn(),
    deleteState: vi.fn(),
  };
  const oidcUserService = {
    findOrCreateUser: vi.fn(() =>
      Promise.resolve({
        id: 'user-1',
        email: 'pat@example.com',
        name: 'Pat',
        profileImage: null,
        isAdmin: false,
        status: UserStatus.active,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    ),
  };
  const authService = {
    createTokenPair: vi.fn(() =>
      Promise.resolve({ access_token: 'access', refresh_token: 'refresh' }),
    ),
  };

  let service: OidcService;

  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(Logger.prototype, 'warn').mockImplementation(() => {});
    service = new OidcService(
      authService as unknown as AuthService,
      oidcConfigService as unknown as OidcConfigService,
      oidcClientService as unknown as OidcClientService,
      oidcStateService as unknown as OidcStateService,
      oidcUserService as unknown as OidcUserService,
    );
  });

  const storedRedirect = () => oidcStateService.storeState.mock.lastCall?.[2];

  const finishSignIn = (redirectUrl: string) => {
    oidcStateService.getState.mockReturnValue({
      state: 'state-1',
      codeVerifier: 'verifier',
      redirectUrl,
      expiresAt: Date.now() + 60_000,
    });
    return service.handleCallback(
      `${APP_URL}/api/auth/oidc/callback?code=c&state=state-1`,
      'state-1',
    );
  };

  describe('when signing in starts', () => {
    it.each([
      ['/\\evil.com'],
      ['//evil.com'],
      ['https://evil.com'],
      ['https://evil.com/notes'],
      ['javascript:alert(1)'],
    ])('turns down %s', async (redirect) => {
      await expect(service.getAuthorizationUrl(redirect)).rejects.toThrow(
        BadRequestException,
      );
      expect(oidcStateService.storeState).not.toHaveBeenCalled();
    });

    it('keeps a path with its search and hash', async () => {
      await service.getAuthorizationUrl('/notes/abc?x=1#y');
      expect(storedRedirect()).toBe('/notes/abc?x=1#y');
    });

    it('keeps an encoded backslash as part of the path on this site', async () => {
      await service.getAuthorizationUrl('/%5Cevil.com');
      expect(storedRedirect()).toBe('/%5Cevil.com');
    });

    it('turns an address on this site into its path', async () => {
      await service.getAuthorizationUrl(`${APP_URL}/notes/abc?x=1#y`);
      expect(storedRedirect()).toBe('/notes/abc?x=1#y');
    });

    it('stores nothing when there is no redirect', async () => {
      await service.getAuthorizationUrl(undefined);
      expect(storedRedirect()).toBeUndefined();
    });
  });

  describe('when the provider sends the user back', () => {
    it.each([
      ['/\\evil.com'],
      ['//evil.com'],
      ['https://evil.com'],
      ['javascript:alert(1)'],
    ])('sends %s to the home page instead', async (redirect) => {
      expect((await finishSignIn(redirect)).redirectUrl).toBe('/');
    });

    it('returns to the stored path', async () => {
      expect((await finishSignIn('/notes/abc?x=1#y')).redirectUrl).toBe(
        '/notes/abc?x=1#y',
      );
    });
  });
});
