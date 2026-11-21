import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedRequest } from '../auth/authenticated-request';
import { coded } from '../common/errors/coded';
import { ErrorCode } from '../common/errors/error-code';

@Injectable()
export class AdminGuard extends JwtAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // First check JWT authentication
    const isAuthenticated = await super.canActivate(context);
    if (!isAuthenticated) {
      return false;
    }

    // Then check if user is admin
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user || !user.isAdmin) {
      throw coded(
        new ForbiddenException('Admin access required'),
        ErrorCode.ADMIN_REQUIRED,
      );
    }

    return true;
  }
}
