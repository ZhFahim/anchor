import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import type { OidcExchangeResult } from './oidc.types';

export interface OidcState {
  state: string;
  codeVerifier?: string;
  redirectUrl?: string;
  expiresAt: number;
}

export type { OidcExchangeResult };

/**
 * In-memory store for OIDC state and exchange codes.
 */
@Injectable()
export class OidcStateService implements OnModuleDestroy {
  private readonly logger = new Logger(OidcStateService.name);
  private readonly stateStore = new Map<string, OidcState>();
  private readonly exchangeCodeStore = new Map<
    string,
    { result: OidcExchangeResult; expiresAt: number }
  >();
  private readonly STATE_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
  private readonly EXCHANGE_CODE_EXPIRY_MS = 60 * 1000; // 1 minute
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    // Start cleanup interval
    this.startCleanupInterval();
  }

  /**
   * Store OIDC state for CSRF protection
   */
  storeState(state: string, codeVerifier?: string, redirectUrl?: string): void {
    this.stateStore.set(state, {
      state,
      codeVerifier,
      redirectUrl,
      expiresAt: Date.now() + this.STATE_EXPIRY_MS,
    });
  }

  /**
   * Retrieve and validate OIDC state
   */
  getState(state: string): OidcState | null {
    const storedState = this.stateStore.get(state);
    if (!storedState) {
      return null;
    }

    // Check if expired
    if (Date.now() > storedState.expiresAt) {
      this.stateStore.delete(state);
      return null;
    }

    return storedState;
  }

  /**
   * Remove state after use
   */
  deleteState(state: string): void {
    this.stateStore.delete(state);
  }

  /**
   * Store OIDC auth result for one-time exchange code (short-lived, single-use).
   */
  storeExchangeResult(code: string, result: OidcExchangeResult): void {
    this.exchangeCodeStore.set(code, {
      result,
      expiresAt: Date.now() + this.EXCHANGE_CODE_EXPIRY_MS,
    });
  }

  /**
   * Consume exchange code: return stored result and delete. Returns null if invalid or expired.
   */
  consumeExchangeCode(code: string): OidcExchangeResult | null {
    const entry = this.exchangeCodeStore.get(code);
    if (!entry) {
      return null;
    }
    this.exchangeCodeStore.delete(code);
    if (Date.now() > entry.expiresAt) {
      return null;
    }
    return entry.result;
  }

  /**
   * Start cleanup interval for expired states
   */
  private startCleanupInterval(): void {
    if (this.cleanupInterval) {
      return;
    }

    // Clean up expired states every 5 minutes
    this.cleanupInterval = setInterval(
      () => {
        this.cleanupExpiredStates();
      },
      5 * 60 * 1000,
    );
  }

  /**
   * Clean up expired states and exchange codes
   */
  private cleanupExpiredStates(): void {
    const now = Date.now();
    let cleanedCount = 0;

    for (const [state, stateData] of this.stateStore.entries()) {
      if (now > stateData.expiresAt) {
        this.stateStore.delete(state);
        cleanedCount++;
      }
    }
    for (const [code, entry] of this.exchangeCodeStore.entries()) {
      if (now > entry.expiresAt) {
        this.exchangeCodeStore.delete(code);
        cleanedCount++;
      }
    }

    if (cleanedCount > 0) {
      this.logger.debug(`Cleaned up ${cleanedCount} expired OIDC states/codes`);
    }
  }

  /**
   * Cleanup on module destroy
   */
  onModuleDestroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }
}
