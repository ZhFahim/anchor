import { Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import type { OAuthClient } from 'src/generated/prisma/client';

export interface OAuthClientRegistration {
  /** List of valid redirect URIs. */
  redirect_uris: string[];
  /** Optional client_name. */
  client_name?: string;
  /** Token endpoint auth method (default client_secret_post). */
  token_endpoint_auth_method?: 'client_secret_post' | 'none';
  /** Requested scopes (subset of read-only/read-write). */
  scope?: string;
}

/**
 * Dynamic client registration for the OAuth AS (RFC 7591). Registers a client
 * (issuing a client_id and, for confidential clients, a client_secret), and
 * looks clients up for the authorize/token flows.
 */
@Injectable()
export class OAuthClientService {
  constructor(private readonly prisma: PrismaService) {}

  private static gen(prefix: string, n = 32): string {
    return `${prefix}_${randomBytes(n).toString('base64url')}`;
  }

  async register(input: OAuthClientRegistration): Promise<{
    client_id: string;
    client_secret?: string;
    redirect_uris: string[];
    token_endpoint_auth_method: string;
    scope: string;
    client_name?: string;
  }> {
    const clientId = OAuthClientService.gen('anchor-oauth');
    const confidential =
      (input.token_endpoint_auth_method ?? 'client_secret_post') ===
      'client_secret_post';
    const clientSecret = confidential ? OAuthClientService.gen('sec') : null;

    const scopes = input.scope
      ? input.scope
          .split(/\s+/)
          .filter((s) => s === 'read-only' || s === 'read-write')
      : ['read-only'];

    const created = await this.prisma.oAuthClient.create({
      data: {
        clientId,
        clientSecret,
        name: input.client_name ?? 'Unnamed',
        redirectUris: input.redirect_uris ?? [],
        scopes,
        isConfidential: confidential,
      },
    });

    return {
      client_id: created.clientId,
      ...(clientSecret ? { client_secret: clientSecret } : {}),
      redirect_uris: created.redirectUris,
      token_endpoint_auth_method: confidential ? 'client_secret_post' : 'none',
      scope: scopes.join(' '),
      client_name: created.name,
    };
  }

  async validateCredentials(
    clientId: string,
    clientSecret?: string,
  ): Promise<OAuthClient | null> {
    const client = await this.prisma.oAuthClient.findUnique({
      where: { clientId },
    });
    if (!client) return null;
    // Confidential clients must present a matching secret; public (PKCE) clients need none.
    if (client.isConfidential && client.clientSecret !== clientSecret)
      return null;
    return client;
  }
}
