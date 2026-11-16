import { describe, expect, it } from 'vitest';
import {
  generateRecoveryCodes,
  normalizeRecoveryCode,
  RECOVERY_CODE_COUNT,
} from './recovery-codes.util';

describe('recovery codes', () => {
  it('makes ten distinct codes shaped xxxxx-xxxxx without lookalikes', () => {
    const codes = generateRecoveryCodes();
    expect(codes).toHaveLength(RECOVERY_CODE_COUNT);
    expect(new Set(codes).size).toBe(RECOVERY_CODE_COUNT);
    for (const code of codes) {
      expect(code).toMatch(/^[a-hj-km-np-z2-9]{5}-[a-hj-km-np-z2-9]{5}$/);
    }
  });

  it('accepts a code however it was typed', () => {
    expect(normalizeRecoveryCode('k7m2-9xqp3a')).toBe('k7m29xqp3a');
    expect(normalizeRecoveryCode('  K7M29-XQP3A ')).toBe('k7m29xqp3a');
    expect(normalizeRecoveryCode('k7m29xqp3a')).toBe('k7m29xqp3a');
  });

  it('rejects anything that cannot be a code', () => {
    expect(normalizeRecoveryCode('')).toBeNull();
    expect(normalizeRecoveryCode('k7m2-9xq')).toBeNull();
    expect(normalizeRecoveryCode('k7m2-9xqp3a0')).toBeNull();
    // 0, 1, i, l and o never appear in generated codes.
    expect(normalizeRecoveryCode('k7m2l-9xqp3')).toBeNull();
  });
});
