import { OAuthMetadataService } from './oauth-metadata.service';

describe('OAuthMetadataService', () => {
  const appConfig = { appUrl: 'https://notes.example.com' } as never;
  let service: OAuthMetadataService;

  beforeEach(() => {
    service = new OAuthMetadataService(appConfig);
  });

  it('advertises OAuth 2.1 discovery endpoints (RFC 8414)', () => {
    const m = service.serverMetadata();
    expect(m.issuer).toBe('https://notes.example.com');
    expect(m.authorization_endpoint).toBe(
      'https://notes.example.com/api/oauth/authorize',
    );
    expect(m.token_endpoint).toBe('https://notes.example.com/api/oauth/token');
    expect(m.jwks_uri).toBe('https://notes.example.com/api/oauth/jwks');
    expect(m.registration_endpoint).toBe(
      'https://notes.example.com/api/oauth/register',
    );
  });

  it('enforces OAuth 2.1 requirements (PKCE, refresh rotation)', () => {
    const m = service.serverMetadata();
    expect(m.require_pkce).toBe(true);
    expect(m.require_refresh_token_rotation).toBe(true);
    expect(m.code_challenge_methods_supported).toEqual(['S256']);
    expect(m.grant_types_supported).toContain('authorization_code');
    expect(m.grant_types_supported).toContain('refresh_token');
  });

  it('exposes PAT-scope-derived OAuth scopes', () => {
    const m = service.serverMetadata();
    expect(m.scopes_supported).toEqual(['read-only', 'read-write']);
  });

  it('serves RFC 9728 protected-resource metadata', () => {
    const r = service.resourceMetadata();
    expect(r.resource).toBe('https://notes.example.com');
    expect(r.authorization_servers).toEqual(['https://notes.example.com']);
    expect(r.scopes_supported).toEqual(['read-only', 'read-write']);
  });
});
