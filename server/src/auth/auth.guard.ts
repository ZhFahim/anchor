import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ExtractJwt } from 'passport-jwt';
import { UserStatus } from '../generated/prisma/enums';
import { TokenResolverService, isApiTokenAuth } from './token-resolver.service';
import { AuthenticatedRequest } from './authenticated-request';
import type { ApiTokenScope } from '../generated/prisma/enums';

const extractBearerToken = ExtractJwt.fromAuthHeaderAsBearerToken();

/** HTTP methods that mutate state; rejected for read-only API tokens. */
const WRITE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokenResolver: TokenResolverService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = extractBearerToken(request);

    if (!token) {
      throw new UnauthorizedException('Missing authentication token');
    }

    const user = await this.tokenResolver.resolveUser(token);

    if (!user) {
      throw new UnauthorizedException('Invalid authentication token');
    }

    if (user.status !== UserStatus.active) {
      throw new UnauthorizedException('Account pending approval');
    }

    request.user = user;
    this.enforceScope(request, user.apiTokenScope);
    return true;
  }

  private enforceScope(
    request: AuthenticatedRequest,
    scope: ApiTokenScope,
  ): void {
    if (!request.user || !isApiTokenAuth(request.user)) return;

    if (scope === 'readOnly' && WRITE_METHODS.has(request.method)) {
      throw new ForbiddenException(
        'API token is read-only; use a read-write token to modify data',
      );
    }
  }
}
