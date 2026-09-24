import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import type { Request } from 'express';
import { SlidingWindowRateLimiter } from '../../common/rate-limit/sliding-window.util';
import { AuthenticatedRequest } from '../../auth/authenticated-request';

export const SEARCH_RATE_WINDOW_MS = 60_000;
export const SEARCH_RATE_MAX = 30;

/**
 * Applies a per-user sliding-window cap to note search requests only.
 * Plain note listings (no `?search=`) are untouched; non-GET methods are
 * untouched. In-memory and deliberately cheap — adequate as the first
 * defense against `?search=` being hammered by a single account.
 */
@Injectable()
export class SearchRateLimitGuard implements CanActivate {
  constructor(
    private readonly limiter: SlidingWindowRateLimiter = new SlidingWindowRateLimiter(
      { windowMs: SEARCH_RATE_WINDOW_MS, max: SEARCH_RATE_MAX },
    ),
  ) {}

  canActivate(context: ExecutionContext): boolean {
    if (context.getType() !== 'http') return true;

    const request = context
      .switchToHttp()
      .getRequest<AuthenticatedRequest & Request>();

    const hasSearch =
      request.method === 'GET' && request.query?.search !== undefined;

    if (!hasSearch) return true;

    const key = request.user?.id ?? 'anonymous';
    if (!this.limiter.tryAcquire(key)) {
      throw new HttpException(
        { message: 'Too many search requests. Slow down and try again.' },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
