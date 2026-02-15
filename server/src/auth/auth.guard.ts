import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ExtractJwt } from 'passport-jwt';
import { UserStatus } from '../generated/prisma/enums';
import { TokenResolverService } from './token-resolver.service';

const extractBearerToken = ExtractJwt.fromAuthHeaderAsBearerToken();

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokenResolver: TokenResolverService) { }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
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
    return true;
  }
}
