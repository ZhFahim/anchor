export const BCRYPT_SALT_ROUNDS = 10;

export const ACCESS_TOKEN_TTL = '15m';

export const REFRESH_TOKEN_VALIDITY_DAYS = 90;

// How long a used refresh token keeps working.
export const REFRESH_TOKEN_REUSE_WINDOW_MS = 24 * 60 * 60 * 1000;

export const REFRESH_TOKEN_BYTES = 64;

export const API_TOKEN_MAX_GENERATION_RETRIES = 5;

// Wrong passwords (sign-in, unlocking a note) allowed per account before it
// has to wait for the window to pass.
export const MAX_FAILED_GUESSES = 10;
export const FAILED_GUESS_WINDOW_MS = 15 * 60 * 1000;

export const PROFILE_IMAGE_MAX_BYTES = 5 * 1024 * 1024;

// A magic sign-in code (Settings' QR code and link) is used once, within this.
export const MAGIC_LOGIN_VALIDITY_MS = 10 * 60 * 1000;
export const MAGIC_LOGIN_CODE_BYTES = 32;
