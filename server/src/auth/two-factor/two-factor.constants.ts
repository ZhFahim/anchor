export const TWO_FACTOR_POLICIES = ['optional', 'admins', 'everyone'] as const;
export type TwoFactorPolicy = (typeof TWO_FACTOR_POLICIES)[number];

export const TWO_FACTOR_POLICY_SETTING_KEY = 'two_factor_policy';

// Wrong codes in a row before a user is locked out of every code check.
export const MAX_FAILED_CODE_ATTEMPTS = 5;
export const LOCKOUT_MS = 10 * 60 * 1000;

export const LOGIN_CHALLENGE_TTL_MS = 5 * 60 * 1000;
export const ENROLL_CHALLENGE_TTL_MS = 15 * 60 * 1000;
export const WEBAUTHN_CHALLENGE_TTL_MS = 5 * 60 * 1000;
// Wrong codes one login challenge survives.
export const MAX_CHALLENGE_ATTEMPTS = 5;
// Unauthenticated passkey sign-ins may only pile up so many open challenges.
export const MAX_OPEN_WEBAUTHN_LOGIN_CHALLENGES = 5000;

export const MAX_PASSKEYS_PER_USER = 10;
export const TOTP_ISSUER = 'Anchor';
