import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Req,
  Res,
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { OidcService } from './oidc.service';
import { OidcConfigService } from './oidc-config.service';
import { getErrorMessage } from './oidc.utils';

@Controller('api/auth/oidc')
export class OidcController {
  constructor(
    private readonly oidcService: OidcService,
    private readonly oidcConfigService: OidcConfigService,
  ) { }

  /**
   * Get OIDC configuration (public endpoint)
   */
  @Get('config')
  async getConfig() {
    return this.oidcConfigService.getPublicConfig();
  }

  /**
   * Initiate OIDC login flow
   */
  @Get('initiate')
  async initiate(
    @Query('redirect') redirectUrl: string | undefined,
    @Res() res: Response,
  ) {
    try {
      const isEnabled = await this.oidcConfigService.isEnabled();
      if (!isEnabled) {
        throw new BadRequestException('OIDC is not enabled');
      }

      const authUrl = await this.oidcService.getAuthorizationUrl(redirectUrl);
      return res.redirect(authUrl);
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new InternalServerErrorException('Failed to initiate OIDC login');
    }
  }

  /**
   * Handle OIDC callback - redirects to frontend with one-time exchange code
   */
  @Get('callback')
  async callback(
    @Req() req: Request,
    @Query('code') code: string | undefined,
    @Query('state') state: string | undefined,
    @Query('error') error: string | undefined,
    @Query('error_description') errorDescription: string | undefined,
    @Res() res: Response,
  ) {
    const frontendUrl = this.oidcConfigService.getAppUrl();

    if (error) {
      const errorMsg = errorDescription || error;
      return res.redirect(
        `${frontendUrl}/login?error=${encodeURIComponent(errorMsg)}`,
      );
    }

    if (!code || !state) {
      return res.redirect(
        `${frontendUrl}/login?error=${encodeURIComponent('Missing authorization code or state')}`,
      );
    }

    try {
      const callbackUrl = `${this.oidcConfigService.getAppUrl()}${req.originalUrl}`;
      const result = await this.oidcService.handleCallback(callbackUrl, state);
      const exchangeCode = this.oidcService.createExchangeCode(result);
      const redirectUrl = result.redirectUrl ?? '/';

      return res.redirect(
        `${frontendUrl}/login?code=${encodeURIComponent(exchangeCode)}&redirect=${encodeURIComponent(redirectUrl)}`,
      );
    } catch (error) {
      const errorMsg = getErrorMessage(error, 'Failed to process OIDC callback');
      return res.redirect(
        `${frontendUrl}/login?error=${encodeURIComponent(errorMsg)}`,
      );
    }
  }

  /**
   * Exchange a one-time code for access token and user
   */
  @Post('exchange')
  async exchange(@Body('code') code: string | undefined) {
    if (!code || typeof code !== 'string') {
      throw new BadRequestException('Missing or invalid code');
    }
    return this.oidcService.exchangeCode(code);
  }

  /**
   * Exchange mobile IdP access token for app tokens
   */
  @Post('exchange/mobile')
  async exchangeMobile(@Body('access_token') accessToken: string | undefined) {
    if (!accessToken || typeof accessToken !== 'string') {
      throw new BadRequestException('Missing or invalid access_token');
    }
    return this.oidcService.exchangeMobileToken(accessToken);
  }
}
