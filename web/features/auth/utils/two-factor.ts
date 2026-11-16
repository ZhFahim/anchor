import { HTTPError } from "ky";
import { errorBody } from "@/lib/api/error-body";
import type {
  AuthResponse,
  EnrollMethods,
  RegisterOutcome,
  SignInOutcome,
} from "../types";

/* ------------------------------ sign-in bodies ----------------------------- */

const isMethods = (value: unknown): value is EnrollMethods =>
  !!value &&
  typeof value === "object" &&
  typeof (value as EnrollMethods).totp === "boolean" &&
  typeof (value as EnrollMethods).passkey === "boolean";

/**
 * The server answers a sign-in that needs one more step with a 401 (a code to
 * enter) or a 403 (a second step to set up), and a challenge in the body.
 * Anything else is a plain refusal and stays an error.
 */
export function signInChallenge(
  status: number,
  body: Record<string, unknown> | null,
): Exclude<SignInOutcome, { kind: "signedIn" }> | null {
  if (!body) return null;
  if (status === 403 && body.passkeyRequired === true)
    return {
      kind: "passkeyRequired",
      message:
        typeof body.message === "string" && body.message
          ? body.message
          : "Sign in with your passkey",
    };
  if (typeof body.challenge !== "string" || !body.challenge) return null;
  if (status === 401 && body.twoFactorRequired === true)
    return { kind: "codeRequired", challenge: body.challenge };
  if (status === 403 && body.twoFactorSetupRequired === true)
    return {
      kind: "setupRequired",
      challenge: body.challenge,
      // Old and new servers alike offer the app when they say nothing.
      methods: isMethods(body.methods)
        ? body.methods
        : { totp: true, passkey: false },
    };
  return null;
}

export function signInChallengeOf(error: unknown) {
  return error instanceof HTTPError
    ? signInChallenge(error.response.status, errorBody(error))
    : null;
}

type RegisterBody = AuthResponse & {
  twoFactorSetupRequired?: boolean;
  challenge?: string;
  methods?: unknown;
};

/** A new account gets a session, a wait for approval, or a second step to set up. */
export function registerOutcome(body: RegisterBody): RegisterOutcome {
  if (body.access_token && body.refresh_token)
    return {
      kind: "signedIn",
      session: {
        access_token: body.access_token,
        refresh_token: body.refresh_token,
        user: body.user,
      },
    };
  if (body.twoFactorSetupRequired && body.challenge)
    return {
      kind: "setupRequired",
      challenge: body.challenge,
      methods: isMethods(body.methods)
        ? body.methods
        : { totp: true, passkey: false },
      user: body.user,
    };
  return { kind: "pending", message: body.message };
}

/* --------------------------------- failures -------------------------------- */

export type TwoFactorFailure =
  | { kind: "wrong-code" }
  | { kind: "expired" }
  | { kind: "locked"; retryAfterSeconds: number }
  | { kind: "throttled" }
  | { kind: "wrong-password" }
  | { kind: "required-by-admin" }
  | { kind: "current-code-required" }
  | { kind: "unavailable" }
  | { kind: "network" }
  | { kind: "server" }
  | { kind: "other"; message: string };

/**
 * What went wrong when a code or a password was turned down. Read from the
 * server's message, because the status for a wrong code differs between the
 * calls (401 when signing in, 400 when enrolling).
 */
export function twoFactorFailure(error: unknown): TwoFactorFailure {
  if (!(error instanceof HTTPError)) return { kind: "network" };
  const { status } = error.response;
  const body = errorBody(error);
  const message = error.message;
  if (status === 429) {
    const seconds = body?.retryAfterSeconds;
    return typeof seconds === "number"
      ? { kind: "locked", retryAfterSeconds: seconds }
      : { kind: "throttled" };
  }
  if (/challenge expired/i.test(message)) return { kind: "expired" };
  if (/invalid code/i.test(message)) return { kind: "wrong-code" };
  if (/current code required/i.test(message))
    return { kind: "current-code-required" };
  if (/required by your admin/i.test(message))
    return { kind: "required-by-admin" };
  if (/password is incorrect/i.test(message)) return { kind: "wrong-password" };
  if (status >= 500) return { kind: "server" };
  if (/not available|unavailable/i.test(message))
    return { kind: "unavailable" };
  return { kind: "other", message };
}

/** “10 minutes”, “1 minute”. Rounded up, so it is never too soon. */
export function formatRetryAfter(seconds: number): string {
  const minutes = Math.max(1, Math.ceil(seconds / 60));
  return minutes === 1 ? "1 minute" : `${minutes} minutes`;
}

export function describeFailure(
  failure: TwoFactorFailure,
  { recovery = false }: { recovery?: boolean } = {},
): string {
  switch (failure.kind) {
    case "wrong-code":
      return recovery
        ? "That recovery code didn’t work. Check it and try again."
        : "That code didn’t work. Check your app and try again.";
    case "expired":
      return "That sign-in took too long. Enter your password again.";
    case "locked":
      return `Too many wrong codes. Try again in ${formatRetryAfter(failure.retryAfterSeconds)}.`;
    case "throttled":
      return "Too many tries. Wait a minute, then try again.";
    case "wrong-password":
      return "That isn’t your current password.";
    case "required-by-admin":
      return "Your admin requires two-factor, so it has to stay on.";
    case "current-code-required":
      return "Enter a code from your current authenticator app.";
    case "unavailable":
      return "Two-factor isn’t available on this server.";
    case "network":
      return "Couldn’t reach the server. Check your connection and try again.";
    case "server":
      return "Something went wrong on the server. Try again in a moment.";
    case "other":
      return "Something went wrong. Try again.";
  }
}

/* ------------------------------ recovery codes ----------------------------- */

const RECOVERY_ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";
const RECOVERY_LENGTH = 10;

/** Lower case, without spaces or dashes: how the server compares them. */
export function normalizeRecoveryCode(input: string): string {
  return input.toLowerCase().replace(/[\s\-‐-―−]/g, "");
}

export function isRecoveryCode(input: string): boolean {
  const code = normalizeRecoveryCode(input);
  return (
    code.length === RECOVERY_LENGTH &&
    [...code].every((char) => RECOVERY_ALPHABET.includes(char))
  );
}

/** “k7m29xqpab” → “k7m29-xqpab”. Leaves a partial entry readable. */
export function formatRecoveryCode(input: string): string {
  const code = normalizeRecoveryCode(input).slice(0, RECOVERY_LENGTH);
  return code.length > 5 ? `${code.slice(0, 5)}-${code.slice(5)}` : code;
}

export function recoveryCodesFile(codes: readonly string[]): string {
  return [
    "Anchor recovery codes",
    "",
    "Each code works once. Keep them somewhere safe.",
    "",
    ...codes,
    "",
  ].join("\n");
}

/* ------------------------------- setup helpers ------------------------------ */

/** “JBSWY3DPEHPK3PXP” → “JBSW Y3DP EHPK 3PXP”. */
export function groupSecret(secret: string): string {
  return secret.replace(/\s+/g, "").replace(/(.{4})(?=.)/g, "$1 ");
}

/** A name to start from, so two passkeys can be told apart. */
export function suggestPasskeyName(userAgent: string): string {
  const os = /iPhone/.test(userAgent)
    ? "iPhone"
    : /iPad/.test(userAgent)
      ? "iPad"
      : /Android/.test(userAgent)
        ? "Android"
        : /Windows/.test(userAgent)
          ? "Windows"
          : /Mac OS X|Macintosh/.test(userAgent)
            ? "Mac"
            : /CrOS/.test(userAgent)
              ? "Chromebook"
              : /Linux/.test(userAgent)
                ? "Linux"
                : "";
  const browser = /Edg\//.test(userAgent)
    ? "Edge"
    : /OPR\/|Opera/.test(userAgent)
      ? "Opera"
      : /Firefox\//.test(userAgent)
        ? "Firefox"
        : /Chrome\/|CriOS/.test(userAgent)
          ? "Chrome"
          : /Safari\//.test(userAgent)
            ? "Safari"
            : "";
  return [os, browser].filter(Boolean).join(" · ") || "My passkey";
}

export type PasskeyCeremonyFailure =
  | "cancelled"
  | "already-registered"
  | "unsupported"
  | "other";

/** Why the browser's passkey prompt ended without a passkey. */
export function passkeyCeremonyFailure(error: unknown): PasskeyCeremonyFailure {
  const name = error instanceof Error ? error.name : "";
  const code = (error as { code?: string } | null)?.code;
  if (name === "NotAllowedError" || name === "AbortError") return "cancelled";
  if (
    name === "InvalidStateError" ||
    code === "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED"
  )
    return "already-registered";
  if (
    name === "NotSupportedError" ||
    code === "ERROR_AUTHENTICATOR_MISSING_DISCOVERABLE_CREDENTIAL_SUPPORT" ||
    code === "ERROR_AUTHENTICATOR_MISSING_USER_VERIFICATION_SUPPORT"
  )
    return "unsupported";
  return "other";
}

/** “Last used today”, “Last used 3 days ago”, “Never used”. */
export function lastUsedLabel(
  iso: string | null | undefined,
  now: Date = new Date(),
): string {
  if (!iso) return "Never used";
  const date = new Date(iso);
  const startOfDay = (d: Date) =>
    new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const days = Math.round((startOfDay(now) - startOfDay(date)) / 86_400_000);
  if (days <= 0) return "Last used today";
  if (days === 1) return "Last used yesterday";
  if (days < 30) return `Last used ${days} days ago`;
  return `Last used ${date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
}

/** What to tell someone whose passkey sign-in failed; nothing if they just closed the prompt. */
export function passkeySignInError(error: unknown): string | null {
  if (error instanceof HTTPError) {
    const { status } = error.response;
    if (status === 429) return "Too many tries. Wait a minute, then try again.";
    if (status >= 500)
      return "Something went wrong on the server. Try again in a moment.";
    return "That passkey didn’t work. Try again, or sign in with your password.";
  }
  const failure = passkeyCeremonyFailure(error);
  if (failure === "cancelled") return null;
  if (failure === "unsupported")
    return "This device can’t use that passkey. Sign in with your password instead.";
  if (error instanceof TypeError)
    return "Couldn’t reach the server. Check your connection and try again.";
  return "Couldn’t sign in with a passkey. Try again, or use your password.";
}
