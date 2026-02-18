import {
  Injectable,
  Logger,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
  ForbiddenException,
  InternalServerErrorException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import type { UserInfoResponse, TokenEndpointResponse } from 'openid-client';
import { AuthService } from '../auth.service';
import { OidcConfigService } from './oidc-config.service';
import { OidcClientService } from './oidc-client.service';
import { OidcStateService } from './oidc-state.service';
import { OidcUserService } from './oidc-user.service';
import { UserStatus } from '../../generated/prisma/enums';
import type { OidcAuthResult, OidcUserClaims } from './oidc.types';
import { getErrorMessage } from './oidc.utils';

export type { OidcAuthResult } from './oidc.types';

@Injectable()
export class OidcService {
  private readonly logger = new Logger(OidcService.name);

  constructor(
    private readonly authService: AuthService,
    private readonly oidcConfigService: OidcConfigService,
    private readonly oidcClientService: OidcClientService,
    private readonly oidcStateService: OidcStateService,
    private readonly oidcUserService: OidcUserService,
  ) { }

  /**
   * Get authorization URL to redirect user to OIDC provider
   */
  async getAuthorizationUrl(redirectUrl?: string): Promise<string> {
    const validatedRedirect = this.validateRedirectUrl(redirectUrl);

    // Generate state for CSRF protection
    const state = this.oidcClientService.generateState();

    // Generate PKCE
    const pkce = await this.oidcClientService.generatePKCE();

    // Store state
    this.oidcStateService.storeState(
      state,
      pkce.codeVerifier,
      validatedRedirect,
    );

    // Build authorization URL
    return this.oidcClientService.buildAuthorizationUrl(
      state,
      pkce.codeChallenge,
    );
  }

  /**
   * Handle OIDC callback - exchange code for tokens and create/link user
   */
  async handleCallback(
    callbackUrl: string,
    stateFromProvider: string,
  ): Promise<OidcAuthResult> {
    const oidcConfig = await this.oidcConfigService.getConfig();

    // Retrieve and validate state
    const storedState = this.oidcStateService.getState(stateFromProvider);
    if (!storedState) {
      throw new BadRequestException('Invalid or expired state');
    }

    // Clean up state immediately after validation
    this.oidcStateService.deleteState(stateFromProvider);

    try {
      // Parse callback URL
      const callbackUrlObj = new URL(callbackUrl);

      // Exchange code for tokens
      const tokenResponse = await this.oidcClientService.exchangeCodeForTokens(
        callbackUrlObj,
        storedState.state,
        storedState.codeVerifier,
      );

      // Fetch user info (pass subject from ID token when available for OpenID spec validation)
      const expectedSubject = (
        tokenResponse as { claims?: () => { sub?: string } }
      ).claims?.()?.sub;
      const userinfo = tokenResponse.access_token
        ? await this.oidcClientService.fetchUserInfo(
          tokenResponse.access_token,
          expectedSubject,
        )
        : null;

      // Extract user claims from token response and userinfo
      const claims = this.extractUserClaims(tokenResponse, userinfo);

      // Find or create user (auto-links by email when match found)
      const user = await this.oidcUserService.findOrCreateUser(claims);

      // Check if user is pending approval
      if (user.status === UserStatus.pending) {
        throw new UnauthorizedException(
          'Account pending approval. Please wait for an administrator to approve your account.',
        );
      }

      // Generate access and refresh tokens
      const tokens = await this.authService.createTokenPair(user.id, user.email);

      return {
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          profileImage: user.profileImage,
          isAdmin: user.isAdmin,
          status: user.status,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        },
        redirectUrl:
          this.validateRedirectUrl(storedState.redirectUrl, '/') ?? '/',
      };
    } catch (error) {
      this.logger.error('OIDC callback error:', error);
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException ||
        error instanceof ConflictException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }
      const msg = getErrorMessage(
        error,
        'Failed to process OIDC callback. Please try again from the login page.',
      );
      const isProviderError = !(error instanceof Error) || (error as { cause?: unknown }).cause;
      throw new InternalServerErrorException(
        isProviderError ? `OIDC provider error: ${msg}` : msg,
      );
    }
  }

  /**
   * Create a short-lived one-time code that can be exchanged for the auth result.
   * Used to avoid passing the JWT in the redirect URL.
   */
  createExchangeCode(result: OidcAuthResult): string {
    const code = randomBytes(32).toString('hex');
    this.oidcStateService.storeExchangeResult(code, {
      access_token: result.access_token,
      refresh_token: result.refresh_token,
      user: result.user,
      redirectUrl: result.redirectUrl ?? '/',
    });
    return code;
  }

  /**
   * Exchange a one-time code for the auth result. Code is consumed (single-use).
   */
  exchangeCode(code: string): OidcAuthResult {
    const result = this.oidcStateService.consumeExchangeCode(code);
    if (!result) {
      throw new BadRequestException(
        'Invalid or expired login code. Please sign in again from the login page.',
      );
    }
    return result;
  }

  /**
   * Exchange mobile IdP access token for app tokens.
   */
  async exchangeMobileToken(accessToken: string): Promise<OidcAuthResult> {
    const userinfo = await this.oidcClientService.fetchUserInfo(accessToken);
    if (!userinfo) {
      throw new UnauthorizedException(
        'Invalid or expired OIDC token. Please sign in again.',
      );
    }

    const emptyTokenResponse = {
      claims: () => ({}),
    } as unknown as TokenEndpointResponse;
    const claims = this.extractUserClaims(emptyTokenResponse, userinfo);

    const user = await this.oidcUserService.findOrCreateUser(claims);

    if (user.status === UserStatus.pending) {
      throw new UnauthorizedException(
        'Account pending approval. Please wait for an administrator to approve your account.',
      );
    }

    const tokens = await this.authService.createTokenPair(user.id, user.email);

    return {
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        profileImage: user.profileImage,
        isAdmin: user.isAdmin,
        status: user.status,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
      redirectUrl: '/',
    };
  }

  /**
   * Extract user claims from OIDC token response and userinfo.
   */
  private extractUserClaims(
    tokenResponse: TokenEndpointResponse,
    userinfo: UserInfoResponse | null,
  ): OidcUserClaims {
    const idTokenClaims =
      (
        tokenResponse as { claims?: () => Record<string, unknown> }
      ).claims?.() ?? {};

    const email = (userinfo?.email ?? idTokenClaims.email) as string;
    const name = (userinfo?.name?.trim() ??
      idTokenClaims.name ??
      userinfo?.preferred_username ??
      email?.split('@')[0]) as string;
    const subject = (userinfo?.sub ?? idTokenClaims.sub) as string;
    const picture = (userinfo?.picture ?? idTokenClaims.picture) as
      | string
      | undefined;

    if (!email || !subject) {
      throw new BadRequestException(
        'OIDC provider did not return required claims (email, sub)',
      );
    }

    if (!this.isValidEmail(email)) {
      throw new BadRequestException(
        'OIDC provider returned an invalid email claim',
      );
    }

    return { email, name, subject, picture };
  }

  /**
   * Validate redirect URL: allow relative paths or same-origin URLs only.
   * Returns validated URL or undefined for empty. Throws if provided and invalid.
   * When fallback is provided, returns fallback instead of throwing on invalid.
   */
  private validateRedirectUrl(
    redirectUrl: string | undefined,
    fallback?: string,
  ): string | undefined {
    const trimmed = redirectUrl?.trim();
    if (!trimmed) {
      return fallback;
    }
    // Reject protocol-relative URLs
    if (trimmed.startsWith('//')) {
      if (fallback !== undefined) return fallback;
      throw new BadRequestException('Invalid redirect URL');
    }
    // Allow relative paths (must start with single / and not contain //)
    if (trimmed.startsWith('/') && !trimmed.includes('//')) {
      return trimmed;
    }
    // Allow same-origin absolute URLs
    const appUrl = this.oidcConfigService.getAppUrl();
    try {
      const redirect = new URL(trimmed);
      const app = new URL(appUrl);
      if (redirect.origin === app.origin) {
        return trimmed;
      }
    } catch {
      this.logger.warn(`Invalid redirect URL: ${trimmed}`);
    }
    if (fallback !== undefined) return fallback;
    throw new BadRequestException('Invalid redirect URL');
  }

  private isValidEmail(value: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return (
      typeof value === 'string' && value.length <= 255 && emailRegex.test(value)
    );
  }
}
