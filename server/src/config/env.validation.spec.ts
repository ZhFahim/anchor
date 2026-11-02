import { describe, expect, it } from 'vitest';
import 'reflect-metadata';
import { validate } from './env.validation';

describe('validate (environment)', () => {
  const base = {
    DATABASE_URL: 'postgresql://anchor:password@localhost:5432/anchor',
    JWT_SECRET: 'a-sufficiently-long-secret',
  };

  it('accepts a minimal valid config and applies defaults', () => {
    const config = validate({ ...base });

    expect(config.DATABASE_URL).toBe(base.DATABASE_URL);
    expect(config.NODE_ENV).toBe('development');
    expect(config.PORT).toBe(3001);
  });

  it('coerces a numeric-string PORT to a number', () => {
    expect(validate({ ...base, PORT: '8080' }).PORT).toBe(8080);
  });

  it('ignores unrelated environment variables', () => {
    expect(() =>
      validate({ ...base, PATH: '/usr/bin', HOME: '/root' }),
    ).not.toThrow();
  });

  it('throws when DATABASE_URL is missing', () => {
    expect(() => validate({ JWT_SECRET: base.JWT_SECRET })).toThrow(
      /DATABASE_URL/,
    );
  });

  it('throws when JWT_SECRET is missing', () => {
    expect(() => validate({ DATABASE_URL: base.DATABASE_URL })).toThrow(
      /JWT_SECRET/,
    );
  });

  it('throws when JWT_SECRET is shorter than 16 characters', () => {
    expect(() => validate({ ...base, JWT_SECRET: 'too-short' })).toThrow(
      /at least 16 characters/,
    );
  });

  it('rejects an out-of-range PORT', () => {
    expect(() => validate({ ...base, PORT: '70000' })).toThrow(/PORT/);
  });

  it('rejects an unknown NODE_ENV', () => {
    expect(() => validate({ ...base, NODE_ENV: 'staging' })).toThrow(
      /NODE_ENV/,
    );
  });

  it('accepts a valid USER_SIGNUP and rejects an invalid one', () => {
    expect(() => validate({ ...base, USER_SIGNUP: 'review' })).not.toThrow();
    expect(() => validate({ ...base, USER_SIGNUP: 'nope' })).toThrow(
      /USER_SIGNUP/,
    );
  });

  it('accepts a heartbeat URL on the LAN and rejects a non-URL', () => {
    expect(() =>
      validate({
        ...base,
        HEARTBEAT_URL: 'http://kuma:3001/api/push/abc?status=up&msg=OK&ping=',
        HEARTBEAT_INTERVAL: '30',
      }),
    ).not.toThrow();
    expect(() => validate({ ...base, HEARTBEAT_URL: 'not a url' })).toThrow(
      /HEARTBEAT_URL/,
    );
  });

  it('rejects a heartbeat interval under 10 seconds', () => {
    expect(() => validate({ ...base, HEARTBEAT_INTERVAL: '5' })).toThrow(
      /HEARTBEAT_INTERVAL/,
    );
  });
});
