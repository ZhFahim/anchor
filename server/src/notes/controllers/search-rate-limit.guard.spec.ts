import { ExecutionContext, HttpException } from '@nestjs/common';
import { SearchRateLimitGuard } from './search-rate-limit.guard';
import { SlidingWindowRateLimiter } from '../../common/rate-limit/sliding-window.util';

describe('SearchRateLimitGuard', () => {
  const options = { windowMs: 1000, max: 3 };
  let limiter: SlidingWindowRateLimiter;
  let tryAcquireSpy: jest.SpyInstance;
  let canActivate: (ctx: ExecutionContext) => boolean;

  beforeEach(() => {
    limiter = new SlidingWindowRateLimiter(options);
    tryAcquireSpy = jest.spyOn(limiter, 'tryAcquire');
    const g = new SearchRateLimitGuard(limiter);
    canActivate = (ctx) => g.canActivate(ctx);
  });

  const ctx = (
    method: string,
    query: Record<string, unknown>,
    user: { id: string },
  ): ExecutionContext =>
    ({
      getType: () => 'http',
      switchToHttp: () => ({
        getRequest: () => ({ method, query, user }),
      }),
    }) as unknown as ExecutionContext;

  it('does not apply when there is no search param', () => {
    expect(canActivate(ctx('GET', {}, { id: 'u1' }))).toBe(true);
    expect(tryAcquireSpy).not.toHaveBeenCalled();
  });

  it('does not apply to non-GET methods even with search', () => {
    expect(canActivate(ctx('POST', { search: 'x' }, { id: 'u1' }))).toBe(true);
  });

  it('allows requests within the limit', () => {
    for (let i = 0; i < options.max; i++) {
      expect(canActivate(ctx('GET', { search: 'x' }, { id: 'u1' }))).toBe(true);
    }
  });

  it('throttles once the limit is exceeded', () => {
    for (let i = 0; i < options.max; i++) {
      canActivate(ctx('GET', { search: 'x' }, { id: 'u1' }));
    }
    expect(() =>
      canActivate(ctx('GET', { search: 'x' }, { id: 'u1' })),
    ).toThrow(HttpException);
  });

  it('rate limits per user independently', () => {
    for (let i = 0; i < options.max; i++) {
      canActivate(ctx('GET', { search: 'x' }, { id: 'u1' }));
    }
    expect(canActivate(ctx('GET', { search: 'x' }, { id: 'u2' }))).toBe(true);
  });

  it('resets after the window elapses', () => {
    jest.useFakeTimers();
    for (let i = 0; i < options.max; i++) {
      canActivate(ctx('GET', { search: 'x' }, { id: 'u1' }));
    }
    expect(() =>
      canActivate(ctx('GET', { search: 'x' }, { id: 'u1' })),
    ).toThrow(HttpException);

    jest.advanceTimersByTime(options.windowMs + 1);
    expect(canActivate(ctx('GET', { search: 'x' }, { id: 'u1' }))).toBe(true);
    jest.useRealTimers();
  });
});
