import {
  Injectable,
  Logger,
  InternalServerErrorException,
} from '@nestjs/common';
import {
  discovery,
  buildAuthorizationUrl,
  authorizationCodeGrant,
  fetchUserInfo,
  randomState,
  randomPKCECodeVerifier,
  calculatePKCECodeChallenge,
  skipSubjectCheck,
  type Configuration,
  type UserInfoResponse,
  type TokenEndpointResponse,
  ClientSecretPost,
} from 'openid-client';
import { OidcConfigService } from './oidc-config.service';

/**
 * Client auth for public clients (no secret).
 * Sends client_id and client_secret (empty) - some IdPs require
 * client_secret to be present in the token request even for public clients.
 */
const PublicClientAuth = (
  _as: unknown,
  client: { client_id: string },
  body: URLSearchParams,
  _headers: Headers,
) => {
  body.set('client_id', client.client_id);
  body.set('client_secret', '');
};

@Injectable()
export class OidcClientService {
  private readonly logger = new Logger(OidcClientService.name);

  constructor(private readonly oidcConfigService: OidcConfigService) { }

  /**
   * Get OIDC client configuration via OpenID discovery.
   */
  async getConfiguration(): Promise<Configuration> {
    const oidcConfig = await this.oidcConfigService.getConfig();
    if (!oidcConfig.enabled || !oidcConfig.issuerUrl || !oidcConfig.clientId) {
      throw new InternalServerErrorException('OIDC is not properly configured');
    }

    try {
      const issuerUrl = new URL(oidcConfig.issuerUrl);

      const clientAuth = oidcConfig.clientSecret
        ? ClientSecretPost(oidcConfig.clientSecret)
        : PublicClientAuth;

      const config = await discovery(
        issuerUrl,
        oidcConfig.clientId,
        {
          redirect_uris: [this.getCallbackUrl()],
          response_types: ['code'],
        },
        clientAuth,
      );

      return config;
    } catch (error) {
      this.logger.error('Failed to initialize OIDC configuration:', error);
      throw new InternalServerErrorException(
        'Failed to initialize OIDC configuration. Check your OIDC settings.',
      );
    }
  }

  /**
   * Build authorization URL
   */
  async buildAuthorizationUrl(
    state: string,
    codeChallenge?: string,
  ): Promise<string> {
    const config = await this.getConfiguration();

    const params: Record<string, string> = {
      redirect_uri: this.getCallbackUrl(),
      response_type: 'code',
      scope: 'openid email profile',
      state,
    };

    if (codeChallenge) {
      params.code_challenge = codeChallenge;
      params.code_challenge_method = 'S256';
    }

    const authUrl = buildAuthorizationUrl(config, params);
    return authUrl.toString();
  }

  /**
   * Exchange authorization code for tokens
   */
  async exchangeCodeForTokens(
    callbackUrl: URL,
    expectedState: string,
    codeVerifier?: string,
  ): Promise<TokenEndpointResponse> {
    const config = await this.getConfiguration();

    const checks: { expectedState: string; pkceCodeVerifier?: string } = {
      expectedState,
    };
    if (codeVerifier) {
      checks.pkceCodeVerifier = codeVerifier;
    }

    return authorizationCodeGrant(config, callbackUrl, checks);
  }

  /**
   * Fetch user info from OIDC provider.
   * When expectedSubject is provided (e.g. from ID token), validates that userinfo sub matches per OpenID spec.
   */
  async fetchUserInfo(
    accessToken: string,
    expectedSubject?: string,
  ): Promise<UserInfoResponse | null> {
    try {
      const config = await this.getConfiguration();
      return await fetchUserInfo(
        config,
        accessToken,
        expectedSubject ?? skipSubjectCheck,
      );
    } catch (error) {
      this.logger.warn('Failed to fetch userinfo:', error);
      return null;
    }
  }

  /**
   * Generate PKCE code verifier and challenge
   */
  async generatePKCE(): Promise<{
    codeVerifier: string;
    codeChallenge: string;
  }> {
    const codeVerifier = randomPKCECodeVerifier();
    const codeChallenge = await calculatePKCECodeChallenge(codeVerifier);
    return { codeVerifier, codeChallenge };
  }

  /**
   * Generate random state for CSRF protection
   */
  generateState(): string {
    return randomState();
  }

  /**
   * Get callback URL
   */
  private getCallbackUrl(): string {
    return `${this.oidcConfigService.getAppUrl()}/api/auth/oidc/callback`;
  }
}
