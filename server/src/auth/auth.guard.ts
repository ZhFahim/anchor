import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ExtractJwt } from 'passport-jwt';
import { UserStatus } from '../generated/prisma/enums';
import { TokenResolverService } from './token-resolver.service';
import { AuthenticatedRequest } from './authenticated-request';
import { coded } from '../common/errors/coded';
import { ErrorCode } from '../common/errors/error-code';

const extractBearerToken = ExtractJwt.fromAuthHeaderAsBearerToken();

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokenResolver: TokenResolverService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = extractBearerToken(request);

    if (!token) {
      throw coded(
        new UnauthorizedException('Missing authentication token'),
        ErrorCode.TOKEN_MISSING,
      );
    }

    const user = await this.tokenResolver.resolveUser(token);

    if (!user) {
      throw coded(
        new UnauthorizedException('Invalid authentication token'),
        ErrorCode.TOKEN_INVALID,
      );
    }

    if (user.status !== UserStatus.active) {
      throw coded(
        new UnauthorizedException('Account pending approval'),
        ErrorCode.ACCOUNT_PENDING,
      );
    }

    request.user = user;
    return true;
  }
}
