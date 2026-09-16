export interface SlidingWindowOptions {
  windowMs: number;
  max: number;
}

interface Bucket {
  timestamps: number[];
}

/**
 * In-memory fixed-window-with-fine-timescale rate limiter, keyed per subject
 * (e.g. user id). Rejects once the number of hits in the trailing window
 * exceeds `max`. Sliding-window semantics (rather than reset-on-boundary)
 * prevent a burst straddling a window edge from sneaking through.
 *
 * Memory is bounded: each key holds only timestamps inside the window and
 * expired keys are pruned on access.
 */
export class SlidingWindowRateLimiter {
  private readonly buckets = new Map<string, Bucket>();
  private readonly windowMs: number;
  private readonly max: number;

  constructor({ windowMs, max }: SlidingWindowOptions) {
    this.windowMs = windowMs;
    this.max = max;
  }

  /** Returns true if the hit is admitted, false if it's over the limit. */
  tryAcquire(key: string, now: number = Date.now()): boolean {
    const cutoff = now - this.windowMs;
    const bucket = this.buckets.get(key);
    const live = (bucket?.timestamps ?? []).filter((ts) => ts >= cutoff);

    if (live.length >= this.max) {
      this.buckets.set(key, { timestamps: live });
      return false;
    }

    live.push(now);
    this.buckets.set(key, { timestamps: live });
    return true;
  }

  /** Count of live hits for a key within the current window. */
  hitsFor(key: string, now: number = Date.now()): number {
    const cutoff = now - this.windowMs;
    const bucket = this.buckets.get(key);
    if (!bucket) return 0;
    const live = bucket.timestamps.filter((ts) => ts >= cutoff);
    this.buckets.set(key, { timestamps: live });
    return live.length;
  }

  /** Number of live (unexpired) keys, for tests/observability. */
  activeUserCount(now: number = Date.now()): number {
    const cutoff = now - this.windowMs;
    let active = 0;
    for (const [key, bucket] of this.buckets) {
      const live = bucket.timestamps.filter((ts) => ts >= cutoff);
      if (live.length > 0) {
        active++;
        this.buckets.set(key, { timestamps: live });
      } else {
        this.buckets.delete(key);
      }
    }
    return active;
  }

  /** Force-remove a key (tests, logout). */
  clearKey(key: string): void {
    this.buckets.delete(key);
  }
}
