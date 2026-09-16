import { SlidingWindowRateLimiter } from './sliding-window.util';

describe('SlidingWindowRateLimiter', () => {
  it('allows requests within the window budget', () => {
    const limiter = new SlidingWindowRateLimiter({ windowMs: 1000, max: 3 });
    expect(limiter.tryAcquire('u1')).toBe(true);
    expect(limiter.tryAcquire('u1')).toBe(true);
    expect(limiter.tryAcquire('u1')).toBe(true);
    expect(limiter.tryAcquire('u1')).toBe(false);
  });

  it('tracks users separately', () => {
    const limiter = new SlidingWindowRateLimiter({ windowMs: 1000, max: 2 });
    expect(limiter.tryAcquire('a')).toBe(true);
    expect(limiter.tryAcquire('a')).toBe(true);
    expect(limiter.tryAcquire('a')).toBe(false);
    expect(limiter.tryAcquire('b')).toBe(true);
  });

  it('does not count a rejected (over-budget) attempt against the next window', () => {
    jest.useFakeTimers();
    const limiter = new SlidingWindowRateLimiter({ windowMs: 1000, max: 1 });
    expect(limiter.tryAcquire('u1')).toBe(true);
    expect(limiter.tryAcquire('u1')).toBe(false);
    jest.advanceTimersByTime(1001);
    expect(limiter.tryAcquire('u1')).toBe(true);
    jest.useRealTimers();
  });

  it('evicts stale windows so memory does not grow unbounded', () => {
    jest.useFakeTimers();
    const limiter = new SlidingWindowRateLimiter({ windowMs: 1000, max: 1 });
    limiter.tryAcquire('u1');
    jest.advanceTimersByTime(2000);
    expect(limiter.activeUserCount()).toBe(0);
    jest.useRealTimers();
  });
});
