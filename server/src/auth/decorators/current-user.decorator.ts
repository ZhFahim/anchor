import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from 'src/generated/prisma/client';

export const CurrentUser = createParamDecorator(
  (data: keyof Omit<User, 'password'> | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const payload = request.user;

    if (!payload) return null;

    return data ? payload[data] : payload;
  },
);
