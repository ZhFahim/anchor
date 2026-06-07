import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthUser } from '../token-resolver.service';
import { AuthenticatedRequest } from '../authenticated-request';

export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<AuthenticatedRequest>();
    const payload = request.user;

    if (!payload) return null;

    return data ? payload[data] : payload;
  },
);
