import { OAuthClientService } from './oauth-client.service';

interface OAuthClientRow {
  clientId: string;
  clientSecret: string | null;
  name: string;
  redirectUris: string[];
  scopes: string[];
  isConfidential: boolean;
}

const mockPrisma = () => ({
  oAuthClient: {
    create: jest.fn() as jest.MockedFunction<
      (args: { data: OAuthClientRow }) => Promise<OAuthClientRow>
    >,
    findUnique: jest.fn() as jest.MockedFunction<
      (args: { where: { clientId: string } }) => Promise<OAuthClientRow | null>
    >,
  },
});

describe('OAuthClientService', () => {
  it('registers a confidential client and issues a secret', async () => {
    const prisma = mockPrisma();
    prisma.oAuthClient.create.mockResolvedValue({
      clientId: 'anchor-oauth_abc',
      clientSecret: 'sec_xyz',
      name: 'App',
      redirectUris: ['https://app/cb'],
      scopes: ['read-only'],
      isConfidential: true,
    });
    const service = new OAuthClientService(prisma as never);
    const out = await service.register({
      redirect_uris: ['https://app/cb'],
      client_name: 'App',
    });
    expect(out.client_id).toBe('anchor-oauth_abc');
    expect(out.client_secret).toMatch(/^sec_/);
    expect(out.token_endpoint_auth_method).toBe('client_secret_post');
    const callData = prisma.oAuthClient.create.mock.calls[0]?.[0] as {
      data: { isConfidential: boolean; scopes: string[] };
    };
    expect(callData.data.isConfidential).toBe(true);
    expect(callData.data.scopes).toEqual(['read-only']);
  });

  it('registers a public client (token_endpoint_auth_method none) with no secret', async () => {
    const prisma = mockPrisma();
    prisma.oAuthClient.create.mockResolvedValue({
      clientId: 'anchor-oauth_abc',
      clientSecret: null,
      name: 'Pub',
      redirectUris: ['https://app/cb'],
      scopes: ['read-only'],
      isConfidential: false,
    });
    const service = new OAuthClientService(prisma as never);
    const out = await service.register({
      redirect_uris: ['https://app/cb'],
      token_endpoint_auth_method: 'none',
    });
    expect(out.client_secret).toBeUndefined();
    expect(out.token_endpoint_auth_method).toBe('none');
    const callData = prisma.oAuthClient.create.mock.calls[0]?.[0] as {
      data: { isConfidential: boolean };
    };
    expect(callData.data.isConfidential).toBe(false);
  });

  it('validates a confidential client only with the matching secret', async () => {
    const prisma = mockPrisma();
    prisma.oAuthClient.findUnique.mockResolvedValue({
      clientId: 'c1',
      clientSecret: 'sec',
      name: 'C',
      redirectUris: ['https://app/cb'],
      scopes: ['read-only'],
      isConfidential: true,
    });
    const service = new OAuthClientService(prisma as never);
    expect(await service.validateCredentials('c1', 'sec')).not.toBeNull();
    expect(await service.validateCredentials('c1', 'bad')).toBeNull();
  });
});
