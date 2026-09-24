import {
  Controller,
  Get,
  HttpException,
  HttpStatus,
  Post,
  Body,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';
import { OAuthMetadataService } from './oauth-metadata.service';
import { OAuthTokenService } from './oauth-token.service';
import { OAuthClientService } from './oauth-client.service';
import { OAuthAuthorizeService } from './oauth-authorize.service';
import { AuthGuard } from '../auth.guard';

/**
 * OAuth 2.1 discovery, registration, authorization, and token endpoints.
 * - `GET  /api/oauth/.well-known/oauth-authorization-server`  (RFC 8414)
 * - `GET  /api/oauth/.well-known/authorization-server`        (RFC 8414 alt)
 * - `GET  /api/oauth/.well-known/resource`                    (RFC 9728)
 * - `POST /api/oauth/register`                                 (RFC 7591 dynamic client registration)
 * - `GET  /api/oauth/authorize`                                (issue PKCE code; requires session)
 * - `POST /api/oauth/token`                                    (PKCE exchange)
 */
@Controller('api/oauth')
export class OAuthController {
  constructor(
    private readonly metadata: OAuthMetadataService,
    private readonly tokenService: OAuthTokenService,
    private readonly clients: OAuthClientService,
    private readonly authorizeService: OAuthAuthorizeService,
  ) {}

  @Get('.well-known/oauth-authorization-server')
  wellKnownAuthServer() {
    return this.metadata.serverMetadata();
  }

  @Get('.well-known/authorization-server')
  authServerAlias() {
    return this.metadata.serverMetadata();
  }

  @Get('.well-known/resource')
  wellKnownResource() {
    return this.metadata.resourceMetadata();
  }

  // Dynamic client registration (RFC 7591): no auth required — clients are
  // registered before they have credentials.
  @Post('register')
  async register(@Body() body: Record<string, unknown>) {
    const redirectUris = Array.isArray(body.redirect_uris)
      ? body.redirect_uris.filter((u): u is string => typeof u === 'string')
      : [];
    if (redirectUris.length === 0) {
      throw new HttpException(
        {
          error: 'invalid_redirect_uri',
          error_description: 'at least one redirect_uri is required',
        },
        HttpStatus.BAD_REQUEST,
      );
    }
    const out = await this.clients.register({
      redirect_uris: redirectUris,
      client_name:
        typeof body.client_name === 'string' ? body.client_name : undefined,
      token_endpoint_auth_method:
        body.token_endpoint_auth_method === 'none'
          ? 'none'
          : 'client_secret_post',
      scope: typeof body.scope === 'string' ? body.scope : undefined,
    });
    return out;
  }

  // Authorization endpoint: rides the resource-owner's session. Issues a
  // single-use PKCE code after implicitly approving the requested scopes.
  @Get('authorize')
  @UseGuards(AuthGuard)
  async authorize(
    @Req() req: Request,
    @Query('client_id') clientId: string,
    @Query('redirect_uri') redirectUri: string,
    @Query('code_challenge') codeChallenge: string,
    @Query('scope') scope?: string,
    @Query('state') state?: string,
  ) {
    const user = (req as unknown as { user?: { id: string } }).user;
    if (!user) throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);

    const result = await this.authorizeService.authorize(
      user.id,
      {
        clientId,
        redirectUri,
        codeChallenge,
        scope,
      },
      state,
    );
    if (result.error) {
      throw new HttpException(
        { error: result.error, error_description: result.error_description },
        HttpStatus.BAD_REQUEST,
      );
    }
    // RFC 6749: redirect back to the client with the code.
    return {
      redirect_uri: result.redirectUri,
      code: result.code,
      state: result.state,
    };
  }

  @Post('token')
  async token(@Body() body: Record<string, unknown>) {
    const grantType = body.grant_type;

    if (grantType === 'refresh_token') {
      // Refresh grant not yet wired; advertise but refuse explicitly.
      throw new HttpException(
        {
          error: 'invalid_grant',
          error_description: 'refresh_token grant not supported',
        },
        HttpStatus.BAD_REQUEST,
      );
    }

    if (grantType !== 'authorization_code') {
      throw new HttpException(
        {
          error: 'unsupported_grant_type',
          error_description: 'grant_type must be authorization_code',
        },
        HttpStatus.BAD_REQUEST,
      );
    }

    const result = await this.tokenService.token({
      grantType: 'authorization_code',
      code: typeof body.code === 'string' ? body.code : '',
      redirectUri:
        typeof body.redirect_uri === 'string' ? body.redirect_uri : '',
      clientId: typeof body.client_id === 'string' ? body.client_id : '',
      codeVerifier:
        typeof body.code_verifier === 'string' ? body.code_verifier : undefined,
      scope: typeof body.scope === 'string' ? body.scope : undefined,
    });

    if ('error' in result) {
      throw new HttpException(result, HttpStatus.BAD_REQUEST);
    }
    return result;
  }
}
